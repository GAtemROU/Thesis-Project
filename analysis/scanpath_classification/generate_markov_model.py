import numpy as np
from typing import List, Dict, Any


class MarkovModel:
    def __init__(self, states: List[str]):
        self.transition_matrix = np.zeros((len(states), len(states)))
        self.states = states
        self.state_index = {state: index for index, state in enumerate(states)}
        self.prior_counts = np.zeros(len(states))
        self.prior_probabilities = np.zeros(len(states))
        self.joint_counts = np.zeros((len(states), len(states)))
        self.joint_probabilities = np.zeros((len(states), len(states)))
    
    def fit(self, scanpaths: List[List[str]]):
        prior_counts = np.zeros(len(self.states))
        join_counts = np.zeros((len(self.states), len(self.states)))
        for scanpath in scanpaths:
            for i in range(1, len(scanpath)):
                current_state = scanpath[i - 1]
                next_state = scanpath[i]
                prior_counts[self.state_index[current_state]] += 1
                join_counts[self.state_index[current_state], self.state_index[next_state]] += 1
        self.prior_counts = prior_counts
        self.joint_counts = join_counts
        self.prior_probabilities = prior_counts / np.sum(prior_counts)
        self.joint_probabilities = join_counts / np.sum(join_counts, axis=1, keepdims=True)
        self.transition_matrix = self.joint_probabilities / self.prior_probabilities[:, np.newaxis]
    
    def get_transition_matrix(self) -> np.ndarray:
        return self.transition_matrix

    def get_prior_probabilities(self) -> np.ndarray:
        return self.prior_probabilities
    
    def get_joint_probabilities(self) -> np.ndarray:
        return self.joint_probabilities
    
    

    