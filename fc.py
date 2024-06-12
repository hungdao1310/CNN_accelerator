import torch
import torch.nn as nn
import numpy as np

wgt_width = 8
tile = 3
in_feature = 8
out_feature = 6
torch.manual_seed(0)

# ifm
ifm = torch.rand(in_feature)*255-128
ifm = torch.round(ifm)

# weight
weight = torch.rand(out_feature,in_feature)*255-128
weight = torch.round(weight)
weight_np = weight.data.numpy().astype(int)
weight_3d = weight_np.reshape(out_feature, in_feature)

# fully connected
fc = nn.Linear(in_features=in_feature, out_features=out_feature, bias = False)
fc.weight = nn.Parameter(weight)

# computing
ofm = fc(ifm)

print("ifm:")
print(ifm)
print("weight:")
print(weight)
print("ofm:")
print(ofm)

# Create a weight_fc.txt file
with open("weight_fc.txt", "w") as file:
    for i in range(out_feature // tile):
        for j in range(in_feature):
            for k in range(tile):
                s = np.binary_repr(weight_3d[k+i*tile][j], wgt_width) + " "
                file.write(s)
            file.write(f"\n")
        file.write(f"\n")

# Create a weight_fc_dec.txt file
with open("weight_fc_dec.txt", "w") as file:
    for i in range(out_feature // tile):
        for j in range(in_feature):
            for k in range(tile):
                file.write(f"{weight_3d[k+i*tile][j]} ")
            file.write(f"\n")
        file.write(f"\n")
