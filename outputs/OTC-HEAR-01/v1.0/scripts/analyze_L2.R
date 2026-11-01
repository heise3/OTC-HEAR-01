source(file.path(dirname(sub("^--file=","",commandArgs(FALSE)[grep("^--file=",commandArgs(FALSE))])),"analysis_common.R"))
status<-read_status();stopifnot(status$gates$L1=="PASS")
d<-get_data();std<-get_standard(d);fwrite(std$table,file.path(out,"L2/standard_population.csv"))
des<-main_domain(d);fit<-svyglm(aid~post+age_sex,design=des,family=gaussian())
g0<-marginal_gradient(fit,make_cells(d,std,post=0),std$p);g1<-marginal_gradient(fit,make_cells(d,std,post=1),std$p)
pre<-linear_result(fit,g0,"pre_standardized_pct");post<-linear_result(fit,g1,"post_standardized_pct")
delta<-linear_result(fit,g1-g0,"post_minus_pre")
stopifnot(abs(delta$estimate_pp-100*coef(fit)["post"])<1e-10)
lo<-delta$ci_lower_pp;hi<-delta$ci_upper_pp
conclusion<-if(lo>(-2.5) && hi<2.5)"全国层面无有意义变化（等效成立）" else if(lo>2.5)"有意义上升" else if(lo>0 && hi>=2.5)"上升，但幅度可能小于有意义阈值" else "不确定，报告可排除的最大幅度"
delta$conclusion<-conclusion;delta$pre_standardized_pct<-pre$estimate_pp;delta$post_standardized_pct<-post$estimate_pp
delta$unweighted_pre_n<-sum(des$variables$post==0);delta$unweighted_post_n<-sum(des$variables$post==1)
delta$largest_increase_not_excluded_pp<-hi;delta$largest_decrease_magnitude_not_excluded_pp<-max(0,-lo)
fwrite(delta,file.path(out,"L2/main_estimate.csv"));fwrite(rbind(pre,post),file.path(out,"L2/period_rates.csv"))
saveRDS(list(fit=fit,delta=delta,standard=std),file.path(root,"work/L2_model.rds"))
# A saturated year by age-sex model gives direct standardization in each year.
eventdes<-domain(make_design(d,"w_event"),with(d,age50 & H==1 & !is.na(aid) & !is.na(age_sex) & (year!=2022 | INTV_QRT %in% 1:3)))
efit<-svyglm(aid~yearF*age_sex,design=eventdes,family=gaussian())
events<-rbindlist(lapply(2019:2025,function(y){
 g<-marginal_gradient(efit,make_cells(d,std,year=y),std$p)
 r<-linear_result(efit,g,paste0("year",y));r$year<-y;r$unweighted_n<-sum(eventdes$variables$year==y)
 r$analysis_role<-if(y==2020)"display_only" else if(y==2025)"extension_only" else if(y==2022)"pre_Q1_Q3" else "main_window";r
}))
fwrite(events,file.path(out,"L2/event_study.csv"));saveRDS(efit,file.path(root,"work/L2_event_model.rds"))
status$gates$L2<-"PASS";status$primary<-list(delta_pp=delta$estimate_pp,ci=list(lo,hi),conclusion=conclusion,
 pre_standardized_pct=pre$estimate_pp,post_standardized_pct=post$estimate_pp)
write_status(status);print(delta);print(events)
