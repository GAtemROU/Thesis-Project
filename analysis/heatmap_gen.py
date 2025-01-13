import base64
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import pprint
import json

pp = pprint.PrettyPrinter(indent=4)

# Load the data

df = pd.read_csv('analysis/experiment_results.csv')

def parse(data):
    global flag
    while data[0] != '{':
        data = data[1:]
    while data[-1] != '}':
        data = data[:-1]
    data = data.replace('\\', '')
    json_data = json.loads(data)
    return json_data


df = pd.concat([df, pd.json_normalize(df.apply(lambda x: parse(x['answer']), axis=1), max_level=0)], axis=1)
df.sort_values(by=['workerid', 'timestamp'], inplace=True)
# print(df.iloc[0].to_string())

df.gaze = df.gaze.apply(lambda x: json.loads(base64.b64decode(x)))


