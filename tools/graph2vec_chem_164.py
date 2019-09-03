import os
import json
import numpy as np
from tools.vec2onehot_chem_164 import vec2onehot

"""
S, W, C features: Node features + Edge features + Var features;
Node self property + Incoming Var + Outgoing Var + Incoming Edge + Outgoing Edge
"""

dict_AC = {"NULL": 0, "LimitedAC": 1, "NoLimit": 2}

dict_NodeName = {"NULL": 0, "VAR0": 1, "VAR1": 2, "VAR2": 3, "VAR3": 4, "VAR4": 5, "S0": 6, "S1": 7, "S2": 8, "S3": 9,
                 "S4": 10, "S5": 11, "W0": 12, 'W1': 13, 'W2': 14, 'W3': 15, 'W4': 16, 'W5': 17, "C0": 18, 'C1': 19,
                 'C2': 20, 'C3': 21, 'C4': 22, 'C5': 23, 'MSG': 24}

dict_VarOpName = {"NULL": 0, "BOOL": 1, "ASSIGN": 2, "INCRT": 3, "DECRT": 4}

dict_EdgeOpName = {"NULL": 0, "FW": 1, "READ": 2, "IF": 3, "GB": 4, "GN": 5, "WHILE": 6, "DW": 7, "FOR": 8, "DF": 9,
                   "BREAK": 10, "CONTI": 11, "RE": 12, "AH": 13, "RG": 14, "RH": 15, "IT": 16}

dict_AllOpName = {"NULL": 0, "FW": 1, "READ": 2, "ASSIGN": 3, "INCRT": 4, "DECRT": 5, "BOOL": 6, "IF": 7, "GB": 8,
                  "GN": 9, "WHILE": 10, "DW": 11, "FOR": 12, "DF": 13, "BREAK": 14, "CONTI": 15, "RE": 16, "ASSERT": 17,
                  "RG": 18, "REVERT": 19, "IT": 20}

dict_NodeOpName = {"NULL": 0, "MSG": 1, "INNADD": 2}

dict_ConName = {"NULL": 0, "ARG1": 1, "ARG2": 2, "ARG3": 3, "CON1": 4, "CON2": 5, "CON3": 6, "CNS1": 7,
                "CNS2": 8, "CNS3": 9}

node_convert = {"S0": 0, "W0": 1, "C0": 2, "VAR0": "VAR0", "VAR1": "VAR1", "VAR2": "VAR2", "VAR3": "VAR3",
                "VAR4": "VAR4"}

v2o = vec2onehot()  # create the one-bot dicts


# extract the features of each node from input file #
def extract_node_features(nodeFile):
    nodeNum = 0
    node_list = []
    node_attribute_list = []

    f = open(nodeFile)
    lines = f.readlines()
    f.close()

    for line in lines:
        node = list(map(str, line.split()))
        verExist = False
        for i in range(0, len(node_list)):
            if node[1] == node_list[i]:
                verExist = True
            else:
                continue
        if verExist is False:
            node_list.append(node[1])
            nodeNum += 1
        node_attribute_list.append(node)

    return nodeNum, node_list, node_attribute_list


# elimination procedure for sub_graph Start here #
def elimination_node(nodeNum, node_list, node_attribute_list):
    node_encode = np.zeros(shape=(nodeNum + 1, 10, 5))
    extra_var_list = []  # extract var with low priority
    for i in range(0, len(node_attribute_list)):
        if i + 1 < len(node_attribute_list):
            if node_attribute_list[i][1] == node_attribute_list[i + 1][1]:
                loc1 = int(node_attribute_list[i][3])  # relative location
                op1 = node_attribute_list[i][4]  # operation
                loc2 = int(node_attribute_list[i + 1][3])
                op2 = node_attribute_list[i + 1][4]
                if loc2 - loc1 == 1:
                    op1_index = dict_VarOpName[op1]
                    op2_index = dict_VarOpName[op2]
                    # extract node attribute based on priority
                    if op1_index < op2_index:
                        extra_var_list.append(node_attribute_list.pop(i))
                    else:
                        extra_var_list.append(node_attribute_list.pop(i + 1))
                else:
                    pass
            else:
                pass
        else:
            pass

    return node_attribute_list, extra_var_list


def embedding_node(node_attribute_list):
    # embedding each node after elimination #
    node_encode = []
    var_encode = []
    node_embedding = []
    var_embedding = []
    main_point = ['S0', 'S1', 'S2', 'S3', 'S4', 'S5', 'W0', 'W1', 'W2', 'W3', 'W4', 'W5', 'C0', 'C1', 'C2',
                  'C3', 'C4', 'C5']

    for j in range(0, len(node_attribute_list)):
        v = node_attribute_list[j][0]
        if v in main_point:
            vf0 = node_attribute_list[j][0]
            vf1 = dict_NodeName[node_attribute_list[j][1]]
            vfm1 = v2o.node2vecEmbedding(node_attribute_list[j][1])
            vf2 = dict_AC[node_attribute_list[j][2]]
            vfm2 = v2o.nodeAC2vecEmbedding(node_attribute_list[j][2])
            vf3 = dict_NodeName[node_attribute_list[j][3]]
            vfm3 = v2o.node2vecEmbedding(node_attribute_list[j][3])
            vf4 = int(node_attribute_list[j][4])
            vfm4 = v2o.sn2vecEmbedding(node_attribute_list[j][4])
            vf5 = dict_NodeOpName[node_attribute_list[j][5]]
            vfm5 = v2o.nodeOP2vecEmbedding(node_attribute_list[j][5])
            nodeEmbedding = vfm1.tolist() + vfm2.tolist() + vfm3.tolist() + vfm4.tolist() + vfm5.tolist()
            node_embedding.append([vf0, np.array(nodeEmbedding)])
            temp = [vf1, vf2, vf3, vf4, vf5]
            node_encode.append([vf0, temp])
        else:
            vf0 = node_attribute_list[j][0]
            vf1 = dict_NodeName[node_attribute_list[j][1]]
            vfm1 = v2o.node2vecEmbedding(node_attribute_list[j][1])
            vf2 = dict_NodeName[node_attribute_list[j][2]]
            vfm2 = v2o.node2vecEmbedding(node_attribute_list[j][2])
            vf3 = int(node_attribute_list[j][3])
            vfm3 = v2o.sn2vecEmbedding(node_attribute_list[j][3])
            vf4 = dict_VarOpName[node_attribute_list[j][4]]
            vfm4 = v2o.varOP2vecEmbedding(node_attribute_list[j][4])
            vf5 = int(dict_NodeOpName['NULL'])
            vfm5 = v2o.nodeOP2vecEmbedding('NULL')
            varEmbedding = vfm1.tolist() + vfm2.tolist() + vfm3.tolist() + vfm4.tolist() + vfm5.tolist()
            var_embedding.append([vf0, np.array(varEmbedding)])
            temp = [vf1, vf2, vf3, vf4, vf5]
            var_encode.append([vf0, temp])

    return node_encode, var_encode, node_embedding, var_embedding


def elimination_edge(edgeFile):
    # eliminate edge #
    edge_list = []  # all edges
    extra_edge_list = []  # eliminated edges

    f = open(edgeFile)
    lines = f.readlines()
    f.close()

    for line in lines:
        edge = list(map(str, line.split()))
        edge_list.append(edge)

    # The ablation of multiple edges between two nodes, taking the edge with the edge_operation priority
    for k in range(0, len(edge_list)):
        if k + 1 < len(edge_list):
            start1 = edge_list[k][0]  # start node
            end1 = edge_list[k][1]  # end node
            op1 = edge_list[k][4]
            start2 = edge_list[k + 1][0]
            end2 = edge_list[k + 1][1]
            op2 = edge_list[k + 1][4]
            if start1 == start2 and end1 == end2:
                op1_index = dict_EdgeOpName[op1]
                op2_index = dict_EdgeOpName[op2]
                # extract edge attribute based on priority
                if op1_index < op2_index:
                    extra_edge_list.append(edge_list.pop(k))
                else:
                    extra_edge_list.append(edge_list.pop(k + 1))

    return edge_list, extra_edge_list


def embedding_edge(edge_list):
    # extract & embedding the features of each edge from input file #
    edge_encode = []
    edge_embedding = []

    for k in range(len(edge_list)):
        start = edge_list[k][0]  # start node
        end = edge_list[k][1]  # end node
        a, b, c = edge_list[k][2], edge_list[k][3], edge_list[k][4]  # origin info

        ef1 = dict_NodeName[a]
        ef2 = int(b)
        ef3 = dict_EdgeOpName[c]

        ef_temp = [ef1, ef2, ef3]
        edge_encode.append([start, end, ef_temp])

        efm1 = v2o.node2vecEmbedding(a)
        efm2 = v2o.sn2vecEmbedding(b)
        efm3 = v2o.edgeOP2vecEmbedding(c)

        efm_temp = efm1.tolist() + efm2.tolist() + efm3.tolist()
        edge_embedding.append([start, end, np.array(efm_temp)])

    return edge_encode, edge_embedding


def construct_var_edge_vec(edge_list, node_embedding, var_embedding, edge_embedding, edge_encode):
    # Vec: Node self property + Incoming Var + Outgoing Var + Incoming Edge + Outgoing Edge
    print("Start constructing node vector...")
    var_in_node = []
    var_in = []
    var_out_node = []
    var_out = []
    edge_in_node = []
    edge_in = []
    edge_out_node = []
    edge_out = []
    node_vec = []
    S_point = ['S0', 'S1', 'S2', 'S3', 'S4', 'S5']
    W_point = ['W0', 'W1', 'W2', 'W3', 'W4', 'W5']
    C_point = ['C0', 'C1', 'C2', 'C3', 'C4', 'C5']
    main_point = ['S0', 'S1', 'S2', 'S3', 'S4', 'S5', 'W0', 'W1', 'W2', 'W3', 'W4', 'W5', 'C0', 'C1', 'C2',
                  'C3', 'C4', 'C5']

    if len(var_embedding) > 0:
        for k in range(len(edge_embedding)):
            if edge_list[k][0] in C_point:
                for i in range(len(var_embedding)):
                    if str(var_embedding[i][0]) == str(edge_embedding[k][1]):
                        var_out.append([edge_embedding[k][0], var_embedding[i][1]])
                        edge_out.append([edge_embedding[k][0], edge_embedding[k][2]])
            elif edge_list[k][1] in C_point:
                for i in range(len(var_embedding)):
                    if str(var_embedding[i][0]) == str(edge_embedding[k][0]):
                        var_in.append([edge_embedding[k][1], var_embedding[i][1]])
                        edge_in.append([edge_embedding[k][1], edge_embedding[k][2]])

            elif edge_list[k][0] in W_point:
                for i in range(len(var_embedding)):
                    if str(var_embedding[i][0]) == str(edge_embedding[k][1]):
                        var_out.append([edge_embedding[k][0], var_embedding[i][1]])
                        edge_out.append([edge_embedding[k][0], edge_embedding[k][2]])
                        break
            elif edge_list[k][1] in W_point:
                for i in range(len(var_embedding)):
                    if str(var_embedding[i][0]) == str(edge_embedding[k][0]):
                        var_in.append([edge_embedding[k][1], var_embedding[i][1]])
                        edge_in.append([edge_embedding[k][1], edge_embedding[k][2]])

            elif edge_list[k][0] in S_point:
                S_OUT = []
                for i in range(len(var_embedding)):
                    if str(var_embedding[i][0]) == str(edge_embedding[k][1]):
                        S_OUT.append(var_embedding[i][1])
                var_out.append([edge_embedding[k][0], S_OUT[0]])
                edge_out.append([edge_embedding[k][0], edge_embedding[k][2]])
            elif edge_list[k][1] in S_point:
                for i in range(len(var_embedding)):
                    if str(var_embedding[i][0]) == str(edge_embedding[k][0]):
                        var_in.append([edge_embedding[k][1], var_embedding[i][1]])
                        edge_in.append([edge_embedding[k][1], edge_embedding[k][2]])
                        break
            else:
                print("Edge from node %s to node %s:  edgeFeature: %s" % (
                    edge_embedding[k][0], edge_embedding[k][1], edge_embedding[k][2]))
    else:
        for k in range(len(edge_embedding)):
            if edge_list[k][0] in C_point:
                edge_out.append([edge_embedding[k][0], edge_embedding[k][2]])
            elif edge_list[k][1] in C_point:
                edge_in.append([edge_embedding[k][1], edge_embedding[k][2]])

            elif edge_list[k][0] in W_point:
                edge_out.append([edge_embedding[k][0], edge_embedding[k][2]])
            elif edge_list[k][1] in W_point:
                edge_in.append([edge_embedding[k][1], edge_embedding[k][2]])

            elif edge_list[k][0] in S_point:
                edge_out.append([edge_embedding[k][0], edge_embedding[k][2]])
            elif edge_list[k][1] in S_point:
                edge_in.append([edge_embedding[k][1], edge_embedding[k][2]])

    node_embeddings_dim = 350
    edge_vec_length = 52
    var_vec_length = 69
    node_embedding_dim_without_edge = 246

    for i in range(len(var_in)):
        var_in_node.append(var_in[i][0])
    for i in range(len(var_out)):
        var_out_node.append(var_out[i][0])
    for i in range(len(edge_in)):
        edge_in_node.append(edge_in[i][0])
    for i in range(len(edge_out)):
        edge_out_node.append(edge_out[i][0])

    for i in range(len(main_point)):
        if main_point[i] not in var_in_node:
            var_in.append([main_point[i], np.zeros(var_vec_length, dtype=int)])
        if main_point[i] not in var_out_node:
            var_out.append([main_point[i], np.zeros(var_vec_length, dtype=int)])
        if main_point[i] not in edge_out_node:
            edge_out.append([main_point[i], np.zeros(edge_vec_length, dtype=int)])
        if main_point[i] not in edge_in_node:
            edge_in.append([main_point[i], np.zeros(edge_vec_length, dtype=int)])

    varIn_dict = dict(var_in)
    varOut_dict = dict(var_out)

    for i in range(len(node_embedding)):
        vec = np.zeros(node_embedding_dim_without_edge, dtype=int)
        if node_embedding[i][0] in S_point:
            node_feature = node_embedding[i][1].tolist() + np.array(varIn_dict[node_embedding[i][0]]).tolist() + \
                           np.array(varOut_dict[node_embedding[i][0]]).tolist()
            vec[0:len(np.array(node_feature))] = np.array(node_feature)
            node_vec.append([node_embedding[i][0], vec])
        elif node_embedding[i][0] in W_point:
            node_feature = node_embedding[i][1].tolist() + np.array(varIn_dict[node_embedding[i][0]]).tolist() + \
                           np.array(varOut_dict[node_embedding[i][0]]).tolist()
            vec[0:len(np.array(node_feature))] = np.array(node_feature)
            node_vec.append([node_embedding[i][0], vec])
        elif node_embedding[i][0] in C_point:
            node_feature = node_embedding[i][1].tolist() + np.array(varIn_dict[node_embedding[i][0]]).tolist() + \
                           np.array(varOut_dict[node_embedding[i][0]]).tolist()
            vec[0:len(np.array(node_feature))] = np.array(node_feature)
            node_vec.append([node_embedding[i][0], vec])

    for i in range(len(node_vec)):
        node_vec[i][1] = node_vec[i][1].tolist()

    print("Node Vec:")
    for i in range(len(node_vec)):
        node_vec[i][0] = node_convert[node_vec[i][0]]
        print(node_vec[i][0], node_vec[i][1])

    for i in range(len(edge_embedding)):
        edge_embedding[i][2] = edge_embedding[i][2].tolist()

    # S -> 0, W -> 1, C -> 2
    if len(edge_encode) == 2:
        end = edge_encode[len(edge_encode) - 2][1]
        start = edge_encode[len(edge_encode) - 1][0]
        flag = edge_encode[len(edge_encode) - 1][1]
        if end == start and ('VAR' in flag or 'MSG' in flag):
            edge_encode[len(edge_encode) - 1][1] = edge_encode[len(edge_encode) - 2][0]

    if len(edge_encode) > 2:
        end1 = edge_encode[len(edge_encode) - 1][1]
        start2 = edge_encode[len(edge_encode) - 2][0]
        if end1 == start2 and ('VAR' in end1 or 'MSG' in end1):
            edge_encode[len(edge_encode) - 1][1] = edge_encode[len(edge_encode) - 3][0]

    for i in range(len(edge_encode)):
        if i + 1 < len(edge_encode):
            start1 = edge_encode[i][0]
            end1 = edge_encode[i][1]
            start2 = edge_encode[i + 1][0]

            if end1 == start2 and ('VAR' in end1 or 'MSG' in end1):
                edge_encode[i][1] = edge_encode[i + 1][1]
                edge_encode[i + 1][0] = edge_encode[i][0]
            elif 'W' in start1 and 'VAR' in end1:
                edge_encode[i][1] = 'S0'

    print("Edge Vec:")
    for i in range(len(edge_encode)):
        edge_encode[i][0] = node_convert[edge_encode[i][0]]
        edge_encode[i][1] = node_convert[edge_encode[i][1]]
        print(edge_encode[i][0], edge_encode[i][1], edge_encode[i][2])

    graph_edge = []

    for i in range(len(edge_encode)):
        graph_edge.append([edge_encode[i][0], edge_encode[i][2][2], edge_encode[i][1]])

    print(graph_edge)

    return node_vec, graph_edge


if __name__ == "__main__":
    v_path = "../graph_data/graph_data_chem_164/node/"
    e_path = "../graph_data/graph_data_chem_164/edge/"

    fileObject = open('../graph_data/graph_data_chem_164/Chem_V1_autoTool.json', 'w')
    LabelOrder_file = open("../graph_data/graph_data_chem_164/new_graph_data_label_SameSettingGCN.txt")  # 合约list
    New_label_file = open("../graph_data/graph_data_chem_164/new_graph_data_label.txt")  # 合约漏洞标签
    line = LabelOrder_file.readline().strip(" ")
    Label = New_label_file.readline()

    while line:
        vertex = os.path.join(v_path, line.strip('\n'))
        edge = os.path.join(e_path, line.strip('\n'))

        nodeNum, node_list, node_attribute_list = extract_node_features(vertex)
        node_attribute_list, extra_var_list = elimination_node(nodeNum, node_list, node_attribute_list)
        node_encode, var_encode, node_embedding, var_embedding = embedding_node(node_attribute_list)
        edge_list, extra_edge_list = elimination_edge(edge)
        edge_encode, edge_embedding = embedding_edge(edge_list)
        node_vec, graph_edge = construct_var_edge_vec(edge_list, node_embedding, var_embedding, edge_embedding,
                                                      edge_encode)

        node_feature_list = []
        for i in range(len(node_vec)):
            node_feature_list.append(node_vec[i][1])

        edge_dict = {
            "graph": graph_edge
        }

        node_feature_dict = {
            "node_features": node_feature_list,
        }

        graph_dict = ({
            "targets": Label.strip('\n'),
            "graph": graph_edge,  # graph_edge,
            "node_features": node_feature_list,  # node_feature_list
        })
        print(graph_dict)
        jsObj = json.dumps(graph_dict)
        fileObject.write(jsObj)
        line = LabelOrder_file.readline()
        Label = New_label_file.readline()
    fileObject.close()
