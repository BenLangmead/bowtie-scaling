pdf(file='thread_times_no_I.pdf')
xy <- read.table('thread_times_no_I.tsv')
plot(xy$V1, jitter(xy$V2, factor=3), ylim=c(0, 160),
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no input locking')
dev.off()

pdf(file='thread_times_no_IO.pdf')
xy <- read.table('thread_times_no_IO.tsv')
plot(xy$V1, jitter(xy$V2, factor=3), ylim=c(0, 160),
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no input or output locking')
dev.off()
