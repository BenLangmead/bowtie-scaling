jitter_factor <- 0

# Scatter plot of thread running times for no input sync
pdf(file='thread_times_no_I.pdf')
xy <- read.table('thread_times_no_I.tsv')
plot(xy$V1, jitter(xy$V2, factor=jitter_factor), ylim=c(0, 160),
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no input locking')
dev.off()

# Scatter plot of thread running times for no input or output sync
pdf(file='thread_times_no_IO.pdf')
xy <- read.table('thread_times_no_IO.tsv')
plot(xy$V1, jitter(xy$V2, factor=jitter_factor), ylim=c(0, 160),
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no input or output locking')
dev.off()

# Scatter plot of thread running times (default)
pdf(file='thread_times_default.pdf')
xy <- read.table('thread_times_default.tsv')
plot(xy$V1, jitter(xy$V2, factor=jitter_factor), ylim=c(0, 160),
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, default bowtie')
dev.off()

# Scatter plot of thread running times for no input or output sync with default average on top
pdf(file='thread_times_no_IO_and_avg.pdf')
xy_noio <- read.table('thread_times_no_IO.tsv')
xy_def_mm <- read.table('min_max_avg_default.tsv')
xy_noio_mm <- read.table('min_max_avg_no_IO.tsv')
plot(xy_def_mm$V4, type="l", ylim=c(0, 160), col='red', lwd=2,
	    xlab='# simultaneous threads',
	    ylab='Running time',
	    main='Running time for each thread, no input or output locking')
lines(xy_noio_mm$V4, type="l", lwd=2)
points(xy_noio$V1, jitter(xy_noio$V2, factor=jitter_factor))
dev.off()
