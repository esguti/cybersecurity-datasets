#!/usr/bin/env python3

import os
import pandas as pd
import argparse
from tensorflow.keras.utils import get_file
from warnings import simplefilter
simplefilter(action="ignore", category=pd.errors.PerformanceWarning)


pd.set_option('display.max_columns', 6)
pd.set_option('display.max_rows', 5)


# Read the headers to process
def read_data_and_store_in_array(filename):
    try:
        with open(filename, 'r') as file:
            # Read the entire file contents
            data = file.read()
            # Split the data by both commas and new lines
            values = data.split(',\n')
            # Remove the end-of-line character from the last element
            values[-1] = values[-1].rstrip('\n')
            # Return the list of values
            return values
    except FileNotFoundError:
        print(f"Error header file does not exist: '{filename}'")
        return []
    except Exception as e:
        print(f"An error occurred: {e}")
        return []



# Read the path
parser = argparse.ArgumentParser(description='Execute the IDS')
parser.add_argument('path', type=str, help='The folder path to csv files')


# Parse the arguments
args = parser.parse_args()
path = args.path

if not os.path.exists(path):
    raise FileNotFoundError(f"The path does not exists: {path}")

csv_folder = os.path.basename(os.path.normpath(path))

# Read all CSV files under path
use_gpu=False
csv_headers='headers_'+csv_folder+'.txt'
csv_file_list = []
for root, dirs, files in os.walk(path):
    for name in files:
        # print(name)
        if name.endswith('.csv'):
            file_path = os.path.join(root, name)
            csv_file_list.append(file_path)

cols=read_data_and_store_in_array(path+'/'+csv_headers)
print(cols)

df = pd.DataFrame()
for filecsv in csv_file_list:
    print ('file: ' + filecsv)
    dft = pd.read_csv(filecsv, usecols=cols)
    df = pd.concat([dft, df])

print("Read {} rows.".format(len(df)))
# df = df.sample(frac=0.1, replace=False) # Uncomment this line to sample only 10% of the dataset
df.dropna(inplace=True,axis=1)
# For now, just drop NA's (rows with missing values)

# display 5 rows
pd.set_option('display.max_columns', 5)
pd.set_option('display.max_rows', 5)
# print(df)

import numpy as np
# print('Convert to float32...')
# columnas_float64 = df.select_dtypes(include=['float64']).columns
# df[columnas_float64] = df[columnas_float64].astype('float32')
print('Remove NaN...')
df_new = df[~df.isin([np.nan, np.inf, -np.inf]).any(1)]

print(df_new.head)
pd.pandas.set_option('display.max_rows', None)
print(df_new.dtypes)
# print(df_new[0:5])
# print(df_new.groupby('Label')['Label'].count())

print("Import pycaret...")
# import pycaret classification and init setup
import mlflow
from pycaret.classification import ClassificationExperiment
from pycaret.classification import *
from pycaret import show_versions
import sklearn
sklearn.set_config(enable_metadata_routing=True)

show_versions()

print("Start setup...")
mlflow.autolog(disable=True)
exp = ClassificationExperiment()
exp.setup(
    data=df_new,
    target = 'Label',
    session_id = 123,
    index = False,
    use_gpu = use_gpu,
    train_size = 0.7,
    log_experiment = True,
    log_plots = False,
    profile = False,
    memory = True,
    numeric_imputation = 'mean',
    preprocess = True,
    normalize=True,
    fold_shuffle=True,
    feature_selection_method='classic',
    feature_selection_estimator="lightgbm",
    max_encoding_ohe=0
)

# print("Compare Models...")
# best_model = exp.compare_models(
#     exclude=['auto-arima']
# )



print("Create Model...")
best_model = exp.compare_models()
# best_model = exp.create_model('dt')  # Random Forest classifier


# print("Tune Model sklearn...")
# tuned_dt1 = exp.tune_model(best_model, n_iter = 50)
# print("Tune Model optuna...")
# tuned_dt2 = exp.tune_model(best_model, n_iter = 50, search_library = 'optuna')
# print("Tune Model scikit-optimize...")
# tuned_dt3 = exp.tune_model(best_model, n_iter = 50, search_library = 'scikit-optimize')
# print("Tune Model tune-sklearn...")
# tuned_dt4 = exp.tune_model(best_model, n_iter = 50, search_library = 'tune-sklearn', search_algorithm = 'hyperopt', choose_better = True)
# print("Predict tuned Model...")
# exp.predict_model(tuned_dt4, df_new)

# # ensemble model
# print("Ensemble Model...")
# ensembled_dt4 = exp.ensemble_model(best_model, choose_better = True)

# print("Predict ensembled model...")
# exp.predict_model(ensembled_dt4, df_new)

print("Save Model...")
from datetime import datetime
import time

if use_gpu == True :
    gpu_cpu ='gpu'
else:
    gpu_cpu = 'cpu'

model_name = 'best_' + csv_folder + '_model_' + gpu_cpu + '-'
model_time = datetime.utcnow().strftime("%Y-%m-%d_%H-%M-%S")
model_file_name = model_name + model_time
exp.save_model(best_model, model_name=model_file_name)
print("Model Name: " + model_file_name + ".pkl")
