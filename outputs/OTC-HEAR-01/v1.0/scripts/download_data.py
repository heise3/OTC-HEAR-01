"""Authorized official NHIS PUF downloads for valid-N audit and gated analyses."""
from pathlib import Path
import urllib.request, concurrent.futures, json, hashlib, datetime, re, zipfile
ROOT=Path(__file__).resolve().parents[4]
DEST=ROOT/'work/nhis_data';DEST.mkdir(parents=True,exist_ok=True)
DOCS=ROOT/'work/nhis_docs'
def fetch_year(year):
    base=f'https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/{year}/'
    idx=DEST/f'{year}_index.html'
    if not idx.exists():idx.write_bytes(urllib.request.urlopen(base,timeout=40).read())
    links=re.findall(r'HREF="([^"]+)"',idx.read_text(),re.I)
    records=[]
    for kind in ['adult','adultinc','paradata']:
        wanted=f'{kind}{str(year)[-2:]}csv.zip'
        link=next(x for x in links if x.rsplit('/',1)[-1].lower()==wanted)
        url='https://ftp.cdc.gov'+link;target=DEST/wanted
        if not target.exists():target.write_bytes(urllib.request.urlopen(url,timeout=60).read())
        data=target.read_bytes()
        with zipfile.ZipFile(target) as z:
            for name in z.namelist():
                if name.lower().endswith('.csv'):
                    # Flatten the official archive; never extract arbitrary paths.
                    (DEST/Path(name).name.lower()).write_bytes(z.read(name))
        records.append({'year':year,'kind':kind,'url':url,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()})
    return records
if __name__=='__main__':
    out=ROOT/'outputs/OTC-HEAR-01/v1.0'
    assert json.loads((out/'status.json').read_text())['gates']['A0']=='PASS'
    records=[]
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
        for rows in ex.map(fetch_year,range(2019,2026)):
            records.extend(rows);print(json.dumps(rows),flush=True)
    (out/'logs/data_downloads.json').write_text(json.dumps(records,indent=2)+'\n')
