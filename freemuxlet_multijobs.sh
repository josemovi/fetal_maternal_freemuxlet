#!/bin/bash

# This script first makes a csv file and then runs cellranger multi in a loop for samples given in a list (ID)

# Last libraries
## yara: for ID in "F1758LJ-CD-Sc-2" "F1682RH-E-Sc" "F1950PYI-AB-sn" "F1958NS-AB-sn"; do
cat samples.txt | while read ID; do
# This is FourthS4 data

# this is part of the script create and sh file and sends a job per $ID library to the cluster
    cat << EOF > freemuxlet_single_job_submission.sh
#!/bin/bash -l
#$ -l h_rt=30:00:00
#$ -l mem=50G
#$ -N Freemux$ID
#$ -V
#$ -pe smp 8
#$ -cwd
#$ -o /home/sejjjjm/Scratch/cellranger7_out/logs/forcecells-$ID-$JOB_ID.out
#$ -e /home/sejjjjm/Scratch/cellranger7_out/logs/forcecells-$ID-$JOB_ID.err

popscle='/home/sejjjjm/Scratch/programs/popscle/bin/popscle'
workdir='/home/sejjjjm/Scratch/cellranger7_out'
datadir=\$workdir

\$popscle dsc-pileup --sam \$datadir/$ID/outs/per_sample_outs/$ID/count/sample_alignments.bam \
--vcf /home/sejjjjm/Scratch/cellranger7_out/ucsc.hg38.liftover.out.withchr.c1_22.nohbb.vcf \
--out \$workdir/freemuxlet_out/$ID

EOF

    qsub freemuxlet_single_job_submission.sh
    echo "Submitted job for id=$ID"

    Wait for X min between jobs to avoid the cluster thinking you are a robot. Adjust accordingly
    sleep 400
done
