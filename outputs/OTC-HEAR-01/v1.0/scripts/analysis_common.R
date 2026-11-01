suppressPackageStartupMessages({library(survey);library(data.table);library(jsonlite)})
options(survey.lonely.psu="fail")
argfile<-sub("^--file=","",commandArgs(FALSE)[grep("^--file=",commandArgs(FALSE))])
root<-normalizePath(file.path(dirname(argfile),"../../../.."));out<-file.path(root,"outputs/OTC-HEAR-01/v1.0")
read_status<-function()fromJSON(file.path(out,"status.json"),simplifyVector=FALSE)
write_status<-function(s){s$updated_at_utc<-format(Sys.time(),tz="UTC",usetz=TRUE);write_json(s,file.path(out,"status.json"),auto_unbox=TRUE,pretty=TRUE,null="null")}
make_design<-function(d,weight="WTFA_A")svydesign(ids=~PPSU,strata=~PSTRAT,weights=as.formula(paste0("~",weight)),nest=TRUE,data=d)
get_data<-function(){
 cache<-file.path(root,"work/analysis_prepared.rds")
 if(file.exists(cache))return(readRDS(cache))
 cols<-c("HHX","WTFA_A","PSTRAT","PPSU","AGEP_A","SEX_A","HEARAID_A","HEARINGDF_A","HEARAIDFR_A","WEARGLSS_A","INTV_QRT","INTV_QRT2","MEDICARE_A","MCCHOICE_A","MCHMO_A","MCADVR_A","MCPART_A","COVER65_A","MILSPC1R_A","MILSPC2_A","AVAIL_A","PROXY_A","PROXYFLAG_A")
 ds<-lapply(2019:2025,function(y){
   f<-file.path(root,sprintf("work/nhis_data/adult%02d.csv",y%%100));names<-names(fread(f,nrows=0))
   d<-fread(f,select=intersect(cols,names),colClasses=list(character="HHX"));d$year<-y
   para<-fread(file.path(root,sprintf("work/nhis_data/paradata%02d.csv",y%%100)),select=c("HHX","INTMODESA"),colClasses=list(character="HHX"))
   merge(d,para,by="HHX",all.x=TRUE,sort=FALSE)
 })
 d<-as.data.frame(rbindlist(ds,fill=TRUE));stopifnot(!anyDuplicated(paste(d$year,d$HHX)))
 d$aid<-ifelse(d$HEARAID_A %in% c(1,2),as.numeric(d$HEARAID_A==1),NA_real_)
 d$H<-ifelse(d$HEARAID_A==1 | d$HEARINGDF_A %in% 2:4,1,
             ifelse(d$HEARAID_A==2 & d$HEARINGDF_A==1,0,NA_real_))
 d$glasses<-ifelse(d$WEARGLSS_A %in% 1:2,as.numeric(d$WEARGLSS_A==1),NA_real_)
 d$always<-ifelse(d$HEARAIDFR_A %in% 1:4,as.numeric(d$HEARAIDFR_A==1),NA_real_)
 d$age_valid<-!is.na(d$AGEP_A) & d$AGEP_A>=18 & d$AGEP_A<=85
 d$age50<-d$age_valid & d$AGEP_A>=50
 d$age4<-cut(ifelse(d$age50,d$AGEP_A,NA_real_),breaks=c(49,64,74,84,85),labels=c("50-64","65-74","75-84","85+"))
 d$sex<-factor(ifelse(d$SEX_A %in% 1:2,d$SEX_A,NA),levels=1:2,labels=c("Male","Female"))
 d$age_sex<-interaction(d$age4,d$sex,sep="_",drop=FALSE)
 pre<-d$year %in% c(2019,2021) | (d$year==2022 & d$INTV_QRT %in% 1:3)
 d$post<-ifelse(pre,0,ifelse(d$year %in% c(2023,2024),1,NA_real_))
 d$w_main<-d$WTFA_A/ifelse(d$post==1 & !is.na(d$post),2,2.75)
 d$w_standard<-d$WTFA_A/6
 d$w_event<-d$WTFA_A*ifelse(d$year==2022,4/3,1)
 d$yearF<-factor(d$year,levels=2019:2025)
 saveRDS(d,cache);d
}
domain<-function(des,mask){mask[is.na(mask)]<-FALSE;des[mask,]}
linear_result<-function(fit,g,label="estimate",scale=100){
 b<-coef(fit);v<-vcov(fit);stopifnot(!anyNA(b),length(g)==length(b))
 est<-as.numeric(g%*%b)*scale;se<-sqrt(as.numeric(g%*%v%*%g))*scale
 df<-fit$df.residual;crit<-qt(.975,df)
 data.frame(estimand=label,estimate_pp=est,se_pp=se,ci_lower_pp=est-crit*se,ci_upper_pp=est+crit*se,df=df)
}
marginal_gradient<-function(fit,newdata,p){
 mm<-model.matrix(delete.response(terms(fit)),newdata,contrasts.arg=fit$contrasts,xlev=fit$xlevels)
 as.numeric(crossprod(p,mm))
}
get_standard<-function(d){
 s<-domain(make_design(d[d$year<=2024,],"w_standard"),with(d[d$year<=2024,],age50 & H==1 & !is.na(age_sex)))
 fit<-svymean(~age_sex,s)
 p<-as.numeric(coef(fit));lev<-levels(d$age_sex)
 tab<-data.frame(age_sex=lev,standard_share=p,standard_share_se=as.numeric(SE(fit)),unweighted_n=as.integer(table(s$variables$age_sex)))
 list(p=p,lev=lev,table=tab)
}
main_domain<-function(d)domain(make_design(d[d$year %in% c(2019,2021,2022,2023,2024),],"w_main"),
 with(d[d$year %in% c(2019,2021,2022,2023,2024),],age50 & H==1 & !is.na(aid) & !is.na(age_sex) & !is.na(post)))
make_cells<-function(d,std,post=NULL,year=NULL){
 nd<-data.frame(age_sex=factor(std$lev,levels=levels(d$age_sex)))
 if(!is.null(post))nd$post<-post
 if(!is.null(year))nd$yearF<-factor(year,levels=levels(d$yearF))
 nd
}
