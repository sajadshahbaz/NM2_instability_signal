#!/usr/bin/env python3
"""
Reconstruction of the historical NM2 bootstrap architecture.

Recovered from archived NM2 output fingerprints:
- resample treatment and control biological samples separately, with replacement
- preserve the original sample count in each group
- recompute treatment-control mean VST effect for each gene
- repeat B times (historical configuration B=500, seed=1)
- summarize bootstrap effects by SD, MAD, sign-flip rate, and near-zero rate

IMPORTANT:
This reconstructs the historical bootstrap architecture. It does not redefine
the final manuscript D+P instability score.
"""
import numpy as np
import pandas as pd
from scipy.stats import median_abs_deviation

VST = "vst_counts_filtered.tsv"
B = 500
SEED = 1

v = pd.read_csv(VST, sep="\t", index_col=0)

groups = {
    "UV_overall": {
        "treatment": [f"SRR120449{i}" for i in list(range(28,46))+list(range(49,73))],
        "control": [f"SRR120449{i}" for i in [25,26,27,46,47,48]],
    },
    "UV_short": {
        "treatment": [f"SRR120449{i}" for i in range(49,73)],
        "control": [f"SRR120449{i}" for i in [46,47,48]],
    },
    "UV_long": {
        "treatment": [f"SRR120449{i}" for i in range(28,46)],
        "control": [f"SRR120449{i}" for i in [25,26,27]],
    },
    "DES_overall": {
        "treatment": ["SRR5218269","SRR5218270","SRR5218271",
                      "SRR5218275","SRR5218276","SRR5218277"],
        "control": ["SRR5218272","SRR5218273","SRR5218274",
                    "SRR5218278","SRR5218279","SRR5218280"],
    },
    "DES_fast": {
        "treatment": ["SRR5218269","SRR5218270","SRR5218271"],
        "control": ["SRR5218272","SRR5218273","SRR5218274"],
    },
    "DES_slow": {
        "treatment": ["SRR5218275","SRR5218276","SRR5218277"],
        "control": ["SRR5218278","SRR5218279","SRR5218280"],
    },
}

def bootstrap_effects(treatment, control, B=B, seed=SEED):
    xt = v[treatment].to_numpy()
    xc = v[control].to_numpy()
    rng = np.random.RandomState(seed)
    it = rng.randint(0, len(treatment), size=(B, len(treatment)))
    ic = rng.randint(0, len(control), size=(B, len(control)))
    boot = xt[:, it].mean(axis=2) - xc[:, ic].mean(axis=2)
    full = xt.mean(axis=1) - xc.mean(axis=1)
    return pd.DataFrame({
        "gene": v.index,
        "effect_full": full,
        "inst_sd": boot.std(axis=1, ddof=1),
        "inst_mad": median_abs_deviation(boot, axis=1, scale="normal"),
        "flip_rate": (np.sign(boot) != np.sign(full[:, None])).mean(axis=1),
    })

for name, g in groups.items():
    out = bootstrap_effects(g["treatment"], g["control"])
    out.to_csv(f"reconstructed_{name}_bootstrap_B{B}.tsv", sep="\t", index=False)
    print(name, "median MAD =", out["inst_mad"].median(),
          "p90 MAD =", out["inst_mad"].quantile(.90))
