import torch.nn as nn


class BasicModel(nn.Module):
    """
    Basic CNN.
    """
    def __init__(self, in_size, out_size):
        """

        Args:
            in_size: input size of the image
            out_size: number of classes to output
        """
        super().__init__()
        self.batchnorm0 = nn.BatchNorm2d(3, affine=False)
        self.conv1 = nn.Conv2d(3, in_size, 3, 1)
        self.batchnorm1 = nn.BatchNorm2d(in_size, affine=False)
        self.conv2 = nn.Conv2d(in_size, in_size*2, 5, 2)
        self.batchnorm2 = nn.BatchNorm2d(in_size*2, affine=False)
        self.maxpool = nn.MaxPool2d(kernel_size=(2, 2), stride=(2, 2))
        self.relu = nn.ReLU()
        self.fc = nn.Linear(in_size * 15 * 15 * 2, out_size)
        self.flat = nn.Flatten()
        self.dropout = nn.Dropout(0.4)

    def forward(self, X):
        X = self.batchnorm0(X)

        X = self.conv1(X)
        X = self.relu(X)
        X = self.maxpool(X)
        X = self.batchnorm1(X)
        X = self.dropout(X)


        X = self.conv2(X)
        X = self.relu(X)
        X = self.maxpool(X)
        X = self.batchnorm2(X)
        X = self.dropout(X)


        X = self.flat(X)
        X = self.fc(X)
        return X
