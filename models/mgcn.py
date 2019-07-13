import torch
import torch.nn as nn
import numpy as np
from parser import parameter_parser
from models.layers import GraphConv

args = parameter_parser()


class MGCN(nn.Module):
    """
    Multigraph Convolutional Network based on
    (B. Knyazev et al., "Spectral Multigraph Networks for Discovering and Fusing Relationships in Molecules")
    """

    def __init__(self, in_features, out_features, n_relations, filters=[64, 64, 64],
                 n_hidden=0, dropout=0.2,adj_sq=False, scale_identity=False):
        super(MGCN, self).__init__()

        # Graph convolution layers
        self.gconv = nn.Sequential(*([GraphConv(in_features=in_features if layer == 0 else filters[layer - 1],
                                                out_features=f,
                                                n_relations=n_relations,
                                                activation=nn.ReLU(inplace=True),
                                                adj_sq=adj_sq,
                                                scale_identity=scale_identity) for layer, f in enumerate(filters)]))

        # Edge prediction NN
        self.edge_pred = nn.Sequential(nn.Linear(in_features * 2, 32),
                                       nn.ReLU(inplace=True),
                                       nn.Linear(32, 1))

        # Fully connected layers
        fc = []
        if dropout > 0:
            fc.append(nn.Dropout(p=dropout))
        if n_hidden > 0:
            fc.append(nn.Linear(filters[-1], n_hidden))
            if dropout > 0:
                fc.append(nn.Dropout(p=dropout))
            n_last = n_hidden
        else:
            n_last = filters[-1]
        fc.append(nn.Linear(n_last, out_features))
        self.fc = nn.Sequential(*fc)

    def forward(self, data):
        # data: [node_features, A, graph_support, N_nodes, label]
        # Predict edges based on features
        x = data[0]
        B, N, C = x.shape
        mask = data[2]
        # find indices of nodes
        x_cat, idx = [], []
        for b in range(B):
            n = int(mask[b].sum())
            node_i = torch.nonzero(mask[b]).repeat(1, n).view(-1, 1)
            node_j = torch.nonzero(mask[b]).repeat(n, 1).view(-1, 1)
            triu = (node_i < node_j).squeeze()  # skip loops and symmetric connections
            x_cat.append(torch.cat((x[b, node_i[triu]], x[b, node_j[triu]]), 2).view(int(torch.sum(triu)), C * 2))
            idx.append((node_i * N + node_j)[triu].squeeze())

        x_cat = torch.cat(x_cat)
        idx_flip = np.concatenate((np.arange(C, 2 * C), np.arange(C)))
        # predict values and encourage invariance to nodes order
        y = torch.exp(0.5 * (self.edge_pred(x_cat) + self.edge_pred(x_cat[:, idx_flip])).squeeze())
        A_pred = torch.zeros(B, N * N, device=args.device)
        c = 0
        for b in range(B):
            A_pred[b, idx[b]] = y[c:c + idx[b].nelement()]
            c += idx[b].nelement()
        A_pred = A_pred.view(B, N, N)
        A_pred = (A_pred + A_pred.permute(0, 2, 1))  # assume undirected edges

        # Use both annotated and predicted adjacency matrices to learn a GCN
        data = (x, torch.stack((data[1], A_pred), 3), mask)
        x = self.gconv(data)[0]
        x = torch.max(x, dim=1)[0].squeeze()  # max pooling over nodes
        x = self.fc(x)
        return x
