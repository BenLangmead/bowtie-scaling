#!/usr/bin/env python

from __future__ import print_function
import re
import sys
from collections import defaultdict


def postprocess_line(ln):
    if 'multicolumn{4}' in ln:
        return ln + ' \\cmidrule(lr){3-6}\\cmidrule(lr){7-10}\\cmidrule(lr){11-14}'
    elif 'multicolumn{2}' in ln:
        return ln + ' \\cmidrule(lr){3-4}\\cmidrule(lr){5-6}\\cmidrule(lr){7-8}\\cmidrule(lr){9-10}\\cmidrule(lr){11-12}\\cmidrule(lr){13-14}'
    elif 'begin{tabular}' in ln:
        return '\\begin{tabular}{llrrrrrrrrrrrr}'
    return ln


def is_number(s):
    s = s.replace(',', '')
    try:
        float(s)
        return True
    except ValueError:
        return False


def format_number(fl):
    if '.' not in fl:
        return "{:,}".format(int(fl))
    return "{:,.2f}".format(float(fl))


def flush_section(section, sect_lines):
    if section == 'bwa':
        for i, ln in enumerate(sect_lines):
            if ln is None:
                sect_lines = sect_lines[:i] + [sect_lines[i+1]]
                break
        sect_lines[-1] = sect_lines[-1].replace('BWA-MEM & B-parsing', '& BWA-MEM')

    best = defaultdict(lambda: (-1, -1))
    secbest = defaultdict(lambda: (-1, -1))
    for lni, ln in enumerate(sect_lines):
        if ln.endswith('\\\\'):
            ln = ln[:-2]
        toks = ln.rstrip().replace(' ', '').split('&')
        i = 3
        while i < len(toks) and is_number(toks[i]):
            num = float(toks[i])
            if num > best[i][0]:
                secbest[i] = best[i]
                best[i] = (num, lni)
            elif num > secbest[i][0]:
                secbest[i] = (num, lni)
            i += 2

    for lni, ln in enumerate(sect_lines):
        trailing = ''
        if ln.endswith('\\\\'):
            trailing = '\\\\'
            ln = ln[:-2]
        toks = list(map(lambda x: x.strip(), ln.rstrip().split('&')))
        i = 3
        had_numbers = False
        while i < len(toks) and is_number(toks[i]):
            had_numbers = True
            if best[i][1] == lni:
                toks[i-1] = '\\cellcolor{red!25}' + format_number(toks[i-1])
                toks[i] = '\\cellcolor{red!25}' + format_number(toks[i])
            elif secbest[i][1] == lni:
                toks[i-1] = '\\cellcolor{orange!25}' + format_number(toks[i-1])
                toks[i] = '\\cellcolor{orange!25}' + format_number(toks[i])
            i += 2
        for i, tok in enumerate(toks):
            if is_number(tok) and float(tok) >= 1000.0:
                toks[i] = format_number(toks[i])
        if lni == 0 and had_numbers:
            toks[-1] = '\\Tstrut ' + toks[-1]
        elif lni == len(sect_lines)-1 and had_numbers:
            toks[-1] = '\\Bstrut ' + toks[-1]
        if lni == len(sect_lines)-1 and section == 'bwa':
            toks[-1] = '\\Tstrut ' + toks[-1]
        print(postprocess_line(' & '.join(toks) + trailing))


def go():
    fn = 'peak_throughput.tex_snippet.tmp'
    if len(sys.argv) > 1:
        fn = sys.argv[1]
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
            assert section == 'bt2'
            section = 'bwa'
            sect_lines.append(None)
            #flush_section(section, sect_lines)
            #section = 'bwa'
            #sect_lines = []
        elif ln.startswith('HISAT'):
            flush_section(section, sect_lines)
            section = 'ht'
            sect_lines = []
        elif ln == '\\hline':
            flush_section(section, sect_lines)
            section = ''
            sect_lines = []
        ln = ln.replace('\\phantom{0}', '')
        ln = ln.replace('\\phantom{00}', '')
        ln = ln.replace('$', '')
        ln = re.sub("\\\\multicolumn\{1\}\{[lrc]\}\{([/0-9.a-zA-Z]+)\}", "\\1", ln, flags=re.DOTALL)
        if not suppressed_hline and 'hline' in ln:
            suppressed_hline = True
        else:
            sect_lines.append(ln)
    flush_section(section, sect_lines)

if __name__ == '__main__':
    go()
