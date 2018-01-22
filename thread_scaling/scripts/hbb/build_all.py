#!/usr/bin/env python

import os
import glob

last_bin, last_tool, last_branch, last_preproc = None, None, None, None
all = ['../bt.tsv', '../bt2.tsv', '../ht.tsv'] + glob.glob('../bt_*.tsv*') + glob.glob('../bt2_*.tsv*') + glob.glob('../ht_*.tsv*')
for fn in all:
    print('Processing "%s"' % fn)
    with open(fn) as fh:
        for ln in fh:
            if ln.startswith('#'):
                continue
            if len(ln.strip()) == 0:
                continue
            toks = ln.split('\t')
            if len(toks) != 6:
                raise RuntimeError('Bad line: ' + str(toks))
            tool, name, branch, preproc = toks[1], toks[0], toks[2], toks[4].rstrip()
            if tool == 'tool':
                continue
            if tool not in ['bowtie', 'bowtie2', 'hisat', 'hisat2', 'bwa']:
                raise RuntimeError('Bad tool: %s' % tool)
            bin_nm = ('%s-%s' if tool == 'bwa' else '%s-align-s-%s') % (tool, name)
            # check case where branch name is a commit
            if len(branch) == 40 and branch.isalnum():
                print('  branch "%s" looks like a commit' % branch)
            if os.path.exists(bin_nm):
                print('  SKIPPING "%s" because it already exists' % bin_nm)
            else:
                if tool == last_tool and branch == last_branch and preproc == last_preproc:
                    cmd = ' '.join(['cp', '-r', last_bin, bin_nm])
                else:
                    cmd = ' '.join(['./bbb_aligner_build.sh', tool, branch, name, preproc])
                print('  cmd: ' + cmd)
                ret = os.system(cmd)
                if ret != 0:
                    raise RuntimeError('cmd "%s" returned %d' % (cmd, ret))
                if not os.path.exists(bin_nm):
                    raise RuntimeError('Failed to create binary with name ' + bin_nm)
            last_bin, last_tool, last_branch, last_preproc = bin_nm, tool, branch, preproc

print('SUCCESS')
