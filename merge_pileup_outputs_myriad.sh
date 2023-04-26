#!/bin/bash
# read list of samples
samples=$1
cat $samples | while read ID; do

## The script popscle_dsc_pileup_merge_splitted.py comes from https://github.com/aertslab/popscle_helper_tools
## this script creat a job per patient ID from a list of patients IDs and merge all the pileaup out files per patient before running freemuxlet

# this is part of the script create and sh file and sends a job per $ID library to the cluster
    cat << EOF > freemuxlet_single_job_submission.sh
#!/bin/bash -l
#$ -l h_rt=30:00:00
#$ -N $ID
#$ -o $ID-\$JOB_ID.out
#$ -e $ID-\$JOB_ID.err

# path to directories and programs
popscle='/home/sejjjjm/Scratch/programs/popscle/bin/popscle'
workdir='/home/sejjjjm/Scratch/cellr_cellb_outs_280323/aggregate_plp_patient_freemuxlet'

# make working directory per sample
mkdir \$workdir/$ID-dir
cd \$workdir/$ID-dir

# path to merger script
plpmerger='~/Scratch/programs/popscle_dsc_pileup_merge_splitted.py'

# path to freemuxlet outputs
freemuxouts='/home/sejjjjm/Scratch/cellr_cellb_outs_280323/freemuxlet_outs'

# path to metadata
metadata='/home/sejjjjm/Scratch/cellr_cellb_outs_280323/Aggr-FMI-All-GEX-TCR-aggregation-20230328-modified.csv'

# copy pileup outputs in workdir per patient
cp \$freemuxouts/$ID*plp.gz .; cp \$freemuxouts/$ID*var.gz .;

# change barcode tag in all cel files per patient:
## for each cel file 
ls \$freemuxouts/$ID*cel.gz | while read plp; do \
sample=\$(echo \$plp | sed 's/.*\///g' | sed 's/\..*//g'); \
tag=\$(grep "\$sample" $metadata | cut -d',' -f14 | sed 's/\r//'); \
zcat \$plp | sed "s/-1/-\$tag/g" | gzip > \$sample.cel.gz; done

# modify file names to match requeriment for the merger script: files must end in *pileup.cel.gz *pileup.var.gz *pileup.plp.gz
for file in *cel.gz*; do mv \$file \${file//\.cel/\.pileup.cel}; done;
for file in *var.gz*; do mv \$file \${file//\.var/\.pileup.var}; done;
for file in *plp.gz*; do mv \$file \${file//\.plp/\.pileup.plp}; done;

# add common string at the beginning of all the files to be merged (here adding 'part.')
ls $ID*gz | while read library; do mv \$library part.\$library; done

# run pileup merger
module load python3
python3 ~/Scratch/programs/popscle_dsc_pileup_merge_splitted.py -i part -o $ID-merged

# run freemuxlet
\$popscle freemuxlet --plp $ID-merged.pileup --nsample 2 --out $ID-merged.pileup

# remove intermediate files
rm part*

EOF

    qsub freemuxlet_single_job_submission.sh
    echo "Submitted job for id=$ID"

done
