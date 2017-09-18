#!/usr/bin/env python

from __future__ import print_function
import re


def postprocess_line(ln):
    if 'multicolumn{4}' in ln:
        return ln + ' \\cmidrule(lr){3-6}\\cmidrule(lr){7-10}'
    elif 'multicolumn{2}' in ln:
        return ln + ' \\cmidrule(lr){3-4}\\cmidrule(lr){5-6}\\cmidrule(lr){7-8}\\cmidrule(lr){9-10}'
    elif 'begin{tabular}' in ln:
        return '\\begin{tabular}{llrrrrrrrr}'
    return ln


def flush_section(section, sect_lines):
    if section != 'bwa':
        for ln in sect_lines:
            print(postprocess_line(ln))
    else:
        ln = sect_lines[0]
        print(' & BWA-MEM ' + ' '.join(ln.split()[3:]))


def go():
    fn = 'peak_throughput.tex_snippet.tmp'
    section = ''
    sect_lines = []
    suppressed_hline = False
    for ln in open(fn):
        ln = ln.rstrip()
        if ln.startswith('Bowtie 2'):
            flush_section(section, sect_lines)
            section = 'bt2'
            sect_lines = []
        elif ln.startswith('Bowtie'):
            flush_section(section, sect_lines)
            section = 'bt'
            sect_lines = []
        elif ln.startswith('BWA-MEM'):
            flush_section(section, sect_lines)
            section = 'bwa'
            sect_lines = []
        elif ln.startswith('HISAT'):
            flush_section(section, sect_lines)
            section = 'ht'
            sect_lines = []
        ln = ln.replace('\\phantom{0}', '')
        ln = ln.replace('$', '')
        ln = re.sub("\\\\multicolumn\{1\}\{[lrc]\}\{([/0-9.a-zA-Z]+)\}", "\\1", ln, flags=re.DOTALL)
        if not suppressed_hline and 'hline' in ln:
            suppressed_hline = True
        else:
            sect_lines.append(ln)
    flush_section(section, sect_lines)

if __name__ == '__main__':
    go()
