---
title: "freemuxlet_combine_outputs_loop_myriad_030423"
author: Jose J Moreno-Villena
date: "2023-04-03"
---

# Assign fetal/maternal cell origin and combine across libraries

This script loops over each single-cell library and processes the demultiplexing output from freemuxlet to assign fetat/maternal origin to each group of cells. It combines the barcodes of all the libraries and adds a library-specitic tag to each barcode. The output is a csv file with all barcodes and their fetat/maternal origin assignemnt plus singlet/doublet detection.

## Load libraries
```{r}
library(Matrix)
library(dplyr)
library(Seurat)
library(SeuratDisk)
library(hdf5r)
library(data.table)
```

## Create an empty data frame to sequentially add results
The empty data frame will be populated with barcodes and their genotype per library in each iteration 

```
setwd('~/Scratch/cellr_cellb_outs_280323')
                       
freemux_object <- data.frame(matrix(ncol = 4, nrow = 0))
names(freemux_object)<-c('barcode','genotype','doublet','library')
```

## Read library metadata
csv file with library information, including conditions, donor attributes and tissue types 

```
samples_info<-read.csv('Aggr-FMI-All-GEX-TCR-aggregation-20230328-modified.csv')
samples<-(samples_info$sample_id)
```

## Loop assign fetal/maternal origin to freemuxlet groups and combine libraries

```
for (i in 1:length(samples)){
  #Path to cellbender outputs
  pathtoCellBenderOutput <-'/home/sejjjjm/Scratch/cellr_cellb_outs_280323/cellbender_matrx_outs/'
  #Open cellbender matrix file
  data.file <- paste0(pathtoCellBenderOutput,samples[i],'-CellBender-out_filtered.h5')
  data.data <- Read10X_h5(filename = data.file, use.names = TRUE)
  # create Seurat object
  dataone <- CreateSeuratObject(counts = data.data, project = "FMI", assay = "RNA")
  rm(data.data)
  rm(data.file)

  # read freemuxlet output
  freemuxlet <- fread(paste0("zcat < ", "freemuxlet_outs/",samples[i],".clust1.samples.gz"))
  
  # extract the best.guess per barcode
  freeout<-(freemuxlet[,c(2,6)])
  
  # Normalize data to later extract average of trohpoblast markers expression by freemuxlet group. This is global-scaling normalization method "LogNormalize" that normalizes the feature expression measurements for each cell by the total expression, multiplies this by a scale factor (10,000 by default), and log-transforms the result
  db <- NormalizeData(dataone, normalization.method = "LogNormalize", scale.factor = 10000)
  ### add freemuxlet groups information to seurat oject using same barcodes order
  db$freemuxlet <- as.vector(freeout[match(colnames(db),freeout$BARCODE),2])
  
  ## get barcodes of each freemuxlet class
  n_zero<-freeout$BARCODE[grep('0,0',freeout$BEST.GUESS)]
  n_one<-freeout$BARCODE[grep('1,1',freeout$BEST.GUESS)]
  
  # if it's myometrium or PBMCs assign maternal to the genotype with a larger number of barcodes
  if (grepl('-CD-|-E-',samples[i])){
    # if the number of barcodes classified in the 0,0 group is greater than number of barcdoes in      1,1 group, assign Maternal origin to barcodes in 0,0 group and Fetal to 1,1 group.
    if (length(n_zero) > length(n_one)) {oneg <- "Fetal"; zerog <- "Maternal"}
    # else, Maternal origin barcodes are included in group 1,1 and Fetal 0,0
    else {oneg <- "Maternal"; zerog <- "Fetal"}
    # assign Maternal/fetal origin to each barcode and add new 'genotype' dataframe to the seurat      object
    db$genotype<-gsub("0,0",zerog,db$freemuxlet)
    db$genotype<-gsub('1,1',oneg,db$genotype)
    db$genotype<-gsub("1,0","Unknown",db$genotype) 
    db$genotype<-gsub("0,1","Unknown",db$genotype)
    # add singlet/doublet info to the seurat object
    db$doublet<-gsub("0,0","False",db$freemuxlet)
    db$doublet<-gsub('1,1',"False",db$doublet)
    db$doublet<-gsub("1,0","True",db$doublet) 
    db$doublet<-gsub("0,1","True",db$doublet)} else {
      
      # if library is not Myometrium or PBMCs, look for the genotype with the highest average expression of trophoblast markers and assign it as the group containing fetal cells
      gfetal<-sort(colMeans(as.data.frame(AverageExpression(db,features = c("CGA","CYP19A1", "GH2","PAPPA","VGLL1","PAPPA2","HLA-G"),group.by = "freemuxlet"))), decreasing = T)[1]
      gfetal<-gsub("\\.",",",gsub("RNA.","",names(gfetal)))
      
      ## assign fetal/maternal origin to barcodes in seurat object: if fetal group is 0,0 
      if(gfetal == '0,0'){
        gmaternal = '1,1'
            # assign Maternal/fetal origin to each barcode and add new 'genotype' dataframe to the seurat object
        db$genotype<-gsub(gfetal,"Fetal",db$freemuxlet) ;   db$genotype<-gsub('1,1',"Maternal",db$genotype)
        db$genotype<-gsub("1,0","Unknown",db$genotype) ; db$genotype<-gsub("0,1","Unknown",db$genotype)
        # add singlet/doublet info to the seurat object
        db$doublet<-gsub(gfetal,"False",db$freemuxlet) ; db$doublet<-gsub('1,1',"False",db$doublet)
        db$doublet<-gsub("1,0","True",db$doublet) ; db$doublet<-gsub("0,1","True",db$doublet)} else         ## assign fetal/maternal origin to barcodes in seurat object: if fetal group is 1,1 
          {
          gmaternal = '0,0'
      db$genotype<-gsub('0,0',"Maternal",db$freemuxlet); db$genotype<-gsub('1,1',"Fetal",db$genotype)
      db$genotype<-gsub("1,0","Unknown",db$genotype) ; db$genotype<-gsub("0,1","Unknown",db$genotype)
      # add singlet/doublet info to the seurat object
      db$doublet<-gsub('0,0',"False",db$freemuxlet); db$doublet<-gsub('1,1',"False",db$doublet)
      db$doublet<-gsub("1,0","True",db$doublet) ; db$doublet<-gsub("0,1","True",db$doublet)}
    }
  
  
  # create data frame with each barcode as a rowname
  freemux <-as.data.frame(colnames(db))
  # tag each barcode with the library number as in the metadata
  lnumber<-samples_info$`Library.number`[i]
  freemux$barcode<-gsub('.$',lnumber,colnames(db))
  names(freemux)[1]<-'barcode'
  
  # add cell origin, single/doublet info and library info to the new dataframe 
  freemux$genotype<-db$genotype
  freemux$doublet<-db$doublet
  freemux$library<-samples[i]
  
  # combine the new dataframe into the growing datafrem with all libraries
  freemux_object <-rbind(freemux_object,freemux[,-1])
  print(paste('finished_n',lnumber))
}
```

## write csv with the combined dataframe

```
write.csv(freemux_object,'freemux_object.csv')
```
