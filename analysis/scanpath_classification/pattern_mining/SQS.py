import tempfile
import subprocess
import os


class SQS:
    """
    Class for "Summarizing event seQuenceS" algorithm.
    This cass is a wrapper for the SQS algorithm, which is originally implementee in C++.
    """
    def __init__(self, min_support=0.1, method='order'):
        """
        Initialize the SQS algorithm with minimum support.
        
        :param min_support: Minimum support threshold for patterns.
        :param method: Method to use for mining patterns, 'order' or 'search'.
        """
        self.min_support = min_support
        self.id_to_item = {}
        self.item_to_id = {}
        self.method = method
    def set_min_support(self, min_support):
        """
        Set the minimum support threshold for the SQS algorithm.
        
        :param min_support: Minimum support threshold.
        """
        self.min_support = min_support
    
    def set_method(self, method):
        """
        Set the method for mining patterns.
        
        :param method: Method to use for mining patterns, 'order' or 'search'.
        """
        if method not in ['order', 'search']:
            raise ValueError("Method must be either 'order' or 'search'.")
        self.method = method

    def mine(self, sequences):
        """
        Run the SQS algorithm on the given sequences.
        
        :param sequences: List of sequences to mine patterns from.
        :return: List of discovered patterns.
        """
        if not sequences:
            return []
        converted_sequences = self.convert_to_sqs_format(sequences)
        # save converted_sequences to a file and pass it to the C++ SQS implementation
        with tempfile.NamedTemporaryFile(mode='w+', delete=False) as seq_file:
            for line in converted_sequences:
                seq_file.write(line + '\n')
            seq_file_path = seq_file.name

        output_file = tempfile.NamedTemporaryFile(delete=False)
        output_file_path = output_file.name
        output_file.close()

        try:
            cmd = [
            
            os.path.join(os.path.dirname(__file__), 'sqs/sqs'),
            '-i', seq_file_path,
            '-o', output_file_path,
            '-m', self.method,
            '-t', str(self.min_support)
            ]
            subprocess.run(cmd, check=True)
            with open(output_file_path, 'r') as f:
                patterns = [line.strip() for line in f if line.strip()]
            #convert patterns back to original item ids
            parsed_patterns = [pattern.split('(') for pattern in patterns]
            print(parsed_patterns)
            res_patterns = []
            for pattern in parsed_patterns:
                items = pattern[0].split(' ')
                items = [self.id_to_item[int(item)] for item in items if item.isdigit()]
                res_patterns.append({'pattern': items, 'other_info': pattern[1].strip(')')})
            return res_patterns
        finally:
            os.remove(seq_file_path)
            os.remove(output_file_path)

    def convert_to_sqs_format(self, sequences, items=None):
        """
        Convert sequences to the format required by the SQS algorithm.
        
        space-separated sequence of ids, unsigned integers.
        -1 acts as a separator between two sequences.
        
        :param sequences: List of sequences to convert.
        :return: Converted sequences in SQS format.
        """
        if items is None:
            items = set(item for seq in sequences for item in seq)
        item_to_id = {item: idx for idx, item in enumerate(sorted(items))}
        id_to_item = {idx: item for item, idx in item_to_id.items()}
        self.id_to_item = id_to_item
        converted_sequences = []
        for i, seq in enumerate(sequences):
            converted_seq = ' '.join(str(item_to_id[item]) for item in seq)
            if i < len(sequences) - 1:
                converted_seq += ' -1'
            converted_sequences.append(converted_seq)
        return converted_sequences
