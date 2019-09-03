
out = "graph_data_number_1584.txt"
f = open(out, 'a')

for i in range(1, 4459, 3):
    f.write(str(i) + ", " + str(i+1) + '\n')
    f.write(str(i+1) + ", " + str(i + 2) + '\n')
    f.write(str(i) + ", " + str(i + 2) + '\n')
    f.write(str(i+2) + ", " + str(i + 1) + '\n')
    f.write(str(i+2) + ", " + str(i) + '\n')
    f.write(str(i+1) + ", " + str(i) + '\n')