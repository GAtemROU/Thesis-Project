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
    
    def fit(self, scanpath: List[str]) -> np.ndarray:
        prior_counts = np.zeros(len(self.states))
        joint_counts = np.zeros((len(self.states), len(self.states)))
        for i in range(1, len(scanpath)):
            current_state = scanpath[i - 1]
            next_state = scanpath[i]
            if current_state in self.states:
                prior_counts[self.state_index[current_state]] += 1
            if current_state in self.states and next_state in self.states:
                joint_counts[self.state_index[current_state], self.state_index[next_state]] += 1
        self.prior_counts = prior_counts
        self.joint_counts = joint_counts
        self.prior_probabilities = prior_counts / len(scanpath)
        self.joint_probabilities = joint_counts / len(scanpath)
        # ignore zero division warning, handle nan later
        with np.errstate(divide='ignore', invalid='ignore'):
            self.transition_matrix = self.joint_probabilities / self.prior_probabilities[:, np.newaxis]
        # handle division by zero
        self.transition_matrix[np.isnan(self.transition_matrix)] = 0
        return self.transition_matrix

    def get_transition_matrix(self) -> np.ndarray:
        return self.transition_matrix

    def get_prior_probabilities(self) -> np.ndarray:
        return self.prior_probabilities
    
    def get_joint_probabilities(self) -> np.ndarray:
        return self.joint_probabilities
    
    @staticmethod
    def get_state_index(states: List[str]) -> Dict[str, int]:
        return {state: index for index, state in enumerate(states)}

    