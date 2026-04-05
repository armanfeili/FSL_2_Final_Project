# Data Directory

**This directory is for Google Drive storage only — not tracked in Git.**

All datasets, raw files, and processed data are stored in **Google Drive** at:
```
MyDrive/ml-colab-agentic/data/
```

---

## Structure (Created in Drive)

```
data/
├── raw/                    # Downloaded datasets (CIFAR-10, ImageNet, etc.)
│   └── cifar-10-batches-py/    # Example: CIFAR-10 dataset (~170 MB)
└── processed/              # Preprocessed or augmented datasets
    └── ...                 # Your custom processed data
```

---

## How It Works

### In Colab Notebook

**Section A1** sets up paths:
```python
DATA_DIR = "/content/drive/MyDrive/ml-colab-agentic/data"
```
