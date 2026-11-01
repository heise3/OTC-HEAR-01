source(file.path(dirname(sub("^--file=","",commandArgs(FALSE)[grep("^--file=",commandArgs(FALSE))])),"analysis_common.R"))
status<-read_status();stopifnot(status$gates$L2=="PASS")
d<-get_data();core<-readRDS(file.path(root,"work/L2_model.rds"));std<-core$standard
a<-d[d$year %in% c(2019,2021,2022,2023,2024),];des<-make_design(a,"w_main")
rows<-list()
estimate_change<-function(y,mask,label,extra=NULL){
 s<-domain(des,mask & !is.na(a[[y]]) & !is.na(a$age_sex) & !is.na(a$post))
 f<-svyglm(as.formula(paste(y,"~post+age_sex",if(!is.null(extra))paste0("+",extra))),s,family=gaussian())
 g<-rep(0,length(coef(f)));g[which(names(coef(f))=="post")]<-1
 r<-linear_result(f,g,label);r$n_pre<-sum(s$variables$post==0);r$n_post<-sum(s$variables$post==1);r$status<-"PASS";r
}
rows$negative_control<-estimate_change("glasses",a$age50,"eyeglasses_all50plus")
rows$H_prevalence<-estimate_change("H",a$age50,"H_prevalence_all50plus")
rows$all50_aid<-estimate_change("aid",a$age50,"aid_all50plus")
validmode<-a$INTMODESA %in% 1:3
rows$mode_baseline<-estimate_change("aid",a$age50 & a$H==1 & validmode,"mode_complete_baseline")
rows$mode_adjusted<-estimate_change("aid",a$age50 & a$H==1 & validmode,"adjusted_for_interview_mode","factor(INTMODESA)")
# Disjoint pre/post cell intercepts plus a pre-only slope, fit jointly to retain survey covariance.
for(i in seq_along(std$lev)){
 a[[paste0("pre_s",i)]]<-as.numeric(a$post==0 & a$age_sex==std$lev[i])
 a[[paste0("post_s",i)]]<-as.numeric(a$post==1 & a$age_sex==std$lev[i])
}
a$pre_t<-ifelse(a$post==0,a$year-2019,0)
tsdes<-domain(make_design(a,"w_main"),with(a,age50 & H==1 & !is.na(aid) & !is.na(age_sex) & !is.na(post)))
tsf<-svyglm(as.formula(paste("aid~0+",paste(c(paste0("pre_s",1:8),"pre_t",paste0("post_s",1:8)),collapse="+"))),tsdes,family=gaussian())
g<-setNames(rep(0,length(coef(tsf))),names(coef(tsf)));g[paste0("post_s",1:8)]<-std$p;g[paste0("pre_s",1:8)]<--std$p;g['pre_t']<--4.5
rows$trend_adjusted<-linear_result(tsf,g,"observed_post_minus_pretrend_projection");rows$trend_adjusted$status<-"PASS"
gs<-g*0;gs['pre_t']<-1;rows$pre_slope<-linear_result(tsf,gs,"pre_slope_pp_per_calendar_year");rows$pre_slope$status<-"PASS"
gp<-g*0;gp[paste0("pre_s",1:8)]<-std$p;gp['pre_t']<-4.5
projection<-linear_result(tsf,gp,"pretrend_projected_post_pct")
# These comparisons also belong to the frozen L3 competition table; L4 reuses them.
a$age_band<-factor(ifelse(a$AGEP_A>=50&a$AGEP_A<=69,"50-69",ifelse(a$AGEP_A>=80&a$AGEP_A<=85,"80+",NA)),levels=c("80+","50-69"))
ad<-domain(make_design(a,"w_main"),with(a,age50 & H==1 & !is.na(aid) & !is.na(age_band) & !is.na(sex) & !is.na(post)))
af<-svyglm(aid~post*age_band+sex,ad,family=gaussian())
for(grp in c("80+","50-69")){
 g<-setNames(rep(0,length(coef(af))),names(coef(af)));g['post']<-1
 if(grp=="50-69")g['post:age_band50-69']<-1
 r<-linear_result(af,g,paste0("age_",grp,"_change"));r$n_pre<-sum(ad$variables$post==0 & ad$variables$age_band==grp);r$n_post<-sum(ad$variables$post==1 & ad$variables$age_band==grp);r$status<-"PASS";rows[[paste0("age",grp)]]<-r
}
g<-setNames(rep(0,length(coef(af))),names(coef(af)));g['post:age_band50-69']<-1;rows$age_gradient<-linear_result(af,g,"age_gradient_50_69_minus80plus");rows$age_gradient$status<-"PASS"
med<-a$MEDICARE_A %in% 1:2 & a$AGEP_A>=65 & a$AGEP_A<=85
ma<-a$COVER65_A==3 | a$MCADVR_A==1 | ((a$MCCHOICE_A==1 | a$MCHMO_A==1) & !(a$MCADVR_A %in% 2))
ma[is.na(ma)]<-FALSE
tm<-a$MCADVR_A %in% 2 | (a$MCCHOICE_A %in% 2 & a$MCHMO_A %in% 2) | a$MCPART_A %in% 1
a$med_group<-factor(ifelse(med & ma,"MA",ifelse(med & tm & !ma,"Traditional",NA)),levels=c("MA","Traditional"))
md<-domain(make_design(a,"w_main"),with(a,med & H==1 & !is.na(aid) & !is.na(age_sex) & !is.na(med_group) & !is.na(post)))
mf<-svyglm(aid~post*med_group+age_sex,md,family=gaussian())
for(grp in c("MA","Traditional")){
 g<-setNames(rep(0,length(coef(mf))),names(coef(mf)));g['post']<-1
 if(grp=="Traditional")g['post:med_groupTraditional']<-1
 r<-linear_result(mf,g,paste0("Medicare_",grp,"_change"));r$n_pre<-sum(md$variables$post==0 & md$variables$med_group==grp);r$n_post<-sum(md$variables$post==1 & md$variables$med_group==grp);r$status<-"PASS";rows[[grp]]<-r
}
g<-setNames(rep(0,length(coef(mf))),names(coef(mf)));g['post:med_groupTraditional']<-1;rows$med_gradient<-linear_result(mf,g,"Traditional_minus_MA_change");rows$med_gradient$status<-"PASS"
va<-a$MILSPC1R_A %in% 1 | a$MILSPC2_A %in% 1
des<-make_design(a,"w_main");rows$VA<-estimate_change("aid",a$age50 & a$H==1 & va,"VA_or_TRICARE_change")
# Weighted descriptive levels retain their design SE; counts are unweighted.
level_rows<-list()
for(grp in c("MA","Traditional","VA_TRICARE"))for(per in 0:1){
 mask<-a$age50 & a$H==1 & !is.na(a$aid) & a$post==per & if(grp=="VA_TRICARE")va else a$med_group==grp
 dd<-domain(des,mask);m<-svymean(~aid,dd);se<-as.numeric(SE(m))*100;est<-as.numeric(coef(m))*100;cr<-qt(.975,degf(dd))
 level_rows[[paste(grp,per)]]<-data.frame(group=grp,post=per,estimate_pct=est,se_pp=se,ci_lower_pct=est-cr*se,ci_upper_pct=est+cr*se,unweighted_n=nrow(dd$variables),status="PASS")
}
fwrite(rbindlist(level_rows),file.path(out,"L3/insurance_descriptive_levels.csv"))
result<-rbindlist(rows,fill=TRUE)
delta<-status$primary$delta_pp;nc<-rows$negative_control$estimate_pp
downgrade<-sign(nc)==sign(delta) && abs(nc)>=0.5*abs(delta)
denom_sensitive<-sign(rows$all50_aid$estimate_pp)!=sign(delta) && rows$all50_aid$estimate_pp!=0 && delta!=0
result$negative_control_downgrade<-downgrade;result$denominator_sensitive<-denom_sensitive
result$policy_interpretation<-if(downgrade)"与全面服务反弹无法区分" else "未触发冻结阴性对照降级条件；仍不能识别政策因果效应"
fwrite(result,file.path(out,"L3/competing.csv"));fwrite(projection,file.path(out,"L3/pretrend_projection.csv"))
saveRDS(list(rows=rows,age_fit=af,med_fit=mf),file.path(root,"work/L3_models.rds"))
status$gates$L3<-"PASS";status$primary$negative_control_downgrade<-downgrade;status$primary$denominator_sensitive<-denom_sensitive
status$primary$policy_interpretation<-result$policy_interpretation[1];write_status(status);print(result)
