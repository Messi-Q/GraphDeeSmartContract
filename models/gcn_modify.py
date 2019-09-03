import torch
import torch.nn as nn
from parser import parameter_parser
from models.layers import GraphConv

args = parameter_parser()


class GCN_MODIFY(nn.Module):
    """
    Baseline Graph Convolutional Network with a stack of Graph Convolution Layers and global pooling over nodes.
    """
    def __init__(self, in_features, out_features, filters=args.filters,
                 n_hidden=args.n_hidden, dropout=args.dropout, adj_sq=False, scale_identity=False):
        super(GCN_MODIFY, self).__init__()
        # Graph convolution layers
        self.gconv = nn.Sequential(*([GraphConv(in_features=in_features if layer == 0 else filters[layer - 1],
                                                out_features=f, activation=nn.ReLU(inplace=True),
                                                adj_sq=adj_sq, scale_identity=scale_identity) for layer, f in enumerate(filters)]))
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
        x = self.gconv(data)[0]
        x = torch.max(x, dim=1)[0].squeeze()  # max pooling over nodes (usually performs better than average)
        x = self.fc(x)
        return x

