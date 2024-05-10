import torch
import torch.nn as nn
import numpy as np


ic = 3
ih = 28
iw = 28

stride = 1
pad = 0
kk = 13

oc = 3
oh = int((ih+2*pad-kk)/stride) + 1
ow = int((iw+2*pad-kk)/stride) + 1

conv2d = nn.Conv2d(in_channels=ic, out_channels=oc, kernel_size=kk, padding=pad, stride = stride, bias=False)
#relu = nn.ReLU(inplace=False)

# randomize input feature map
ifm = torch.rand(1, ic, ih, iw)*255-128
ifm = torch.round(ifm)

# randomize weight
weight = torch.rand(oc, ic, kk, kk)*255 - 128
weight = torch.round(weight)

# setting the kernel of conv2d as weight
conv2d.weight = nn.Parameter(weight)

# computing output feature
ofm = conv2d(ifm)
ofm = torch.round(ofm)
#ofm_relu = relu(ofm)

ifm_np = ifm.data.numpy().astype(int)
weight_np = weight.data.numpy().astype(int)
ofm_np = ofm.data.numpy().astype(int)

# Reshape the ifm to a 3D array
ifm_3d = ifm_np.reshape(ic, ih, iw)

# Create a ifm.txt file and write the sorted ifm values
with open("ifm.txt", "w") as file:
    for i in range(ic):
        for j in range(ih):
            for k in range(iw):
                s = np.binary_repr(ifm_3d[i][j][k], 8) + " "
                file.write(s)
                #file.write(f"{ifm_3d[i][j][k]} ")
            file.write(f"\n")
        file.write("\n")

# Create a ifm_dec.txt file and write the sorted ifm values
with open("ifm_dec.txt", "w") as file:
    for i in range(ic):
        for j in range(ih):
            for k in range(iw):
                #s = np.binary_repr(ifm_3d[i][j][k], 8) + " "
                #file.write(s)
                file.write(f"{ifm_3d[i][j][k]} ")
            file.write(f"\n")
        file.write("\n")

# Reshape the weight to a 3D array
weight_3d = weight_np.reshape(oc, ic, kk, kk)

# Create a weight.txt file and write the sorted ifm values
with open("weight.txt", "w") as file:
    for i in range(oc):
        for j in range(ic):
            for k1 in range(kk):
                for k2 in range(kk):
                    s = np.binary_repr(weight_3d[i][j][k1][k2], 8)
                    file.write(s)
                    #file.write(f"{weight_3d[i][j][k1][k2]} ")
            file.write(f"\n")
        file.write("\n")

# Create a weight_dec.txt file and write the sorted ifm values
with open("weight_dec.txt", "w") as file:
    for i in range(oc):
        for j in range(ic):
            for k1 in range(kk):
                for k2 in range(kk):
                    #s = np.binary_repr(weight_3d[i][j][k1][k2], 8)
                    #file.write(s)
                    file.write(f"{weight_3d[i][j][k1][k2]} ")
            file.write(f"\n")
        file.write("\n")

# Reshape the ifm to a 3D array
ofm_3d = ofm_np.reshape(oc, oh, ow)

# Create a ofm.txt file and write the sorted ifm values
with open("ofm.txt", "w") as file:
    for i in range(oc):
        for j in range(oh):
            for k in range(ow):
                s = np.binary_repr(ofm_3d[i][j][k], 25) + " "
                file.write(s)
                #file.write(f"{ofm_3d[i][j][k]} ")
            file.write(f"\n")
        file.write("\n")

# Create a ofm_dec.txt file and write the sorted ifm values
with open("ofm_dec.txt", "w") as file:
    for i in range(oc):
        for j in range(oh):
            for k in range(ow):
                #s = np.binary_repr(ofm_3d[i][j][k], 25) + " "
                #file.write(s)
                file.write(f"{ofm_3d[i][j][k]} ")
            file.write(f"\n")
        file.write("\n")
