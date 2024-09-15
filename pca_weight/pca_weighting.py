# -*- coding: utf-8 -*-
"""
Created on Sat Sep 14 10:50:36 2024

@author: elisa
"""

import pandas as pd
import numpy as np
from sklearn.decomposition import PCA
from sklearn import preprocessing

# read in data from excel
data_path = 'sample_data\\202106_POS_Summary_Morning en.xlsx'
df = pd.read_excel(data_path)

print(df.info)
print(df.columns)

# select columns and fillna
df_use = df[['shopper coverage',
             'sales volume as a percentage of',
             'surge factor',
             'Burst factor']]

df_use = df_use.fillna(0)

# standardize data and fit PCA
df_scale = preprocessing.scale(df_use) 
pca = PCA(n_components='mle')
pca.fit(df_scale)

# get variance explained ratio and components matrix
comps = pca.components_
var = pca.explained_variance_ratio_

# calculate weight for each variable
w = comps.T*var/var.sum()
w_i = w.sum(axis=1)
w_scale = w_i/w_i.sum()

# calculate score for each product 
df['score'] = df['shopper coverage']*w_scale[0] 
+ df['sales volume as a percentage of']*w_scale[1] 
+ df['surge factor']*w_scale[2] 
+ df['Burst factor']*w_scale[3]

# final table contains only the useful information and a weighted score
df_final = df[['product_id','name',
               'shopper coverage',
               'sales volume as a percentage of',
               'surge factor',
               'Burst factor',
               'score']]
df_final.sort_values(by='score', ascending = False, inplace = True)

# print out result
print('The weight of Shopper Coverage is: ', round(w_scale[0],2))
print('The weight of Sales Volume Percentage is: ', round(w_scale[1],2))
print('The weight of Surge Factor is: ', round(w_scale[2],2))
print('The weight of Burst Factor is: ', round(w_scale[3],2))
