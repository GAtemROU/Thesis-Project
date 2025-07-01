from typing import List
from pattern_mining.SQS import SQS
import pandas as pd
from itertools import product


class SequentialPatternMiner:
    """Class for mining patterns from sequential data using the SQS algorithm.
    This class helps in managing sequences coming from different classes.
    :param df: DataFrame containing sequences.
    :param split_by: List of columns to split sequences by, if any.

    """
    def __init__(self, df, target, split_by:List[str]|None=None, min_support=None, method=None):
        self.target = target
        self.df = df
        assert target in df.columns, f"Target column '{target}' not found in DataFrame."
        self.patterns = pd.DataFrame(columns=['patterns'] + (split_by if split_by else []))
        self.split_by = split_by
        self.sqs = SQS()
        if min_support is not None:
            self.sqs.set_min_support(min_support)
        if method is not None:
            self.sqs.set_method(method)
            
    def mine_patterns(self):
        """
        Mine patterns from the scanpaths using the SQS algorithm.
        
        :return: DataFrame containing discovered patterns.
        """
        if self.split_by:
            permutations = self.generate_permutations()                
            for permutation in permutations:
                data = {}
                sub_df = self.df
                for i, col in enumerate(self.split_by):
                    data[col] = permutation[i]
                    sub_df = sub_df[sub_df[col] == permutation[i]]
                patterns = self.sqs.mine(sub_df[self.target].tolist())
                data['patterns'] = patterns
                patterns_df = pd.DataFrame([data])
                self.patterns = pd.concat([self.patterns, patterns_df], ignore_index=True)
        else:
            patterns = self.sqs.mine(self.df[self.target].tolist())
            self.patterns['patterns'] = patterns

        return self.patterns

    def generate_permutations(self):
        """
        Generate all permutations of the split_by columns.
        
        :return: List of permutations.
        """
        if not self.split_by:
            return [[]]
        return list(product(*[self.df[col].unique() for col in self.split_by]))

    def get_patterns(self):
        """
        Extract patterns from the given scanpaths using the SQS algorithm.
        
        :param scanpaths: List of scanpaths to mine patterns from.
        :return: List of discovered patterns.
        """
        return self.patterns
