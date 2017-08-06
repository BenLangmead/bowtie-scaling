#!/bin/sh

for m in 1 2 ; do
    for l in 50 100 ; do
	for b in "" "_block" ; do
	    if [ ! -f "mix${l}${b}_${m}.fq.gz" ] ; then
		cat >.zip${l}${b}_${m}.sh <<EOF
#!/bin/bash -l
#SBATCH
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --mem=1G
#SBATCH --time=12:00:00
#SBATCH --ntasks-per-node=1
cat mix${l}_?${b}_${m}.fq | grep -v '^$' | gzip -c9 > mix${l}_?${b}_${m}.fq.gz
EOF
		echo "sbatch .zip${l}${b}_${m}.sh"
	    fi
	done
    done
done
