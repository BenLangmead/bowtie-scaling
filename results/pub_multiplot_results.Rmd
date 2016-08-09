root<-'C:/bowtie-scaling'
library(dplyr)
library(ggplot2)
library(gridExtra)
library(grid)

#from http://stackoverflow.com/questions/13649473/add-a-common-legend-for-combined-ggplots
grid_arrange_shared_legend <- function(...) {
    plots <- list(...)
    g <- ggplotGrob(plots[[1]] + theme(legend.position="bottom"))$grobs
    legend <- g[[which(sapply(g, function(x) x$name) == "guide-box")]]
    lheight <- sum(legend$height)
    grid.arrange(
        do.call(arrangeGrob, lapply(plots, function(x)
            x + theme(legend.position="none"))),
        legend,
        ncol = 1,
        heights = unit.c(unit(1, "npc") - lheight, lheight))
}

width1<-13
height1<-13

#three sets of plots, one where parsing is held constant (original parsing), lock is held constant (TBB queuing lock), and finally one for both locks and parsing mixed (all)
for(variable_ in c("_locks","_parsing",""))
{
    m2 <- read.table(paste(root,'/results/elephant6/pub/pub_runs',variable_,'.tsv',sep=""), header=T, sep='\t')
    m <- read.table(paste(root,'/results/marcc/pub/pub_runs',variable_,'.tsv',sep=""), header=T, sep='\t')
    #unp=unpaired, pe=paired end
    for(pairing_ in c("unp","pe"))
    {
        #plot both machines three alingers, one plot; this works with shared legend
        pdf(paste(paste(root,"/results/all_",pairing_,variable_,".pdf",sep=""),sep=""), width=width1, height=height1, paper='a4r', onefile=FALSE)
        p<-list()
        i<-1
        for(tool_ in c("bowtie","bowtie2","hisat"))
        {
            mtmp <- m %>% filter(tool == tool_ & paired == pairing_)
            m2tmp <- m2 %>% filter(tool == tool_ & paired == pairing_)
            p[[i]]<-ggplot(mtmp, aes(x=threads, y=seconds, linetype=version, color=lock), log="y") + geom_line() + geom_point() + labs(y="Normalized running time", x=paste(tool_," # threads",sep=""))
            i<-i+1
            p[[i]]<-ggplot(m2tmp, aes(x=threads, y=seconds, linetype=version, color=lock), log="y") + geom_line() + geom_point() + labs(y="Normalized running time", x=paste(tool_," # threads",sep=""))
          
            if(variable_ == '_parsing')
            {
                i<-i-1
                p[[i]]<-ggplot(mtmp, aes(x=threads, y=seconds, linetype=lock, color=version), log="y") + geom_line() + geom_point() + labs(y="Normalized running time", x=paste(tool_," # threads",sep=""))
                i<-i+1
                p[[i]]<-ggplot(m2tmp, aes(x=threads, y=seconds, linetype=lock, color=version), log="y") + geom_line() + geom_point() + labs(y="Normalized running time", x=paste(tool_," # threads",sep=""))
            }
            i<-i+1
        }
        grid_arrange_shared_legend(p[[1]],p[[2]],p[[3]],p[[4]],p[[5]],p[[6]])
        dev.off()
    }
}