"""Download only public official NHIS documentation. No individual records."""
from pathlib import Path
import urllib.request, concurrent.futures, json, hashlib, datetime

ROOT=Path(__file__).resolve().parents[4]
DEST=ROOT/'work/nhis_docs'
DEST.mkdir(parents=True,exist_ok=True)
URLS={}
for year in range(2019,2026):
    base=f'https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/{year}/'
    for name in ['Adult-codebook.pdf','Adult-summary.pdf','Paradata-codebook.pdf','Paradata-summary.pdf','srvydesc-508.pdf',
                 'Adultinc-summary.pdf',f'NHIS{year}-imputation-techdoc-508.pdf']:
        URLS[f'{year}_{name}']=base+name
    URLS[f'{year}_index.html']=base

def fetch(item):
    name,url=item
    target=DEST/name
    result={'file':name,'url':url,'at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()}
    try:
        if target.exists():
            data=target.read_bytes();result['http_status']='cached_previous_200'
        else:
            with urllib.request.urlopen(url,timeout=40) as r:
                data=r.read();result['http_status']=r.status
            target.write_bytes(data)
        result.update(bytes=len(data),sha256=hashlib.sha256(data).hexdigest(),state='OK')
    except Exception as e:
        result.update(state='ERROR',error=repr(e))
    return result

if __name__=='__main__':
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        records=[]
        for result in pool.map(fetch,URLS.items()):
            records.append(result);print(json.dumps(result),flush=True)
    (DEST/('download_log_'+datetime.datetime.now(datetime.timezone.utc).strftime('%H%M%S')+'.json')).write_text(json.dumps(records,indent=2)+'\n')
