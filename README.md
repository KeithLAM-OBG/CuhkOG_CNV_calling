# '''CNV analysis for FetalSeq'''
## Dependencies
- Ubuntu (https://ubuntu.com/desktop/wsl)
- Perl (https://webhostinggeeks.com/howto/how-to-install-perl-on-ubuntu/)
- R (conda + r-base installation)
- samtools-1.10, samtools-1.5
- bwa-0.7.15

## Scripts & Files
- General workflow (run_cnv.sh)
    - Alignment 
    - Sort
    - EXT & Gender information (transBAM)
    - Ratio
    - Normalisation
    - CNV calling
    - Homo
    - Breakpoint
    - Draw
    - Annotate

- Create directoy and access correct scripts
    - [write.sh](http://write.sh) : a script which creates all child directories and writes the necessary child scripts based on a path of the fastq (e.g. fq.lst) of the sample.

## Quick Tutorial
- Set-up
    0) Use docker pull to obtain bin file (https://docs.docker.com/reference/cli/docker/image/pull/).
    1) Make a directory called 'RawData' to store your fastq files.
            cd /home/CuhkOG_CNV_Calling #move into working dir with that the bin is cloned.
            mkdir -p RawData
    2) Make a directory with for your project (e.g. FlowCell1) using mkdir.
            mkdir -p RawData/FlowCell1
    3) Enter the 'FlowCell1' directory and create a sample.list file using vim. Here, write information of the sample with the following format (sampleID,path_to_fq1,path_to_fq2)
        e.g. 
            sample1,/home/CuhkOG_CNV_Calling/RawData/sample1.r1.fq.gz,/home/CuhkOG_CNV_Calling/RawData/sample1.r2.fq.gz
            sample2,/home/CuhkOG_CNV_Calling/RawData/sample2.r1.fq.gz,/home/CuhkOG_CNV_Calling/RawData/sample2.r2.fq.gz

            cd RawData/FlowCell1
    4) Now, run the write.sh script located in the bin to create all downstream files. The bin path is path to the bin folder (e.g. /home/CuhkOG_CNV_Calling/bin/) 
            cd FlowCell1
            sh /home/CuhkOG_CNV_Calling/bin/write.pl <Outdir> <sample.list> <bin_path>
            sh /home/CuhkOG_CNV_Calling/bin/write.pl /home/CuhkOG_CNV_Calling/FlowCell1 sample.list /home/CuhkOG_CNV_Calling/bin
    5) after creating the relevant scripts located in Project/results/sample/shell/all.sh. Take a look and run each part for your sample. (Make sure to check number of CPUs available before running each line) 

- While the docker is uploading/you figure out how to download it, you can run the write.sh script and try to conduct the alignment using all the scripts up to 'transBAM'.
    - for this, you need to install the binaries for samtools-1.5, samtools-1.10, and bwa-0.7.15 and put them into a directory like this "bin/tools" which will be the bin path for write.sh.
    - once the full bin directory is copied from the docker container, simply delete or move the 'bin' you created for alignment and replace it with the full bin. As long as the bin path remains the same, you can run the rest of the scripts after alignment or simply re-run write.sh (backup bam files and all intermediary files before re-running write.sh.)