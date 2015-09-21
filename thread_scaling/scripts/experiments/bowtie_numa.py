#!/usr/bin/env python

"""
 Copyright 2015, Ben Langmead <langmea@cs.jhu.edu>

 This file is part of Bowtie.

 Bowtie is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Bowtie is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Bowtie.  If not, see <http://www.gnu.org/licenses/>.
"""


import os
import sys
import copy
import inspect
import logging
import subprocess


class NumaInfo(object):
    _numa_info = None

    @classmethod
    def get_info(cls):
        if not cls._numa_info:
            NumaInfo.collect_numa_info()
        return copy.deepcopy(cls._numa_info)

    @classmethod
    def collect_numa_info(cls):
        cls._numa_info = dict()
        numa = cls._numa_info

        cmd = [r"numactl --hardware | grep available| awk '{print $2}'"]
        process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        numa_nodes = process.communicate()[0]
        numa['nodes'] = int(numa_nodes)

        cmd = [r"numactl --hardware| tail -n %d | sed -e 's/.*://'" % numa['nodes']]
        process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        # TODO: Ideally we should use this to properly balance the load among nodes.
        dist_lines = process.communicate()[0]
        dist_matrix = list()
        for line in dist_lines.splitlines():
            line_tp = tuple(dist for dist in line.split())
            dist_matrix.append(line_tp)
        numa['distances'] = dist_matrix
        # TODO: os.sysconf()
        cmd = [r"cat /proc/cpuinfo |grep 'physical id'|sort -u| wc -l"]
        process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        numa['physical_cpus'] = int(process.communicate()[0])

        cmd = [r"cat /proc/cpuinfo |grep 'cpu cores'|sort -u| awk -vFS=$':' '{print $2}'"]
        process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        cpu_cores = int(process.communicate()[0])
        numa['cpu_cores'] = cpu_cores

        cmd = [r"cat /proc/cpuinfo |grep 'siblings'|sort -u| awk -vFS=$':' '{print $2}'"]
        process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        cpu_siblings = int(process.communicate()[0])

        if cpu_cores == cpu_siblings:
            numa['hyperthreading'] = False
        else:
            numa['hyperthreading'] = True
        # TODO: Get memory per node?


class BowtieScheduler(object):

    def __init__(self, bin_spec, opts, args):
        self.cmd_lines = list()
        self.bin_spec = bin_spec
        self.opts = opts
        self.args = args
        self.build_cmd_lines()

    def build_cmd_lines(self):
        # No abc for now
        raise NotImplementedError("You should never call the base class build_cmd_lines()")


class NumaScheduler(BowtieScheduler):

    def __init__(self, bin_spec, opts, args):
        super(NumaScheduler, self).__init__(bin_spec, opts, args)
        self.numa = NumaInfo.get_info()
        self.policy = None

    def build_cmd_lines(self):
        numa_nodes = self.numa['nodes']
        cpu_cores = self.numa['cpu_cores']
        # TODO: Need to parse -U/-1 & -2 params and split by ','
        # TODO: For the case of no I/O tests this does not matter though.
        return


class SimpleScheduler(BowtieScheduler):

    def __init__(self, bin_spec, opts, args):
        super(SimpleScheduler, self).__init__(bin_spec, opts, args)

    def build_cmd_lines(self):
        self.args[0] = self.bin_spec
        for key, value in self.opts.iteritems():
            self.args.append(key)
            self.args.append(value)

        self.cmd_lines.append(' '.join(self.args))
        return

# p # of threads
# c #cores
# n # numa nodes
# process to start: min[[2pn/c], n]
def get_bowtie_scheduler(bin_spec, opts, args):
    no_threads = opts.get("-p", None)
    # TODO: Hard coding the maximum #threads from where bowtie performance
    # TODO: starts dropping is probably not ok.
    if no_threads and int(no_threads) > 3:
        return NumaScheduler(bin_spec, opts, args)
    return SimpleScheduler(bin_spec, opts, args)


class BowtieRunner(object):
    """ bowtie runner """

    def __init__(self, bin_spec, opts, args):
        self.scheduler = get_bowtie_scheduler(bin_spec, opts, args)

    def run(self):
        pid_list = list()
        for cmd_line in self.scheduler.cmd_lines:
            logging.info('Starting command: %s' % cmd_line)
            pid_list.append(subprocess.Popen([cmd_line], shell=True))
        for pid in pid_list:
            pid.wait()


def build_args():
    """
    Parse the wrapper arguments. Returns the options,<program arguments> tuple.
    """
    parsed_args = {}
    to_remove = []
    argv = sys.argv[:]
    for i, arg in enumerate(argv):
        if arg == '--large-index':
            parsed_args[arg] = ""
            to_remove.append(i)
        elif arg == '--debug':
            parsed_args[arg] = ""
            to_remove.append(i)
        elif arg == '--verbose':
            parsed_args[arg] = ""
            to_remove.append(i)
        elif arg == '-p':
            parsed_args[arg] = argv[i+1]
            to_remove.append(i)
            to_remove.append(i+1)
        elif arg == '--bowtie-bin':
            parsed_args[arg] = argv[i+1]
            to_remove.append(i)
            to_remove.append(i+1)

    for i in reversed(to_remove):
        del argv[i]

    return parsed_args, argv


def main():
    logging.basicConfig(level=logging.ERROR,
                        format='%(levelname)s: %(message)s'
                        )
    bin_name = "bowtie"
    bin_s = "bowtie-align-s"
    bin_l = "bowtie-align-l"
    idx_ext_l = '.1.ebwtl'
    idx_ext_s = '.1.ebwt'
    curr_script = os.path.realpath(inspect.getsourcefile(main))
    ex_path = os.path.dirname(curr_script)
    options, arguments = build_args()

    if '--bowtie-bin' in options:
    bin_spec = os.path.join(ex_path, bin_s)

    if '--verbose' in options:
        logging.getLogger().setLevel(logging.INFO)
        
    if '--debug' in options:
        bin_spec += '-debug'
        bin_l += '-debug'
        del options['--debug']
        
    if '--large-index' in options:
        bin_spec = os.path.join(ex_path, bin_l)
        del options['--large-index']
    elif len(arguments) >= 2:
        idx_basename = arguments[-2]
        large_idx_exists = os.path.exists(idx_basename + idx_ext_l)
        small_idx_exists = os.path.exists(idx_basename + idx_ext_s)
        if large_idx_exists and not small_idx_exists:
            logging.info("No small index but a large one is present. Using large index.")
            bin_spec = os.path.join(ex_path, bin_l)
    
    arguments[0] = bin_name
    arguments.insert(1, 'basic-0')
    arguments.insert(1, '--wrapper')
    runner = BowtieRunner(bin_spec, options, arguments)
    runner.run()


if __name__ == "__main__":
    main()





