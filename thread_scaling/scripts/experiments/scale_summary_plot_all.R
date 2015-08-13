pdf(file='fast_normal.pdf')
xy <- read.table('fast_normal.tsv')
plot(xy$V1, xy$V2,
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread',
        sub='bowtie2 fast mode')
dev.off()

pdf(file='fast_no_in.pdf')
xy <- read.table('fast_no_in.tsv')
plot(xy$V1, xy$V2,
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no input locking',
        sub='bowtie2 fast mode')
dev.off()

pdf(file='fast_no_io.pdf')
xy <- read.table('fast_no_io.tsv')
plot(xy$V1, xy$V2, 
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no I/O locking',
        sub='bowtie2 fast mode')
dev.off()

pdf(file='sensitive_normal.pdf')
xy <- read.table('sensitive_normal.tsv')
plot(xy$V1, xy$V2,
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread',
        sub='bowtie2 sensitive mode')
dev.off()

pdf(file='sensitive_no_in.pdf')
xy <- read.table('sensitive_no_in.tsv')
plot(xy$V1, xy$V2,
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no input locking',
        sub='bowtie2 sensitive mode')
dev.off()

pdf(file='sensitive_no_io.pdf')
xy <- read.table('sensitive_no_io.tsv')
plot(xy$V1, xy$V2, 
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no I/O locking',
        sub='bowtie2 sensitive mode')
dev.off()

pdf(file='very-fast_normal.pdf')
xy <- read.table('very-fast_normal.tsv')
plot(xy$V1, xy$V2,
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread',
        sub='bowtie2 very-fast mode')
dev.off()

pdf(file='very-fast_no_in.pdf')
xy <- read.table('very-fast_no_in.tsv')
plot(xy$V1, xy$V2,
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no input locking',
        sub='bowtie2 very-fast mode')
dev.off()

pdf(file='very-fast_no_io.pdf')
xy <- read.table('very-fast_no_io.tsv')
plot(xy$V1, xy$V2, 
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no I/O locking',
        sub='bowtie2 very-fast mode')
dev.off()

pdf(file='very-sensitive_normal.pdf')
xy <- read.table('very-sensitive_normal.tsv')
plot(xy$V1, xy$V2,
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread',
        sub='bowtie2 very-sensitive mode')
dev.off()

pdf(file='very-sensitive_no_in.pdf')
xy <- read.table('very-sensitive_no_in.tsv')
plot(xy$V1, xy$V2,
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no input locking',
        sub='bowtie2 very-sensitive mode')
dev.off()

pdf(file='very-sensitive_no_io.pdf')
xy <- read.table('very-sensitive_no_io.tsv')
plot(xy$V1, xy$V2, 
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no I/O locking',
        sub='bowtie2 very-sensitive mode')
dev.off()




