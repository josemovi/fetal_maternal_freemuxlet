#!/bin/bash -l
# Batch script to run an parallel job
# Request ten minutes of wallclock time (format hours:minutes:seconds).
#$ -l h_rt=24:00:0
# Request 4 gigabyte of RAM per process (must be an integer followed by M, G, or T)
#$ -l mem=4G
# Request 15 cores
#$ -pe smp 15
# Request 50 gigabyte of TMPDIR space per node 
# (default is 10 GB - remove if cluster is diskless)
#$ -l tmpfs=50G
# Set the name of the job.
#$ -N F1668RK-E-Sc-4-1

# Set the working directory to somewhere in your scratch space.
# Replace "<your_UCL_id>" with your UCL user ID :
#$ -wd /home/sejjjjm/Scratch/genotyping_popscle

# Run job (sample name can be replaced using sed 's/F1668RK-E-Sc-4-1/$sample/g' freemuxlet_myriad_job.sh > $sample_freemuxlet.sh)

popscle='/home/sejjjjm/Scratch/programs/popscle/bin/popscle'
workdir='/home/sejjjjm/Scratch/genotyping_popscle/'
datadir='/home/sejjjjm/Scratch/cell_ranger_out'

$popscle dsc-pileup --sam $datadir/F1668RK-E-Sc-4-1/outs/per_sample_outs/F1668RK-E-Sc-4-1/count/sample_alignments.bam --vcf ucsc.hg38.liftover.out.withchr.c1_22.nohbb.vcf --out $workdir/out-data/F1668RK-E-Sc-4-1

$popscle freemuxlet --plp $workdir/out-data/F1668RK-E-Sc-4-1 --nsample 2 --out $workdir/out-data/F1668RK-E-Sc-4-1
