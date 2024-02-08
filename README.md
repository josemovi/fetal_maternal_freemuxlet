# Fetal/Maternal interface cell origin classification pipeline using Freemuxlet

## 1) Run pileup per sample

Use `bash freemuxlet_multijobs.sh` 

## 2) Merge pileup outputs per patient and run freemuxlet (combine oll cells from all samples per patient to gain SNPs/variants detection)

Use `bash merge_pileup_outputs_myriad.sh list_patient_ids.txt`

## 3) Assign maternal/fetal origin to each freemuxlet group based on fetal markers

Use `freemuxlet_combine_outputs_loop_myriad_030423.md` in R
