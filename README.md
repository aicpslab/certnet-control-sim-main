# CertNet Control Simulation Release

This repository provides a MATLAB evaluation package for the accompanying manuscript:

**Provably Constraint-Satisfying Low-Latency Control via Structural Decoupling of Feasibility and Performance**

The manuscript is currently under review. This repository is provided to support reproducibility of the reported experiments.

## Key Message

CertNet is designed for hard-constrained real-time control problems where **feasibility**, **performance**, and **online latency** must be considered together.

The experiments compare CertNet with representative controller types:

- **Online optimization (QP/Opt):** reliable and high-quality, but slower and sensitive to runtime tails.
- **Explicit PWA control:** fast when available, but can require a large objective-induced partition and may become impractical to compile.
- **PureNN:** very fast, but does not enforce hard constraints.
- **NN+Proj:** restores feasibility through projection, but reintroduces online correction cost and tail latency.
- **CertNet:** preserves hard feasibility through a certified executor while keeping online evaluation non-iterative and low-latency.

Across the released benchmarks, CertNet achieves **zero observed hard-constraint violation rate above the numerical tolerance**, competitive tracking or teacher-matching performance, and substantial speedups over online optimization.

---

## Main Results at a Glance

| Benchmark | CertNet mean runtime | CertNet p99 runtime | Speedup vs. optimization | Hard-feasibility violation rate | Main observation |
|---|---:|---:|---:|---:|---|
| mpQP S1 | 33.02 us | 66.20 us | 36.01x vs QP | 0.00% | Feasible and faster than QP/PWA in this implementation |
| mpQP S2 | 46.41 us | 85.20 us | 26.89x vs QP | 0.00% | PWA compilation times out; CertNet remains deployable |
| CA | 63.3 us | 185.8 us | 15.89x vs Opt | 0.00% | Zero deadline misses under `T_s = 1000 us` |
| ACC | 24.7 us | 56.3 us | 32.60x vs Opt | 0.00% | Safe rollout with Opt-like behavior |

---

## Repository Contents

```text
.
├─ Cert/
│  ├─ @Cert/
│  │  └─ Cert.m
│  └─ api/
│     ├─ api_build_mex_.m
│     └─ api_cover_/
│        ├─ cover_build_model_.m
│        ├─ cover_filter_rows_.m
│        ├─ cover_reduce_active_by_data_.m
│        ├─ cover_select_add_law_.m
│        └─ cover_solve_mip_.m
│
├─ cert_policy_mex.mexw64
├─ nn_policy_mex.mexw64
├─ pwa_policy_mex.mexw64
│
├─ demo_Regions_release_pack.mat
├─ demo_mpqp_release_pack.mat
├─ demo_CA_release_pack.mat
├─ demo_ACC_release_pack.mat
│
├─ demo_regions_.mlx
├─ demo_mpqp_.mlx
├─ demo_ca_.mlx
├─ demo_acc_.mlx
│
├─ sim_region_compare.pdf
├─ sim_region_compare.png
├─ sim_mpQP.pdf
├─ sim_mpQP.png
├─ sim_CA.pdf
├─ sim_CA.png
├─ sim_ACC.pdf
├─ sim_ACC.png
│
├─ LICENSE
└─ README.md
```

---

## Release Organization

This repository is organized as a reproducible evaluation release.

The `.mat` release packs contain the generated artifacts required by the demo scripts, including certified executor data, trained controllers, baseline objects, and evaluation data. The MATLAB live scripts load these release packs and reproduce the reported testing protocols, figures, timing summaries, feasibility checks, and closed-loop evaluation results.

The intended workflow is simple:

1. load the released experiment pack;
2. run the corresponding MATLAB live script;
3. reproduce the reported metrics and figures;
4. inspect the deployed CertNet and baseline behavior.

---

## Quick Start

1. Clone or download this repository.
2. Open MATLAB.
3. Set the current MATLAB folder to the repository root.
4. Add the repository to the MATLAB path:

```matlab
addpath(genpath(pwd));
```

5. Open and run the live scripts:

```matlab
open("demo_regions_.mlx")
open("demo_mpqp_.mlx")
open("demo_ca_.mlx")
open("demo_acc_.mlx")
```

Each script loads its corresponding release pack:

| Script | Release pack | Purpose |
|---|---|---|
| `demo_regions_.mlx` | `demo_Regions_release_pack.mat` | PWA partition vs. certified active validity-region cover |
| `demo_mpqp_.mlx` | `demo_mpqp_release_pack.mat` | Unbounded mpQP benchmark evaluation |
| `demo_ca_.mlx` | `demo_CA_release_pack.mat` | Control allocation closed-loop evaluation |
| `demo_acc_.mlx` | `demo_ACC_release_pack.mat` | Adaptive cruise control safety-filter evaluation |

---

## Tested Environment

The release was prepared and tested in a Windows MATLAB environment.

- **OS:** Windows 11
- **MATLAB:** R2025a
- **Solvers/Libraries used in the experiments:** MOSEK, YALMIP, MPT3
- **Compiled evaluators:** Windows 64-bit MEX files (`*.mexw64`)

The included MEX files are Windows 64-bit binaries. On non-Windows platforms, these binaries require recompilation or a MATLAB fallback implementation.

MOSEK requires a valid license if the scripts call solver-dependent baseline or projection routines.

---

## Figures

The repository includes paper-ready PDF figures and PNG previews for GitHub visualization.

| PDF figure | PNG preview | Description |
|---|---|---|
| [`sim_region_compare.pdf`](sim_region_compare.pdf) | [`sim_region_compare.png`](sim_region_compare.png) | PWA critical-region partition vs. certified active validity-region cover |
| [`sim_mpQP.pdf`](sim_mpQP.pdf) | [`sim_mpQP.png`](sim_mpQP.png) | mpQP benchmark timing and hard-feasibility diagnostics |
| [`sim_CA.pdf`](sim_CA.pdf) | [`sim_CA.png`](sim_CA.png) | Control allocation closed-loop trajectories under deadline-limited execution |
| [`sim_ACC.pdf`](sim_ACC.pdf) | [`sim_ACC.png`](sim_ACC.png) | ACC closed-loop speed, input, and safety-margin trajectories |

The PNG files are displayed once in the corresponding experiment sections below. The PDF files are retained as high-quality paper-ready versions.

---

## Method-Level Interpretation

CertNet separates two roles that are usually entangled in hard-constrained controllers:

- **Feasibility protection:** handled by the certified executor and the precomputed feasible family.
- **Performance recovery:** handled by learning inside that feasible family.

This design is different from directly learning the control action and then repairing it afterward. As a result, learning errors may affect performance quality, but the hard-feasibility protection is inherited from the certified executor structure.

The experiments below are organized to show this distinction across different settings: mpQP benchmarks, deadline-aware control allocation, and ACC safety filtering.

---

## 1. PWA Partition vs. Feasibility-Certified Active Cover

This demo illustrates why CertNet does not need to reconstruct the full explicit optimizer partition.

For a strictly convex mpQP, an explicit PWA solution partitions the parameter space according to both the hard constraints and the objective-dependent KKT optimality conditions. CertNet instead focuses on the hard-constraint-induced feasible structure and uses learning to recover performance within the certified family.

The figure compares these two representations on a two-dimensional unbounded hard-constrained example, shown on a bounded plotting window. The left panel shows the explicit mpQP critical-region partition. The right panel shows the certified active validity-region cover generated by the active library, where color indicates the number of queried active candidates.

<p align="center">
  <img src="sim_region_compare.png" width="600" alt="PWA partition vs. certified active validity-region cover"><br>
  <b>PWA partition vs. certified active validity-region cover.</b>
</p>

PDF version: [`sim_region_compare.pdf`](sim_region_compare.pdf)

In this example:

- the explicit mpQP solution contains **52** critical regions;
- **38** of these regions intersect the bounded plotting window;
- CertNet compiles **71** Full-library feasibility candidates;
- CertNet deploys **23** active candidates.

This comparison highlights the intended structural advantage: explicit mpQP represents the objective-induced optimizer partition, whereas CertNet deploys a feasibility-certified active cover and learns the performance-dependent selection inside that cover.

Run:

```matlab
open("demo_regions_.mlx")
```

---

## 2. Unbounded mpQP Benchmarks

The mpQP benchmark evaluates the latency-feasibility-performance trade-off on two unbounded hard-constrained instances.

Compared methods:

- **QP:** online optimization teacher;
- **PWA:** explicit solution when available;
- **PureNN:** unconstrained neural policy;
- **NN+Proj:** neural policy followed by projection when needed;
- **CertNet:** certified executor with learned selection.

The figure summarizes runtime and hard-feasibility behavior. The timing panels show mean, median, and p99 runtime. The violation-CDF panels show the hard-constraint residual distribution relative to the numerical feasibility tolerance.

<p align="center">
  <img src="sim_mpQP.png" width="560" alt="mpQP benchmark timing and hard-feasibility diagnostics"><br>
  <b>mpQP benchmark timing and hard-feasibility diagnostics.</b>
</p>

PDF version: [`sim_mpQP.pdf`](sim_mpQP.pdf)

Run:

```matlab
open("demo_mpqp_.mlx")
```

### mpQP Results

| Setting | Method | Mean runtime | p99 runtime | Speedup | Violation rate | Mean `u`-MSE |
|---|---:|---:|---:|---:|---:|---:|
| S1 | QP | 1188.92 us | 1626.65 us | 1.00x | 0.00% | --- |
| S1 | PWA | 477.95 us | 612.65 us | 2.49x | 0.00% | 7.81e-11 |
| S1 | PureNN | 8.59 us | 16.00 us | 138.39x | 30.78% | 2.94e-2 |
| S1 | NN+Proj | 295.27 us | 1218.35 us | 4.03x | 0.00% | 2.82e-2 |
| S1 | **CertNet** | **33.02 us** | **66.20 us** | **36.01x** | **0.00%** | **2.50e-2** |
| S2 | QP | 1247.93 us | 1612.85 us | 1.00x | 0.00% | --- |
| S2 | PureNN | 9.87 us | 17.15 us | 126.46x | 50.82% | 4.16e-2 |
| S2 | NN+Proj | 477.67 us | 1165.95 us | 2.61x | 0.00% | 3.90e-2 |
| S2 | **CertNet** | **46.41 us** | **85.20 us** | **26.89x** | **0.00%** | **3.34e-2** |

For NN+Proj, the projection-use rates are **30.84%** in S1 and **50.96%** in S2. This explains the increased mean and tail runtime compared with the raw neural predictor.

### mpQP Offline Representation

| Setting | Dimensions `(n_u,n_xi,n_eta)` | Hard/soft inequalities `(m_H,m_S)` | PWA regions | Active/Full library |
|---|---:|---:|---:|---:|
| S1 | `(3,2,1)` | `(18,30)` | 12091 | 75 / 236 |
| S2 | `(3,6,2)` | `(33,40)` | timeout | 436 / 1935 |

The mpQP results show the main trade-off clearly. PureNN is fastest but violates hard constraints. NN+Proj restores feasibility but adds projection cost and tail latency. QP is reliable but slower. CertNet preserves hard feasibility while avoiding both online QP solving and online projection.

---

## 3. Control Allocation Benchmark

The control allocation benchmark evaluates deadline-aware closed-loop deployment.

At each step, the controller must finish within the sampling budget. If a method exceeds the deadline, the system applies a zero-increment hold action. Therefore, runtime tails directly affect the closed-loop trajectory.

Compared methods:

- **Opt:** online optimization teacher;
- **PureNN:** unconstrained neural policy;
- **NN+Proj:** neural policy with projection repair;
- **CertNet:** certified executor.

The figure shows the closed-loop behavior under this deadline-enforced execution rule. It tests whether runtime tails and deadline misses propagate into trajectory-level degradation.

<p align="center">
  <img src="sim_CA.png" width="650" alt="Control allocation closed-loop trajectories under deadline-limited execution"><br>
  <b>Control allocation closed-loop trajectories under deadline-limited execution.</b>
</p>

PDF version: [`sim_CA.pdf`](sim_CA.pdf)

Run:

```matlab
open("demo_ca_.mlx")
```

### CA Results

Sampling deadline:

```text
T_s = 1000 microseconds
```

| Method | Mean runtime | p99 runtime | Speedup | Violation rate | Deadline miss rate | `w`RMSE |
|---|---:|---:|---:|---:|---:|---:|
| Opt | 1006.3 us | 2027.4 us | 1.00x | 0.00% | 26.00% | 2.098e-1 |
| PureNN | 10.1 us | 32.2 us | 99.97x | 48.60% | 0.00% | 3.097e-1 |
| NN+Proj | 387.2 us | 1885.3 us | 2.60x | 0.00% | 10.40% | 3.222e-1 |
| **CertNet** | **63.3 us** | **185.8 us** | **15.89x** | **0.00%** | **0.00%** | **4.231e-2** |

The CA benchmark shows that the runtime profile matters for closed-loop deployment. Opt can miss deadlines. PureNN is fast but violates the hard interface. NN+Proj restores feasibility but suffers from projection overhead. CertNet avoids both hard-interface violations and deadline misses in this experiment.

Released CA artifacts:

```text
N_train = 20000
N_test  = 500
n_LFull = 4096
n_LAct  = 353
```

---

## 4. Adaptive Cruise Control Benchmark

The ACC benchmark evaluates CLF/CBF-style safety-filter recovery.

The hard interface includes input bounds, safety constraints, and one-step state bounds. Runtime is measured for deployment comparison, while the rollout evaluates safety and controller quality.

Compared methods:

- **Opt:** online CLF/CBF-style optimization teacher;
- **PureNN:** unconstrained neural policy;
- **NN+Proj:** neural policy with projection repair;
- **CertNet:** certified executor.

The figure shows closed-loop speed, input, and safety-margin behavior. This benchmark tests whether the certified executor can recover the behavior of a safety-filtering teacher while keeping the online path low-latency.

<p align="center">
  <img src="sim_ACC.png" width="650" alt="ACC closed-loop speed, input, and safety-margin trajectories"><br>
  <b>ACC closed-loop speed, input, and safety-margin trajectories.</b>
</p>

PDF version: [`sim_ACC.pdf`](sim_ACC.pdf)

Run:

```matlab
open("demo_acc_.mlx")
```

### ACC Results

| Method | Mean runtime | p99 runtime | Speedup | Violation rate | Rollout status | Cost |
|---|---:|---:|---:|---:|---:|---:|
| Opt | 805.0 us | 1286.0 us | 1.00x | 0.00% | safe | 1.648e1 |
| PureNN | 8.9 us | 21.2 us | 90.29x | 70.00% | unsafe | N/A |
| NN+Proj | 173.8 us | 1054.4 us | 4.63x | 0.07% | stop 568/1500 | N/A |
| **CertNet** | **24.7 us** | **56.3 us** | **32.60x** | **0.00%** | **safe** | **1.651e1** |

PureNN is fast but unsafe in closed-loop rollout. NN+Proj repairs many infeasible neural outputs, but projection becomes a runtime and robustness bottleneck. CertNet follows Opt-like safe behavior while substantially reducing both mean and tail runtime.

Released ACC artifacts:

```text
N_train = 20000
N_test  = 1500
n_LFull = 5
n_LAct  = 4
```

---

## Notes on Metrics

- Timings exclude one-time setup overhead.
- Timing statistics are steady-state evaluation times.
- Mean and p99 are reported to show both average runtime and tail behavior.
- Violation rate is computed using the numerical feasibility threshold used in the experiments.
- A reported `0.00%` violation rate means zero observed violations above the prescribed numerical tolerance.
- For NN+Proj, projection-use rate is reported because projection calls explain much of its runtime tail.

---

## Reproducibility Scope

This repository supports reproduction of the released evaluation artifacts:

- loading released controller and baseline artifacts;
- evaluating CertNet and baselines under the reported protocols;
- reproducing timing, feasibility, and closed-loop metrics;
- regenerating the provided figures.

The release packs are the intended evaluation interface for the reported experiments.

---

## Citation

The manuscript is currently under review. A formal citation will be added after publication.

---

## License

This project is released under the license included in this repository. See [`LICENSE`](LICENSE).

---

## Contact

For questions, please open a GitHub issue or contact the authors.
