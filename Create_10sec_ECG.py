#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Mar 25 14:19:36 2022

@author: sg
"""

from IPython.display import display
import matplotlib.pyplot as plt
%matplotlib inline
import numpy as np
import os
import shutil
import posixpath
import wfdb
import pandas as pd

os.chdir("/Users/sg/Downloads/ten_sec_ECGS")

lst = os.listdir("/Users/sg/Downloads/ECG_project/physionet.org/files/cded/1.0.0/Data/ECG/formatted_data/")
lst2 = []

for filename in lst:
    name = filename.split('.')[0]
    lst2.append(name)

# Get unique list
lst3 = list(set(lst2))

# Manually check quality of ECGS
for filename in lst3:
    print(filename)
    # load a record using the 'rdrecord' function
    record = wfdb.rdrecord("/Users/sg/Downloads/ECG_project/physionet.org/files/cded/1.0.0/Data/ECG/formatted_data/" + filename)    
    sig1 = pd.DataFrame(record.p_signal)
    sig1.columns = ['ecg_0' , 'ecg_1', 'sensor_0' , 'sensor_1', 'emg_0', 'emg_1', 'accelerometer_0', 'accelerometer_1']
    figure, axis = plt.subplots(2, 2, figsize=(25, 8))
    L = record.fs*10
    
    axis[0, 0].plot(sig1.iloc[1:L,0])
    axis[0, 0].set_title(record.record_name)
    axis[0, 1].plot(sig1.iloc[1:L,1])
    axis[0, 1].set_title(record.record_name)
    axis[1, 0].plot(sig1.iloc[2:L,2])
    axis[1, 0].set_title(record.record_name)
    axis[1, 1].plot(sig1.iloc[3:L,3]) 
    axis[1, 1].set_title(record.record_name)

# Plot 10 second ECGs for all individuals both first ECG signal and second
### Signal 1 ###
for filename in lst3:
    
    print(filename)
    
    # load a record using the 'rdrecord' function
    record = wfdb.rdrecord("/Users/sg/Downloads/ECG_project/physionet.org/files/cded/1.0.0/Data/ECG/formatted_data/" + filename)
    
    sig1 = pd.DataFrame(record.p_signal)
    
    # record time
    print('How many 10 second measurement intervals:', sig1.shape[0] / record.fs/ 10)
    
    # Define 10 sec interval via record freq times 10
    ten = record.fs*10
    # Create sequence of intervals
    ten_int = np.arange(0, sig1.shape[0], ten)
    
    # Limit to first 300
    if (len(ten_int) > 300):
        len_sig = 300
    else:
        len_sig = len(ten_int)
        
    print(len_sig)
        
    for x in range(1,len_sig):
        print(x)
        plt.figure()
        plt.plot(sig1.iloc[ten_int[x-1]:ten_int[x],0])
        plt.xlabel('Time')
        plt.savefig(filename + "_signal1_" + str(x) + "_plot.png")

### Signal 2 ###
for filename in lst3:
    
    print(filename)
    
    # load a record using the 'rdrecord' function
    record = wfdb.rdrecord("/Users/sg/Downloads/ECG_project/physionet.org/files/cded/1.0.0/Data/ECG/formatted_data/" + filename)
    
    sig1 = pd.DataFrame(record.p_signal)
    
    # record time
    print('How many 10 second measurement intervals:', sig1.shape[0] / record.fs/ 10)
    
    # Define 10 sec interval via record freq times 10
    ten = record.fs*10
    # Create sequence of intervals
    ten_int = np.arange(0, sig1.shape[0], ten)
    
    # Limit to first 300
    if (len(ten_int) > 300):
        len_sig = 300
    else:
        len_sig = len(ten_int)
        
    print(len_sig)
        
    for x in range(1,len_sig):
        print(x)
        plt.figure()
        plt.plot(sig1.iloc[ten_int[x-1]:ten_int[x],1])
        plt.xlabel('Time')
        plt.savefig(filename + "_signal1_" + str(x) + "_plot.png")



