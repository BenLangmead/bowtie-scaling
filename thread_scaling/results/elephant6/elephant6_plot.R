prefix <- ''

# Scatter plot of thread running times for no input or output sync
pdf(file=paste(prefix, 'elephant6_sensitive_no_io.pdf', sep=''))
xy <- read.table(paste(prefix, 'sensitive_no_io.tsv', sep=''))
plot(xy$V1, xy$V2, ylim=c(0, 110),
	xlab='# simultaneous threads',
	ylab='Running time',
	main='Running time for each thread, no input or output locking')
dev.off()

# Scatter plot of thread running times for no input or output sync
pdf(file=paste(prefix, 'elephant6_sensitive_no_io_rescaled.pdf', sep=''))
xy <- read.table(paste(prefix, 'sensitive_no_io.tsv', sep=''))
plot(xy$V1, xy$V2,
	xlab='# simultaneous threads',
	ylab='Running time',
	main='Running time for each thread, no input or output locking')
dev.off()

# Scatter plot of thread running times for no input or output sync with default average on top
pdf(file=paste(prefix, 'elephant6_sensitive_no_io_and_avg.pdf', sep=''))
xy_noio <- read.table(paste(prefix, 'sensitive_no_io.tsv', sep=''))
xy_def_mm <- read.table(paste(prefix, 'avg_sensitive_normal.tsv', sep=''))
xy_noio_mm <- read.table(paste(prefix, 'avg_sensitive_no_io.tsv', sep=''))
plot(xy_def_mm$V4, type="l", ylim=c(0, 450), col='red', lwd=2,
		xlab='# simultaneous threads',
		ylab='Running time',
		main='Running time for each thread, no input or output locking')
lines(xy_noio_mm$V4, type="l", lwd=2)
points(xy_noio$V1, xy_noio$V2)
dev.off()

# Series of 4 plots, all with same y axis showing the 4 different sensitivities
pdf(file=paste(prefix, 'elephant6_series_no_io_series.pdf', sep=''), height=4, width=14)
par(mfrow=c(1,4))
for(sens in c('very-fast', 'fast', 'sensitive', 'very-sensitive')) {
	xy <- read.table(paste(prefix, sens, '_no_io.tsv', sep=''))
	plot(xy$V1, xy$V2, ylim=c(30, 200), col=rgb(0, 0, 0, 0.2),
		xlab='# simultaneous threads',
		ylab='Running time',
		main=sens)
}
dev.off()

# Series of 4 plots, all with same y axis showing the 4 different sensitivities
pdf(file=paste(prefix, 'elephant6_series_no_io_and_avg_series.pdf', sep=''), height=4, width=14)
par(mfrow=c(1,4))
for(sens in c('very-fast', 'fast', 'sensitive', 'very-sensitive')) {
	xy_noio <- read.table(paste(prefix, sens, '_no_io.tsv', sep=''))
	xy_def_mm <- read.table(paste(prefix, 'avg_', sens, '_normal.tsv', sep=''))
	xy_noio_mm <- read.table(paste(prefix, 'avg_', sens, '_no_io.tsv', sep=''))
	plot(xy_def_mm$V4, type="l", ylim=c(0, 450), col='red', lwd=2,
			xlab='# simultaneous threads',
			ylab='Running time')
	points(xy_noio$V1, xy_noio$V2, col=rgb(0, 0, 0, 0.1))
	lines(xy_noio_mm$V4, type="l", lwd=2, col="blue")
}
dev.off()
