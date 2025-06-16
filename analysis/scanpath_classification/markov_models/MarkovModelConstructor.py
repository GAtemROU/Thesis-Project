import pandas as pd
from MarkovModel import MarkovModel
import os

class MarkovModelConstructor:
    def __init__(self, states):
        self.states = states

    def create_markov_models_per_trial(self, df: pd.DataFrame, states):
        df_grouped = df.groupby(['Condition', 'Subject', 'Trial']).agg({
            'AOI': list,
            'Correct': 'first',
            'StrategyLabel': 'first',
            'TrgtPos': 'first',
            'MsgType': 'first'
        }).reset_index()
        df_grouped.rename(columns={'AOI': 'Scanpath'}, inplace=True)
        df_grouped['TransitionMatrix'] = df_grouped['Scanpath'].apply(lambda x: MarkovModel(states).fit(x))
        return df_grouped

    def create_markov_models_per_participant(self, df: pd.DataFrame, states):
        # scanpaths from all trials are grouped together for each participant
        df_grouped = df.groupby(['Condition', 'Subject']).agg({
            'AOI': list,
            'Correct': 'first',
            'StrategyLabel': 'first',
            'TrgtPos': 'first',
            'MsgType': 'first'
        }).reset_index()
        df_grouped.rename(columns={'AOI': 'Scanpath'}, inplace=True)
        df_grouped['TransitionMatrix'] = df_grouped['Scanpath'].apply(lambda x: MarkovModel(states).fit(x))
        return df_grouped

    def explode_transition_matrix(self, df: pd.DataFrame, states):
        state_to_id = MarkovModel.get_state_index(states)
        for state_from in states:
            for state_to in states:
                df[f'{state_from}_to_{state_to}'] = df['TransitionMatrix'].apply(lambda x: x[state_to_id[state_from]][state_to_id[state_to]])
        return df
           

    def create_markov_models(self, path, states, include_non_aoi=False, save=False, explode=False, per='participant', save_path=None):
        if save_path is None:
            save_path = "analysis/data/markov_models/"
        assert per in ['trial', 'participant'], "Parameter 'per' must be either 'trial' or 'participant'."
        scanpaths = pd.read_csv(path)
        if not include_non_aoi:
            scanpaths = scanpaths[scanpaths['AOI'] != 'non_aoi']
        df = None
        if per == 'trial':
            df = self.create_markov_models_per_trial(scanpaths, states)
        elif per == 'participant':
            df = self.create_markov_models_per_participant(scanpaths, states)
        if explode and df is not None:
            df = self.explode_transition_matrix(df, states)
        if save and df is not None:
            os.makedirs(save_path, exist_ok=True)
            df.to_csv(f"{save_path}/markov_models_{per}{'_exp_matrix' if explode else ""}.csv", index=False)
        return df