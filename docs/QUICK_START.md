# Quick Start Guide

**Train CIFAR-10 on Colab GPU in under 5 minutes.**

This guide walks you through running your first training session using the Drive-first architecture.

---

## Prerequisites

- Google account (for Colab and Drive)
- **No local setup required!**

---

## Step-by-Step

### 1. Open the Notebook in Colab

**Option A:** Click the badge in [README.md](../README.md)

**Option B:** Direct link:
```
https://colab.research.google.com/github/armanfeili/ml-colab-agentic/blob/main/notebooks/01_train.ipynb
```

### 2. Enable GPU Runtime

1. Top menu: **Runtime** → **Change runtime type**
2. **Hardware accelerator**: GPU
3. **GPU type**: T4 (free tier) or A100 (if available)
4. Click **Save**

### 3. Verify GPU Access

Run the first cell or check GPU info:
```python
!nvidia-smi
```

You should see output like:
```
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 525.x.xx    Driver Version: 525.x.xx    CUDA Version: 12.x      |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  Tesla T4            Off  | 00000000:00:04.0 Off |                    0 |
| N/A   45C    P0    28W /  70W |      0MiB / 15360MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
```

### 4. Run All Cells

Click **Runtime** → **Run all** or run cells sequentially:

#### **Section A — Setup (Drive + Repo)**

| Cell | Description | Duration |
|------|-------------|----------|
| A0 | Mount Google Drive | ~5 sec (requires authorization first time) |
| A1 | Set up Drive paths | <1 sec |
| A2 | Clone/pull repo from GitHub | ~10 sec |
| A3 | Install dependencies | ~30 sec |
| A4 | Import utilities | <1 sec |
| A4b | Set cache paths & deterministic mode | <1 sec |
| A5 | (Optional) GPU info | <1 sec |

**What happens:**
- Drive mounted at `/content/drive/MyDrive/`
- Repo cloned to `/content/ml-colab-agentic/`
- Packages installed: `torch`, `torchvision`, `pyyaml`, etc.
- Drive folder structure created: `data/`, `runs/`, `latest/`

#### **Section B — Run Config**

| Cell | Description | Duration |
|------|-------------|----------|
| B0 | Create timestamped run folder | <1 sec |
| B1 | Set up metrics logger | <1 sec |

**What happens:**
- Creates run folder: `runs/2025-10-31_14-20_cifar10_simplenet_amp/`
- Saves frozen config to `cfg.yaml`
- Sets up CSV logger for metrics

#### **Section C — Train**

| Cell | Description | Duration |
|------|-------------|----------|
| C0 | Set seed & device | <1 sec |
| C1 | Load CIFAR-10 dataset | ~1-2 min (first run only; downloads dataset) |
| C2 | Initialize model & optimizer | <1 sec |
| C3 | Training loop (5 epochs) | ~50 sec (T4) / ~20 sec (A100) |

**What happens:**
- Downloads CIFAR-10 to `data/raw/` (cached for future runs)
- Trains `SimpleNet` (3-layer CNN) on 50,000 train images
- Validates on 10,000 test images
- Saves checkpoints every epoch to `checkpoints/`
- Logs metrics to `metrics.csv`

**Sample output:**
```
Epoch 01/05 | Train: loss=1.5234 acc=0.4521 | Val: loss=1.3456 acc=0.5234
Epoch 02/05 | Train: loss=1.2345 acc=0.5678 | Val: loss=1.1234 acc=0.6012
Epoch 03/05 | Train: loss=1.0123 acc=0.6345 | Val: loss=0.9876 acc=0.6543
Epoch 04/05 | Train: loss=0.8765 acc=0.6890 | Val: loss=0.8765 acc=0.6890
Epoch 05/05 | Train: loss=0.7654 acc=0.7234 | Val: loss=0.8123 acc=0.7012

[DONE] Training complete! Best val acc: 0.7012
```

#### **Section D — Inspect**

| Cell | Description |
|------|-------------|
| D0 | Show run folder structure |
| D1 | Display metrics (table & pivot) |

**What you'll see:**
```
2025-10-31_14-20_cifar10_simplenet_amp/
  cfg.yaml (0.2 KB)
  metrics.csv (0.5 KB)
  checkpoints/
    best.pt (245.3 KB)
    epoch_001.pt (245.3 KB)
    ...
```

---

## Understanding the Output

### Folder Structure in Drive

After running, check `MyDrive/ml-colab-agentic/`:

```
ml-colab-agentic/
├── data/
│   └── raw/
│       └── cifar-10-batches-py/    # CIFAR-10 dataset (cached)
├── runs/
│   └── 2025-10-31_14-20_cifar10_simplenet_amp/
│       ├── cfg.yaml                # Frozen config
│       ├── metrics.csv             # Train/val metrics
│       ├── checkpoints/
│       │   ├── best.pt             # Best model (by val acc)
│       │   ├── epoch_001.pt
│       │   └── epoch_005.pt
│       ├── plots/                  # (empty for now)
│       ├── artifacts/              # (empty for now)
│       └── cache/                  # (empty for now)
└── latest/
    └── run/                        # Pointer to this run
```

### Metrics CSV

Open `metrics.csv` in Google Sheets or view in notebook (Section D1):

| split | epoch | metric | value |
|-------|-------|--------|-------|
| train | 1 | loss | 1.5234 |
| train | 1 | acc | 0.4521 |
| val | 1 | loss | 1.3456 |
| val | 1 | acc | 0.5234 |
| ... | ... | ... | ... |

---

## Next Steps

### 1. Modify the Config

In **Section B**, cell B0, edit the `CFG` dict:

```python
CFG = {
    "seed": 42,
    "epochs": 10,           # ← Train longer
    "batch_size": 64,       # ← Smaller batch if OOM
    "lr": 5e-4,             # ← Lower learning rate
    "dataset": "CIFAR10",
    "data_root": f"{DATA_DIR}/raw",
    "num_workers": 2,
    "amp": True,            # ← Mixed precision (faster)
}
```

Then re-run **Section B → C → D**.

### 2. Edit Code Locally

**Workflow:**
1. Clone repo locally:
   ```bash
   git clone https://github.com/armanfeili/ml-colab-agentic.git
   ```

2. Open in VS Code:
   ```bash
   cd ml-colab-agentic
   code .
   ```

3. Edit `src/utils.py` (e.g., change model architecture)

4. Commit and push:
   ```bash
   git add .
   git commit -m "feat: add dropout to SimpleNet"
   git push
   ```

5. In Colab, re-run **Section A2** (Clone/Update) to pull latest code

6. Re-run training with updated code

### 3. Add Custom Dataset

1. **Add loader in `src/utils.py`:**
   ```python
   def prepare_dataloaders_custom(root, batch_size, num_workers):
       # Load your dataset
       train_dataset = ...
       test_dataset = ...
       
       train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
       test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False)
       
       return train_loader, test_loader
   ```

2. **Update notebook (Section C1):**
   ```python
   train_dl, test_dl = prepare_dataloaders_custom(
       root=CFG["data_root"],
       batch_size=CFG["batch_size"],
       num_workers=CFG["num_workers"],
   )
   ```

3. **Update config:**
   ```python
   CFG = {
       "dataset": "CustomDataset",
       # ...
   }
   ```

---

## Customization Examples

### Train Faster (Mixed Precision)

Already enabled by default (`amp: True`). Speeds up training by ~2× on T4.

### Save Plots

Add after training loop (Section C3):

```python
import matplotlib.pyplot as plt

# Load metrics
df = pd.read_csv(METRICS_CSV)
train_loss = df[(df.split == "train") & (df.metric == "loss")]["value"]
val_loss = df[(df.split == "val") & (df.metric == "loss")]["value"]

# Plot
plt.plot(train_loss, label="Train")
plt.plot(val_loss, label="Val")
plt.xlabel("Epoch")
plt.ylabel("Loss")
plt.legend()
plt.savefig(f"{RUN_DIR}/plots/loss.png")
plt.show()
```

### Use Different Model

In `src/utils.py`, add new model:

```python
class ResNet18Custom(nn.Module):
    def __init__(self, num_classes=10):
        super().__init__()
        import torchvision.models as models
        self.model = models.resnet18(pretrained=False)
        self.model.fc = nn.Linear(512, num_classes)
    
    def forward(self, x):
        return self.model(x)
```

In notebook (Section C2):
```python
model = ResNet18Custom(num_classes=10).to(device)
```

---

## Troubleshooting

### GPU Not Available

**Error:**
```
Device: cpu | CUDA available: False
```

**Fix:**
1. Runtime → Change runtime type → GPU → Save
2. Re-run all cells

### Drive Mount Fails

**Error:**
```
MessageError: Error: credential propagation was unsuccessful
```

**Fix:**
1. Click the link in the cell output
2. Authorize access to Google Drive
3. Copy the code and paste back into Colab

### Out of Memory (OOM)

**Error:**
```
RuntimeError: CUDA out of memory. Tried to allocate X.XX GiB
```

**Fix:**
Reduce batch size in config:
```python
CFG = {
    "batch_size": 32,  # Was 128
    # ...
}
```

### CIFAR-10 Download Slow

**First run only** — downloads ~160 MB to Drive. Subsequent runs reuse cached data.

**Speed up:**
- Use faster internet connection
- Wait patiently (1-2 min typical)

### Module Not Found

**Error:**
```
ModuleNotFoundError: No module named 'yaml'
```

**Fix:**
Re-run **Section A3** (Install dependencies).

### Git Pull Fails

**Error:**
```
fatal: couldn't find remote ref main
```

**Fix:**
Check branch name in your repo (might be `master` instead of `main`):
```python
subprocess.run(["git", "-C", REPO_PATH, "checkout", "master"], check=True)
```

---

## Tips for Success

### Best Practices

- **First run:** Just run all cells to verify everything works
- **Iterate:** Modify config → re-run training → inspect results
- **Version control:** Edit code locally → commit → pull in Colab
- **Cache data:** Keep datasets in `data/raw/` — downloads only once

### Expected Timings (T4 GPU)

| Task | Duration |
|------|----------|
| Setup (Section A) | ~45 sec |
| Config (Section B) | <2 sec |
| Load CIFAR-10 (first time) | ~1-2 min |
| Load CIFAR-10 (cached) | ~10 sec |
| Train 1 epoch | ~10 sec |
| Train 5 epochs | ~50 sec |
| Inspect (Section D) | <1 sec |
| **Total (first run)** | ~3-4 min |
| **Total (subsequent runs)** | ~2 min |

---

## What's Next?

1. **Read the main [README](../README.md)** for architecture overview
2. **Explore `src/utils.py`** to understand training loop
3. **Modify the model** and experiment with hyperparameters
4. **Add your own dataset** following examples above
5. **Use GitHub Copilot** locally for AI-assisted development

---

**Questions?** See [README.md](../README.md) or open an issue on GitHub!
