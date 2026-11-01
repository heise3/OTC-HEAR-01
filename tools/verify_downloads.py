"""Fail closed if official ZIP bytes differ from the archived execution."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[1]
expected=ROOT/'provenance/original_data_downloads.json'
if not expected.exists():expected=ROOT/'environment/original_data_downloads.json'
records=json.loads(expected.read_text());fail=[]
for row in records:
    name=row['url'].rsplit('/',1)[-1];p=ROOT/'work/nhis_data'/name
    if not p.exists():fail.append(name+':MISSING');continue
    actual=hashlib.sha256(p.read_bytes()).hexdigest()
    if actual!=row['sha256']:fail.append(name+':HASH_MISMATCH')
if fail:raise SystemExit('STOP_SOURCE_DRIFT: '+'; '.join(fail))
print(json.dumps({'status':'PASS','official_ZIP_files_verified':len(records)}))
