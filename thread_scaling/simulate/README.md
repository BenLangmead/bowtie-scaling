Simulations that allow us to project scaling for Bowtie-like programs.  These are programs with several simultaneous worker threads that cycle through three activities:

1. Get a read from the input file in a synchronized manner
2. Analyze the read (e.g. align to reference genome)
3. Write the output (e.g. alignment) to the output file in a synchronized manner

For such programs, some portions are serial, some are critical sections, and some are fully parallel.  Here's a sketch of Bowtie w/r/t those categories:

1. Serial: Loading the Bowite index, and other startup activities
2. Critical section: Getting the next read
3. Parallel: Alignment
4. Critical section: Writing the output record

[Amdahl's law] is a well known way to predict scaling behavior given a couple parameters related to how much of the program is serial versus how much is parallel.  It is *not* concerned with critical sections.  If the primary limiter for scalability is contention over a shared lock, [Amdahl's law] will not capture that!

[Amdahl's law]: https://en.wikipedia.org/wiki/Amdahl%27s_law

How to capture the impact of contention of critical section on thread scaling?  One proposal by [Eyerman and Eeckhout] makes some mild assumptions about critical section length and how they are spread across the program and derives some expressions for expected speedup.

[Eyerman and Eeckhout]: http://dl.acm.org/citation.cfm?id=1816011

That may be applicable -- requires more study.  But as an alternate starting point for thinking about this, I wrote a simple simulator that directly measures how much time is spent: (a) in parallel code, (b) waiting to enter a critical section, (c) in a critical section.  The simulator makes simplifying assumptions, including

* The system is a symmetric multiprocessor
* Each thread does the same thing
* Each thread alternates between a critical section (getting the next read) and parallel code (aligning the read)
* The time required to align a read is Gaussian distributed
* There is only one kind of critical section -- the input-parsing section
* The critical section requires constant work to complete
