"""Check released files and aggregate arithmetic without individual data."""
from pathlib import Path
import ast,csv,hashlib,json,re,shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
STUDY=ROOT/'outputs/OTC-HEAR-01/v1.0'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def check_manifest(base,name):
    lines=(base/name).read_text().splitlines();paths=[]
    for line in lines:
        expected,rel=line.split('  ',1)
        target=(base/rel).resolve()
        if not target.is_relative_to(base.resolve()):raise ValueError('Unsafe manifest path')
        if sha(target)!=expected:raise ValueError('Hash mismatch: '+rel)
        paths.append(rel)
    return paths
public=check_manifest(ROOT,'PUBLIC_SHA256SUMS')
actual=[]
for p in ROOT.rglob('*'):
    if not p.is_file() or any(x in {'.git','work','.venv','__pycache__'} for x in p.relative_to(ROOT).parts):continue
    if p==ROOT/'PUBLIC_SHA256SUMS' or p.name=='.DS_Store':continue
    actual.append(p.relative_to(ROOT).as_posix())
if set(actual)!=set(public):raise ValueError('Manifest file set differs from release file set')
frozen=check_manifest(STUDY,'ARTIFACT_SHA256SUMS')
check_manifest(STUDY,'SHA256SUMS')
assert len([p for p in STUDY.rglob('*') if p.is_file()])==74
assert sha(STUDY/'contract.md')=='1e232c152a8e4446b7a833f9f6dd316e559fc2498c46ea06c4e5af6390832889'
assert sha(STUDY/'config.yaml')=='6c27c9d16b9674540dde5fc34da50fc2d7d90137e96906699175ed5592766ddf'
python_files=list(ROOT.rglob('*.py'));python_files=[p for p in python_files if not any(x in {'.git','work','.venv'} for x in p.relative_to(ROOT).parts)]
for p in python_files:ast.parse(p.read_text(),filename=str(p))
rfiles=[p for p in ROOT.rglob('*.R') if not any(x in {'.git','work','.venv'} for x in p.relative_to(ROOT).parts)]
r_syntax='NOT_RUN_RSCRIPT_UNAVAILABLE'
if shutil.which('Rscript'):
    subprocess.run(['Rscript','-e','for (p in commandArgs(TRUE)) invisible(parse(file=p))',*map(str,rfiles)],check=True)
    r_syntax='PASS'
for rel in public:
    p=ROOT/rel
    if p.suffix.lower() in {'.rds','.rdata','.docx','.zip','.parquet','.sav','.dta'}:raise ValueError('Unexpected artifact type: '+rel)
    if p.suffix in {'.py','.R','.md','.txt','.json','.yaml','.yml','.csv','.cff'}:
        text=p.read_text()
        if ('/'+'Users'+'/') in text:raise ValueError('Local user path: '+rel)
        if re.search(r'gh[pousr]_[A-Za-z0-9]{25,}|sk-[A-Za-z0-9]{25,}|-----BEGIN [A-Z ]*PRIVATE KEY-----',text):raise ValueError('Secret-like content: '+rel)
    if p.suffix=='.csv':
        with p.open(newline='') as f:fields=next(csv.reader(f))
        if any(x in fields for x in ['HHX','AGEP_A','SEX_A','WTFA_A']):raise ValueError('Possible participant-record table: '+rel)
def rows(path):return list(csv.DictReader(path.open()))
main=rows(STUDY/'L2/main_estimate.csv')[0]
lo=float(main['ci_lower_pp']);hi=float(main['ci_upper_pp']);delta=float(main['estimate_pp'])
assert -2.5<lo<hi<2.5
assert abs((float(main['post_standardized_pct'])-float(main['pre_standardized_pct']))-delta)<1e-9
assert (int(main['unweighted_pre_n']),int(main['unweighted_post_n']))==(12910,10493)
for name,rel in [('event_study.csv','L2/event_study.csv'),('main_estimate.csv','L2/main_estimate.csv'),('period_rates.csv','L2/period_rates.csv'),('competing.csv','L3/competing.csv'),('secondary.csv','L4/secondary.csv')]:
    assert sha(ROOT/'artwork/source_data'/name)==sha(STUDY/rel)
comp={r['estimand']:r for r in rows(STUDY/'L3/competing.csv')}
sec={r['estimand']:r for r in rows(STUDY/'L4/secondary.csv')}
expected=[main]+[comp[k] for k in ['observed_post_minus_pretrend_projection','adjusted_for_interview_mode','aid_all50plus','H_prevalence_all50plus','eyeglasses_all50plus']]+[sec[k] for k in ['extension2025_minus_pre','income_low_minus_high_DiD']]
figure=rows(ROOT/'artwork/figure_source_values.csv');assert len(figure)==8
for a,b in zip(figure,expected):
    for k in ['estimate_pp','ci_lower_pp','ci_upper_pp']:assert float(a[k])==float(b[k])
print(json.dumps({'status':'PASS','release_files_verified':len(public),'original_snapshot_files':len(frozen)+1,'python_syntax_files':len(python_files),'R_syntax':r_syntax,'figure_rows_exact':8,'primary_delta_pp':delta,'primary_95CI_pp':[lo,hi],'participant_records_downloaded_or_analyzed':False},indent=2))
