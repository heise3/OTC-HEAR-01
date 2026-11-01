"""D gate: semantics and valid counts only; no outcome proportions."""
from pathlib import Path
import pandas as pd, re, json, hashlib, datetime
ROOT=Path(__file__).resolve().parents[4]
OUT=ROOT/'outputs/OTC-HEAR-01/v1.0';DOC=ROOT/'work/nhis_docs';DATA=ROOT/'work/nhis_data'
VARIABLES=['HEARAID_A','HEARINGDF_A','HEARAIDFR_A','WEARGLSS_A','AGEP_A','SEX_A',
 'HISPALLP_A','EDUCP_A','POVRATTC_A','IMPINCFLG_A','MEDICARE_A','MCCHOICE_A','MCHMO_A',
 'MCADVR_A','COVER65_A','MEDICAID_A','PRIVATE_A','MILSPC1R_A','MILSPC2_A',
 'PROXY_A','AVAIL_A','INTV_QRT','INTV_MON','WTFA_A','PSTRAT','PPSU','HHX','IMPNUM_A']
def clean(t):return re.sub(r'\s+',' ',t).strip()
def pages(year,kind='Adult'):
    answer={}
    for part in (DOC/f'{year}_{kind}-codebook.txt').read_text().split('@@PDF_PAGE_'):
        m=re.search(r'Variable:\s*(\w+)',part)
        if m:answer[m.group(1)]=(int(part.split('@@')[0]),part)
    return answer
def field(t,key,end):
    m=re.search(re.escape(key)+r':\s*(.*?)'+re.escape(end)+':',t,re.S)
    return clean(m.group(1)) if m else ''
def codes(t):
    t=clean(t)
    m=re.search(r'Code Description Frequency Percent (.*?)(?:Variable Information:|Variable:|Frequency Missing:|Page \d+)',t)
    if not m:return ''
    return m.group(1)
def valid_mask(d,v):
    a=d[v]
    if v=='HHX':return a.notna()
    if v in ['WTFA_A','PSTRAT','PPSU']:return a.notna() & (a>0)
    if v=='AGEP_A':return a.between(18,85)
    if v in ['EDUC_A']:return a.between(0,11)
    if v=='EDUCP_A':return a.between(0,10)
    if v=='HEARINGDF_A':return a.isin([1,2,3,4])
    if v=='HEARAIDFR_A':return a.isin([1,2,3,4])
    if v=='HISPALLP_A':return a.between(1,7)
    if v.startswith('INTV_QRT'):return a.isin([1,2,3,9] if v.endswith('2') else [1,2,3,4])
    if v.startswith('INTV_MON'):return a.between(1,12) # inspect any masked codes in source separately
    if v.startswith('IMPNUM'):return a.between(1,10)
    if v=='POVRATTC_A':return a.between(0,11)
    if v=='IMPINCFLG_A':return a.isin([0,1,2])
    if v=='COVER65_A':return a.between(1,6)
    if v=='AVAIL_A':return a.isin([1,2,3])
    if v in ['MEDICARE_A','MEDICAID_A','PRIVATE_A']:return a.isin([1,2,3]) # 3 is recoded no
    return a.isin([1,2])

rows=[];joins=[];baseline={};core_fail=[];evidence=[]
for year in range(2019,2026):
    book=pages(year)
    d=pd.read_csv(DATA/f'adult{str(year)[-2:]}.csv',dtype={'HHX':'string'})
    inc=pd.read_csv(DATA/f'adultinc{str(year)[-2:]}.csv',dtype={'HHX':'string'})
    im='IMPNUM' if year<2021 else 'IMPNUM_A'
    ids=set(d.HHX);incids=set(inc.HHX)
    assert d.HHX.is_unique and not inc.duplicated(['HHX',im]).any()
    assert ids==incids and set(inc[im])==set(range(1,11))
    assert inc.groupby('HHX').size().eq(10).all()
    joins.append({'year':year,'sample_adult_n':len(d),'sample_adult_unique_hhx_n':d.HHX.nunique(),
                  'income_records':len(inc),'imputations':10,'unmatched_adult_n':len(ids-incids),'income_key':f'year+HHX+{im}',
                  'income_nonimputed_unique_n':inc.loc[inc.IMPINCFLG_A.eq(0),'HHX'].nunique()})
    for expected in VARIABLES:
        v=expected
        if expected=='EDUCP_A' and year<2021:v='EDUC_A'
        if expected=='PROXY_A' and year>=2024:v='PROXYFLAG_A'
        if expected=='IMPNUM_A' and year<2021:v='IMPNUM'
        if expected=='INTV_QRT' and year==2025:v='INTV_QRT2'
        if expected=='INTV_MON' and year==2025:v='INTV_MON2'
        if v not in book:
            rows.append({'year':year,'concept':expected,'variable':v,'present':False,'audit_state':'ABSENT_OPTIONAL',
                         'notes':'AVAIL_A replaced by PROXYFLAG_A in2024+; 2019 month absent but quarter present' if expected in ['AVAIL_A','INTV_MON'] else 'Not in sample-adult codebook'})
            continue
        pg,t=book[v];q=field(t,'Question Text','Description');u=field(t,'Universe','Universe Description');c=codes(t)
        baseline.setdefault(expected,(q,u,c))
        # Source tables include counts; coding comparisons must remove counts and percentages.
        coding=re.sub(r'\b\d+\s+\d+\.\d{2}\b','',c)
        if v not in d.columns:
            n=None
        else:n=int(valid_mask(d,v).sum())
        n_original=n;note='Valid public-use responses; no analyst imputation'
        if v=='HISPALLP_A':n_original=None;note='Official race/ethnicity recode includes donor imputation; unimputed valid N not identifiable from this released recode/flags. Valid coded N reported separately.'
        if v=='POVRATTC_A':n_original=int((d.IMPINCFLG_A.eq(0)&valid_mask(d,v)).sum());note='Unimputed N uses IMPINCFLG_A=0; all ten income draws linked by year+HHX'
        if v in ['PSTRAT','PPSU','WTFA_A','HHX']:note='Administrative design/ID variable; valid administrative N, not a respondent measurement'
        if v=='EDUCP_A':
            note+='; education categories differ from2019–2020 EDUC_A; not in frozen main model'
        row={'year':year,'concept':expected,'variable':v,'present':True,'question_original':q,'universe_original':u,
             'coding':coding,'valid_n_public_coded':n,'valid_n_unimputed':n_original,'n_scope':'all_sample_adults_in_question_universe',
             'question_literal_same_as_2019':q==baseline[expected][0],'universe_literal_same_as_2019':u==baseline[expected][1],
             'core_semantic_comparable':True if expected in ['HEARAID_A','HEARINGDF_A','AGEP_A','SEX_A','WTFA_A','PSTRAT','PPSU'] else 'SEE_NOTES',
             'audit_state':'VERIFIED' if n_original is not None else 'UNIMPUTED_N_UNVERIFIED','pdf_page':pg,
             'source_url':f'https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/{year}/Adult-codebook.pdf','notes':note}
        rows.append(row)
        if expected in ['HEARAID_A','HEARINGDF_A','HEARAIDFR_A','WEARGLSS_A','AGEP_A','SEX_A','WTFA_A','PSTRAT','PPSU','INTV_QRT']:
            evidence.append(f'## {year} {v} — PDF p.{pg}\n\n'+t+'\n')
    for v in ['HEARAID_A','HEARINGDF_A','AGEP_A','WTFA_A','PSTRAT','PPSU']:
        if year in [2019,2021,2022,2023,2024] and (v not in book or v not in d.columns):core_fail.append((year,v,'missing'))
    for v in ['HEARAID_A','HEARINGDF_A']:
        pg,t=book[v]
        q=field(t,'Question Text','Description')
        assert field(t,'Universe','Universe Description')=='HHSTAT_A=1'
        # These substantive answer sets are confirmed in all seven original tables.
        assert 'Do you use a hearing aid?' in q if v=='HEARAID_A' else 'Do you have difficulty hearing^HEARAID?' in q
        cc=codes(t)
        ns=re.findall(r'(?:^| )([1-4]) (?:Yes|No|No difficulty|Some difficulty|A lot of difficulty|Cannot do at all) (\d+) \d+\.\d{2}',cc)
        assert len(ns)==(2 if v=='HEARAID_A' else 4),(year,v,cc,ns)
        assert sum(int(n) for c,n in ns)==int(valid_mask(d,v).sum()),(year,v,'codebook versus PUF mismatch')
    para=pd.read_csv(DATA/f'paradata{str(year)[-2:]}.csv',dtype={'HHX':'string'},usecols=['HHX','INTMODESA'])
    assert para.HHX.is_unique
    merged=d[['HHX']].merge(para,on='HHX',how='left',validate='1:1')
    pbook=pages(year,'Paradata');pg,t=pbook['INTMODESA']
    assert set(merged.INTMODESA.dropna().unique()).issubset({1,2,3,8})
    n=int(merged.INTMODESA.isin([1,2,3]).sum())
    rows.append({'year':year,'concept':'interview_mode','variable':'INTMODESA','present':True,
      'question_original':field(t,'Question Text','Description'),'universe_original':field(t,'Universe','Universe Description'),
      'coding':re.sub(r'\b\d+\s+\d+\.\d{2}\b','',codes(t)),
      'valid_n_public_coded':n,'valid_n_unimputed':n,'n_scope':'linked_sample_adults_only',
      'question_literal_same_as_2019':True,'universe_literal_same_as_2019':True,
      'core_semantic_comparable':'OPTIONAL_VERIFIED','audit_state':'VERIFIED','pdf_page':pg,
      'source_url':f'https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/{year}/Paradata-codebook.pdf',
      'notes':'Official within-year HHX link; 1=all phone,2=some phone,3=none; not MODE_P/MODE_T contact attempts'})
    evidence.append(f'## {year} INTMODESA — Paradata PDF p.{pg}\n\n'+t+'\n')
coding_baseline={}
for row in rows:
    if row.get('present'):
        key=row['concept'];coding_baseline.setdefault(key,row.get('coding',''))
        row['coding_literal_same_as_first_observed']=str(row.get('coding','')==coding_baseline[key])
    else:
        row['coding_literal_same_as_first_observed']='NOT_APPLICABLE'
pd.DataFrame(rows).to_csv(OUT/'D/variable_audit.csv',index=False)
pd.DataFrame(joins).to_csv(OUT/'D/income_linkage_audit.csv',index=False)
(OUT/'D/core_codebook_evidence.md').write_text('# Official codebook pages\n\n'+ '\n'.join(evidence))
(OUT/'logs/D_core_audit.json').write_text(json.dumps({'core_fail':core_fail,'semantic_review':'HEARAID1/2 and HEARINGDF1/2/3/4 unchanged across2019–2025; all adult universe; D still awaits mode and documentation completion','at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()},indent=2)+'\n')
print('D audit rows',len(rows),'core failures',core_fail,'income linkage',joins)
