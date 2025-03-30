import os
from os.path import join
import torch
import datetime
from copy import deepcopy


class Trainer:

    def __init__(self, model, save_path, loss, train_loader=None, eval_loader=None, optimizer=None, logger=None,
                 autosave=True, verbose=True):
        if torch.cuda.is_available():
            self.model = model.cuda()
        else:
            self.model = model
        self.train_loader = train_loader
        self.val_loader = eval_loader
        self.save_path = save_path
        self.loss = loss
        self.optimizer = optimizer
        self.logger = logger
        self.epoch = 0
        self.max_val_acc = 0.
        self.best_model_dict = None
        self.autosave = autosave
        self.verbose = verbose
        if not os.path.exists(self.save_path):
            os.makedirs(self.save_path)

    def run_epoch(self):
        self.model.train()
        epoch_loss = 0.
        for batch_input, batch_target in self.train_loader:
            if torch.cuda.is_available():
                batch_input = batch_input.cuda()
                batch_target = batch_target.cuda()
            self.optimizer.zero_grad()
            batch_out = self.model.forward(batch_input)
            loss = self.loss(batch_out, batch_target)
            epoch_loss += loss.item()
            loss.backward()
            self.optimizer.step()
        self.epoch += 1
        avg_loss = epoch_loss / len(self.train_loader)
        val_acc = self.evaluate()
        if self.verbose:
            print('{} --- Epoch [{}], Loss: {:.4f}, Val acc: {:.2f}'.format(
                datetime.datetime.now().strftime("%d.%m %H:%M:%S"), self.epoch, avg_loss, val_acc * 100))
        if self.logger is not None:
            self.logger.log_epoch(self.epoch, avg_loss, val_acc)

    def save_best_model(self):
        if self.best_model_dict is None and self.verbose:
            print("No best model found")
        else:
            if self.verbose:
                print("Saving best model to   {}".format(join(self.save_path, "best_model.pkl")))
            torch.save(self.best_model_dict, join(self.save_path, "best_model.pkl"))

    def save_cur_model(self):
        torch.save(self.model.state_dict(), join(self.save_path, "model_epoch_{}.pkl".format(self.epoch)))

    def print_best_validation_acc(self):
        print("Best validation accuracy: {:.4f}".format(self.max_val_acc * 100))

    @torch.no_grad()
    def evaluate(self):
        """Evaluates model on validation loader
        Saves current model to save_path with name of current epoch, if autosave is True"""
        self.model.eval()
        valid_accuracy = 0.0
        valid_samples = 0
        for batch_input, batch_target in self.val_loader:
            if torch.cuda.is_available():
                batch_input = batch_input.cuda()
                batch_target = batch_target.cuda()
            batch_out = self.model.forward(batch_input)
            _, predicted = torch.max(batch_out, 1)
            valid_accuracy += (predicted == batch_target).sum().item()
            valid_samples += batch_target.size(0)
        valid_accuracy /= valid_samples
        if valid_accuracy > self.max_val_acc:
            self.max_val_acc = valid_accuracy
            self.best_model_dict = deepcopy(self.model.state_dict())
            if self.epoch > 1 and self.autosave:
                self.save_cur_model()
        return valid_accuracy

    def set_train_loader(self, train_loader):
        self.train_loader = train_loader

    def set_val_loader(self, val_loader):
        self.val_loader = val_loader

    def load_best_model(self):
        self.model.load_state_dict(self.best_model_dict)

    def set_optimizer(self, optimizer):
        self.optimizer = optimizer

    def set_model(self, model):
        if torch.cuda.is_available():
            self.model = model.cuda()
        else:
            self.model = model

    def reset(self):
        self.epoch = 0
        self.max_val_acc = 0.
        self.best_model_dict = None

    def set_save_path(self, save_path):
        self.save_path = save_path
        if not os.path.exists(self.save_path):
            os.makedirs(self.save_path)
