"""Render the scientific figure from frozen aggregate CSVs in a new folder."""
from pathlib import Path
import argparse,shutil,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--destination',required=True,type=Path);a=p.parse_args()
target=a.destination.expanduser().resolve()
if target.exists():raise SystemExit('Destination exists; choose a new path.')
shutil.copytree(ROOT/'artwork',target)
subprocess.run(['Rscript',str(target/'scripts/make_submission_figure.R')],check=True)
subprocess.run([sys.executable,str(target/'scripts/export_tiff.py')],check=True)
print(target)
