input = "SMARTCONTRACT_full_node_attributes.txt"
f_r = open(input, 'r')
lines = f_r.readlines()

out = "graph_data_number_1584.txt"
f = open(out, 'a')

for line in lines:
    if ".txt" not in line:
        f.write(line)

