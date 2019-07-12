import os
import re
import numpy as np

var_list = ['balances[msg.sender]', 'participated[msg.sender]', 'playerPendingWithdrawals[msg.sender]',
            'nonces[msgSender]', 'balances[beneficiary]', 'transactions[transactionId]', 'tokens[token][msg.sender]',
            'totalDeposited[token]', 'tokens[0][msg.sender]', 'accountBalances[msg.sender]', 'accountBalances[_to]',
            'creditedPoints[msg.sender]', 'balances[from]', 'withdrawalCount[from]', 'balances[recipient]',
            'investors[_to]', 'Bal[msg.sender]', 'Accounts[msg.sender]', 'Holders[_addr]', 'balances[_pd]',
            'ExtractDepositTime[msg.sender]', 'Bids[msg.sender]', 'participated[msg.sender]', 'deposited[_participant]',
            'Transactions[TransHash]', 'm_txs[_h]', 'balances[investor]', 'this.balance', 'proposals[_proposalID]',
            'accountBalances[accountAddress]', 'Chargers[id]', 'latestSeriesForUser[msg.sender]',
            'balanceOf[_addressToRefund]', 'tokenManage[token_]', 'milestones[_idMilestone]', 'payments[msg.sender]',
            'rewardsForA[recipient]', 'userBalance[msg.sender]', 'credit[msg.sender]', 'credit[to]', 'round_[_rd]',
            'userPendingWithdrawals[msg.sender]', '[msg.sender]', '[from]', '[to]', '[_to]']

function_limit = ['private', 'onlyOwner', 'internal', 'onlyGovernor', 'onlyCommittee', 'onlyAdmin', 'onlyPlayers',
                  'onlyManager', 'onlyHuman', 'only_owner', 'onlyCongressMembers', 'preventReentry', 'onlyMembers',
                  'onlyProxyOwner', 'ownerExists', 'noReentrancy', 'notExecuted', 'noReentrancy', 'noEther',
                  'notConfirmed']

var_op_bool = ['!', '~', '**', '*', '!=', '<', '>', '<=', '>=', '==', '<<', '>>', '||', '&&']


var_op_assign = ['|=', '=', '^=', '&=', '<<=', '>>=', '+=', '-=', '*=', '/=', '%=', '++', '--']


# split all functions of contracts
def split_function(filepath):
    function_list = []
    f = open(filepath, 'r')
    lines = f.readlines()
    f.close()
    flag = -1

    for line in lines:
        text = line.strip()
        if len(text) > 0 and text != "\n":
            if text.split()[0] == "function" or text.split()[0] == "constructor":
                function_list.append([text])
                flag += 1
            elif len(function_list) > 0 and ("function" or "constructor" in function_list[flag][0]):
                function_list[flag].append(text)

    return function_list


# Position the call.value to generate the graph
def generate_graph(filepath):
    allFunctionList = split_function(filepath)  # Store all functions
    callValueList = []  # Store all W functions that call call.value
    cFunctionList = []  # 存放调用 W 函数 C 函数(针对某个具体的)
    CFunctionLists = []  # Store all C functions that call W function
    withdrawNameList = []  # 存放调用 call.value 的 W 函数名
    otherFunctionList = []  # 存储 call.value 以外的函数
    node_list = []  # 存放所有的点的列表
    edge_list = []  # 存放边和边的特征
    node_feature_list = []  # 存放结点特征
    params = []  # 存放 W 函数的参数
    key_count = 0  # 核心结点 S 和 W 的个数
    c_count = 0  # 核心结点 C 的个数

    # ======================================================================
    # ---------------------------  Handle node  ----------------------------
    # ======================================================================

    # 存储 call.value 以外的函数
    for i in range(len(allFunctionList)):
        flag = 0
        for j in range(len(allFunctionList[i])):
            text = allFunctionList[i][j]
            if '.call.value' in text:
                flag += 1
        if flag == 0:
            otherFunctionList.append(allFunctionList[i])

    # 遍历所有函数，找到 call.value 关键字，存储 S 和 W 结点
    for i in range(len(allFunctionList)):
        for j in range(len(allFunctionList[i])):
            text = allFunctionList[i][j]
            if '.call.value' in text:
                node_list.append("S" + str(key_count))
                node_list.append("W" + str(key_count))
                location_i, location_j = i, j  # call.value 所处的位置
                callValueList.append([allFunctionList[location_i], "S" + str(key_count), "W" + str(key_count)])

                # 处理 MSG 和 INNADD 类别
                # 获取 W 函数的参数
                ss = allFunctionList[location_i][0]
                p = re.compile(r'[(](.*?)[)]', re.S)  # 最小匹配
                result = re.findall(p, ss)
                result_params = result[0].split(",")
                # print("result_params", result_params, len(result_params))
                # 处理参数
                params1 = []
                for n in range(len(result_params)):
                    params1.append(result_params[n].strip().split(" ")[-1])
                # print(params1)

                # 添加 W 函数的参数
                params.append([params1, "S" + str(key_count), "W" + str(key_count)])

                # 处理 W 函数访问限制的情况(其可用于 S 和 W 点的访问限制属性)
                limit_count = 0
                for k in range(len(function_limit)):
                    # if 后的处理是针对 LimitedAC 的情况
                    if function_limit[k] in callValueList[key_count][0][0]:
                        limit_count += 1
                        if "address" in text:
                            node_feature_list.append(
                                ["S" + str(key_count), "S" + str(key_count), "LimitedAC", "W" + str(key_count),
                                 2, "INNADD"])
                            node_feature_list.append(
                                ["W" + str(key_count), "W" + str(key_count), "LimitedAC", "C" + str(key_count),
                                 1, "NULL"])
                            break
                        elif "msg.sender" in text:
                            node_feature_list.append(
                                ["S" + str(key_count), "S" + str(key_count), "LimitedAC", "W" + str(key_count),
                                 2, "MSG"])
                            node_feature_list.append(
                                ["W" + str(key_count), "W" + str(key_count), "LimitedAC", "C" + str(key_count),
                                 1, "NULL"])
                            break
                        else:
                            # 处理 W 函数参数与调用 call.value 的参数匹配情况
                            param_count = 0
                            for param in params1:
                                if param in text and param != "":
                                    param_count += 1
                                    node_feature_list.append(
                                        ["S" + str(key_count), "S" + str(key_count), "LimitedAC", "W" + str(key_count),
                                         2, "MSG"])
                                    node_feature_list.append(
                                        ["W" + str(key_count), "W" + str(key_count), "LimitedAC", "C" + str(key_count),
                                         1, "NULL"])
                                    break
                            if param_count == 0:
                                node_feature_list.append(
                                    ["S" + str(key_count), "S" + str(key_count), "LimitedAC", "W" + str(key_count),
                                     2, "INNADD"])
                                node_feature_list.append(
                                    ["W" + str(key_count), "W" + str(key_count), "LimitedAC", "C" + str(key_count),
                                     1, "NULL"])
                            break
                # if 后的处理是针对 NoLimit 的情况
                if limit_count == 0:
                    if "address" in text:
                        node_feature_list.append(
                            ["S" + str(key_count), "S" + str(key_count), "NoLimit", "W" + str(key_count),
                             2, "INNADD"])
                        node_feature_list.append(
                            ["W" + str(key_count), "W" + str(key_count), "NoLimit", "C" + str(key_count),
                             1, "NULL"])
                    elif "msg.sender" in text:
                        node_feature_list.append(
                            ["S" + str(key_count), "S" + str(key_count), "NoLimit", "W" + str(key_count),
                             2, "MSG"])
                        node_feature_list.append(
                            ["W" + str(key_count), "W" + str(key_count), "NoLimit", "C" + str(key_count),
                             1, "NULL"])
                    else:
                        # 处理 W 函数参数与调用 call.value 的参数匹配情况
                        param_count = 0
                        for param in params1:
                            if param in text and param != "":
                                param_count += 1
                                node_feature_list.append(
                                    ["S" + str(key_count), "S" + str(key_count), "NoLimit", "W" + str(key_count),
                                     2, "MSG"])
                                # 这里调用 W 结点的 C 结点不确定，先默认为 C
                                node_feature_list.append(
                                    ["W" + str(key_count), "W" + str(key_count), "NoLimit", "C0", 1, "NULL"])
                                break
                        if param_count == 0:
                            node_feature_list.append(
                                ["S" + str(key_count), "S" + str(key_count), "NoLimit", "W" + str(key_count),
                                 2, "INNADD"])
                            # 这里调用 W 结点的 C 结点不确定，先默认为 C
                            node_feature_list.append(
                                ["W" + str(key_count), "W" + str(key_count), "NoLimit", "C0", 1, "NULL"])

                # 处理 W 函数，例如:function transfer(address _to, uint _value, bytes _data, string _custom_fallback)
                # 取到该函数的函数名 (transfer)
                tmp = re.compile(r'\b([_A-Za-z]\w*)\b(?:(?=\s*\w+\()|(?!\s*\w+))')
                result_withdraw = tmp.findall(allFunctionList[location_i][0])
                withdrawNameTmp = result_withdraw[1]
                if withdrawNameTmp == "payable":
                    withdrawName = withdrawNameTmp
                else:
                    withdrawName = withdrawNameTmp + "("
                withdrawNameList.append(["W" + str(key_count), withdrawName])  # 将所有可能的 W 函数存在数组中

                key_count += 1

    # 处理 S 和 W 函数结点 (sol合约中不存在 call.value 关键字时)
    # TODO 可作为后续考虑，目前处理的智能合约数据集都带有 call.value 关键字
    if key_count == 0:
        print("Currently, there is no key word call.value")
        node_feature_list.append(["S0", "S0", "NoLimit", "NULL", 0, "NULL"])
        node_feature_list.append(["W0", "W0", "NoLimit", "NULL", 0, "NULL"])

    # 遍历所有函数，找到调用 W 函数的 C 函数结点 (通过匹配参数的个数确定函数的调用)
    for k in range(len(withdrawNameList)):
        w_key = withdrawNameList[k][0]
        w_name = withdrawNameList[k][1]
        for i in range(len(otherFunctionList)):
            if len(otherFunctionList[i]) > 2:
                for j in range(1, len(otherFunctionList[i])):
                    # 处理参数
                    text = otherFunctionList[i][j]
                    if w_name in text:
                        p = re.compile(r'[(](.*?)[)]', re.S)  # 最小匹配
                        result = re.findall(p, text)
                        result_params = result[0].split(",")
                        # print("result_params", result_params[0], len(result_params), params)

                        if result_params[0] != "" and len(result_params) == len(params[k][0]):
                            cFunctionList += otherFunctionList[i]  # 存储当前 C 函数
                            CFunctionLists.append(
                                [w_key, w_name, "C" + str(c_count), otherFunctionList[i]])  # 存储所有 C 函数结点
                            node_list.append("C" + str(c_count))

                            # 处理 C 函数访问限制的情况(其用于 C 点的访问限制属性)
                            limit_count = 0
                            for m in range(len(function_limit)):
                                if function_limit[m] in cFunctionList[0]:
                                    limit_count += 1
                                    node_feature_list.append(
                                        ["C" + str(c_count), "C" + str(c_count), "LimitedAC", "NULL", 0, "NULL"])
                                    # 处理调用 W 结点的 C 结点
                                    for n in range(len(node_feature_list)):
                                        if w_key in node_feature_list[n][0]:
                                            node_feature_list[n][3] = "C" + str(c_count)
                                    break
                            if limit_count == 0:
                                node_feature_list.append(
                                    ["C" + str(c_count), "C" + str(c_count), "NoLimit", "NULL", 0, "NULL"])
                                # 处理调用 W 结点的 C 结点
                                for n in range(len(node_feature_list)):
                                    if w_key in node_feature_list[n][0]:
                                        node_feature_list[n][3] = "C" + str(c_count)

                            c_count += 1

    # 处理 C 函数结点 (若不存在 C 函数调用的情况)
    if c_count == 0:
        print("At present, There is no C node")
        node_list.append("C0")
        node_feature_list.append(["C0", "C0", "NoLimit", "NULL", 0, "NULL"])
        # 若没有 C 结点，则处理默认定义的 W 结点属性
        for n in range(len(node_feature_list)):
            if "W" in node_feature_list[n][0]:
                node_feature_list[n][3] = "NULL"

    # ======================================================================
    # ---------------------------  Handle edge  ----------------------------
    # ======================================================================

    # (1) 处理 W->S 的边 (包括 W->VAR, VAR->S, S->VAR)
    # 遍历调用 call.value 关键字的 W 函数的每一行
    for i in range(len(callValueList)):
        flag = 0  # 分割的标志，表示遇到 call.value 关键字的flag: flag=0, before; flag>0, after
        before_var_count = 0
        after_var_count = 0
        var_tmp = []  # var点临时存储
        var_name = []  # var点名称存储
        var_w_name = []
        for j in range(len(callValueList[i][0])):
            text = callValueList[i][0][j]
            if '.call.value' not in text:
                if flag == 0:
                    # print("before call.value")
                    # 处理 W->VAR
                    # TODO 这里暂时无法判断哪些VAR结点已经使用过
                    for k in range(len(var_list)):
                        if var_list[k] in text:
                            node_list.append("VAR" + str(before_var_count))
                            var_tmp.append("VAR" + str(before_var_count))

                            if len(var_w_name) == 0:
                                if "assert" in text:
                                    edge_list.append(
                                        [callValueList[i][2], "VAR" + str(before_var_count), callValueList[i][2], 1,
                                         'AH'])
                                elif "require" in text:
                                    edge_list.append(
                                        [callValueList[i][2], "VAR" + str(before_var_count), callValueList[i][2], 1,
                                         'RG'])
                                elif j > 1:
                                    if "if" in callValueList[i][0][j - 1]:
                                        edge_list.append(
                                            [callValueList[i][2], "VAR" + str(before_var_count), callValueList[i][2], 1,
                                             'GN'])
                                    elif "for" in callValueList[i][0][j - 1]:
                                        edge_list.append(
                                            [callValueList[i][2], "VAR" + str(before_var_count), callValueList[i][2], 1,
                                             'FOR'])
                                    elif "else" in callValueList[i][0][j - 1]:
                                        edge_list.append(
                                            [callValueList[i][2], "VAR" + str(before_var_count), callValueList[i][2], 1,
                                             'GB'])
                                    elif j + 1 < len(callValueList[i][0]):
                                        if "if" and "throw" in callValueList[i][0][j] or "if" in callValueList[i][0][j] \
                                                and "throw" in callValueList[i][0][j + 1]:
                                            edge_list.append(
                                                [callValueList[i][2], "VAR" + str(before_var_count),
                                                 callValueList[i][2], 1, 'IT'])
                                        elif "if" and "revert" in callValueList[i][0][j] or "if" in callValueList[i][0][
                                            j] and "revert" in callValueList[i][0][j + 1]:
                                            edge_list.append(
                                                [callValueList[i][2], "VAR" + str(before_var_count),
                                                 callValueList[i][2], 1, 'RH'])
                                        elif "if" in text:
                                            edge_list.append(
                                                [callValueList[i][2], "VAR" + str(before_var_count),
                                                 callValueList[i][2], 1, 'IF'])
                                        else:
                                            edge_list.append(
                                                [callValueList[i][2], "VAR" + str(before_var_count),
                                                 callValueList[i][2], 1, 'FW'])
                                    else:
                                        edge_list.append(
                                            [callValueList[i][2], "VAR" + str(before_var_count), callValueList[i][2], 1,
                                             'FW'])
                                else:
                                    edge_list.append(
                                        [callValueList[i][2], "VAR" + str(before_var_count), callValueList[i][2], 1,
                                         'FW'])

                                var_node = 0
                                for b in range(len(var_op_bool)):
                                    if var_op_bool[b] in text:
                                        node_feature_list.append(
                                            ["VAR" + str(before_var_count), "VAR" + str(before_var_count),
                                             callValueList[i][2], 1, 'BOOL'])
                                        var_node += 1
                                        break

                                for a in range(len(var_op_assign)):
                                    if var_op_assign[a] in text:
                                        node_feature_list.append(
                                            ["VAR" + str(before_var_count), "VAR" + str(before_var_count),
                                             callValueList[i][2], 1, 'ASSIGN'])
                                        var_node += 1
                                        break

                                if var_node == 0:
                                    node_feature_list.append(
                                        ["VAR" + str(before_var_count), "VAR" + str(before_var_count),
                                         callValueList[i][2], 1, 'NULL'])

                                var_w_name.append(var_list[k])
                                var_name.append(var_list[k])
                                before_var_count += 1
                            else:
                                var_w_count = 0
                                for n in range(len(var_w_name)):
                                    if var_list[k] == var_w_name[n]:
                                        var_w_count += 1
                                        var_tmp.append(var_tmp[len(var_tmp) - 1])

                                        var_node = 0
                                        for b in range(len(var_op_bool)):
                                            if var_op_bool[b] in text:
                                                node_feature_list.append(
                                                    [var_tmp[len(var_tmp) - 1], var_tmp[len(var_tmp) - 1],
                                                     callValueList[i][2], 1, 'BOOL'])
                                                var_node += 1
                                                break

                                        for a in range(len(var_op_assign)):
                                            if var_op_assign[a] in text:
                                                node_feature_list.append(
                                                    [var_tmp[len(var_tmp) - 1], var_tmp[len(var_tmp) - 1],
                                                     callValueList[i][2], 1, 'ASSIGN'])
                                                var_node += 1
                                                break

                                        if var_node == 0:
                                            node_feature_list.append(
                                                [var_tmp[len(var_tmp) - 1], var_tmp[len(var_tmp) - 1],
                                                 callValueList[i][2], 1, 'NULL'])

                                if var_w_count == 0:
                                    var_node = 0
                                    var_tmp.append("VAR" + str(before_var_count))

                                    for b in range(len(var_op_bool)):
                                        if var_op_bool[b] in text:
                                            node_feature_list.append(
                                                ["VAR" + str(before_var_count), "VAR" + str(before_var_count),
                                                 callValueList[i][2], 1, 'BOOL'])
                                            var_node += 1
                                            break

                                    for a in range(len(var_op_assign)):
                                        if var_op_assign[a] in text:
                                            node_feature_list.append(
                                                ["VAR" + str(before_var_count), "VAR" + str(before_var_count),
                                                 callValueList[i][2], 1, 'ASSIGN'])
                                            var_node += 1
                                            break

                                    if var_node == 0:
                                        node_feature_list.append(
                                            ["VAR" + str(before_var_count), "VAR" + str(before_var_count),
                                             callValueList[i][2], 1, 'NULL'])

                elif flag == 1:
                    # print("after call.value")
                    # 处理 S->VAR TODO else(GN)
                    var_count = 0
                    for k in range(len(var_list)):
                        if var_list[k] in text:
                            if before_var_count == 0:
                                node_list.append("VAR" + str(after_var_count))
                                var_tmp.append("VAR" + str(after_var_count))

                                if "assert" in text:
                                    edge_list.append(
                                        [callValueList[i][1], "VAR" + str(after_var_count), callValueList[i][1], 3,
                                         'AH'])
                                elif "require" in text:
                                    edge_list.append(
                                        [callValueList[i][1], "VAR" + str(after_var_count), callValueList[i][1], 3,
                                         'RG'])
                                elif "return" in text:
                                    edge_list.append(
                                        [callValueList[i][1], "VAR" + str(after_var_count), callValueList[i][1], 3,
                                         'RE'])
                                elif "if" and "throw" in text:
                                    edge_list.append(
                                        [callValueList[i][1], "VAR" + str(after_var_count), callValueList[i][1], 3,
                                         'IT'])
                                elif "if" and "revert" in text:
                                    edge_list.append(
                                        [callValueList[i][1], "VAR" + str(after_var_count), callValueList[i][1], 3,
                                         'RH'])
                                elif "if" in text:
                                    edge_list.append(
                                        [callValueList[i][1], "VAR" + str(after_var_count), callValueList[i][1], 3,
                                         'IF'])
                                else:
                                    edge_list.append(
                                        [callValueList[i][1], "VAR" + str(after_var_count), callValueList[i][1], 3,
                                         'FW'])

                                var_node = 0
                                for b in range(len(var_op_bool)):
                                    if var_op_bool[b] in text:
                                        node_feature_list.append(
                                            ["VAR" + str(after_var_count), "VAR" + str(after_var_count),
                                             callValueList[i][1], 3, 'BOOL'])
                                        var_node += 1
                                        break

                                for a in range(len(var_op_assign)):
                                    if var_op_assign[a] in text:
                                        node_feature_list.append(
                                            ["VAR" + str(after_var_count), "VAR" + str(after_var_count),
                                             callValueList[i][1], 3, 'ASSIGN'])
                                        var_node += 1
                                        break

                                if var_node == 0:
                                    node_feature_list.append(
                                        ["VAR" + str(after_var_count), "VAR" + str(after_var_count),
                                         callValueList[i][1], 3, 'NULL'])

                                # after_var_count += 1

                            elif before_var_count > 0:
                                for n in range(len(var_name)):
                                    if var_list[k] == var_name[n]:
                                        var_count += 1
                                        if "assert" in text:
                                            edge_list.append(
                                                [callValueList[i][1], var_tmp[len(var_tmp) - 1], callValueList[i][1], 3,
                                                 'AH'])
                                        elif "require" in text:
                                            edge_list.append(
                                                [callValueList[i][1], var_tmp[len(var_tmp) - 1], callValueList[i][1], 3,
                                                 'RG'])
                                        elif "return" in text:
                                            edge_list.append(
                                                [callValueList[i][1], var_tmp[len(var_tmp) - 1], callValueList[i][1], 3,
                                                 'RE'])
                                        elif "if" and "throw" in text:
                                            edge_list.append(
                                                [callValueList[i][1], var_tmp[len(var_tmp) - 1], callValueList[i][1], 3,
                                                 'IT'])
                                        elif "if" and "revert" in text:
                                            edge_list.append(
                                                [callValueList[i][1], var_tmp[len(var_tmp) - 1], callValueList[i][1], 3,
                                                 'RH'])
                                        elif "if" in text:
                                            edge_list.append(
                                                [callValueList[i][1], var_tmp[len(var_tmp) - 1], callValueList[i][1], 3,
                                                 'IF'])
                                        else:
                                            edge_list.append(
                                                [callValueList[i][1], var_tmp[len(var_tmp) - 1], callValueList[i][1], 3,
                                                 'FW'])

                                        after_var_count += 1

                    # if var_count == 0 and before_var_count > 0:
                    #     after_var_count = before_var_count
                    #     node_list.append("VAR" + str(after_var_count))
                    #     var_tmp.append("VAR" + str(after_var_count))
                    #
                    #     var_node = 0
                    #     for b in range(len(var_op_bool)):
                    #         if var_op_bool[b] in text:
                    #             node_feature_list.append(
                    #                 ["VAR" + str(after_var_count), "VAR" + str(after_var_count),
                    #                  callValueList[i][1], 3, 'BOOL'])
                    #             var_node += 1
                    #             break
                    #
                    #     for a in range(len(var_op_assign)):
                    #         if var_op_assign[a] in text:
                    #             node_feature_list.append(
                    #                 ["VAR" + str(after_var_count), "VAR" + str(after_var_count),
                    #                  callValueList[i][1], 3, 'ASSIGN'])
                    #             var_node += 1
                    #             break
                    #
                    #     if var_node == 0:
                    #         node_feature_list.append(
                    #             ["VAR" + str(after_var_count), "VAR" + str(after_var_count),
                    #              callValueList[i][1], 3, 'NULL'])
                    #
                    #     if "assert" in text:
                    #         edge_list.append(
                    #             [callValueList[i][1], "VAR" + str(after_var_count), callValueList[i][1], 3, 'AH'])
                    #     elif "require" in text:
                    #         edge_list.append(
                    #             [callValueList[i][1], "VAR" + str(after_var_count), callValueList[i][1], 3, 'RG'])
                    #     elif "return" in text:
                    #         edge_list.append(
                    #             [callValueList[i][1], "VAR" + str(after_var_count), callValueList[i][1], 3, 'RE'])
                    #     elif "if" and "throw" in text:
                    #         edge_list.append(
                    #             [callValueList[i][1], "VAR" + str(after_var_count), callValueList[i][1], 3, 'IT'])
                    #     elif "if" and "revert" in text:
                    #         edge_list.append(
                    #             [callValueList[i][1], "VAR" + str(after_var_count), callValueList[i][1], 3, 'RH'])
                    #     elif "if" in text:
                    #         edge_list.append(
                    #             [callValueList[i][1], "VAR" + str(after_var_count), callValueList[i][1], 3, 'IF'])
                    #     else:
                    #         edge_list.append(
                    #             [callValueList[i][1], "VAR" + str(after_var_count), callValueList[i][1], 3, 'FW'])

            elif '.call.value' in text:
                flag += 1  # 表示遇见 call.value

                if len(var_tmp) > 0:
                    if "assert" in text:
                        edge_list.append([var_tmp[len(var_tmp) - 1], callValueList[i][1], callValueList[i][2], 2, 'AH'])
                    elif "require" in text:
                        edge_list.append([var_tmp[len(var_tmp) - 1], callValueList[i][1], callValueList[i][2], 2, 'RG'])
                    elif "return" in text:
                        edge_list.append([var_tmp[len(var_tmp) - 1], callValueList[i][1], callValueList[i][2], 2, 'RE'])
                    elif j > 1:
                        if "if" in callValueList[i][0][j - 1]:
                            edge_list.append(
                                [var_tmp[len(var_tmp) - 1], callValueList[i][1], callValueList[i][2], 2, 'GN'])
                        elif "for" in callValueList[i][0][j - 1]:
                            edge_list.append(
                                [var_tmp[len(var_tmp) - 1], callValueList[i][1], callValueList[i][2], 2, 'FOR'])
                        elif "else" in callValueList[i][0][j - 1]:
                            edge_list.append(
                                [var_tmp[len(var_tmp) - 1], callValueList[i][1], callValueList[i][2], 2, 'GB'])
                        elif j + 1 < len(callValueList[i][0]):
                            if "if" and "throw" in callValueList[i][0][j] or "if" in callValueList[i][0][j] \
                                    and "throw" in callValueList[i][0][j + 1]:
                                edge_list.append(
                                    [var_tmp[len(var_tmp) - 1], callValueList[i][1], callValueList[i][2], 2, 'IT'])
                            elif "if" and "revert" in callValueList[i][0][j] or "if" in callValueList[i][0][j] \
                                    and "revert" in callValueList[i][0][j + 1]:
                                edge_list.append(
                                    [var_tmp[len(var_tmp) - 1], callValueList[i][1], callValueList[i][2], 2, 'RH'])
                            elif "if" in text:
                                edge_list.append(
                                    [var_tmp[len(var_tmp) - 1], callValueList[i][1], callValueList[i][2], 2, 'IF'])
                            else:
                                edge_list.append(
                                    [var_tmp[len(var_tmp) - 1], callValueList[i][1], callValueList[i][2], 2, 'FW'])
                        else:
                            edge_list.append(
                                [var_tmp[len(var_tmp) - 1], callValueList[i][1], callValueList[i][2], 2, 'FW'])
                    else:
                        edge_list.append(
                            [var_tmp[len(var_tmp) - 1], callValueList[i][1], callValueList[i][2], 2, 'FW'])

                elif len(var_tmp) == 0:
                    if "assert" in text:
                        edge_list.append(
                            [callValueList[i][2], callValueList[i][1], callValueList[i][2], 1, 'AH'])
                    elif "require" in text:
                        edge_list.append(
                            [callValueList[i][2], callValueList[i][1], callValueList[i][2], 1, 'RG'])
                    elif "return" in text:
                        edge_list.append(
                            [callValueList[i][2], callValueList[i][1], callValueList[i][2], 1, 'RE'])
                    elif j > 1:
                        if "if" in callValueList[i][0][j - 1]:
                            edge_list.append(
                                [callValueList[i][2], callValueList[i][1], callValueList[i][2], 1, 'GN'])
                        elif "for" in callValueList[i][0][j - 1]:
                            edge_list.append(
                                [callValueList[i][2], callValueList[i][1], callValueList[i][2], 1, 'FOR'])
                        elif "else" in callValueList[i][0][j - 1]:
                            edge_list.append(
                                [callValueList[i][2], callValueList[i][1], callValueList[i][2], 1, 'GB'])
                        elif j + 1 < len(callValueList[i][0]):
                            if "if" and "throw" in callValueList[i][0][j] or "if" in callValueList[i][0][j] \
                                    and "throw" in callValueList[i][0][j + 1]:
                                edge_list.append(
                                    [callValueList[i][2], callValueList[i][1], callValueList[i][2], 1, 'IT'])
                            elif "if" and "revert" in callValueList[i][0][j] or "if" in callValueList[i][0][j] \
                                    and "revert" in callValueList[i][0][j + 1]:
                                edge_list.append(
                                    [callValueList[i][2], callValueList[i][1], callValueList[i][2], 1, 'RH'])
                            elif "if" in text:
                                edge_list.append(
                                    [callValueList[i][2], callValueList[i][1], callValueList[i][2], 1, 'IF'])
                            else:
                                edge_list.append(
                                    [callValueList[i][2], callValueList[i][1], callValueList[i][2], 1, 'FW'])
                        else:
                            edge_list.append(
                                [callValueList[i][2], callValueList[i][1], callValueList[i][2], 1, 'FW'])
                    else:
                        edge_list.append(
                            [callValueList[i][2], callValueList[i][1], callValueList[i][2], 1, 'FW'])

    # (2) 处理 C->W 的边 (包括 C->VAR, VAR->W) TODO W->VAR
    for i in range(len(CFunctionLists)):
        for j in range(len(CFunctionLists[i][3])):
            text = CFunctionLists[i][3][j]
            var_flag = 0
            for k in range(len(var_list)):
                if var_list[k] in text:
                    var_flag += 1

                    var_node = 0
                    for b in range(len(var_op_bool)):
                        if var_op_bool[b] in text:
                            node_feature_list.append(
                                ["VAR" + str(len(var_tmp)), "VAR" + str(len(var_tmp)),
                                 CFunctionLists[i][2], 1, 'BOOL'])
                            var_node += 1
                            break

                    for a in range(len(var_op_assign)):
                        if var_op_assign[a] in text:
                            node_feature_list.append(
                                ["VAR" + str(len(var_tmp)), "VAR" + str(len(var_tmp)),
                                 CFunctionLists[i][2], 1, 'ASSIGN'])
                            var_node += 1
                            break

                    if var_node == 0:
                        node_feature_list.append(
                            ["VAR" + str(len(var_tmp)), "VAR" + str(len(var_tmp)),
                             CFunctionLists[i][2], 1, 'NULL'])

                    if "assert" in text:
                        edge_list.append(
                            [CFunctionLists[i][2], "VAR" + str(len(var_tmp)), CFunctionLists[i][2], 1, 'AH'])
                        edge_list.append(
                            ["VAR" + str(len(var_tmp)), CFunctionLists[i][0], CFunctionLists[i][2], 2, 'FW'])
                    elif "require" in text:
                        edge_list.append(
                            [CFunctionLists[i][2], "VAR" + str(len(var_tmp)), CFunctionLists[i][2], 1, 'RG'])
                        edge_list.append(
                            ["VAR" + str(len(var_tmp)), CFunctionLists[i][0], CFunctionLists[i][2], 2, 'FW'])
                    elif "if" and "throw" in text:
                        edge_list.append(
                            [CFunctionLists[i][2], "VAR" + str(len(var_tmp)), CFunctionLists[i][2], 1, 'IT'])
                        edge_list.append(
                            ["VAR" + str(len(var_tmp)), CFunctionLists[i][0], CFunctionLists[i][2], 2, 'FW'])
                    elif "if" and "revert" in text:
                        edge_list.append(
                            [CFunctionLists[i][2], "VAR" + str(len(var_tmp)), CFunctionLists[i][2], 1, 'RH'])
                        edge_list.append(
                            ["VAR" + str(len(var_tmp)), CFunctionLists[i][0], CFunctionLists[i][2], 2, 'FW'])
                    elif "if" in text:
                        edge_list.append(
                            [CFunctionLists[i][2], "VAR" + str(len(var_tmp)), CFunctionLists[i][2], 1, 'IF'])
                        edge_list.append(
                            ["VAR" + str(len(var_tmp)), CFunctionLists[i][0], CFunctionLists[i][2], 2, 'FW'])
                    else:
                        edge_list.append(
                            [CFunctionLists[i][2], "VAR" + str(len(var_tmp)), CFunctionLists[i][2], 1, 'FW'])
                        edge_list.append(
                            ["VAR" + str(len(var_tmp)), CFunctionLists[i][0], CFunctionLists[i][2], 2, 'FW'])
                    break

            if var_flag == 0:
                if "assert" in text:
                    edge_list.append(
                        [CFunctionLists[i][2], CFunctionLists[i][0], CFunctionLists[i][2], 1, 'AH'])
                elif "require" in text:
                    edge_list.append(
                        [CFunctionLists[i][2], CFunctionLists[i][0], CFunctionLists[i][2], 1, 'RG'])
                elif "if" and "throw" in text:
                    edge_list.append(
                        [CFunctionLists[i][2], CFunctionLists[i][0], CFunctionLists[i][2], 1, 'IT'])
                elif "if" and "revert" in text:
                    edge_list.append(
                        [CFunctionLists[i][2], CFunctionLists[i][0], CFunctionLists[i][2], 1, 'RH'])
                elif "if" in text:
                    edge_list.append(
                        [CFunctionLists[i][2], CFunctionLists[i][0], CFunctionLists[i][2], 1, 'IF'])
                else:
                    edge_list.append(
                        [CFunctionLists[i][2], CFunctionLists[i][0], CFunctionLists[i][2], 1, 'FW'])
                break
            else:
                print("该 C 函数未调用相应的 W 函数")

    # 处理一些重复的元素，筛选留下唯一的
    edge_list = list(set([tuple(t) for t in edge_list]))
    edge_list = [list(v) for v in edge_list]
    node_feature_list = list(set([tuple(t) for t in node_feature_list]))
    node_feature_list = [list(v) for v in node_feature_list]
    node_list = list(set(node_list))

    # print("node_list", node_list)
    # print("node_feature_list", node_feature_list)
    # print("edge_list", edge_list)
    return node_feature_list, edge_list


# 输出结果
def printResult(file, node_feature, edge_feature):
    # 将结果 node_feature_list和edge_list 输入到相应的文件中
    nodeOutPath = "../graph_data/graph_data_by_automatic_tool/node/" + file
    edgeOutPath = "../graph_data/graph_data_by_automatic_tool/edge/" + file

    f_node = open(nodeOutPath, 'a')
    for i in range(len(node_feature)):
        result = " ".join(np.array(node_feature[i]))
        f_node.write(result + '\n')
    f_node.close()

    f_edge = open(edgeOutPath, 'a')
    for i in range(len(edge_feature)):
        result = " ".join(np.array(edge_feature[i]))
        print(result)
        f_edge.write(result + '\n')
    f_edge.close()


if __name__ == "__main__":
    # test_contract = "../SmartContractDataSet/smart_contract_source_code/25196.sol"  # 具体的文件路径
    # node_feature, edge_feature = generate_graph(test_contract)
    # node_feature = sorted(node_feature, key=lambda x: (x[0]))
    # edge_feature = sorted(edge_feature, key=lambda x: (x[2], x[3]))
    # print("node_feature", node_feature)
    # print("edge_feature", edge_feature)

    inputFileDir = "../smart_contract_source_code/"
    dirs = os.listdir(inputFileDir)  # 具体的文件夹路径
    for file in dirs:
        inputFilePath = inputFileDir + file
        node_feature, edge_feature = generate_graph(inputFilePath)
        node_feature = sorted(node_feature, key=lambda x: (x[0]))
        edge_feature = sorted(edge_feature, key=lambda x: (x[2], x[3]))
        printResult(file, node_feature, edge_feature)
