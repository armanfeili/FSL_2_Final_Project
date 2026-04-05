# ML Colab Agentic Template

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/armanfeili/ml-colab-agentic/blob/main/notebooks/01_train.ipynb)

**This is a minimal template to combine the power of GitHub Copilot in VS Code with GPU training in Google Colab.**

- **Code on GitHub** — version control with Copilot support
- **Storage on Google Drive** — datasets, runs, checkpoints persist across sessions
- **Run in Colab** — free T4/A100 GPUs, no local setup required
- **Reproducible** — frozen configs, deterministic seeds, structured outputs

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  LOCAL (VS Code + Copilot)                                      │
│  ├─ Edit src/utils.py, notebooks/                              │
│  ├─ Commit & push to GitHub                                    │
│  └─ No data/runs stored here                                   │
└─────────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  COLAB VM (/content/)                                           │
│  ├─ Clone repo from GitHub (code only)                         │
│  ├─ Mount Google Drive at /content/drive                       │
│  └─ Run training → outputs to Drive                            │
└─────────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  GOOGLE DRIVE (MyDrive/ml-colab-agentic/)                      │
│  ├─ data/raw/                  ← datasets cached here          │
│  ├─ data/processed/             ← preprocessed data            │
│  ├─ runs/<timestamp_dataset_model>/  ← per-run outputs         │
│  │   ├─ cfg.yaml               ← frozen config                 │
│  │   ├─ metrics.csv            ← epoch-wise metrics            │
│  │   ├─ checkpoints/           ← model weights (.pt files)     │
│  │   ├─ plots/                 ← learning curves, etc.         │
│  │   └─ artifacts/             ← confusion matrices, etc.      │
│  └─ latest/run/                ← pointer to most recent run    │
└─────────────────────────────────────────────────────────────────┘
```

**Key Principle:** Code travels through Git. Data stays in Drive.

---

## Quick Start (3 steps)

### 1. Open in Colab
Click the badge above or go to:
```
https://colab.research.google.com/github/armanfeili/ml-colab-agentic/blob/main/notebooks/01_train.ipynb
```

### 2. Enable GPU
- **Runtime** → **Change runtime type** → **GPU** (T4 or A100) → **Save**

### 3. Run All Cells
- **Section A**: Mounts Drive, clones repo, installs dependencies
- **Section B**: Creates timestamped run folder, freezes config
- **Section C**: Trains model (5 epochs × ~10 sec = ~1 min)
- **Section D**: Shows metrics and artifacts

**First run downloads CIFAR-10** (~160 MB) to Drive — subsequent runs reuse it.

---

## Repository Structure (Code Only)

```
ml-colab-agentic/
├── notebooks/
│   └── 01_train.ipynb       # Colab entry point (run this!)
├── src/
│   ├── __init__.py
│   └── utils.py             # Training loop, model, dataloaders
├── tests/
│   └── test_smoke.py        # Basic smoke tests
├── docs/
│   └── QUICK_START.md       # Detailed setup guide
├── requirements.txt         # Dependencies (torch, pyyaml, etc.)
├── LICENSE
└── README.md                # This file
```

**Not in repo:** `data/`, `runs/`, `outputs/`, `checkpoints/`, `*.pt` (all in Drive or `.gitignore`)

---

## Google Drive Structure (Storage Only)

Created automatically on first run:

```
MyDrive/ml-colab-agentic/
├── data/
│   ├── raw/                          # Downloaded datasets (e.g., CIFAR-10)
│   └── processed/                    # Preprocessed datasets
├── runs/
│   ├── 2025-10-31_14-20_cifar10_simplenet_amp/
│   │   ├── cfg.yaml                  # Frozen config for this run
│   │   ├── metrics.csv               # Train/val loss & accuracy per epoch
│   │   ├── checkpoints/
│   │   │   ├── best.pt               # Best model (by val accuracy)
│   │   │   ├── epoch_001.pt
│   │   │   └── epoch_005.pt
│   │   ├── plots/                    # Learning curves, etc.
│   │   ├── artifacts/                # Test predictions, confusion matrices
│   │   └── cache/                    # Temporary files
│   └── 2025-11-01_09-15_cifar10_simplenet_amp/  # Next run
└── latest/
    └── run/                          # Pointer to most recent run
```

---

## How It Works

### A. Setup (Notebook Section A)
1. **Mount Drive** → `/content/drive/MyDrive/ml-colab-agentic/`
2. **Clone/pull repo** → `/content/ml-colab-agentic/` (fresh code from GitHub)
3. **Install dependencies** → `pip install -r requirements.txt`
4. **Import utilities** → `from src.utils import ...`

### B. Run Config (Section B)
```python
CFG = {
    "seed": 42,
    "epochs": 5,
    "batch_size": 128,
    "lr": 1e-3,
    "dataset": "CIFAR10",
    "data_root": f"{DATA_DIR}/raw",  # Points to Drive
    "num_workers": 2,
    "amp": True,
}
```
- Creates timestamped folder: `runs/2025-10-31_14-20_cifar10_simplenet_amp/`
- Saves `cfg.yaml` to Drive for reproducibility

### C. Train (Section C)
- Loads CIFAR-10 from `data_root` (downloads if missing)
- Trains `SimpleNet` (3-layer CNN) for 5 epochs
- Saves checkpoints to `runs/<run_id>/checkpoints/`
- Logs metrics to `runs/<run_id>/metrics.csv`

### D. Inspect (Section D)
- Shows metrics as pandas DataFrame
- Lists all artifacts in Drive folder

---

## Customization

### Change Dataset
1. Edit `CFG["dataset"]` in notebook
2. Add loader in `src/utils.py`:
```python
def prepare_dataloaders_imagenet(root, batch_size, num_workers):
    # Your custom dataset logic
    return train_loader, test_loader
```

### Train Longer
```python
CFG = {
    "epochs": 20,
    "batch_size": 64,  # Reduce if OOM
}
```

### Use Your Own Model
In `src/utils.py`, replace `SimpleNet` or add new class:
```python
class MyModel(nn.Module):
    def __init__(self, num_classes=10):
        super().__init__()
        # Your architecture
```

Then in notebook:
```python
model = MyModel(num_classes=10).to(device)
```

---

## Local Development (Optional)

### 1. Clone Repo
```bash
git clone https://github.com/armanfeili/ml-colab-agentic.git
cd ml-colab-agentic
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Edit Code Locally
- Use **VS Code** with **GitHub Copilot** for AI-assisted development
- Modify `src/utils.py`, add features to notebook
- Commit changes:
```bash
git add .
git commit -m "feat: add custom dataset loader"
git push
```

### 4. Pull in Colab
Next Colab run (Section A2) automatically pulls latest code from GitHub.

---

## Tips & Best Practices

### Best Practices
- **Edit code locally** (VS Code + Copilot) → commit → pull in Colab
- **Store all data/runs in Drive** → survives Colab session resets
- **Use timestamped run folders** → never overwrite previous experiments
- **Check GPU allocation** → Runtime → Change runtime type → GPU (T4 or A100)

### Common Pitfalls to Avoid
- **Don't commit large files** (`.pt`, datasets) → they're `.gitignore`d
- **Don't edit code in Colab UI** → changes won't sync to GitHub
- **Don't rely on Colab VM storage** → it's ephemeral (deleted after 12h idle)

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `CUDA not available` | Runtime → Change runtime type → GPU (T4) |
| `Drive mount fails` | Re-run cell A0, authenticate in popup |
| `OOM error` | Reduce `batch_size` (try 64 or 32) |
| `Git pull fails` | Check repo URL in A2, ensure `main` branch exists |
| `Module not found` | Re-run A3 (`pip install -r requirements.txt`) |
| `CIFAR-10 download slow` | First run only; cached in `data/raw/` for future runs |

---

## What's Different About This Template?

1. **Drive-first storage** — no repo clutter with datasets/checkpoints
2. **Code-only Git** — clean version control (12 files tracked vs. typical 100+)
3. **Reproducible runs** — timestamped folders + frozen YAML configs
4. **Copilot-ready** — develop locally, run remotely with ease
5. **Zero local setup** — works entirely in browser (Colab)

---

## Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/amazing-feature`
3. Commit changes: `git commit -m "feat: add amazing feature"`
4. Push to branch: `git push origin feat/amazing-feature`
5. Open a Pull Request

---

## Creator

Created by **[Arman Feili](https://github.com/armanfeili)** — Full-Stack Developer, Data Scientist

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## See Also

- [docs/QUICK_START.md](docs/QUICK_START.md) — Detailed walkthrough
- [notebooks/01_train.ipynb](notebooks/01_train.ipynb) — Main training notebook
- [src/utils.py](src/utils.py) — Core training utilities
