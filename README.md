# OTC-HEAR-01

Analysis code, frozen protocol, documentation audits, aggregate results, and figure-generation code for **Hearing Aid Use After Over-the-Counter Availability**, using the US National Health Interview Survey (NHIS), 2019–2025.

**Public archive release:** v1.0.0, November 1, 2026. **Frozen scientific contract:** v1.0, October 30, 2026. This repository was published after the analyses were completed. It is a retrospective public code/protocol archive, not prospective public preregistration. The original local freeze records are retained with their original timestamps and hashes.

## Start here

- [Frozen protocol](outputs/OTC-HEAR-01/v1.0/contract.md) and [configuration](outputs/OTC-HEAR-01/v1.0/config.yaml)
- [Analysis scripts](outputs/OTC-HEAR-01/v1.0/scripts/)
- [Primary estimate](outputs/OTC-HEAR-01/v1.0/L2/main_estimate.csv), [period rates](outputs/OTC-HEAR-01/v1.0/L2/period_rates.csv), and [secondary estimates](outputs/OTC-HEAR-01/v1.0/L4/secondary.csv)
- [Frozen execution report](outputs/OTC-HEAR-01/v1.0/REPORT.md), [status](outputs/OTC-HEAR-01/v1.0/status.json), and [numeric QA](outputs/OTC-HEAR-01/v1.0/logs/numeric_QA.csv)
- [Reproduction instructions](docs/REPRODUCING.md), [interpretation and measurement limits](docs/MEASUREMENT_AND_SCOPE.md), and [release provenance](docs/RELEASE_PROVENANCE.md)
- [Revised scientific figure and source code](artwork/)

## What is preserved

The complete 74-file frozen analysis package under `outputs/OTC-HEAR-01/v1.0/` is preserved byte for byte. Its original protocol/configuration hashes and full artifact manifest are included. Presentation artwork is supplied separately and reads existing aggregate CSV files. Original code is licensed MIT; original documentation, figures, and aggregate-result presentation are CC BY 4.0, with upstream government materials and dependencies retaining their own terms. See [LICENSING.md](LICENSING.md).

No participant-level data, model caches, manuscript drafts, or private author-information forms are included. Source NHIS public-use files are downloaded directly from NCHS by the supplied code. Local raw-data and scratch directories are ignored by Git. Only published official documentation and aggregate results are included in this archive.

## Verify without downloading participant data

```bash
python3 tools/verify_archive.py
```

This standard-library check verifies the release manifest, both original frozen manifests, aggregate source consistency, primary equivalence arithmetic, and Python/R source syntax where the interpreter is available. It does not re-estimate survey models or establish causal validity. GitHub Actions runs the lightweight archive checks; it does not download or analyze participant records.

For a full numerical reproduction, create a separate workspace and follow [REPRODUCING.md](docs/REPRODUCING.md). The archived snapshot should remain intact.

## Scientific scope

The frozen primary comparison is 2019, 2021, and January–September 2022 versus 2023–2024 among adults aged 50 years or older with hearing difficulty or current hearing-aid use. 2025 is a separate extension. The standardized difference was 0.785 percentage points (95% CI, −0.529 to 2.099), within the prespecified ±2.5-point bounds. These are national period associations. The equivalence margin reflected precision planning rather than an established minimum important difference; the full interval supports interpretation against alternative substantive thresholds. The design does not identify an OTC-specific causal effect.

The original snapshot retains its historical labels and frozen decisions. Later wording clarifications are recorded in [MEASUREMENT_AND_SCOPE.md](docs/MEASUREMENT_AND_SCOPE.md); they do not alter the protocol, windows, thresholds, models, or estimates.

## Citation

Please cite the versioned [v1.0.0 release](https://github.com/heise3/OTC-HEAR-01/releases/tag/v1.0.0) and its commit, using [CITATION.cff](CITATION.cff). This software/protocol release is not a journal publication and has no assigned DOI.

Authors: Peng Liang, Jie Wu, BaoLong Li, XiangYan Wu, and Xiaona Zhu. Peng Liang and Jie Wu contributed equally. Xiaona Zhu is the corresponding author for the study. Source-study funding or source-survey ethical oversight is not represented as a grant or new ethics approval awarded to this secondary analysis.

中文说明：本仓库是分析完成后公开的代码／冻结协议归档。原始v1.0科学合同和74个文件保持原样；发布版本v1.0.0与科学合同版本分别记录。下载原始公开数据后的复算应在独立工作目录进行；不改窗口、人群、阈值或分析子集。
