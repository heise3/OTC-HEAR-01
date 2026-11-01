suppressPackageStartupMessages({library(survey);library(data.table);library(jsonlite)})
options(survey.lonely.psu="fail")
args<-commandArgs(trailingOnly=FALSE)
script<-sub("^--file=","",args[grep("^--file=",args)])
root<-normalizePath(file.path(dirname(script),"../../../.."))
out<-file.path(root,"outputs/OTC-HEAR-01/v1.0")
status<-fromJSON(file.path(out,"status.json"),simplifyVector=FALSE)
stopifnot(status$gates$L0=="PASS")
d<-as.data.frame(fread(file.path(root,"work/nhis_data/adult19.csv")))
d$aid<-ifelse(d$HEARAID_A %in% c(1,2),as.numeric(d$HEARAID_A==1),NA_real_)
d$some<-ifelse(d$HEARINGDF_A %in% 1:4,as.numeric(d$HEARINGDF_A==2),NA_real_)
d$severe<-ifelse(d$HEARINGDF_A %in% 1:4,as.numeric(d$HEARINGDF_A %in% c(3,4)),NA_real_)
des<-svydesign(ids=~PPSU,strata=~PSTRAT,weights=~WTFA_A,nest=TRUE,data=d)
targets<-data.frame(target=c("aid45plus","aid65plus","aid65plus_male","aid65plus_female","some18plus","severe18plus"),
                    published_pct=c(7.1,14.4,19.2,10.6,13.0,1.6),
                    published_lower=c(6.7,13.6,17.8,9.7,12.5,1.5),
                    published_upper=c(7.5,15.2,20.6,11.5,13.5,1.8),
                    source_pdf_page=c(4,4,4,4,1,1))
fwrite(targets,file.path(out,"L1/official_targets.csv"))
masks<-list(d$AGEP_A>=45 & d$AGEP_A<=85,d$AGEP_A>=65 & d$AGEP_A<=85,
             d$AGEP_A>=65 & d$AGEP_A<=85 & d$SEX_A==1,d$AGEP_A>=65 & d$AGEP_A<=85 & d$SEX_A==2,
             rep(TRUE,nrow(d)),rep(TRUE,nrow(d)))
ys<-c("aid","aid","aid","aid","some","severe")
rows<-lapply(seq_len(nrow(targets)),function(i){
  mask<-masks[[i]] & !is.na(d[[ys[i]]]);mask[is.na(mask)]<-FALSE
  dd<-des[mask,];fit<-svymean(as.formula(paste0("~",ys[i])),dd)
  est<-100*as.numeric(coef(fit));se<-100*as.numeric(SE(fit));crit<-qt(.975,degf(dd))
  cbind(targets[i,],estimate_pct=est,se_pp=se,ci_lower_pct=est-crit*se,ci_upper_pct=est+crit*se,
        unweighted_n=sum(mask),design_df=degf(dd),status=if(est>=targets$published_lower[i] && est<=targets$published_upper[i])"PASS" else "CALIBRATION_FAIL")
})
result<-rbindlist(rows);fwrite(result,file.path(out,"L1/calibration.csv"))
passed<-all(result$status=="PASS");status$gates$L1<-if(passed)"PASS" else "CALIBRATION_FAIL"
if(!passed){status$terminal<-TRUE;status$decision<-"CALIBRATION_FAIL"}
status$updated_at_utc<-format(Sys.time(),tz="UTC",usetz=TRUE)
write_json(status,file.path(out,"status.json"),auto_unbox=TRUE,pretty=TRUE,null="null")
print(result)
writeLines(capture.output(sessionInfo()),file.path(out,"logs/R_sessionInfo.txt"))
