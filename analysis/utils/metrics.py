import numpy as np
import torch
from sklearn.metrics import confusion_matrix, f1_score


def compute_confusion_matrices(model, dataset, participants, labels=None):
    """
    Computes confusion for a given list of participants on the given model.
    Args:
        model: model to compute confusion matrices
        dataset: DatasetHandler object to get the instances
        participants: list of participants as strings

    Returns:
        dictionary of {participant: confusion matrix}
    """
    cfs = {}
    model.eval()
    if torch.cuda.is_available():
        model = model.cuda()
    with torch.no_grad():
        for p in participants:
            y_true = []
            y_pred = []
            loader = dataset.get_loader([p])
            for imgs, labs in loader:
                if torch.cuda.is_available():
                    imgs = imgs.cuda()
                y_true.extend(labs.detach().cpu().numpy())
                _, preds = torch.max(model.forward(imgs), 1)
                y_pred.extend(preds.detach().cpu().numpy())
            cfs[p] = confusion_matrix(np.array(y_true).flatten(), np.array(y_pred).flatten(), labels=labels)
    return cfs


def compute_accuracy(model, loader):
    """
    Computes accuracy on a given model and data loader

    Args:
        model: model to compute accuracy
        loader: data loader to compute accuracy

    Returns:
        accuracy computed on the loader
    """
    model.eval()
    if torch.cuda.is_available():
        model = model.cuda()
    with torch.no_grad():
        test_accuracy = 0.0
        test_samples = 0
        for imgs, labs in loader:
            if torch.cuda.is_available():
                imgs = imgs.cuda()
            out = model.forward(imgs)
            _, preds = torch.max(out, 1)
            preds = preds.detach().cpu()
            test_accuracy += (preds == labs).sum().item()
            test_samples += labs.size(0)
    test_accuracy /= test_samples
    return test_accuracy


def compute_f1score(model, loader, labels=None, pos_label=1):
    """
    Computes f1 score on a given model and data loader

    Args:
        model: model to compute f1 score
        loader: data loader to compute f1 score

    Returns:
        f1 score computed on the loader
    """
    all_true_labels = []
    all_pred_labels = []
    model.eval()
    if torch.cuda.is_available():
        model = model.cuda()
    with torch.no_grad():
        for imgs, labs in loader:
            if torch.cuda.is_available():
                imgs = imgs.cuda()
            outputs = model(imgs)
            _, preds = torch.max(outputs, 1)
            all_true_labels.extend(labs.detach().cpu().numpy())
            all_pred_labels.extend(preds.detach().cpu().numpy())
    f1 = f1_score(all_true_labels, all_pred_labels, labels=labels, pos_label=pos_label)
    return f1
