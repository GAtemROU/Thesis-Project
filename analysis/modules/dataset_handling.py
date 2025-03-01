from os.path import join
from torchvision.datasets import ImageFolder
from torch.utils.data import Subset, DataLoader
from pathlib import Path


class DatasetHandler:
    """
    Manages the dataset, to get only the instances for the specific participants.

    Attributes:
        dataset: ImageFolder object got from root and transform parameters
        participants: sorted list of all participants found
    """
    def __init__(self, root, transform, targets=None):
        if targets is None:
            targets = ['C', 'P']
        self.dataset = ImageFolder(root, transform)
        self.participants = []
        for t in targets:
            t_participants = [f.name for f in sorted(Path(join(root, t)).iterdir())
                              if f.is_dir()]
            self.participants = list(set(self.participants).union(set(t_participants)))
        self.participants = sorted(self.participants)

    def get_participants(self):
        return self.participants

    def get_ids(self, participants):
        """
        Get ids of all instances in dataset, for the given list of participants.

        Args:
            participants: list of participants

        Returns:
            list of ids
        """
        return [i for i in range(len(self.dataset))
                if self.dataset.imgs[i][0].replace('\\', '/').split('/')[-2] in participants]

    def get_loader(self, participants, batch_size=1, shuffle=True):
        """
        Get loader with instances for the given list of participants.

        Args:
            participants: list of participants
            batch_size: batch size to create the loader
            shuffle: shuffle flag

        Returns:
            DataLoader object
        """
        return DataLoader(Subset(self.dataset, indices=self.get_ids(participants)), batch_size, shuffle=shuffle)

    def get_instances(self, participants):
        """
        Get paths to instances from the given participants.

        Args:
            participants: list of participants

        Returns:
            dictionary of {participants: list of paths}
        """
        instances = {}
        for participant in participants:
            p_dict = {}
            p_ids = self.get_ids(participant)
            for p_id in p_ids:
                img_path, target = self.dataset.imgs[p_id]
                if p_dict.get(target) is None:
                    p_dict[target] = []
                p_dict[target].append(img_path)
                instances[participant] = p_dict
        return instances


