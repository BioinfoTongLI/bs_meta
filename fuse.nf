#!/usr/bin/env/ nextflow

// Copyright (C) 2020 Tong LI <tongli.bioinfo@protonmail.com>

/*Take pairwise correlated tiles and fuse them*/

params.bs_xml = "/home/ubuntu/Documents/bs_meta/BigStitcher_xmls/191114_hBrest_rep_b4-1-MIP_info_for_bs.xml"

params.img_dir = "/nfs/team283_imaging/0ExternalData/2020-05-lucyYates_SciLife/20190617_Breast_Cancer_InSitu_Sequencing_878_csm_names/R1_Mutation_raw/Raw_zen_files/MutPD9694d3_raw/Cycle4/"

params.out_dir = "/home/ubuntu/Documents/bs_meta/"

params.ch_names = Channel.from("DAPI", "Fluorescein", "Texas Red_narrow", "AF750", "Cy3_narrow", "Cy5_narrow")

Channel.fromPath(params.bs_xml).into{bs_xml_to_generate_macro; bs_xml_to_generate_xml}


process generate_macro_for_fuse {
    echo true
    container "/lustre/scratch117/cellgen/team283/BigStitcher_stitching/ImageAnalysis_cpu.sif"
    containerOptions "-B /lustre:/lustre:ro"
    publishDir params.out_dir + "BigStitcher_ijms", mode:"copy"

    queue 'imaging'

    input:
    path bs_xml from bs_xml_to_generate_macro

    output:
    path "*.ijm" into fuse_ijms

    script:
    """
    python ${baseDir}/generate_macro_for_fuse.py -xml ${bs_xml} -img_dir /data/ -xml_folder /xml_folder/ -out_dir /fused/
    """
}


fuse_ijms.combine(params.ch_names).combine(bs_xml_to_generate_xml.combine(params.ch_names), by: 1)
    .set{params_for_all_channels}

process generate_xml_per_channel {
    echo true
    container "/lustre/scratch117/cellgen/team283/BigStitcher_stitching/ImageAnalysis_cpu.sif"
    containerOptions "-B /lustre:/lustre:ro"
    publishDir params.out_dir + "BigStitcher_confs", mode:"copy"

    queue 'imaging'

    input:
    tuple val(ch_name), path(macro), path(bs_xml) from params_for_all_channels

    output:
    tuple path("${xml_stem}_${ch_name}.xml"), path("${xml_stem}_${ch_name}_mod.ijm") into diff_ch_files_for_fuse

    script:
    xml_stem = file(bs_xml).baseName
    xml_name = file(bs_xml).name
    """
    echo "${ch_name}"
    sed 's/DAPI/${ch_name}/g' ${macro} > "./${xml_stem}_${ch_name}.ijm"
    sed 's/${xml_name}/${xml_stem}_${ch_name}.xml/g' "./${xml_stem}_${ch_name}.ijm" > "./${xml_stem}_${ch_name}_mod.ijm"

    sed 's/DAPI/${ch_name}/g' ${bs_xml} > "./${xml_stem}_${ch_name}.xml"
    """
}


process fuse {
    echo true
    container "/lustre/scratch117/cellgen/team283/BigStitcher_stitching/fiji.sif"
    containerOptions "-B " + params.img_dir + ":/data/:ro," + params.out_dir + "fused/:/fused/,/nfs:/nfs," + params.out_dir + "/xml_folder/:/xml_folder/"
    //"gitlab-registry.internal.sanger.ac.uk/tl10/img-fiji"
    //containerOptions "-v " + params.img_dir + ":/data/:ro -v " + params.out_dir + "fused/:/fused/"

    queue = "imaging"
    cpus = 12
    memory = 15.GB
    maxForks = 6

    input:
    tuple path(xml), path(ijm) from diff_ch_files_for_fuse

    script:
    """
    cp $xml /xml_folder/
    ls /xml_folder/
    #more /xml_folder/$xml
    /Fiji.app/ImageJ-linux64 --ij2 --headless --console --cpus-per-task=12 -macro $ijm
    more $ijm
    """
}
