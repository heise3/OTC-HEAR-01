"""Stage the immutable archive into a new local reproduction workspace."""
from pathlib import Path
import argparse,shutil,json
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--destination',required=True,type=Path);a=p.parse_args()
target=a.destination.expanduser().resolve()
if target.exists():raise SystemExit('Destination exists; choose a new empty path.')
source=ROOT/'outputs/OTC-HEAR-01/v1.0'
shutil.copytree(source,target/'outputs/OTC-HEAR-01/v1.0')
(target/'tools').mkdir()
shutil.copy2(ROOT/'tools/verify_downloads.py',target/'tools/verify_downloads.py')
(target/'provenance').mkdir()
shutil.copy2(source/'logs/data_downloads.json',target/'provenance/original_data_downloads.json')
print(json.dumps({'reproduction_workspace':str(target),'participant_data_copied':False}))
