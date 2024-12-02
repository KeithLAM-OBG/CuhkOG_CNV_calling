#!/bin/bash
if [ "$#" -ne 3 ]; then
    echo "Error: Exactly 2 arguments required. Usage: $0 <Outdir>  <sample.info> <Bin path>" >&2
    exit 1
fi

path="$1"
samples="$2"
bin="$3"

#setup
mkdir -p "$path/result"



while IFS=, read -r sampleID fastq fastq2; do #reads and splits each line by commas and assign fields to variables
    # Skip lines that are empty or improperly formatted
    if [ -z "$sampleID" ] || [ -z "$fastq" ] || [ -z "$fastq2" ]; then
        echo "Skipping invalid line: $sampleID,$fastq,$fastq2" >&2
        continue
    fi

    # Create a directory named after the sampleID
    mkdir -p "$path/result/$sampleID"
    mkdir -p "$path/result/$sampleID/rawdata"
    mkdir -p "$path/result/$sampleID/shell"
    # Create symbolic links for fastq and fastq2 inside the rawdata subdirectory
    fq1=$(basename "$fastq")
    fq2=$(basename "$fastq2")
    fq1_name="${fq1%.fq.gz}"
    fq2_name="${fq2%.fq.gz}"
    ln -s "$fastq" "$path/result/$sampleID/rawdata/$fq1"
    ln -s "$fastq2" "$path/result/$sampleID/rawdata/$fq2"

    #write custom scripts to shell
    filepath="$path/result/$sampleID"
    cat <<EOL > "$filepath/shell/all.sh"
#!/bin/bash
#align paired reads
$bin/tools/bwa-0.7.15/bwa aln -t 8 -f $filepath/${fq1}.sai $bin/hg19/hg19.fa $filepath/rawdata/$fq1 && echo "aln first done{\n}"
$bin/tools/bwa-0.7.15/bwa samse $bin/hg19/hg19.fa $filepath/${fq1}.sai $filepath/rawdata/$fq1 | $bin/tools/samtools-1.5/samtools view -b -S -T -> $filepath/${fq1_name}.bam && echo "samse first done{\n}"
$bin/tools/samtools-1.5/samtools sort -@ 8 -m 2G -o $filepath/${fq1_name}_sort.bam $filepath/${fq1_name}.bam && echo "sort first done{\n}"
echo $filepath/${fq1_name}_sort.bam > $filepath/bam.lst

$bin/tools/bwa-0.7.15/bwa aln -t 8 -f $filepath/${fq2}.sai $bin/hg19/hg19.fa $filepath/rawdata/$fq2 && echo "aln done{\n}"
$bin/tools/bwa-0.7.15/bwa samse $bin/hg19/hg19.fa $filepath/${fq2}.sai $filepath/rawdata/$fq2 | $bin/tools/samtools-1.5/samtools view -b -S -T -> $filepath/${fq2_name}.bam && echo "samse done{\n}"
$bin/tools/samtools-1.5/samtools sort -@ 8 -m 2G -o $filepath/${fq2_name}_sort.bam $filepath/${fq2_name}.bam && echo "sort done{\n}"
echo $filepath/${fq2_name}_sort.bam >> $filepath/bam.lst
#merge
$bin/tools/samtools-1.10/samtools merge -@ 8 -b $filepath/bam.lst $filepath/${sampleID}_sort.bam && $bin/tools/samtools-1.5/samtools index $filepath/${sampleID}_sort.bam && echo "merge bam index done {\n}"
#transBAM
$bin/bin/TransBAM_EXT -ext $filepath/${sampleID}_sort.bam -out $filepath/${sampleID}_sort.ext.gz -sample $sampleID -gender $filepath/${sampleID}.gender.information -ref $bin/hg19/chr/ -insert 400 -samtools $bin/tools/samtools-1.5/samtools && echo "ext done" && sh $bin/low-pass/bin/ext.sort.sh $filepath/${sampleID}_sort.ext.gz $filepath/${sampleID}_sort.ext && rm $filepath/${sampleID}_sort.ext.gz && gzip $filepath/${sampleID}_sort.ext && echo "sort done"
#ratio
$bin/bin/ratio $filepath/${sampleID}_sort.ext.gz $filepath/ $filepath/${sampleID}.gender.information $bin/low-pass/bin/Config_file/ && echo "ratio done"
#normalise
$bin/bin/normalized_5k $filepath/ $bin/low-pass/bin/Config_file/ && echo "normalized done"
#cnv
$bin/bin/Increment_Ratio_of_Coverage_50k.20190508 -name $sampleID -outdir $filepath/ -gender $filepath/${sampleID}.gender.information -file $bin/low-pass/bin/ && echo "cnv done" 
#homo
$bin/bin/homo_20181211 $filepath/ $filepath/${sampleID}_raw.xls $filepath/${sampleID}_final.xls $bin/low-pass/bin/  > $filepath/homo && echo "home done"
#breakpoint
$bin/bin/find_breakpoint_cryptic20191219 $filepath/${sampleID}_final.xls $filepath/5k_summary.gz $filepath/${sampleID}_final.xlsx > $filepath/${sampleID}_final.xls.find.b.r && echo "find breakpoint done"
#draw
perl $bin/bin/copy-ratio.figure_50k_20190507.pl $filepath/ $filepath/${sampleID}.gender.information $sampleID && $bin/Rscript $filepath/${sampleID}_figure/copy-ratio.r && $bin/Rscript $bin/low-pass/bin/QC.r $filepath/{$sampleID}.all.gz $filepath/${sampleID}_figure/${sampleID}.QC.pdf && echo "draw done"
#annotate
perl $bin/low-pass/Annotate_cnv_50k_20181213.pl -name $sampleID -outdir $filepath/ -file $bin/low-pass/bin/ -clean $filepath/${sampleID}_final.xlsx -sex $filepath/${sampleID}.gender.information && echo "anno done"

EOL
	
done < "$samples"

echo 'write done'



