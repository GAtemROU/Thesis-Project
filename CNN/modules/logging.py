import os
from datetime import datetime


class MyLogger:
    """
    Class to log training

    When the object is created, the file with the current date and time is created in log_dir.
    All the statistic is saved to the log file and to the f1_history file.

    Attributes:
        log_dir: directory to save logs
        name: overwrites the default name of the log file by a given one
    """
    def __init__(self, log_dir, name=None):
        if name is None:
            self.name = datetime.now().strftime("log_%d.%m_%H%M")
        else:
            self.name = name
        self.log_dir = log_dir
        if not os.path.exists(log_dir):
            os.makedirs(log_dir)
        self.f1_list = []

    def log_epoch(self, epoch, loss, val_acc):
        """
        Logs epoch in the form of:
            Epoch [{epoch}], Loss: {loss}, Val acc: {val_acc}}

        Args:
            epoch: epoch to be saved
            loss: loss value to be saved
            val_acc: validation accuracy value to be saved

        Returns:
            None
        """
        with open(os.path.join(self.log_dir, self.name), "a") as f:
            f.write(f"Epoch [{epoch}], Loss: {loss:.4f}, Val acc: {val_acc:.2f}\n")

    def log_new_fold(self, fold, add_info=None):
        """
        Logs change of fold and any additional info if given in the form of :
            Fold {fold}
            {add_info}
            
        Args:
            fold: fold number
            add_info: any additional info, i.e. test participants for the fold

        Returns:
            None
        """
        with open(os.path.join(self.log_dir, self.name), "a") as f:
            f.write(f"Fold {fold}\n")
            if add_info is not None:
                f.write(f"{add_info}\n")

    def log_test_metrics(self, acc, f1, cfs):
        """
        Logs test metrics in the form of:


        Args:
            acc:
            f1:
            cfs:

        Returns:

        """
        self.f1_list.append(f1)
        with open(os.path.join(self.log_dir, self.name), "a") as f:
            f.write(f"Test accuracy: {acc:.4f}, F1 score: {f1:.4f}\n")
            f.write(f"Confusion matrices:\n{cfs}\n")

    def log_f1_history(self, file_name='f1_history', save_avg=True):
        with open(os.path.join(self.log_dir, file_name), "a") as f:
            f.write(self.f1_list.__str__() + '\n')
            if save_avg:
                f.write(f'AVG: {sum(self.f1_list) / len(self.f1_list)}\n')
