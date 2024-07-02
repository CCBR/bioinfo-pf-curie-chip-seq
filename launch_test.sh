#!/bin/bash
. "/data/CCBR_Pipeliner/db/PipeDB/Conda/etc/profile.d/conda.sh"
conda activate dev
module load java
#nextflow run main.nf -profile test,singularity --singularityImagePath /data/CCBR/projects/ccbr1330/pipelines/singularity_image_path
nextflow run main.nf -profile test,docker
