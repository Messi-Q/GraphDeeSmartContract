
input = "SMARTCONTRACT_full_node_attributes.txt"
out = "2.txt"
f = open(input, 'r')
f_w = open(out, 'w')
count = 0

lines = f.readlines()

for line in lines:
    if len(line) < 5:
        continue
    else:
        f_w.write(line)

