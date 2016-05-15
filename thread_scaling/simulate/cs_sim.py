#!/usr/bin/env python

"""
We keep track of N threads.  Each thread begins with a serial section,
corresponding to index loading.  Then each thread cycles through three
states: (a) parallel section, (b) waiting to enter critical section, (c) in
critical section.  All threads begin in state (a), as though they all just got
a read.

The simulator steps forward in time, stopping only for the moments where at
least one thread changes state.  Those are the same as the moments where any
thread moves into or out of a critical section.
"""

from __future__ import print_function
import argparse
import heapq
from collections import deque
import numpy


class Simulation(object):

    def __init__(self, nthreads, cs_len_func, p_len_func, initial_time=0.0):
        self.N = nthreads
        # function that returns critical section length in time
        self.cs_len_func = cs_len_func
        # function that returns parallel section length in time
        self.p_len_func = p_len_func
        self.in_cs = None
        self.coming_up = []
        self.waiting = deque()
        for i in range(nthreads):
            time = self.p_len_func()
            heapq.heappush(self.coming_up, (initial_time + time, 'P', i, time))
        self.p_time = 0
        self.cs_time = 0
        self.wait_time = 0

    def step(self, stop_after=float('inf')):
        """
        Step forward to the next point in time where some thread either enters
        or exits a critical section.

        Let's break this into cases:

        A.

        All threads are in parallel mode.  The heap contains a bunch of
        records indicating when each thread will next attempt to enter the
        critical section.

        Thread to advance: one of the threads in parallel mode

        Possible states to follow: B

        B.

        All but one thread is in parallel mode.  The final thread is in the
        critical section.

        Thread to advance: either thread in CS or one of the threads in
        parallel mode

        Possible states to follow: A or C

        C.

        One thread is in the critical section, one or more threads are
        waiting, and the rest (if any) are in the parallel section.

        Thread to advance: either thread in CS or one of the threads in
        parallel mode

        Possible states to follow: B or C
        """
        while True:
            assert self.rep_ok()
            new_time, old_state, thread, elapsed = heapq.heappop(self.coming_up)
            if new_time > stop_after:
                return
            if old_state == 'P':
                self.p_time += elapsed
                if self.in_cs is not None:
                    # put in waiting state
                    self.waiting.appendleft((thread, new_time))
                else:
                    # immediately enter CS
                    self.in_cs = thread
                    time = self.cs_len_func()
                    heapq.heappush(self.coming_up, (new_time + time, 'C', thread, time))
            elif old_state == 'C':
                # possibly awaken a waiting task
                self.cs_time += elapsed
                if len(self.waiting) > 0:
                    wait_thread, wait_time = self.waiting.pop()
                    assert new_time > wait_time
                    self.wait_time += (new_time - wait_time)
                    yield wait_time, new_time, wait_thread
                    self.in_cs = wait_thread
                    time = self.cs_len_func()
                    heapq.heappush(self.coming_up, (new_time + time, 'C', wait_thread, time))
                else:
                    self.in_cs = None
                time = self.p_len_func()
                heapq.heappush(self.coming_up, (new_time + time, 'P', thread, time))
            else:
                raise RuntimeError('Bad old state: ' + old_state)

    def rep_ok(self):
        return True


def go(args):
    print("nthreads\tp_time\tcs_time\twait_time\tpt_thruput\tpt_thruput2")
    ideal_thru = float(args.until) / (args.p_length + args.cs_length_sd)
    ideal_thru2 = float(args.until - args.serial_length) / (args.p_length + args.cs_length_sd)
    for n in map(int, args.threads.rstrip(',').split(',')):
        def norm_cs():
            return max(numpy.random.normal(args.cs_length, args.cs_length_sd), args.cs_length_min)
        def norm_p():
            return max(numpy.random.normal(args.p_length, args.p_length_sd), args.p_length_min)
        sim = Simulation(n,
                         (lambda: args.cs_length) if (args.cs_length_sd == 0) else norm_cs,
                         (lambda: args.p_length) if (args.p_length_sd == 0) else norm_p,
                         args.serial_length)
        for _ in sim.step(stop_after=args.until):
            pass
        print("%d\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f" % (n, sim.p_time, sim.cs_time, sim.wait_time,
                                                         sim.p_time/(n*ideal_thru), sim.p_time/(n*ideal_thru2)))

if __name__ == '__main__':
    import sys
    import unittest

    class TestSimulation(unittest.TestCase):

        def test_sim1(self):
            # only 1 thread, so no waiting time
            sim = Simulation(1, lambda: 10, lambda: 100)
            ls = [x for x in sim.step(10000)]
            self.assertEqual(0, len(ls))

        def test_sim2(self):
            # 2 threads with predictable overlap
            sim = Simulation(2, lambda: 10, lambda: 10)
            ls = [x for x in sim.step(10000)]
            self.assertEqual(1, len(ls))
            self.assertEqual((10, 20, 1), ls[0])

        def test_sim3(self):
            # 3 threads with predictable overlap
            sim = Simulation(3, lambda: 10, lambda: 20)
            ls = [x for x in sim.step(10000)]
            self.assertEqual(2, len(ls))
            self.assertEqual((20, 30, 1), ls[0])
            self.assertEqual((20, 40, 2), ls[1])

        def test_sim4(self):
            # 3 threads with predictable overlap
            sim = Simulation(2, lambda: 20, lambda: 10)
            # have to run until last waiting period has expired
            ls = [x for x in sim.step(51)]
            self.assertEqual(2, len(ls))
            self.assertEqual((10, 30, 1), ls[0])
            self.assertEqual((40, 50, 0), ls[1])


    if '--test' in sys.argv:
        unittest.main(argv=[sys.argv[0]])

    else:

        parser = argparse.ArgumentParser(description='Set up critical-section thread scaling experiments.')

        parser.add_argument('--threads', metavar='int,int,...', type=str, required=True,
                            help='Series of comma-separated ints giving the number of threads to simulate.')
        parser.add_argument('--serial-length', type=float, default=100.0,
                            help='Time taken by serial portion at the beginning of program.')
        parser.add_argument('--cs-length', type=float, default=0.01,
                            help='Average time required by critical section block.')
        parser.add_argument('--cs-length-sd', type=float, default=0.002,
                            help='Standard deviation for critical section block.')
        parser.add_argument('--cs-length-min', type=float, default=0.002,
                            help='Minimium length of critical section block.')
        parser.add_argument('--p-length', type=float, default=1.0,
                            help='Average time required by parallel code block.')
        parser.add_argument('--p-length-sd', type=float, default=0.2,
                            help='Standard deviation for length of parallel-code block.')
        parser.add_argument('--p-length-min', type=float, default=0.2,
                            help='Minimium length of parallel-code block.')
        parser.add_argument('--until', type=float, default=10000.0,
                            help='Run simulation until we reach this time point.')

        go(parser.parse_args())
