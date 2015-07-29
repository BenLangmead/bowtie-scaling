pdf(file='tt_normal.pdf')
xy <- read.table('tt_normal.tsv')
plot(xy$V1, jitter(xy$V2, factor=3), ylim=c(0, 160), col=xy$V3,
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no input locking')
dev.off()

pdf(file='tt_no_in.pdf')
xy <- read.table('tt_no_in.tsv')
plot(xy$V1, jitter(xy$V2, factor=3), ylim=c(0, 160), col=xy$V3,
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no input locking')
dev.off()

pdf(file='tt_no_io.pdf')
xy <- read.table('tt_no_io.tsv')
plot(xy$V1, jitter(xy$V2, factor=3), ylim=c(0, 160), col=xy$V3,
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no input locking')
dev.off()
