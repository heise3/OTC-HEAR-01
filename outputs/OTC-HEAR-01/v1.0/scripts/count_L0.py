"""L0: count independent Sample Adults; never compute outcome proportions."""
from pathlib import Path
import pandas as pd,json,datetime
ROOT=Path(__file__).resolve().parents[4];OUT=ROOT/'outputs/OTC-HEAR-01/v1.0';DATA=ROOT/'work/nhis_data'
status=json.loads((OUT/'status.json').read_text());assert status['gates']['D']=='PASS'
rows=[];low={p:[] for p in ['pre','post']};hs={p:0 for p in ['pre','post']}
for year in [2019,2021,2022,2023,2024]:
 d=pd.read_csv(DATA/f'adult{str(year)[-2:]}.csv',dtype={'HHX':'string'})
 period='pre' if year<2023 else 'post'
 eligible=d.AGEP_A.between(50,85)
 if year==2022:eligible &= d.INTV_QRT.isin([1,2,3])
 h=d.HEARAID_A.eq(1)|d.HEARINGDF_A.isin([2,3,4])
 hids=set(d.loc[eligible&h,'HHX']);n=len(hids);hs[period]+=n
 rows.append({'gate':'H_year','year':year,'period':period,'imputation':0,'unweighted_n':n,'threshold':None,'status':'DESCRIPTIVE_COUNT','note':'H union, age50-85;2022Q1-Q3'})
 main_n=int((eligible&h&d.HEARAID_A.isin([1,2])&d.SEX_A.isin([1,2])).sum())
 rows.append({'gate':'H_main_complete_year','year':year,'period':period,'imputation':0,'unweighted_n':main_n,'threshold':None,'status':'DESCRIPTIVE_COUNT','note':'Valid outcome and sex; count only'})
 inc=pd.read_csv(DATA/f'adultinc{str(year)[-2:]}.csv',dtype={'HHX':'string'})
 im='IMPNUM' if year==2019 else 'IMPNUM_A'
 inc=inc[inc.HHX.isin(hids)]
 for m in range(1,11):
  k=inc[inc[im].eq(m)]
  low[period].append((year,m,int(k.POVRATTC_A.lt(2).sum())))
 # Observed-income-only unique adult count, never the ten-draw row count.
 obs=inc.loc[inc.IMPINCFLG_A.eq(0)&inc.POVRATTC_A.lt(2),'HHX'].nunique()
 rows.append({'gate':'low_income_observed_year','year':year,'period':period,'imputation':0,'unweighted_n':int(obs),'threshold':None,'status':'DESCRIPTIVE_COUNT','note':'Reported income only; IMPINCFLG_A0'})
failed=[]
for p in ['pre','post']:
 threshold=6000 if p=='pre' else 5000
 passed=hs[p]>=threshold
 rows.append({'gate':'H_period','year':'pooled','period':p,'imputation':0,'unweighted_n':hs[p],'threshold':threshold,'status':'PASS' if passed else 'STOP_N','note':'Independent sample adults; no imputation multiplicity'})
 if not passed:failed.append(p+'_H')
 for m in range(1,11):
  n=sum(n for y,imp,n in low[p] if imp==m);passed=n>=1000
  rows.append({'gate':'low_income_H_period','year':'pooled','period':p,'imputation':m,'unweighted_n':n,'threshold':1000,'status':'PASS' if passed else 'STOP_N','note':'One row per adult in this income draw; minimum draw required to pass'})
  if not passed:failed.append(p+'_low_income_draw'+str(m))
pd.DataFrame(rows).to_csv(OUT/'L0/counts.csv',index=False)
status['gates']['L0']='STOP_N' if failed else 'PASS'
if failed:status.update(terminal=True,decision='STOP_N')
status['updated_at_utc']=datetime.datetime.now(datetime.timezone.utc).isoformat();(OUT/'status.json').write_text(json.dumps(status,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'H_counts':hs,'low_income_min':{p:min(sum(n for y,imp,n in low[p] if imp==m) for m in range(1,11)) for p in low},'gate':status['gates']['L0'],'failed':failed},ensure_ascii=False))
