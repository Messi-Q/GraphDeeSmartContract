
input_contract = "./infinite_loop/results/infinite_loop_AutoExtract_corenodes_gcn.txt"
contract = open(input_contract, "r")
contracts = contract.readlines()
input_label = "./infinite_loop/infinite_loop_label.txt"
label = open(input_label, "r")
labels = label.readlines()
input_name = "./infinite_loop/infinite_loop_name.txt"
name = open(input_name, "r")
names = name.readlines()
input_number = "./infinite_loop/infinite_loop_number.txt"
number = open(input_number, "r")
numbers = number.readlines()

out_att= "./infinite_loop/att.txt"
f_w = open(out_att, "a")
out_label = "./infinite_loop/label.txt"
f_l = open(out_label, "a")

count = 0
fragment = []

for i in range(len(names)):
    name = names[i].strip()
    label = labels[i].strip()
    number = numbers[i].strip()

    for k in range(int(number)):
        for j in range(len(contracts)):
            if name == contracts[j].strip():
                count += 1
                fragment.append(contracts[j])
            elif count != 0:
                if ".c" in contracts[j].strip():
                    count = 0
                    break
                else:
                    fragment.append(contracts[j])

        for m in range(len(fragment)):
            f_w.write(fragment[m])
        f_l.write(label + '\n')
        fragment = []
