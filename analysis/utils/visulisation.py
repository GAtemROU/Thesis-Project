import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns


def plot_confusion_matrices(confusion_matrices):
    """
    Visualize confusion matrices and their sum.

    Args:
        confusion_matrices: Dictionary of confusion matrices for each participant.

    Returns:
        None
    """

    # Calculate the number of rows needed for visualization
    num_participants = len(confusion_matrices)
    num_rows = (num_participants + 3) // 4  # Ceiling division to ensure enough rows

    # Create subplots for each participant's confusion matrix
    fig, axes = plt.subplots(num_rows, 4, figsize=(16, 4 * num_rows))
    fig.subplots_adjust(hspace=0.5)

    # Iterate over each participant and visualize the confusion matrix
    for idx, (participant, matrix) in enumerate(confusion_matrices.items()):
        row_idx, col_idx = divmod(idx, 4)
        ax = axes[row_idx, col_idx] if num_rows > 1 else axes[col_idx]

        sns.heatmap(matrix, annot=True, fmt="d", cmap="Blues", cbar=False, ax=ax)
        ax.set_title(f"Participant {participant}")
        ax.set_xlabel("Predicted Label")
        ax.set_ylabel("True Label")

    # Remove empty subplots
    for idx in range(num_participants, num_rows * 4):
        row_idx, col_idx = divmod(idx, 4)
        fig.delaxes(axes[row_idx, col_idx] if num_rows > 1 else axes[col_idx])

    # Calculate and visualize the sum of all confusion matrices
    sum_matrix = np.sum(list(confusion_matrices.values()), axis=0)

    plt.figure(figsize=(8, 6))
    sns.heatmap(sum_matrix, annot=True, fmt="d", cmap="Blues", cbar=False)
    plt.title("Sum of Confusion Matrices")
    plt.xlabel("Predicted Label")
    plt.ylabel("True Label")
    plt.show()


def plot_history(history_dict, metric):
    """
    Plots history of a given metric on different folds.

    Args:
        history_dict: dictionary of {fold: history list}
        metric: name of the metric

    Returns:
        None
    """
    plt.figure(figsize=(10, 6))
    for fold, loss_history in history_dict.items():
        plt.plot(loss_history, label=f'Fold {fold}')

    plt.xlabel('Epoch')
    plt.ylabel(metric)
    plt.legend()
    plt.grid(True, color='lightgray', linestyle='--', linewidth=0.5)
    plt.show()
