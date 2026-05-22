# certnet-control-sim

## Overview

This repository provides the MATLAB implementation of our **certified executor / CertNet** framework for hard-constrained control with **deployable, predictable-latency execution**.

The key idea is to **decouple hard-feasibility guarantees from performance learning**: the certified executor enforces hard constraint satisfaction **structurally** at deployment time, while learning is used only to recover reference-policy performance **within a certified feasible family**. This yields **(i) feasibility by construction (R1)**, **(ii) competitive performance recovery (R2)**, and **(iii) low latency (R3)**.

This repository includes:
- a reusable toolbox **`cnet-tb-v1`** for certified library construction and CertNet execution
- reproducible experiments for three case studies: **mpQP benchmark**, **control allocation (CA)**, and **adaptive cruise control (ACC)**

Offline, the framework synthesizes certified feasible candidate libraries and trains the learning component; online, it executes a fixed-structure algebraic pipeline without iterative optimization.

---

## Repository Structure

```text
.
├─ cnet-tb-v1/                              # Core toolbox for certified executor / CertNet
│  ├─ cert/                                 # Certified feasible library construction and querying
│  │  ├─ @Cert/
│  │  │  ├─ Cert.m
│  │  │  ├─ api_build_.m
│  │  │  ├─ api_check_cover_cacheAct_.m
│  │  │  ├─ api_supplement_cacheAct_.m
│  │  │  └─ api_vertices_.m
│  │  ├─ cfg/
│  │  │  └─ set_cert_default_cfg_.m
│  │  └─ query_cache/                       # Cached query structures for fast online lookup
│  │     ├─ cache_append_.m
│  │     ├─ cache_init_.m
│  │     └─ query_.m
│  │
│  ├─ cert-net/                             # CertNet executor and training/inference APIs
│  │  ├─ @Certnet/
│  │  │  ├─ Certnet.m
│  │  │  ├─ api_build_.m
│  │  │  ├─ api_forward_.m
│  │  │  └─ api_train_.m
│  │  ├─ cfg/
│  │  │  └─ set_certnet_cfg_default_.m
│  │  ├─ InterFcn/                          # Interface/export helpers
│  │  │  └─ export_phi_params_.m
│  │  ├─ cvxOpt/                            # Convex/simplex/Carathéodory utilities
│  │  │  ├─ carath_reduce_.m
│  │  │  ├─ convex_rep_ok_.m
│  │  │  ├─ proj_simplex_.m
│  │  │  └─ simplex_ls_.m
│  │  └─ utilFcn/                           # General utility functions
│  │     ├─ getfield_def_.m
│  │     ├─ norm_x_.m
│  │     ├─ simplex_cus.m
│  │     ├─ softplus_.m
│  │     └─ struct_merge_.m
│
├─ Experiments/                             # Reproducible experiment scripts
│  ├─ sim_ACC/                              # Adaptive Cruise Control (ACC) case study
│  │  ├─ core/                              # ACC experiment functions (test/plot/report)
│  │  │  ├─ acc_plot_.m
│  │  │  ├─ acc_report_.m
│  │  │  └─ acc_test_closedloop_.m
│  │  └─ sim_ACC.mlx                        # Main ACC experiment script
│  │
│  ├─ sim_CA/                               # Control Allocation (CA) case study
│  │  ├─ core/                              # CA experiment functions (test/plot/report)
│  │  │  ├─ ca_plot_.m
│  │  │  ├─ ca_report_.m
│  │  │  └─ ca_test_sync_inject_.m
│  │  └─ sim_CA.mlx                         # Main CA experiment script
│  │
│  ├─ sim_mpQP/                             # mpQP benchmark experiments
│  │  ├─ core/                              # mpQP experiment functions (build/test/plot/report)
│  │  │  ├─ mpqp_build_baseline_.m
│  │  │  ├─ mpqp_gen_trainingData.m
│  │  │  ├─ mpqp_make_problem_.m
│  │  │  ├─ mpqp_plot_.m
│  │  │  ├─ mpqp_report_problem_.m
│  │  │  └─ mpqp_test_problem_.m
│  │  └─ sim_mpqp.mlx                       # Main mpQP experiment script
│  │
│  └─ tmpFcns/                              # Shared temporary/helper functions for experiments
│     ├─ build_pureNN_.m
│     ├─ net_to_alg_.m
│     └─ pure_nn_forward_alg_.m
│
├─ Figures/                                 # Exported paper-ready figures (PDF/EPS) and README previews (PNG)
│  ├─ sim_ACC.pdf
│  ├─ sim_ACC.eps
│  ├─ sim_ACC.png
│  ├─ sim_CA.pdf
│  ├─ sim_CA.eps
│  ├─ sim_CA.png
│  ├─ sim_mpQP.pdf
│  ├─ sim_mpQP.eps
│  └─ sim_mpQP.png
│
├─ ACC_vars_2026-02-20_101044.mat           # Saved ACC experiment variables/results
├─ CA_vars_2026-02-20_104948.mat            # Saved CA experiment variables/results
├─ MPQP_vars_2026-02-20_160236.mat          # Saved mpQP experiment results
├─ LICENSE
└─ README.md
```

> **Notes**
> - This repository provides the simple toolbox implementation **`cnet-tb-v1`**, which realizes the framework and experiment pipeline used in the paper.
> - The folders `cvxOpt/` and `utilFcn/` contain supporting convex-geometry and general mathematical utilities used by the implementation. These are foundational building blocks and can be replaced by alternative implementations.

---

## Quick Start for Reproducibility

1. Clone or download this repository and keep the folder structure unchanged.
2. Open MATLAB and set the current folder to the repository root.
3. Add the repository root and all subfolders to the MATLAB path.
4. Run the following live scripts to reproduce the reported results (figures, tables, and intermediate logs/process information):
   - `Experiments/sim_mpQP/sim_mpqp.mlx`
   - `Experiments/sim_CA/sim_CA.mlx`
   - `Experiments/sim_ACC/sim_ACC.mlx`

### Reproducing Figures/Reports from Saved Data (Optional)

To regenerate reported figures/tables without rerunning full simulations:
1. Load the corresponding saved `.mat` file in MATLAB (e.g., `MPQP_vars_*.mat`, `CA_vars_*.mat`, `ACC_vars_*.mat`).
2. Run the associated `report` and `plot` functions in the corresponding experiment `core/` folder.

> **Notes**
> - This repository includes saved simulation data used in the paper, containing the key parameters and baseline outputs needed for reproduction.
> - Full simulation runs save timestamped files automatically, so the paper snapshots are not overwritten.
> - Figures are exported in **PDF / EPS** (paper-ready) and **PNG** (GitHub README preview).

---

## Tested Environment

The code has been tested with the following environment:

- **OS:** Windows 11
- **CPU:** 11th Gen Intel(R) Core(TM) i7-11850H @ 2.50GHz
- **MATLAB:** R2025a (25.1.0.2943329)
- **Solvers/Libraries:** MOSEK 11.0.27; YALMIP 20250626; MPT3 3.2.1

MATLAB product dependencies are not enumerated here for brevity; missing products will be reported at runtime when executing the provided live scripts/models.

> **Note:** MOSEK requires a valid license.

---

## Features and Experimental Highlights

> **Preview note:** Figures are shown as **PNG** in this README for GitHub compatibility. Paper-ready **PDF/EPS** versions are included in `Figures/`.

The experiments evaluate CertNet across three representative settings:
- **mpQP** (controlled scaling benchmark)
- **Control Allocation (CA)** (deadline-aware closed-loop deployment)
- **Adaptive Cruise Control (ACC)** (CLF/CBF-style safety filtering)

Across all cases, the same deployment principle is tested: **feasibility is enforced structurally**, **learning recovers performance**, and the deployed executor runs through a **non-iterative fixed graph** with low latency.

---

## 1) mpQP Benchmark (Controlled Scaling; PWA Included if Available)

### What this benchmark shows

The mpQP suite provides a controlled comparison among:
- **QP (online solver)**
- **PWA (explicit solution, if available)**
- **PureNN**
- **NN+Proj**
- **CertNet (ours)**

Across both settings, **CertNet preserves hard feasibility (up to numerical tolerance) while significantly reducing runtime**, including tail latency.

### Headline results

- **Setting 1 (S1)**
  - **CertNet:** **125.6 / 114.1 / 333.5 μs** (mean / p50 / p99)
  - **Hard-feasibility violation rate:** **0.00%**
  - **Mean speedup vs QP:** **13.43×**
- **Setting 2 (S2)**
  - **CertNet:** **196.4 / 178.3 / 465.8 μs** (mean / p50 / p99)
  - **Hard-feasibility violation rate:** **0.00%**
  - **Mean speedup vs QP:** **8.76×**

### Offline deployability (mpQP)

- **PWA availability**
  - **S1:** available (**5899 / 1815** full/active regions)
  - **S2:** **unavailable** under the same offline compilation budget (timeout)
- **Certified library footprint**
  - **S1:** `n_LFull / n_LAct = 148 / 105`
  - **S2:** `n_LFull / n_LAct = 773 / 530`

### Included artifacts

- Runtime CDF / violation CDF / timing summary / runtime-error trade-off figure
- Reported paper metrics (timing / feasibility / fidelity; see paper for full table)
- Offline deployability scale summary (PWA availability + library sizes)

<p align="center">
  <img src="Figures/sim_mpQP.png" width="900" alt="mpQP diagnostics: runtime CDF, violation CDF, timing summary, and runtime-error trade-off"><br>
  <b>mpQP diagnostics (S1/S2): runtime CDF, violation CDF, timing summary, and runtime-error trade-off</b>
</p>

---

## 2) Control Allocation (CA) - Deadline-Aware Closed-Loop Deployment

### What this benchmark shows

The CA benchmark evaluates deployment semantics, not just timing numbers.

A fixed sampling deadline is enforced:
- if a method finishes within the budget, its command is applied
- otherwise, the controller executes a **hold action** (no update)

This makes runtime tails directly affect closed-loop behavior.

### Headline results (CA, `Ts = 1000 μs`)

- **CertNet**
  - **217.2 / 189.4 / 680.8 μs** (mean / p50 / p99)
  - **Timeout rate:** **0.00%**
  - **Hard-feasibility violation rate:** **0.00%**
- **NN+Proj**
  - **1271.2 / 1099.4 / 3590.1 μs**
  - **Timeout rate:** **56.60%**
- **Opt (online solver)**
  - **1521.9 / 1326.3 / 4142.6 μs**
  - **Timeout rate:** **100.00%** under the same deadline semantics
- **PureNN**
  - very fast, but **14.80%** hard-feasibility violation rate

### Included artifacts

- Closed-loop trajectory figure under hold-on-timeout execution
- Reported paper metrics (timing / timeout / feasibility / tracking metric; see paper for full table)
- Optional "ideal Opt" (timing-ignored oracle) reference trajectory

<p align="center">
  <img src="Figures/sim_CA.png" width="720" alt="CA closed-loop trajectories under hold-on-timeout semantics"><br>
  <b>Control Allocation (CA): closed-loop trajectories under deadline (hold-on-timeout) execution</b>
</p>

---

## 3) Adaptive Cruise Control (ACC) - CLF/CBF-Style Safety Filtering

### What this benchmark shows

The ACC benchmark evaluates a safety-critical CLF/CBF-style setup with hard constraints including:
- input bounds
- safety constraints
- one-step state bounds

Runtime is measured on representative deploy-time inputs but **not injected into the state update** (timing-only protocol), so the comparison isolates controller quality from platform-specific delay/jitter assumptions.

### Headline results (ACC, `Ts = 20 ms`)

- **CertNet**
  - **81.2 / 72.1 / 168.2 μs** (mean / p50 / p99)
  - **Hard-feasibility violation rate:** **0.00%**
  - Mean performance matches feasible baselines (≈ **1.65e1**)
- **Opt (online solver):** **897.3 / 859.1 / 1425.4 μs**
- **NN+Proj:** **800.6 / 812.7 / 1449.4 μs**
- **PureNN:** fast, but **66.27%** hard-feasibility violation rate

### Included artifacts

- Closed-loop trajectory figure (speed / acceleration / safety margin)
- Reported paper metrics (timing / feasibility / performance; see paper for full table)
- Timing statistics on representative closed-loop inputs

<p align="center">
  <img src="Figures/sim_ACC.png" width="720" alt="ACC closed-loop trajectories and safety margin"><br>
  <b>Adaptive Cruise Control (ACC): closed-loop speed, acceleration, and safety margin under timing-only evaluation</b>
</p>

---

## 4) At-a-Glance Summary (CA + ACC)

| Benchmark | Method | mean / p99 runtime (μs) | Feasibility | Deploy-time note |
|---|---|---:|---|---|
|  | Opt | 1521.9 / 4142.6 | 0.00% violation | 100.00% timeout (deadline semantics) |
| CA | NN+Proj | 1271.2 / 3590.1 | 0.00% violation | 56.60% timeout |
|  | **CertNet** | **217.2 / 680.8** | **0.00% violation** | **0.00% timeout** |
|  | Opt | 897.3 / 1425.4 | 0.00% violation | timing-only evaluation |
| ACC | NN+Proj | 800.6 / 1449.4 | 0.00% violation | timing-only evaluation |
|  | **CertNet** | **81.2 / 168.2** | **0.00% violation** | timing-only evaluation |

> **Takeaway:** Across both closed-loop benchmarks, **CertNet** provides the strongest overall deployment profile: **feasibility by construction + competitive control performance + much lower runtime (including tail latency)**.
> 
---

## Notes on Reported Timing Metrics

- Timings are reported after warm-up (steady-state execution)
- We report **mean / p50 / p99** to capture both central tendency and tail behavior
- **p99** is emphasized as the main tail metric (more stable than sample max under platform/timer jitter)

---

## Citation

If you use this repository in your research, please cite the corresponding paper (citation entry to be added upon publication).

---

## License

This project is released under the license included in this repository (see `LICENSE`).

---

## Contact

For questions or issues, please open a GitHub issue or contact the authors.
