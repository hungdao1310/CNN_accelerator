import torch
import torch.nn as nn
import numpy as np

ifm_width = 16
wgt_width = 8
out_width = 32
tile      = 8

# Input image
ih = 227
iw = 227

# Convolution 1
kk = 11
stride = 4
pad = 0
relu = 1
ic = 1
oc = 2

# Max pooling 1
kk_pool = 3
stride_pool = 2

# Convolution 2
kk_1 = 5
stride_1 = 1
pad_1 = 2
relu_1 = 1
oc_1 = 4

# Max pooling 2
kk_pool_1 = 3
stride_pool_1 = 2

# Convolution 3
kk_2 = 3
stride_2 = 1
pad_2 = 1
relu_2 = 1
oc_2 = 6

# Convolution 4
kk_3 = 3
stride_3 = 1
pad_3 = 1
relu_3 = 1
oc_3 = 8

# Convolution 5
kk_4 = 3
stride_4 = 1
pad_4 = 1
relu_4 = 1
oc_4 = 10

# Max pooling 3
kk_pool_2 = 3
stride_pool_2 = 2

# FC1
in_feature_1 = 360
out_feature_1 = 160

# FC1
out_feature_2 = 80

# FC1
out_feature_3 = 40 

oh_conv = int((ih+2*pad-kk)/stride) + 1
ow_conv = int((iw+2*pad-kk)/stride) + 1
oh_pool = int((oh_conv-kk_pool)/stride_pool) + 1
ow_pool = int((ow_conv-kk_pool)/stride_pool) + 1
oh_conv_1 = int((oh_pool+2*pad_1-kk_1)/stride_1) + 1
ow_conv_1 = int((ow_pool+2*pad_1-kk_1)/stride_1) + 1
oh_pool_1 = int((oh_conv_1-kk_pool_1)/stride_pool_1) + 1
ow_pool_1 = int((ow_conv_1-kk_pool_1)/stride_pool_1) + 1
oh_conv_2 = int((oh_pool_1+2*pad_2-kk_2)/stride_2) + 1
ow_conv_2 = int((ow_pool_1+2*pad_2-kk_2)/stride_2) + 1
oh_conv_3 = int((oh_conv_2+2*pad_3-kk_3)/stride_3) + 1
ow_conv_3 = int((ow_conv_2+2*pad_3-kk_3)/stride_3) + 1
oh_conv_4 = int((oh_conv_3+2*pad_4-kk_4)/stride_4) + 1
ow_conv_4 = int((ow_conv_3+2*pad_4-kk_4)/stride_4) + 1
oh_pool_2 = int((oh_conv_4-kk_pool_2)/stride_pool_2) + 1
ow_pool_2 = int((ow_conv_4-kk_pool_2)/stride_pool_2) + 1
oh = oh_pool_2
ow = ow_pool_2

torch.manual_seed(0)

conv2d = nn.Conv2d(in_channels=ic, out_channels=oc, kernel_size=kk, padding=pad, stride = stride, bias=False)
conv2d_1 = nn.Conv2d(in_channels=oc, out_channels=oc_1, kernel_size=kk_1, padding=pad_1, stride = stride_1, bias=False)
conv2d_2 = nn.Conv2d(in_channels=oc_1, out_channels=oc_2, kernel_size=kk_2, padding=pad_2, stride = stride_2, bias=False)
conv2d_3 = nn.Conv2d(in_channels=oc_2, out_channels=oc_3, kernel_size=kk_3, padding=pad_3, stride = stride_3, bias=False)
conv2d_4 = nn.Conv2d(in_channels=oc_3, out_channels=oc_4, kernel_size=kk_4, padding=pad_4, stride = stride_4, bias=False)
fc_1 = nn.Linear(in_features=in_feature_1, out_features=out_feature_1, bias = False)
fc_2 = nn.Linear(in_features=out_feature_1, out_features=out_feature_2, bias = False)
fc_3 = nn.Linear(in_features=out_feature_2, out_features=out_feature_3, bias = False)

# randomize input feature map
ifm = torch.rand(1, ic, ih, iw)*128-64
ifm = torch.round(ifm)

# randomize weight
weight = torch.rand(oc, ic, kk, kk)*4 - 2
weight = torch.round(weight)
weight1 = torch.rand(oc_1, oc, kk_1, kk_1)*4 - 2
weight1 = torch.round(weight1)
weight2 = torch.rand(oc_2, oc_1, kk_2, kk_2)*4 - 2
weight2 = torch.round(weight2)
weight3 = torch.rand(oc_3, oc_2, kk_3, kk_3)*4 - 2
weight3 = torch.round(weight3)
weight4 = torch.rand(oc_4, oc_3, kk_4, kk_4)*4 - 2
weight4 = torch.round(weight4)
weight_fc1 = torch.rand(out_feature_1,in_feature_1)*2-1
weight_fc1 = torch.round(weight_fc1)
weight_fc2 = torch.rand(out_feature_2,out_feature_1)*2-1
weight_fc2 = torch.round(weight_fc2)
weight_fc3 = torch.rand(out_feature_3,out_feature_2)*2-1
weight_fc3 = torch.round(weight_fc3)

# setting the weight
conv2d.weight = nn.Parameter(weight)
conv2d_1.weight = nn.Parameter(weight1)
conv2d_2.weight = nn.Parameter(weight2)
conv2d_3.weight = nn.Parameter(weight3)
conv2d_4.weight = nn.Parameter(weight4)
fc_1.weight = nn.Parameter(weight_fc1)
fc_2.weight = nn.Parameter(weight_fc2)
fc_3.weight = nn.Parameter(weight_fc3)

# computing output feature
ofm = conv2d(ifm)
ofm = nn.ReLU()(ofm)
ofm = nn.MaxPool2d(kk_pool, stride = stride_pool)(ofm)
ofm = conv2d_1(ofm)
ofm = nn.ReLU()(ofm)
ofm = nn.MaxPool2d(kk_pool_1, stride = stride_pool_1)(ofm)
ofm = conv2d_2(ofm)
ofm = nn.ReLU()(ofm)
ofm = conv2d_3(ofm)
ofm = nn.ReLU()(ofm)
ofm = conv2d_4(ofm)
ofm = nn.ReLU()(ofm)
ofm = nn.MaxPool2d(kk_pool_2, stride = stride_pool_2)(ofm)
ofm = torch.flatten(ofm, 1)
ofm = fc_1(ofm)
ofm = fc_2(ofm)
ofm = fc_3(ofm)
ofm = torch.round(ofm)

ifm_np = ifm.data.numpy().astype(int)
weight_np = weight.data.numpy().astype(int)
weight1_np = weight1.data.numpy().astype(int)
weight2_np = weight2.data.numpy().astype(int)
weight3_np = weight3.data.numpy().astype(int)
weight4_np = weight4.data.numpy().astype(int)
weight_fc1_np = weight_fc1.data.numpy().astype(int)
weight_fc2_np = weight_fc2.data.numpy().astype(int)
weight_fc3_np = weight_fc3.data.numpy().astype(int)
ofm_np = ofm.data.numpy().astype(int)

# Reshape the ifm to a 3D array
ifm_3d = ifm_np.reshape(ic, ih, iw)

# Create a ifm.txt file and write the sorted ifm values
with open("ifm.txt", "w") as file:
    for i in range(ic):
        for j in range(ih):
            for k in range(iw):
                s = np.binary_repr(ifm_3d[i][j][k], ifm_width) + " "
                file.write(s)
            file.write(f"\n")
        file.write("\n")

# Create a ifm_dec.txt file and write the sorted ifm values
with open("ifm_dec.txt", "w") as file:
    for i in range(ic):
        for j in range(ih):
            for k in range(iw):
                file.write(f"{ifm_3d[i][j][k]} ")
            file.write(f"\n")
        file.write("\n")

# Reshape the weight to a 3D array
weight_3d = weight_np.reshape(oc, ic, kk, kk)
weight1_3d = weight1_np.reshape(oc_1, oc, kk_1, kk_1)
weight2_3d = weight2_np.reshape(oc_2, oc_1, kk_2, kk_2)
weight3_3d = weight3_np.reshape(oc_3, oc_2, kk_3, kk_3)
weight4_3d = weight4_np.reshape(oc_4, oc_3, kk_4, kk_4)
weight_fc1_3d = weight_fc1_np.reshape(out_feature_1, in_feature_1)
weight_fc2_3d = weight_fc2_np.reshape(out_feature_2, out_feature_1)
weight_fc3_3d = weight_fc3_np.reshape(out_feature_3, out_feature_2)

# Create a weight file
with open("weight.txt", "w") as file:
    for i in range(oc):
        for j in range(ic):
            for k1 in range(kk):
                for k2 in range(kk):
                    s = np.binary_repr(weight_3d[i][j][k1][k2], wgt_width) + " "
                    file.write(s)
                file.write(f"\n")
            file.write(f"\n")
        file.write("\n")

with open("weight1.txt", "w") as file:
    for i in range(oc_1):
        for j in range(oc):
            for k1 in range(kk_1):
                for k2 in range(kk_1):
                    s = np.binary_repr(weight1_3d[i][j][k1][k2], wgt_width) + " "
                    file.write(s)
                file.write(f"\n")
            file.write(f"\n")
        file.write("\n")

with open("weight2.txt", "w") as file:
    for i in range(oc_2):
        for j in range(oc_1):
            for k1 in range(kk_2):
                for k2 in range(kk_2):
                    s = np.binary_repr(weight2_3d[i][j][k1][k2], wgt_width) + " "
                    file.write(s)
                file.write(f"\n")
            file.write(f"\n")
        file.write("\n")

with open("weight3.txt", "w") as file:
    for i in range(oc_3):
        for j in range(oc_2):
            for k1 in range(kk_3):
                for k2 in range(kk_3):
                    s = np.binary_repr(weight3_3d[i][j][k1][k2], wgt_width) + " "
                    file.write(s)
                file.write(f"\n")
            file.write(f"\n")
        file.write("\n")

with open("weight4.txt", "w") as file:
    for i in range(oc_4):
        for j in range(oc_3):
            for k1 in range(kk_4):
                for k2 in range(kk_4):
                    s = np.binary_repr(weight4_3d[i][j][k1][k2], wgt_width) + " "
                    file.write(s)
                file.write(f"\n")
            file.write(f"\n")
        file.write("\n")

with open("weight_fc1.txt", "w") as file:
    for i in range(out_feature_1 // tile):
        for j in range(in_feature_1):
            for k in range(tile):
                s = np.binary_repr(weight_fc1_3d[k+i*tile][j], wgt_width) + " "
                file.write(s)
            file.write(f"\n")
        file.write(f"\n")

with open("weight_fc2.txt", "w") as file:
    for i in range(out_feature_2 // tile):
        for j in range(out_feature_1):
            for k in range(tile):
                s = np.binary_repr(weight_fc2_3d[k+i*tile][j], wgt_width) + " "
                file.write(s)
            file.write(f"\n")
        file.write(f"\n")

with open("weight_fc3.txt", "w") as file:
    for i in range(out_feature_3 // tile):
        for j in range(out_feature_2):
            for k in range(tile):
                s = np.binary_repr(weight_fc3_3d[k+i*tile][j], wgt_width) + " "
                file.write(s)
            file.write(f"\n")
        file.write(f"\n")

# Reshape the ifm to a 3D array
ofm_3d = ofm_np.reshape(out_feature_3)

# Create a ofm.txt file
with open("ofm.txt", "w") as file:
    for i in range(out_feature_3):
        s = np.binary_repr(ofm_3d[i], out_width) + " "
        file.write(s)
        file.write("\n")

# Create a ofm_dec.txt file
with open("ofm_dec.txt", "w") as file:
    for i in range(out_feature_3):
        file.write(f"{ofm_3d[i]:>11} ")
        file.write("\n")
