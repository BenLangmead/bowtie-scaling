#!/usr/bin/env sh

# Human whole genome DNA sequencing reads from 1000 Genomes project
# ERR050082 has 42,245,074 paired-end 100 x 100 nt reads
# ERR050083 has 66,391,067 paired-end 100 x 100 nt reads

# Human RNA sequencing reads from GEUVADIS
# SRR1216135 has 10,908,030 paired-end 100 x 100 nt reads

# http://www.ebi.ac.uk/ena/data/view/SRR1216135

# WGS DNA-seq data for bowtie/bowtie2
for d in ERR050082 ERR050083 ; do

    pref=`echo ${d} | sed 's/\(......\).*/\1/'`

    for m in 1 2 ; do
        if [ ! -f "${d}_${m}.fastq" ] ; then
            curl ftp://ftp.sra.ebi.ac.uk/vol1/fastq/${pref}/${d}/${d}_${m}.fastq.gz | gzip -dc | head -n 1000000 > ${d}_${m}.fastq
        fi
    done
done

# RNA-seq data for HISAT
for m in 1 2 ; do
    if [ ! -f "SRR1216135_100k_${m}.fastq" ] ; then
        curl ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR121/005/SRR1216135/SRR1216135_${m}.fastq.gz | gzip -dc | head -n 4000000 > SRR1216135_100k_${m}.fastq
    fi
done
