import csv
golden_result = csv.reader(open("./ofm_dec.txt"), delimiter=' ')
my_result     = csv.reader(open("./ofm_rtl.txt"), delimiter=' ')

golden_vec = []
for line in golden_result:
    if (line == []):
        continue
    handle = []
    for item in line:
        if item != "":
            handle.append(item)
    golden_vec.append(handle)
my_vec = []
for line in my_result:
    if (line == []):
        continue
    handle = []
    for item in line:
        if item != "":
            handle.append(item)
    my_vec.append(handle)

result = 0;
for i in range(len(my_vec)):
    if (len(my_vec[i]) != len(golden_vec[i])):
        print (i, " ", len(my_vec[i]), " ",   len(golden_vec[i]))
    for j in range(len(my_vec[i])):
        if (my_vec[i][j] != golden_vec[i][j]):
            result = 1
            print ("\033[33mOpps! wrong result", my_vec[i][j], ", ", golden_vec[i][j],"\033[0m")

if (not result):
    print ("\033[32mPass, Correct result !!!\033[0m")
else:
    print ("\033[31mOpss, Wrong result !!!\033[0m")
