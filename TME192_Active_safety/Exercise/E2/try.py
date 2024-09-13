# -*- coding: utf-8 -*-
"""
Created on Mon Sep 11 10:29:03 2023

@author: 13906
"""


import pickle
import dill
	   
data = dill.load(open('check_output.pkl', 'rb'))
 
data(speed_index, speed_hex, speed_bin, speed, accelerator_index, accelerator_hex, accelerator_bin, accelerator, speed_time, accelerator_time, speed_time_from_0, accelerator_time_from_0, sync_time, speed_sync, accelerator_sync, predicted_speed, warning_time)
