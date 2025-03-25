from torchvision import transforms
import torch.nn as nn


class ResizeTransform(nn.Module):
    def __init__(self, width, height):
        super().__init__()
        self.width = width
        self.height = height
        self.transform = transforms.Compose([
                transforms.Resize((self.height, self.width)),
                transforms.ToTensor()
        ])

    def __call__(self, img):
        return self.transform(img)


class NoTransform(nn.Module):
    """Transform that returns the input unchanged"""
    def __call__(self, img):
        return transforms.ToTensor()(img)
