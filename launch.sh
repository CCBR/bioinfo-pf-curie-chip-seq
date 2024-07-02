#https://feb2023.archive.ensembl.org/Drosophila_melanogaster/Info/Index
output_dir=$1
callout=$2
# callout can be "cat" or "submit_batch"
# cat - prints the nextflow script to screen
# submit_batch - submits the above script to slurm

module load nextflow

# set dirs
# pipeline_dir="/data/CMBS_POB_JEE/PIPELINES/ChIP-seq"
pipeline_dir="/data/CCBR/projects/ccbr1330/pipelines/bioinfo-pf-curie-chip-seq"

logdir=$output_dir/log
if [[ ! -d $logdir ]]; then mkdir -p $logdir; fi

# if tracefile exists ... rename it
tracedir="${output_dir}/results/summary/trace"
if [[ -d $tracedir ]];then
	tracedate=$(stat -c %y $tracedir | awk '{print $1" "$2}' | sed 's/[-: ]//g' | cut -c 3-14)
	mv ${tracedir} ${tracedir}.${tracedate}
fi

submit_batch(){
        sbatch --cpus-per-task=8 --verbose \
        --output=$logdir/%j.out \
        --mem=200g --gres=lscratch:200 --time 24:00:00 \
        --error=$logdir/%j.err $1
}

# prep
cd $pipeline_dir
#cp /data/CMBS_POB_JEE/analysis/chip/spikein_configs/nextflow.config $pipeline_dir/nextflow.config

# run workflow
launch_file="$logdir/launch.sh"
cat <<EOF >${launch_file}
#!/bin/bash
# load java
module load java/18.0.1.1

# check for singularity
if ! command -v singularity &> /dev/null
then
	module load singularity
fi

# check if nextflow in path
if ! command -v nextflow &> /dev/null
then
	. "/data/CCBR_Pipeliner/db/PipeDB/Conda/etc/profile.d/conda.sh"
	conda activate dev
fi

nextflow run main.nf \\
  -resume \\
  -profile biowulf,docker,slurm \\
  --genome 'hs1' \\
  --spikes true \\
  --spike 'dmelr6.32' \\
  --samplePlan '/data/CCBR/rawdata/ccbr1330/samplePlan.csv' \\
  --design '/data/CCBR/rawdata/ccbr1330/design.csv' \\
  --singleEnd false \\
  --outDir '${output_dir}/results' \\
  --skipSaturation true \\
  --sif-cache '/data/CCBR_Pipeliner/SIFS' 

EOF

echo "${launch_file} written!"

eval $callout ${launch_file}
