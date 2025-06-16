import pandas as pd
from typing import List, Dict, Any
import numpy as np
import skmine
from skmine.itemsets import SLIM


class ScanpathClassifier:
    def __init__(self, scanpaths: List[List[str]], target: str, aois: List[str] = None):
        self.scanpaths = scanpaths
        self.target = target
        self.patterns = []
        self.slim = SLIM(pruning=False, items=aois, max_time=30)
    
    def fit(self):
        self.slim = self.slim.fit(self.scanpaths)
        # self.patterns = self.slim.transform(self.scanpaths)



    def get_patterns(self) -> List[Dict[str, Any]]:
        """
        Returns the discovered patterns.
        """
        return self.patterns
    

if __name__ == "__main__":
    df = pd.read_csv("analysis\\data\\markov_models\\markov_models_trial.csv")
    df['Scanpath'] = df['Scanpath'].apply(lambda x: eval(x))
    df_simple = df[df['Condition'] == 'simple']
    df_simple_l0 = df_simple[df_simple['StrategyLabel'] == 0]['Scanpath'].tolist()
    df_simple_l1 = df_simple[df_simple['StrategyLabel'] == 1]['Scanpath'].tolist()
    df_simple_l2 = df_simple[df_simple['StrategyLabel'] == 2]['Scanpath'].tolist()

    aois = ['trgt', 'comp', 'dist', 'sent_msg', 'av_msgs']
    D = [
    ['bananas', 'milk'],
    ['milk', 'bananas', 'cookies'],
    ['cookies', 'butter', 'tea'],
    ['tea'], 
    ['milk', 'bananas', 'tea'],
    ]
    miner_simple_l0 = ScanpathClassifier(D, target='StrategyLabel')

    # miner_simple_l0 = ScanpathClassifier(df_simple_l0, target='StrategyLabel', aois=aois)
    miner_simple_l0.fit()
    patterns_simple_l0 = miner_simple_l0.get_patterns()
    print("Patterns for simple L0:", patterns_simple_l0)