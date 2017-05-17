root<-'F:/bowtie-scaling'
#source<-'langmead-bigmem/'
source<-'stampede_knl_new/'
detach("package:plyr",unload=TRUE)
library(dplyr)
library(ggplot2)
library(ggrepel)

baseline <- read.delim("F:/bowtie-scaling/new_results/stampede_knl/pub_final.run.tsv.baseline.tsv")
parsing <- read.delim("F:/bowtie-scaling/new_results/stampede_knl/pub_final.run.tsv.parsing.tsv")
final <- read.delim("F:/bowtie-scaling/new_results/stampede_knl/pub_final.run.tsv.final.tsv")

multip(c('bowtie2','hisat','bowtie'),c('unp','pe'),c('baseline','parsing','final'))

multip<-function(tools,pairs,vars)
{

  for(tool1 in tools)
  {
    for(paired1 in pairs)
    {
      for(variable1 in vars)
      {
        if(variable1 == 'bwa' & tool1 != 'bowtie2')
          next
        dsource = baseline
        dsource_flag = 0
        if(variable1 == 'parsing')
        {
          dsource = parsing
          dsource_flag = 1
        }
        if(variable1 == 'final')
        {
          dsource = final
        }
        mtmp <- dsource %>% filter(tool == tool1 & paired == paired1)
        mop_<-findop(dsource,tool1,paired1)
        pdf(paste(root,"/results/",source,tool1,"_",paired1,"_",variable1,".pdf",sep=""), width=width1, height=height1, paper='a4r', onefile=TRUE)
        plotme(mtmp,mop_,dsource_flag)
        dev.off()
      }
    }
  }
}

plotme<-function(d,mop,i)
{
    if(i == 1)
    {
        print(ggplot(d, aes(x=threads, y=seconds, color=version, linetype=lock)) +
          geom_line() + theme_bw() +
          labs(y="Normalized running time", x="# threads") +
          coord_cartesian(ylim=c(0, max(d$seconds)*1.05)) +
          #coord_cartesian(ylim=c(0, 50)) +
          geom_point(data=mop) + 
          geom_text_repel(data=mop,aes(label=round(mop$optimal,1),vjust=+1.5)))
    }
    else
    {
      print(ggplot(d, aes(x=threads, y=seconds, color=lock, linetype=version)) +
        geom_line() + theme_bw() +
        labs(y="Normalized running time", x="# threads") +
        coord_cartesian(ylim=c(0, max(d$seconds)*1.05)) +
        geom_point(data=mop) + 
        geom_text_repel(data=mop,aes(label=round(mop$optimal,1),vjust=+1.5)))
    }
}

findop<-function(m,tool_,paired_)
{
  mtmp <- mutate(filter(m, tool == tool_ & paired == paired_), optimal = (threads/seconds))
  mtmp_by_line <- group_by(mtmp, lock, version)
  mtmp_optimal <- summarise(mtmp_by_line, opti = max(optimal))
  m3<-list()
  for(i in 1:nrow(mtmp_optimal)) { n<-mtmp_optimal[i,]; m_<-filter(mtmp, optimal==n$opti); m3[[length(m3)+1]]<-m_ }
  
  #WARNING: including plyr overrides dplyr's functions, will cause problems if you try
  #to continue to use dplyr after this
  library(plyr)
  m3a<-ldply(m3,data.frame)
  detach("package:plyr",unload=TRUE)
  return (m3a)
}

width1=13
height1=13







#Bowtie2 unp lock
tool1='bowtie2'
paired1='unp'
variable1='locks'
mtmp <- locks %>% filter(tool == tool1 & paired == paired1)
mop_<-findop(locks,tool1,paired1)
pdf(paste(root,"/results/",source,tool1,"_",paired1,"_",variable1,".pdf",sep=""), width=width1, height=height1, paper='a4r', onefile=FALSE)
plotme(mtmp,mop_,0)
dev.off()

#Bowtie2 pe lock
paired1='pe'
mtmp <- locks %>% filter(tool == tool1 & paired == paired1)
mop_<-findop(locks,tool1,paired1)
pdf(paste(root,"/results/",source,tool1,"_",paired1,"_",variable1,".pdf",sep=""), width=width1, height=height1, paper='a4r', onefile=FALSE)
plotme(mtmp,mop_,0)
dev.off()


#Bowtie2 unp parsing
variable1='parsing'
paired1='unp'
mtmp <- parsing %>% filter(tool == tool1 & paired == paired1)
mop_<-findop(parsing,tool1,paired1)
pdf(paste(root,"/results/",source,tool1,"_",paired1,"_",variable1,".pdf",sep=""), width=width1, height=height1, paper='a4r', onefile=FALSE)
plotme(mtmp,mop_,1)
dev.off()

#Bowtie2 pe parsing
paired1='pe'
mtmp <- parsing %>% filter(tool == tool1 & paired == paired1)
mop_<-findop(parsing,tool1,paired1)
pdf(paste(root,"/results/",source,tool1,"_",paired1,"_",variable1,".pdf",sep=""), width=width1, height=height1, paper='a4r', onefile=FALSE)
plotme(mtmp,mop_,1)
dev.off()



#Hisat unp lock
tool1='hisat'
paired1='unp'
variable1='locks'
mtmp <- locks %>% filter(tool == tool1 & paired == paired1)
mop_<-findop(locks,tool1,paired1)
pdf(paste(root,"/results/",source,tool1,"_",paired1,"_",variable1,".pdf",sep=""), width=width1, height=height1, paper='a4r', onefile=FALSE)
plotme(mtmp,mop_,0)
dev.off()

#Hisat pe lock
paired1='pe'
mtmp <- locks %>% filter(tool == tool1 & paired == paired1)
mop_<-findop(locks,tool1,paired1)
pdf(paste(root,"/results/",source,tool1,"_",paired1,"_",variable1,".pdf",sep=""), width=width1, height=height1, paper='a4r', onefile=FALSE)
plotme(mtmp,mop_,0)
dev.off()


#Hisat unp parsing
variable1='parsing'
paired1='unp'
mtmp <- parsing %>% filter(tool == tool1 & paired == paired1)
mop_<-findop(parsing,tool1,paired1)
pdf(paste(root,"/results/",source,tool1,"_",paired1,"_",variable1,".pdf",sep=""), width=width1, height=height1, paper='a4r', onefile=FALSE)
plotme(mtmp,mop_,1)
dev.off()

#Hisat pe parsing
paired1='pe'
mtmp <- parsing %>% filter(tool == tool1 & paired == paired1)
mop_<-findop(parsing,tool1,paired1)
pdf(paste(root,"/results/",source,tool1,"_",paired1,"_",variable1,".pdf",sep=""), width=width1, height=height1, paper='a4r', onefile=FALSE)
plotme(mtmp,mop_,1)
dev.off()



#Bowtie1 unp lock
tool1='bowtie'
paired1='unp'
variable1='locks'
mtmp <- locks %>% filter(tool == tool1 & paired == paired1)
mop_<-findop(locks,tool1,paired1)
pdf(paste(root,"/results/",source,tool1,"_",paired1,"_",variable1,".pdf",sep=""), width=width1, height=height1, paper='a4r', onefile=FALSE)
plotme(mtmp,mop_,0)
dev.off()

#Bowtie1 pe lock
paired1='pe'
mtmp <- locks %>% filter(tool == tool1 & paired == paired1)
mop_<-findop(locks,tool1,paired1)
pdf(paste(root,"/results/",source,tool1,"_",paired1,"_",variable1,".pdf",sep=""), width=width1, height=height1, paper='a4r', onefile=FALSE)
plotme(mtmp,mop_,0)
dev.off()


#Bowtie1 unp parsing
variable1='parsing'
paired1='unp'
mtmp <- parsing %>% filter(tool == tool1 & paired == paired1)
mop_<-findop(parsing,tool1,paired1)
pdf(paste(root,"/results/",source,tool1,"_",paired1,"_",variable1,".pdf",sep=""), width=width1, height=height1, paper='a4r', onefile=FALSE)
plotme(mtmp,mop_,1)
dev.off()

#Bowtie1 pe parsing
paired1='pe'
mtmp <- parsing %>% filter(tool == tool1 & paired == paired1)
mop_<-findop(parsing,tool1,paired1)
pdf(paste(root,"/results/",source,tool1,"_",paired1,"_",variable1,".pdf",sep=""), width=width1, height=height1, paper='a4r', onefile=FALSE)
plotme(mtmp,mop_,1)
dev.off()
