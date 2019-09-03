InputSmartContractDir = "result.txt"
SmartContractName = "graph_data_name_164.txt"
SmartContractLabel = "graph_data_number_label_oyente.txt"
SmartContractNumber = "graph_data_number_1584.txt"
out = "att.txt"
out1 = "label.txt"

ContractName = open(SmartContractName, "r")
ContractNames = ContractName.readlines()
ContractLabel = open(SmartContractLabel, "r")
ContractLabels = ContractLabel.readlines()
ContractNumber = open(SmartContractNumber, "r")
ContractNumbers = ContractNumber.readlines()
f = open(InputSmartContractDir, "r")
lines = f.readlines()
f_w = open(out, "a")
f_l = open(out1, "a")

for i in range(len(ContractNames)):
    name = ContractNames[i].strip()
    label = ContractLabels[i].strip()
    number = ContractNumbers[i].strip()

    for k in range(int(number)):
        for j in range(len(lines)):
            if name == lines[j].strip():
                f_w.write(lines[j])
                f_w.write(lines[j + 1])
                f_w.write(lines[j + 2])
                f_w.write(lines[j + 3])

        f_l.write(label + "\n")
