inputfile = "chem.txt"
f_r = open(inputfile, "r")
lines = f_r.readlines()
out = "1.txt"
f_w = open(out, "a")
flag = 0
count = 0
total = 0

for i in range(len(lines)):
    if ".txt" in lines[i]:
        flag += 1
        count = 0
        continue
    else:
        count += 1


for i in range(37, 43, 6):
    f_w.write(str(i) + ", " + str(i + 1) + "\n")
    f_w.write(str(i + 1) + ", " + str(i + 2) + "\n")
    f_w.write(str(i) + ", " + str(i + 2) + "\n")
    f_w.write(str(i + 2) + ", " + str(i + 1) + "\n")
    f_w.write(str(i + 2) + ", " + str(i) + "\n")
    f_w.write(str(i + 1) + ", " + str(i) + "\n")
