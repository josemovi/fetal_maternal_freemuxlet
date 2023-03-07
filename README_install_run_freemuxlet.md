(from popscle github https://github.com/statgen/popscle) `poscle` is a suite of population scale analysis tools for single-cell genomics data. The key software tools in this repository includes demuxlet (version 2) and freemuxlet, a genotyping-free method to deconvolute barcoded cells by their identities while detecting doublets.

# Quick Overview

With `popscle`, we recommend analyzing single cell RNA-seq (and other single cell genomic) dataset in two steps.

    Use `dsc-pileup` to generate pileups around known variants from aligned sequence reads.
    Use `demuxlet` (with genotypes) or `freemuxlet` (without genotypes) to deconvolute the identities of barcoded cells.

Read the tutorial at https://github.com/statgen/popscle/wiki , if you would like to learn how to run software tools in popscle by example.

# Install Freemuxlet

```
git clone https://github.com/statgen/popscle
cd popscle
mkdir build
cd build
```
The next step is 
```
cmake
```

We found that the library htslib is missing in myriad. So, we need to install it first. 
clone the htslib (missing in myriad) and specify customized installing path by replacing "cmake .." with:

```
mkdir programs
cd programs
git clone https://github.com/samtools/htslib
```
Then, you can proceed with the cmake step and modify your path as:

```
cmake -DHTS_INCLUDE_DIRS=/home/sejjjjm/Scratch/programs/htslib  -DHTS_LIBRARIES=/home/sejjjjm/Scratch/programs/htslib/libhts.a ..
```
Finally, to to build the binary, run

```
make
```
# Run freemxulet 

```
popscle='/home/sejjjjm/Scratch/programs/popscle/bin/popscle'
workdir='/home/sejjjjm/Scratch/genotyping_popscle/'
datadir='/home/sejjjjm/Scratch/cell_ranger_out'

mkdir $workdir/out-data

$popscle dsc-pileup --sam $datadir/F1668RK-E-Sc-4-1/outs/per_sample_outs/F1668RK-E-Sc-4-1/count/sample_alignments.bam --vcf ucsc.hg38.liftover.out.withchr.c1_22.nohbb.vcf --out $workdir/out-data/F1668RK-E-Sc-4-1

$popscle freemuxlet --plp $workdir/out-data/F1668RK-E-Sc-4-1 --nsample 2 --out $workdir/out-data/F1668RK-E-Sc-4-1
```
