from torch.utils.data import Dataset
import torchvision.datasets as datasets


class CustomCIFAR10(Dataset):
    def __init__(self, root, train=True, transform=None, download=False):
        self.cifar10 = datasets.CIFAR10(root=root, train=train, download=download)
        self.transform = transform

    def __len__(self):
        return len(self.cifar10)

    def __getitem__(self, index):
        image, label = self.cifar10[index]
        if self.transform:
            image = self.transform(image)
        return image, label