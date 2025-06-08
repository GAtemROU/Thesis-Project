import pandas as pd
from MarkovModel import MarkovModel

class MarkovModelConstructor:
    def __init__(self, states):
        self.states = states

    def create_markov_models_per_trial(self, df: pd.DataFrame, states, save=False):
        df_grouped = df.groupby(['Condition', 'Subject', 'Trial']).agg({
            'AOI': list,
            'Correct': 'first',
            'StrategyLabel': 'first',
            'TrgtPos': 'first',
            'MsgType': 'first'
        }).reset_index()
        df_grouped.rename(columns={'AOI': 'Scanpath'}, inplace=True)
        model = MarkovModel(states)
        model.fit(df_grouped.loc[0]['Scanpath'])
        df_grouped['TransitionMatrix'] = df_grouped['Scanpath'].apply(lambda x: MarkovModel(states).fit(x))
        if save:
            df_grouped.to_csv("analysis/data/markov_models/markov_models_trials.csv", index=False)
        return df_grouped

    def create_markov_models_per_participant(self, df: pd.DataFrame, states, save=False):
        # scanpaths from all trials are grouped together for each participant
        df_grouped = df.groupby(['Condition', 'Subject']).agg({
            'AOI': list,
            'Correct': 'first',
            'StrategyLabel': 'first',
            'TrgtPos': 'first',
            'MsgType': 'first'
        }).reset_index()
        df_grouped.rename(columns={'AOI': 'Scanpath'}, inplace=True)
        model = MarkovModel(states)
        model.fit(df_grouped.loc[0]['Scanpath'])
        df_grouped['TransitionMatrix'] = df_grouped['Scanpath'].apply(lambda x: MarkovModel(states).fit(x))
        if save:
            df_grouped.to_csv("analysis/data/markov_models/markov_models_participants.csv", index=False)
        return df_grouped

    def create_markov_models(self, path, states, save=False, per='participant'):
        scanpaths = pd.read_csv(path)
        if per == 'trial':
            return self.create_markov_models_per_trial(scanpaths, states, save)
        elif per == 'participant':
            return self.create_markov_models_per_participant(scanpaths, states, save)
