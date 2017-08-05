#!/bin/sh

for m in 1 2 ; do
    for l in 50 100 ; do
	cat >.zip${l}_${m}.sh <<EOF
#!/bin/bash -l
#SBATCH
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --mem=1G
#SBATCH --time=4:00:00
#SBATCH --ntasks-per-node=1
cat mix${l}_?_${m}.fq | gzip -c9 > mix${l}_${m}.fq.gz
EOF
	echo "sbatch .zip${l}_${m}.sh"
    done
done
