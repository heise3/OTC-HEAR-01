source(file.path(dirname(sub("^--file=","",commandArgs(FALSE)[grep("^--file=",commandArgs(FALSE))])),"analysis_common.R"))
suppressPackageStartupMessages(library(mitools))
status<-read_status();stopifnot(status$gates$L3=="PASS")
d<-get_data();std<-readRDS(file.path(root,"work/L2_model.rds"))$standard
a<-d[d$year %in% c(2019,2021,2022,2023,2024),]
income<-rbindlist(lapply(c(2019,2021,2022,2023,2024),function(y){
 z<-fread(file.path(root,sprintf("work/nhis_data/adultinc%02d.csv",y%%100)),colClasses=list(character="HHX"))
 z$year<-y;if(y==2019)setnames(z,"IMPNUM","IMPNUM_A")
 z[,c("year","HHX","IMPNUM_A","POVRATTC_A","IMPINCFLG_A"),with=FALSE]
}))
fits<-list();counts<-list();draw_results<-list()
for(m in 1:10){
 inc<-income[IMPNUM_A==m];stopifnot(!anyDuplicated(inc[,.(year,HHX)]))
 z<-merge(a,as.data.frame(inc),by=c("year","HHX"),all.x=TRUE,sort=FALSE);stopifnot(nrow(z)==nrow(a),!anyNA(z$POVRATTC_A))
 z$income_group<-factor(ifelse(z$POVRATTC_A<2,"Low",ifelse(z$POVRATTC_A>=4,"High",NA)),levels=c("High","Low"))
 sd<-domain(make_design(z,"w_main"),with(z,age50 & H==1 & !is.na(aid) & !is.na(age_sex) & !is.na(post) & !is.na(income_group)))
 fits[[m]]<-svyglm(aid~post*income_group+age_sex,sd,family=gaussian())
 for(gr in c("Low","High"))for(per in 0:1){
  mask<-sd$variables$income_group==gr & sd$variables$post==per
  sm<-domain(sd,mask);v<-svymean(~aid,sm)
  counts[[paste(m,gr,per)]]<-data.frame(imputation=m,income_group=gr,post=per,unweighted_n=sum(mask),raw_weighted_pct=100*as.numeric(coef(v)),raw_design_se_pp=100*as.numeric(SE(v)),raw_design_df=degf(sm))
 }
 draw_results[[m]]<-data.frame(imputation=m,high_change_pp=100*coef(fits[[m]])['post'],
  low_change_pp=100*(coef(fits[[m]])['post']+coef(fits[[m]])['post:income_groupLow']),
  low_minus_high_DiD_pp=100*coef(fits[[m]])['post:income_groupLow'])
}
pool_contrast<-function(name,g){
 est<-lapply(fits,function(f)as.numeric(g%*%coef(f)))
 vari<-lapply(fits,function(f)matrix(as.numeric(g%*%vcov(f)%*%g),1,1))
 pooled<-MIcombine(est,vari,df.complete=min(sapply(fits,function(f)f$df.residual)))
 b<-as.numeric(pooled$coefficients);se<-sqrt(as.numeric(pooled$variance));df<-as.numeric(pooled$df);cr<-qt(.975,df)
 data.frame(estimand=name,estimate_pp=100*b,se_pp=100*se,ci_lower_pp=100*(b-cr*se),ci_upper_pp=100*(b+cr*se),df=df,
             within_variance_pp2=mean(sapply(vari,as.numeric))*10000,between_variance_pp2=var(unlist(est))*10000,
             imputations=10,status="PASS",role="secondary_MI")
}
g<-setNames(rep(0,length(coef(fits[[1]]))),names(coef(fits[[1]])));g['post']<-1
high<-pool_contrast("income_high_change",g);g['post:income_groupLow']<-1
low<-pool_contrast("income_low_change",g);g['post']<-0
did<-pool_contrast("income_low_minus_high_DiD",g)
fwrite(rbindlist(counts),file.path(out,"L4/income_counts_and_raw_levels_by_draw.csv"));fwrite(rbindlist(draw_results),file.path(out,"L4/income_estimates_by_draw.csv"))
# Pool descriptive period levels using the same Rubin rule; these remain unadjusted levels.
levs<-rbindlist(counts);pooled_levels<-rbindlist(lapply(c("Low","High"),function(gr)rbindlist(lapply(0:1,function(per){
 x<-levs[income_group==gr & post==per];p<-MIcombine(as.list(x$raw_weighted_pct),lapply(x$raw_design_se_pp^2,function(v)matrix(v,1,1)),df.complete=min(x$raw_design_df))
 b<-as.numeric(p$coefficients);se<-sqrt(as.numeric(p$variance));cr<-qt(.975,p$df)
 data.frame(income_group=gr,post=per,estimate_pct=b,se_pp=se,ci_lower_pct=b-cr*se,ci_upper_pct=b+cr*se,n_min=min(x$unweighted_n),n_max=max(x$unweighted_n),note="Rubin pooled unadjusted survey levels; N is range across10draws")
}))))
fwrite(pooled_levels,file.path(out,"L4/income_pooled_raw_levels.csv"))
# Always-use frequency among users, not H severity strata.
fd<-domain(make_design(a,"w_main"),with(a,age50 & aid==1 & !is.na(always) & !is.na(age_sex) & !is.na(post)))
ff<-svyglm(always~post+age_sex,fd,family=gaussian());g<-setNames(rep(0,length(coef(ff))),names(coef(ff)));g['post']<-1
freq<-linear_result(ff,g,"always_use_among_aid_users_change");freq$n_pre<-sum(fd$variables$post==0);freq$n_post<-sum(fd$variables$post==1);freq$status<-"PASS";freq$role<-"secondary_frequency"
frates<-rbindlist(lapply(0:1,function(per){sd<-domain(fd,fd$variables$post==per);m<-svymean(~always,sd);b<-as.numeric(coef(m))*100;se<-as.numeric(SE(m))*100;cr<-qt(.975,degf(sd));data.frame(post=per,estimate_pct=b,se_pp=se,ci_lower_pct=b-cr*se,ci_upper_pct=b+cr*se,unweighted_n=nrow(sd$variables))}))
fwrite(frates,file.path(out,"L4/frequency_raw_levels.csv"))
# Extension2025 is compared with the frozen pre-period, never pooled into2023-24.
e<-d[d$year %in% c(2019,2021,2022,2025),];e$post<-ifelse(e$year==2025,1,e$post)
e$w_extension<-e$WTFA_A/ifelse(e$post==1 & !is.na(e$post),1,2.75)
ed<-domain(make_design(e,"w_extension"),with(e,age50 & H==1 & !is.na(aid) & !is.na(age_sex) & !is.na(post)))
ef<-svyglm(aid~post+age_sex,ed,family=gaussian());g<-setNames(rep(0,length(coef(ef))),names(coef(ef)));g['post']<-1
extension<-linear_result(ef,g,"extension2025_minus_pre");extension$n_pre<-sum(ed$variables$post==0);extension$n_post<-sum(ed$variables$post==1);extension$status<-"PASS";extension$role<-"separate_extension"
e0<-linear_result(ef,marginal_gradient(ef,make_cells(d,std,post=0),std$p),"extension_model_pre_pct")
e1<-linear_result(ef,marginal_gradient(ef,make_cells(d,std,post=1),std$p),"extension_model2025_pct")
fwrite(rbind(e0,e1),file.path(out,"L4/extension_period_rates.csv"))
comp<-fread(file.path(out,"L3/competing.csv"));reuse<-comp[grepl("^age_|^Medicare_|^Traditional_|^VA_",estimand),.(estimand,estimate_pp,se_pp,ci_lower_pp,ci_upper_pp,df,n_pre,n_post,status)]
reuse$role<-ifelse(grepl("Medicare|Traditional|VA_",reuse$estimand),"descriptive_insurance","secondary_age")
secondary<-rbindlist(list(high,low,did,freq,extension,reuse),fill=TRUE)
secondary$secondary_multiplicity_note<-"Prespecified secondary/descriptive analyses; pointwise95%CIs, no multiplicity adjustment; do not replace primary conclusion"
fwrite(secondary,file.path(out,"L4/secondary.csv"))
file.copy(file.path(out,"L3/insurance_descriptive_levels.csv"),file.path(out,"L4/insurance_descriptive_levels.csv"),overwrite=TRUE)
saveRDS(list(income_fits=fits,frequency_fit=ff,extension_fit=ef),file.path(root,"work/L4_models.rds"))
status$gates$L4<-"PASS";status$terminal<-TRUE;status$decision<-"GO"
status$decision_scope<-"Frozen gates complete with valid calibrated national period-change estimate; GO does not mean OTC causal effect or meaningful uptake increase"
status$secondary<-list(income_DiD_pp=did$estimate_pp,income_DiD_ci=list(did$ci_lower_pp,did$ci_upper_pp),
  frequency_delta_pp=freq$estimate_pp,extension2025_delta_pp=extension$estimate_pp)
write_status(status);print(secondary);print(pooled_levels)
