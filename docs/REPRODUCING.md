# Reproduction

## Environment

The completed analysis used R 4.6.1 with survey 4.5, mitools 2.7, data.table 1.18.6.1, and jsonlite 2.0.0. See the unchanged [R session record](../outputs/OTC-HEAR-01/v1.0/logs/R_sessionInfo.txt). Documentation/count work used Python 3.12 with pandas and pypdf; standard-library download code was also run with system Python 3.14.6. Exact available Python versions used for this public packaging are listed in `environment/python-requirements.txt`. Pillow is needed only for the600 dpi TIFF format export.

Install the Python dependencies in a virtual environment. Install the listed R packages in a separate R library, matching the recorded versions if exact reproduction is required. The full workflow depends on network access to official NCHS resources. The complete microdata analysis was not rerun for publication of this repository; the original numerical QA and session records are archived.

## Preserve the completed snapshot

The original scripts write to `outputs/OTC-HEAR-01/v1.0/` relative to their workspace root. Create a separate reproduction directory before running them:

```bash
python3 tools/verify_archive.py
python3 tools/prepare_reproduction.py --destination /absolute/path/to/new-otc-reproduction
cd /absolute/path/to/new-otc-reproduction
```

The destination must not already exist. The helper copies the frozen analysis and utilities without copying any participant records. It preserves the original relative paths expected by the unchanged scripts.

## Official files and gates

```bash
python3 outputs/OTC-HEAR-01/v1.0/scripts/download_docs.py
python3 outputs/OTC-HEAR-01/v1.0/scripts/extract_docs.py
python3 outputs/OTC-HEAR-01/v1.0/scripts/download_data.py
python3 tools/verify_downloads.py
```

The data-source check compares all 21 official ZIP files with the hashes used in the original execution. If a source is unavailable or the bytes differ, stop and report source drift; do not silently substitute a different release. The original downloader also saves a new local download receipt; the expected hashes are read from the archived copy of the original receipt. No source hashes are updated by the verification utility.

A0 literature adjudication and parts of D documentation adjudication were human-reviewed and are supplied as archived decisions and evidence. The numerical scripts rely on those recorded gates; they do not independently repeat a literature search or certify an ethics/access determination. Review documentation and original adjudication before recomputing.

```bash
python3 outputs/OTC-HEAR-01/v1.0/scripts/audit_variables.py
python3 outputs/OTC-HEAR-01/v1.0/scripts/count_L0.py
Rscript outputs/OTC-HEAR-01/v1.0/scripts/calibrate_L1.R
Rscript outputs/OTC-HEAR-01/v1.0/scripts/analyze_L2.R
Rscript outputs/OTC-HEAR-01/v1.0/scripts/analyze_L3.R
Rscript outputs/OTC-HEAR-01/v1.0/scripts/analyze_L4.R
Rscript outputs/OTC-HEAR-01/v1.0/scripts/verify_numeric_results.R
Rscript outputs/OTC-HEAR-01/v1.0/scripts/make_figures.R
```

Subsequent stages require the previous recorded PASS state. Preserve the frozen estimand, population, periods, thresholds, and contrasts. Do not change the contract to obtain a different result. New exploratory work needs a separate, explicitly labeled design.

## Rebuild the revised figure from aggregate data only

From the repository root, with R/data.table and Python/Pillow installed:

```bash
python3 tools/render_figure.py --destination /absolute/path/to/new-figure-directory
```

The helper copies `artwork/` to a new destination and runs its unchanged plotting and TIFF-export scripts there. It does not overwrite the archived artwork. The TIFF export is lossless RGB LZW at 600 dpi without upsampling. Rendering can vary with platform/font libraries; the underlying estimates must remain identical.

## Interpretation of verification

`tools/verify_archive.py` checks archive integrity and arithmetic on already released aggregate estimates. The original `verify_numeric_results.R` performs numerical cross-checks using downloaded public files. Neither proves policy causality, a minimum clinically important margin, or absence of undiscovered related work.
