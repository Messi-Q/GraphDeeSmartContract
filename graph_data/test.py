
input = "./SMARTCONTRACT_full_node_attributes.txt"
out = "./1.txt"

f = open(input, 'r')
f_w = open(out, 'a')
lines = f.readlines()
count = 0
count1 = 0
#
# for line in lines:
#     result = line.split(",")
#     r1 = result[0].strip()
#     r2 = result[1].strip()
#     f_w.write(str(int(r1) + 3) + ", " + str(int(r2) + 3) + '\n')


for line in lines:
    if len(line) <= 4:
        continue
    else:
        f_w.write(line)
