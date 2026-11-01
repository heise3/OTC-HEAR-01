source(file.path(dirname(sub("^--file=","",commandArgs(FALSE)[grep("^--file=",commandArgs(FALSE))])),"analysis_common.R"))
status<-read_status();stopifnot(status$terminal,all(unlist(status$gates)=="PASS"))
d<-get_data();obj<-readRDS(file.path(root,"work/L2_model.rds"));fit<-obj$fit
X<-model.matrix(fit);dd<-fit$survey.design$variables;w<-as.numeric(weights(fit$survey.design));y<-dd$aid
Ainv<-solve(crossprod(X,X*w));b<-as.numeric(Ainv%*%crossprod(X,w*y))
stopifnot(max(abs(b-coef(fit)))<1e-9)
j<-which(colnames(X)=="post");u<-as.numeric(w*(y-X%*%b)*(X%*%Ainv[,j]))
cluster_score<-aggregate(u,list(PSTRAT=dd$PSTRAT,PPSU=dd$PPSU),sum);names(cluster_score)[3]<-"u"
full<-unique(d[d$year %in% c(2019,2021,2022,2023,2024),c("PSTRAT","PPSU")])
cs<-merge(full,cluster_score,all.x=TRUE);cs$u[is.na(cs$u)]<-0
vmanual<-sum(vapply(split(cs$u,cs$PSTRAT),function(z){stopifnot(length(z)>1);length(z)/(length(z)-1)*sum((z-mean(z))^2)},numeric(1)))
se_manual_pp<-sqrt(vmanual)*100;se_survey_pp<-sqrt(vcov(fit)[j,j])*100
stopifnot(abs(se_manual_pp-se_survey_pp)<1e-8)
l0<-fread(file.path(out,"L0/counts.csv"));main<-fread(file.path(out,"L2/main_estimate.csv"))
stopifnot(sum(l0[gate=="H_main_complete_year" & period=="pre",unweighted_n])==main$unweighted_pre_n,
          sum(l0[gate=="H_main_complete_year" & period=="post",unweighted_n])==main$unweighted_post_n)
secondary<-fread(file.path(out,"L4/secondary.csv"));fits<-readRDS(file.path(root,"work/L4_models.rds"))$income_fits
q<-sapply(fits,function(f)coef(f)['post:income_groupLow']*100)
uv<-sapply(fits,function(f)vcov(f)['post:income_groupLow','post:income_groupLow']*10000)
rubin_se<-sqrt(mean(uv)+(1+1/10)*var(q));reported<-secondary[estimand=="income_low_minus_high_DiD"]
stopifnot(abs(mean(q)-reported$estimate_pp)<1e-9,abs(rubin_se-reported$se_pp)<1e-9)
event<-fread(file.path(out,"L2/event_study.csv"));stopifnot(nrow(event)==7,all(is.finite(event$se_pp)),all(event$estimate_pp>=0 & event$estimate_pp<=100))
qa<-data.frame(check=c("independent_WLS_point_calculation","independent_WR_PSU_linearization_SE_pp","Python_R_main_domain_counts","manual_Rubin_pooling_DiD_SE_pp","event_years_and_finite_results"),
 value=c(max(abs(b-coef(fit))),se_manual_pp,main$unweighted_pre_n+main$unweighted_post_n,rubin_se,nrow(event)),
 reference=c(0,se_survey_pp,23403,reported$se_pp,7),status="PASS")
fwrite(qa,file.path(out,"logs/numeric_QA.csv"));print(qa)
