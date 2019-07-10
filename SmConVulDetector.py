import matplotlib

matplotlib.use('agg')
import numpy as np
import os
import copy
import time
import torch
import torch.utils
import torch.utils.data
import torch.nn.functional as F
import torch.optim as optim
import torch.optim.lr_scheduler as lr_scheduler
from torch.utils.data import DataLoader
from os.path import join as pjoin
from parser import parameter_parser
from models.gcn import GCN
from models.gcn_test import GCN_TEST
from models.gat import GAT
from models.mgcn import MGCN
from models.graphUnet import GraphUnet

print('using torch', torch.__version__)

args = parameter_parser()

if args.torch_geom:
    from torch_geometric.datasets import TUDataset

args.filters = list(map(int, args.filters.split(',')))
args.lr_decay_steps = list(map(int, args.lr_decay_steps.split(',')))

for arg in vars(args):
    print(arg, getattr(args, arg))

n_folds = 10  # n-fold cross validation
torch.backends.cudnn.deterministic = True
torch.backends.cudnn.benchmark = True
torch.manual_seed(args.seed)
torch.cuda.manual_seed(args.seed)
torch.cuda.manual_seed_all(args.seed)
rnd_state = np.random.RandomState(args.seed)


def split_ids(ids, folds=n_folds):
    n = len(ids)
    stride = int(np.ceil(n / float(folds)))
    test_ids = [ids[i: i + stride] for i in range(0, n, stride)]
    assert np.all(
        np.unique(np.concatenate(test_ids)) == sorted(ids)), 'some graphs are missing in the test sets'
    assert len(test_ids) == folds, 'invalid test sets'
    train_ids = []
    for fold in range(folds):
        train_ids.append(np.array([e for e in ids if e not in test_ids[fold]]))
        assert len(train_ids[fold]) + len(test_ids[fold]) == len(
            np.unique(list(train_ids[fold]) + list(test_ids[fold]))) == n, 'invalid splits'

    return train_ids, test_ids


if not args.torch_geom:
    # Universal data loader and reader
    class GraphData(torch.utils.data.Dataset):
        def __init__(self, datareader, fold_id, split):
            self.fold_id = fold_id
            self.split = split
            self.rnd_state = datareader.rnd_state
            self.set_fold(datareader.data, fold_id)

        def set_fold(self, data, fold_id):
            self.total = len(data['targets'])
            self.N_nodes_max = data['N_nodes_max']
            self.num_classes = data['num_classes']
            self.num_features = data['num_features']
            self.idx = data['splits'][fold_id][self.split]
            # use deepcopy to make sure we don't alter objects in folds
            self.labels = copy.deepcopy([data['targets'][i] for i in self.idx])
            self.adj_list = copy.deepcopy([data['adj_list'][i] for i in self.idx])
            self.features_onehot = copy.deepcopy([data['features_onehot'][i] for i in self.idx])
            print('%s: %d/%d' % (self.split.upper(), len(self.labels), len(data['targets'])))

        def __len__(self):
            return len(self.labels)

        def __getitem__(self, index):
            # convert to torch
            return [torch.from_numpy(self.features_onehot[index]).float(),  # node_features
                    torch.from_numpy(self.adj_list[index]).float(),  # adjacency matrix
                    int(self.labels[index])]


    class DataReader():
        """
        Class to read the txt files containing all data of the dataset
        """
        def __init__(self, data_dir, rnd_state=None, use_cont_node_attr=False, folds=n_folds):
            self.data_dir = data_dir
            self.rnd_state = np.random.RandomState() if rnd_state is None else rnd_state
            self.use_cont_node_attr = use_cont_node_attr
            files = os.listdir(self.data_dir)
            data = {}
            nodes, graphs = self.read_graph_nodes_relations(
                list(filter(lambda f: f.find('graph_indicator') >= 0, files))[0])
            data['features'] = self.read_node_features(list(filter(lambda f: f.find('node_labels') >= 0, files))[0],
                                                       nodes, graphs, fn=lambda s: int(s.strip()))
            data['adj_list'] = self.read_graph_adj(list(filter(lambda f: f.find('_A') >= 0, files))[0], nodes, graphs)
            data['targets'] = np.array(
                self.parse_txt_file(list(filter(lambda f: f.find('graph_labels') >= 0, files))[0],
                                    line_parse_fn=lambda s: int(float(s.strip()))))
            if self.use_cont_node_attr:
                data['attr'] = self.read_node_features(list(filter(lambda f: f.find('node_attributes') >= 0, files))[0],
                                                       nodes, graphs,
                                                       fn=lambda s: np.array(list(map(float, s.strip().split(',')))))
            features, n_edges, degrees = [], [], []
            for sample_id, adj in enumerate(data['adj_list']):
                N = len(adj)  # number of nodes
                if data['features'] is not None:
                    assert N == len(data['features'][sample_id]), (N, len(data['features'][sample_id]))
                n = np.sum(adj)  # total sum of edges
                assert n % 2 == 0, n
                n_edges.append(int(n / 2))  # undirected edges, so need to divide by 2
                if not np.allclose(adj, adj.T):
                    print(sample_id, 'not symmetric')
                degrees.extend(list(np.sum(adj, 1)))
                features.append(np.array(data['features'][sample_id]))

            # Create features over graphs as one-hot vectors for each node
            features_all = np.concatenate(features)
            features_min = features_all.min()
            num_features = int(features_all.max() - features_min + 1)  # number of possible values

            features_onehot = []
            for i, x in enumerate(features):
                feature_onehot = np.zeros((len(x), num_features))
                for node, value in enumerate(x):
                    feature_onehot[node, value - features_min] = 1
                if self.use_cont_node_attr:
                    feature_onehot = np.concatenate((feature_onehot, np.array(data['attr'][i])), axis=1)
                features_onehot.append(feature_onehot)

            if self.use_cont_node_attr:
                num_features = features_onehot[0].shape[1]

            shapes = [len(adj) for adj in data['adj_list']]
            labels = data['targets']  # graph class labels
            labels -= np.min(labels)  # to start from 0

            classes = np.unique(labels)
            num_classes = len(classes)

            if not np.all(np.diff(classes) == 1):
                print('making labels sequential, otherwise pytorch might crash')
                labels_new = np.zeros(labels.shape, dtype=labels.dtype) - 1
                for lbl in range(num_classes):
                    labels_new[labels == classes[lbl]] = lbl
                labels = labels_new
                classes = np.unique(labels)
                assert len(np.unique(labels)) == num_classes, np.unique(labels)

            def stats(x):
                return (np.mean(x), np.std(x), np.min(x), np.max(x))

            print('N nodes avg/std/min/max: \t%.2f/%.2f/%d/%d' % stats(shapes))
            print('N edges avg/std/min/max: \t%.2f/%.2f/%d/%d' % stats(n_edges))
            print('Node degree avg/std/min/max: \t%.2f/%.2f/%d/%d' % stats(degrees))
            print('Node features dim: \t\t%d' % num_features)
            print('N classes: \t\t\t%d' % num_classes)
            print('Classes: \t\t\t%s' % str(classes))
            for lbl in classes:
                print('Class %d: \t\t\t%d samples' % (lbl, np.sum(labels == lbl)))

            for u in np.unique(features_all):
                print('feature {}, count {}/{}'.format(u, np.count_nonzero(features_all == u), len(features_all)))

            N_graphs = len(labels)  # number of samples (graphs) in data
            assert N_graphs == len(data['adj_list']) == len(features_onehot), 'invalid data'

            # Create test sets first
            train_ids, test_ids = split_ids(rnd_state.permutation(N_graphs), folds=folds)

            # Create train sets
            splits = []
            for fold in range(folds):
                splits.append({'train': train_ids[fold],
                               'test': test_ids[fold]})

            data['features_onehot'] = features_onehot
            data['targets'] = labels
            data['splits'] = splits
            data['N_nodes_max'] = np.max(shapes)  # max number of nodes
            data['num_features'] = num_features
            data['num_classes'] = num_classes
            self.data = data

        def parse_txt_file(self, fpath, line_parse_fn=None):
            with open(pjoin(self.data_dir, fpath), 'r') as f:
                lines = f.readlines()
            data = [line_parse_fn(s) if line_parse_fn is not None else s for s in lines]
            return data

        def read_graph_adj(self, fpath, nodes, graphs):
            edges = self.parse_txt_file(fpath, line_parse_fn=lambda s: s.split(','))
            adj_dict = {}
            for edge in edges:
                node1 = int(edge[0].strip()) - 1  # -1 because of zero-indexing in our code
                node2 = int(edge[1].strip()) - 1
                graph_id = nodes[node1]
                assert graph_id == nodes[node2], ('invalid data', graph_id, nodes[node2])
                if graph_id not in adj_dict:
                    n = len(graphs[graph_id])
                    adj_dict[graph_id] = np.zeros((n, n))
                ind1 = np.where(graphs[graph_id] == node1)[0]
                ind2 = np.where(graphs[graph_id] == node2)[0]
                assert len(ind1) == len(ind2) == 1, (ind1, ind2)
                adj_dict[graph_id][ind1, ind2] = 1
            adj_list = [adj_dict[graph_id] for graph_id in sorted(list(graphs.keys()))]
            return adj_list

        def read_graph_nodes_relations(self, fpath):
            graph_ids = self.parse_txt_file(fpath, line_parse_fn=lambda s: int(s.rstrip()))
            nodes, graphs = {}, {}
            for node_id, graph_id in enumerate(graph_ids):
                if graph_id not in graphs:
                    graphs[graph_id] = []
                graphs[graph_id].append(node_id)
                nodes[node_id] = graph_id
            graph_ids = np.unique(list(graphs.keys()))
            for graph_id in graph_ids:
                graphs[graph_id] = np.array(graphs[graph_id])
            return nodes, graphs

        def read_node_features(self, fpath, nodes, graphs, fn):
            node_features_all = self.parse_txt_file(fpath, line_parse_fn=fn)
            node_features = {}
            for node_id, x in enumerate(node_features_all):
                graph_id = nodes[node_id]
                if graph_id not in node_features:
                    node_features[graph_id] = [None] * len(graphs[graph_id])
                ind = np.where(graphs[graph_id] == node_id)[0]
                assert len(ind) == 1, ind
                assert node_features[graph_id][ind[0]] is None, node_features[graph_id][ind[0]]
                node_features[graph_id][ind[0]] = x
            node_features_lst = [node_features[graph_id] for graph_id in sorted(list(graphs.keys()))]
            return node_features_lst


def collate_batch(batch):
    """
    Creates a batch of same size graphs by zero-padding node features and adjacency matrices up to
    the maximum number of nodes in the CURRENT batch rather than in the entire dataset.
    Graphs in the batches are usually much smaller than the largest graph in the dataset, so this method is fast.
    :param batch: batch in the PyTorch Geometric format or [node_features*batch_size, A*batch_size, label*batch_size]
    :return: [node_features, A, graph_support, N_nodes, label]
    """
    B = len(batch)
    if args.torch_geom:
        N_nodes = [len(batch[b].x) for b in range(B)]
        C = batch[0].x.shape[1]
    else:
        N_nodes = [len(batch[b][1]) for b in range(B)]
        C = batch[0][0].shape[1]
    N_nodes_max = int(np.max(N_nodes))

    graph_support = torch.zeros(B, N_nodes_max)
    A = torch.zeros(B, N_nodes_max, N_nodes_max)
    x = torch.zeros(B, N_nodes_max, C)
    for b in range(B):
        if args.torch_geom:
            x[b, :N_nodes[b]] = batch[b].x
            A[b].index_put_((batch[b].edge_index[0], batch[b].edge_index[1]), torch.Tensor([1]))
        else:
            x[b, :N_nodes[b]] = batch[b][0]
            A[b, :N_nodes[b], :N_nodes[b]] = batch[b][1]
        graph_support[b][:N_nodes[b]] = 1  # mask with values of 0 for dummy (zero padded) nodes, otherwise 1

    N_nodes = torch.from_numpy(np.array(N_nodes)).long()
    labels = torch.from_numpy(np.array([batch[b].y if args.torch_geom else batch[b][2] for b in range(B)])).long()
    return [x, A, graph_support, N_nodes, labels]


print('Loading data')

if args.torch_geom:
    dataset = TUDataset('./data/%s/' % args.dataset, name=args.dataset,
                        use_node_attr=args.use_cont_node_attr)
    train_ids, test_ids = split_ids(rnd_state.permutation(len(dataset)), folds=n_folds)
else:
    datareader = DataReader(data_dir='./data/%s/' % args.dataset, rnd_state=rnd_state, folds=n_folds,
                            use_cont_node_attr=args.use_cont_node_attr)

acc_folds = []
for fold_id in range(n_folds):
    loaders = []
    for split in ['train', 'test']:
        if args.torch_geom:
            gdata = dataset[torch.from_numpy((train_ids if split.find('train') >= 0 else test_ids)[fold_id])]
        else:
            gdata = GraphData(fold_id=fold_id, datareader=datareader, split=split)
        loader = DataLoader(gdata, batch_size=args.batch_size, shuffle=split.find('train') >= 0,
                            num_workers=args.threads, collate_fn=collate_batch)
        loaders.append(loader)
    print('\nFOLD {}, train {}, test {}'.format(fold_id, len(loaders[0].dataset), len(loaders[1].dataset)))

    if args.model == 'gcn':
        model = GCN(in_features=loaders[0].dataset.num_features,
                    out_features=loaders[0].dataset.num_classes,
                    n_hidden=args.n_hidden,
                    filters=args.filters,
                    dropout=args.dropout,
                    adj_sq=args.adj_sq,
                    scale_identity=args.scale_identity).to(args.device)
    elif args.model == 'gcn_test':
        model = GCN_TEST(n_feature=loaders[0].dataset.num_features,
                         n_hidden=64,
                         n_class=loaders[0].dataset.num_classes,
                         dropout=args.dropout).to(args.device)
    elif args.model == 'unet':
        model = GraphUnet(in_features=loaders[0].dataset.num_features,
                          out_features=loaders[0].dataset.num_classes,
                          n_hidden=args.n_hidden,
                          filters=args.filters,
                          dropout=args.dropout,
                          adj_sq=args.adj_sq,
                          scale_identity=args.scale_identity,
                          shuffle_nodes=args.shuffle_nodes,
                          visualize=args.visualize).to(args.device)
    elif args.model == 'mgcn':
        model = MGCN(in_features=loaders[0].dataset.num_features,
                     out_features=loaders[0].dataset.num_classes,
                     n_relations=2,
                     n_hidden=args.n_hidden,
                     filters=args.filters,
                     dropout=args.dropout,
                     adj_sq=args.adj_sq,
                     scale_identity=args.scale_identity).to(args.device)
    elif args.model == 'gat':
        model = GAT(nfeat=loaders[0].dataset.num_features,
                    nhid=64,
                    nclass=loaders[0].dataset.num_classes,
                    dropout=args.dropout,
                    alpha=args.alpha,
                    nheads=args.multi_head).to(args.device)
    else:
        raise NotImplementedError(args.model)
    print('\nInitialize model')
    print(model)

    train_params = list(filter(lambda p: p.requires_grad, model.parameters()))
    print('N trainable parameters:', np.sum([p.numel() for p in train_params]))
    optimizer = optim.Adam(train_params, lr=args.lr, betas=(0.5, 0.999), weight_decay=args.wd)
    # 三段式lr，epoch进入milestones范围内即乘以gamma，离开milestones范围之后再乘以gamma
    scheduler = lr_scheduler.MultiStepLR(optimizer, args.lr_decay_steps, gamma=0.1)


    def train(train_loader):
        scheduler.step()
        model.train()

        start = time.time()
        train_loss, n_samples = 0, 0
        for batch_idx, data in enumerate(train_loader):
            for i in range(len(data)):
                data[i] = data[i].to(args.device)
            # if args.use_cont_node_attr:
            #     data[0] = norm_features(data[0])
            optimizer.zero_grad()
            # output = model(data[0], data[1])
            output = model(data)
            loss = loss_fn(output, data[4])
            loss.backward()
            optimizer.step()

            time_iter = time.time() - start
            train_loss += loss.item() * len(output)
            n_samples += len(output)
            if batch_idx % args.log_interval == 0 or batch_idx == len(train_loader) - 1:
                print('Train Epoch: {} [{}/{} ({:.0f}%)]\tLoss: {:.6f} (avg: {:.6f}) \tsec/iter: {:.4f}'.format(
                    epoch + 1, n_samples, len(train_loader.dataset),
                    100. * (batch_idx + 1) / len(train_loader), loss.item(), train_loss / n_samples,
                    time_iter / (batch_idx + 1)))


    def test(test_loader):
        model.eval()
        start = time.time()
        test_loss, correct, n_samples = 0, 0, 0
        for batch_idx, data in enumerate(test_loader):
            for i in range(len(data)):
                data[i] = data[i].to(args.device)
            # if args.use_cont_node_attr:
            #     data[0] = norm_features(data[0])
            # output = model(data[0], data[1])
            output = model(data)
            loss = loss_fn(output, data[4], reduction='sum')
            test_loss += loss.item()
            n_samples += len(output)
            pred = output.detach().cpu().max(1, keepdim=True)[1]
            correct += pred.eq(data[4].detach().cpu().view_as(pred)).sum().item()

        acc = 100. * correct / n_samples
        print('Test set (epoch {}): Average loss: {:.4f}, Accuracy: {}/{} ({:.2f}%) \tsec/iter: {:.4f}\n'.format(
            epoch + 1,
            test_loss / n_samples,
            correct,
            n_samples,
            acc, (time.time() - start) / len(test_loader)))
        return acc


    # loss_fn = F.nll_loss
    loss_fn = F.cross_entropy
    for epoch in range(args.epochs):
        train(loaders[0])
        acc = test(loaders[1])
    acc_folds.append(acc)

print(acc_folds)
print('{}-fold cross validation avg acc (+- std): {} ({})'.format(n_folds, np.mean(acc_folds), np.std(acc_folds)))
