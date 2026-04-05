"""Utility functions for Colab-first training."""

from __future__ import annotations

import os
import random
import pathlib
import csv

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import DataLoader
from torchvision import datasets, transforms


def set_seed(seed: int = 42) -> None:
    """Set random seed across all libraries for reproducibility."""
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False


def get_device() -> torch.device:
    """Get CUDA device if available, else CPU."""
    return torch.device("cuda" if torch.cuda.is_available() else "cpu")


def prepare_dataloaders_cifar10(
    root: str, batch_size: int, num_workers: int = 2
) -> tuple[DataLoader, DataLoader]:
    """Prepare CIFAR-10 training and test dataloaders with augmentation."""
    tf_train = transforms.Compose([
        transforms.RandomHorizontalFlip(),
        transforms.RandomCrop(32, padding=4),
        transforms.ToTensor(),
    ])
    tf_test = transforms.ToTensor()

    train_ds = datasets.CIFAR10(
        root, train=True, download=True, transform=tf_train
    )
    test_ds = datasets.CIFAR10(
        root, train=False, download=True, transform=tf_test
    )

    train_dl = DataLoader(
        train_ds,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
        pin_memory=True,
    )
    test_dl = DataLoader(
        test_ds,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=True,
    )
    return train_dl, test_dl


class SimpleNet(nn.Module):
    """Simple CNN for CIFAR-10 classification."""

    def __init__(self, num_classes: int = 10):
        super().__init__()
        self.net = nn.Sequential(
            nn.Conv2d(3, 32, 3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2),
            nn.Conv2d(32, 64, 3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2),
            nn.Flatten(),
            nn.Linear(64 * 8 * 8, 128),
            nn.ReLU(),
            nn.Linear(128, num_classes),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.net(x)


def train_one_epoch(
    model: nn.Module,
    dl: DataLoader,
    opt: torch.optim.Optimizer,
    device: torch.device,
) -> tuple[float, float]:
    """Train one epoch, return (loss, accuracy)."""
    model.train()
    total, correct, loss_sum = 0, 0, 0.0

    for x, y in dl:
        x, y = x.to(device, non_blocking=True), y.to(device, non_blocking=True)
        logits = model(x)
        loss = F.cross_entropy(logits, y)
        opt.zero_grad()
        loss.backward()
        opt.step()

        loss_sum += float(loss) * x.size(0)
        pred = logits.argmax(1)
        correct += (pred == y).sum().item()
        total += x.size(0)

    return loss_sum / total, correct / total


@torch.no_grad()
def evaluate(model: nn.Module, dl: DataLoader, device: torch.device) -> tuple[float, float]:
    """Evaluate model, return (loss, accuracy)."""
    model.eval()
    total, correct, loss_sum = 0, 0, 0.0

    for x, y in dl:
        x, y = x.to(device, non_blocking=True), y.to(device, non_blocking=True)
        logits = model(x)
        loss = F.cross_entropy(logits, y)
        loss_sum += float(loss) * x.size(0)
        pred = logits.argmax(1)
        correct += (pred == y).sum().item()
        total += x.size(0)

    return loss_sum / total, correct / total


def save_checkpoint(model: nn.Module, path: str) -> None:
    """Save model checkpoint."""
    pathlib.Path(os.path.dirname(path)).mkdir(parents=True, exist_ok=True)
    torch.save(model.state_dict(), path)


def append_metrics_csv(
    path: str, rows: list[tuple[int, float, float, float, float]]
) -> None:
    """Append metrics to CSV. rows: (epoch, train_loss, train_acc, val_loss, val_acc)."""
    pathlib.Path(os.path.dirname(path)).mkdir(parents=True, exist_ok=True)
    is_new = not os.path.exists(path)

    with open(path, "a", newline="") as f:
        writer = csv.writer(f)
        if is_new:
            writer.writerow(["epoch", "train_loss", "train_acc", "val_loss", "val_acc"])
        for row in rows:
            writer.writerow(row)
