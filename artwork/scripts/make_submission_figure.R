suppressPackageStartupMessages(library(data.table))
argfile<-sub("^--file=","",commandArgs(FALSE)[grep("^--file=",commandArgs(FALSE))])
out<-normalizePath(file.path(dirname(argfile),".."))
event<-fread(file.path(out,"source_data/event_study.csv"))
main<-fread(file.path(out,"source_data/main_estimate.csv"))
comp<-fread(file.path(out,"source_data/competing.csv"))
secondary<-fread(file.path(out,"source_data/secondary.csv"))
period<-fread(file.path(out,"source_data/period_rates.csv"))
rows<-rbindlist(list(
 main[,.(estimate_pp,ci_lower_pp,ci_upper_pp)],
 comp[estimand=="observed_post_minus_pretrend_projection",.(estimate_pp,ci_lower_pp,ci_upper_pp)],
 comp[estimand=="adjusted_for_interview_mode",.(estimate_pp,ci_lower_pp,ci_upper_pp)],
 comp[estimand=="aid_all50plus",.(estimate_pp,ci_lower_pp,ci_upper_pp)],
 comp[estimand=="H_prevalence_all50plus",.(estimate_pp,ci_lower_pp,ci_upper_pp)],
 comp[estimand=="eyeglasses_all50plus",.(estimate_pp,ci_lower_pp,ci_upper_pp)],
 secondary[estimand=="extension2025_minus_pre",.(estimate_pp,ci_lower_pp,ci_upper_pp)],
 secondary[estimand=="income_low_minus_high_DiD",.(estimate_pp,ci_lower_pp,ci_upper_pp)]))
labels<-c("Primary: hearing aid use","Departure from prerule trend","Adjusted for interview mode","Hearing aid use, all adults aged ≥50 y","Hearing difficulty or aid use,\nall adults aged ≥50 y","Eyeglass use (negative control)","2025 vs prerule","Low- minus high-income change")
rows$label<-labels;fwrite(rows,file.path(out,"figure_source_values.csv"))
minus<-function(s)gsub("-","−",s,fixed=TRUE)
draw<-function(){
 layout(matrix(c(1,2),2,1),heights=c(1,1.25))
 par(family="sans",las=1,cex=.82,fg="#252525",col.axis="#252525",col.lab="#252525",mgp=c(2.15,.65,0))
 par(mai=c(.47,.76,.37,.32))
 x<-event$year+.5;x[event$year==2022]<-2022.375
 plot(x,event$estimate_pp,type="n",xlim=c(2019.0,2025.95),ylim=c(28.6,35.6),xaxt="n",yaxt="n",bty="l",xlab="",ylab="Hearing aid use, % (95% CI)")
 abline(h=29:35,col="#e4e4e4",lwd=.6);axis(1,at=2019:2025+.5,labels=2019:2025,tck=-.018,cex.axis=.88);axis(2,at=c(29,31,33,35),tck=-.018)
 policy<-2022+289/365;abline(v=policy,col="#818181",lwd=.9)
 text(policy+.05,35.35,"OTC rule effective\nOctober 17, 2022",adj=c(0,1),cex=.72,col="#666666")
 pre<-period[estimand=="pre_standardized_pct",estimate_pp];post<-period[estimand=="post_standardized_pct",estimate_pp]
 segments(2019.2,pre,2022.60,pre,lty=2,lwd=1,col="#333333");segments(2023.2,post,2024.85,post,lty=2,lwd=1,col="#2466aa")
 colors<-ifelse(event$year %in% c(2020,2025),"#8a8a8a",ifelse(event$year>=2023,"#2466aa","#252525"))
 arrows(x,event$ci_lower_pp,x,event$ci_upper_pp,angle=90,code=3,length=.025,col=colors,lwd=1)
 points(x,event$estimate_pp,pch=ifelse(event$year %in% c(2020,2025),21,19),bg=ifelse(event$year %in% c(2020,2025),"white",colors),col=colors,cex=.9,lwd=1.2)
 text(2022.87,pre,sprintf("Prerule\n%.1f%%",pre),adj=c(0,.5),cex=.72);text(2024.91,post,sprintf("Postrule\n%.1f%%",post),adj=c(0,.5),cex=.72,col="#2466aa")
 mtext("A  Annual age- and sex-standardized hearing aid use",side=3,line=1.0,adj=0,font=2,cex=.92)
 par(mai=c(.64,2.73,.40,1.24))
 yy<-8:1
 plot(0,0,type="n",xlim=c(-4.75,4.9),ylim=c(.45,8.85),xaxt="n",yaxt="n",bty="n",xlab="",ylab="")
 # Only the primary analysis has the frozen equivalence criterion.
 rect(-2.5,7.64,2.5,8.36,col="#e8eef7",border=NA);segments(c(-2.5,2.5),7.64,c(-2.5,2.5),8.36,lty=3,col="#7f9cbd")
 abline(v=0,col="#999999",lwd=.7)
 segments(rows$ci_lower_pp,yy,rows$ci_upper_pp,yy,col=c("#2466aa",rep("#252525",7)),lwd=c(1.8,rep(1.1,7)))
 points(rows$estimate_pp,yy,pch=c(15,rep(19,7)),col=c("#2466aa",rep("#252525",7)),cex=.8)
 segments(-4.75,7.5,4.9,7.5,col="#d9d9d9",lwd=.6)
 axis(1,at=c(-4,-2,0,2,4),labels=c("−4","−2","0","2","4"),tck=-.018,lwd=.7,pos=.48)
 mtext("Change, percentage points (95% CI)",side=1,line=2,cex=.82)
 par(xpd=NA)
 for(i in seq_along(yy)){
  text(-4.90,yy[i],labels[i],adj=c(1,.5),cex=.77,font=ifelse(i==1,2,1))
  value<-minus(sprintf("%.1f (%.1f to %.1f)",rows$estimate_pp[i],rows$ci_lower_pp[i],rows$ci_upper_pp[i]))
  text(5.18,yy[i],value,adj=c(0,.5),cex=.73,col=ifelse(i==1,"#2466aa","#252525"))
 }
 text(0,8.65,"Primary equivalence bounds: ±2.5",cex=.65,col="#526b8b")
 mtext("B  Changes from the prerule period",side=3,line=1.05,adj=0,font=2,cex=.92,at=-12.8)
}
cairo_pdf(file.path(out,"Figure_OTC_HEAR_01.pdf"),width=6.8,height=5.9,family="sans");draw();dev.off()
svg(file.path(out,"Figure_OTC_HEAR_01.svg"),width=6.8,height=5.9);draw();dev.off()
png(file.path(out,"Figure_OTC_HEAR_01.png"),width=6.8,height=5.9,units="in",res=200,type="cairo");draw();dev.off()
# R's supplied Cairo build has no TIFF writer. Export600dpi without resampling;
# export_tiff.py packages the exact raster into lossless LZW TIFF.
png(file.path(out,".Figure_OTC_HEAR_01_600dpi.png"),width=6.8,height=5.9,units="in",res=600,type="cairo");draw();dev.off()
