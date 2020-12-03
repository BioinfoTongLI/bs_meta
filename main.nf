#!/usr/bin/env/ nextflow

// Copyright (C) 2020 Tong LI <tongli.bioinfo@protonmail.com>

/*Run bigStitcher for .czi files*/


params.img_dir = "/nfs/team283_imaging/0ExternalData/2020-05-lucyYates_SciLife/20190617_Breast_Cancer_InSitu_Sequencing_878_csm_names/R1_Mutation_raw/Raw_zen_files/MutPD9694d3_raw/Cycle4/"
params.czi_xml = "191114_hBrest_rep_b4-1-MIP_info.xml"
params.out_dir = "/home/ubuntu/Documents/bs_meta/"
params.dapi_pattern = "191114_hBrest_rep_b4-1-MIP_m{xxx}_DAPI_ORG.tif"

czi_xml_path = params.img_dir + params.czi_xml


process generate_xml_for_bigstitcher {
    /*echo true*/
    publishDir params.out_dir + "BigStitcher_xmls", mode:"copy"
    container "/lustre/scratch117/cellgen/team283/BigStitcher_stitching/ImageAnalysis_cpu.sif"
    containerOptions "-B /lustre:/lustre:ro,/nfs:/nfs:ro"

    queue "imaging"

    input:
    path xml from czi_xml_path
    val dapi_pattern from params.dapi_pattern

    output:
    path "*.xml" into bigstitcher_xml

    script:
    """
    ls -lh /nfs/
    python ${baseDir}/read_meta.py -czi_xml ${xml} -out "./" -pattern_str ${dapi_pattern}
    """
}


process generate_ijm_for_fiji {
    echo true
    publishDir params.out_dir + "BigStitcher_ijms", mode:"copy"
    container "/lustre/scratch117/cellgen/team283/BigStitcher_stitching/ImageAnalysis_cpu.sif"
    containerOptions "-B /lustre:/lustre:ro,/nfs/:/nfs/"

    queue "imaging"

    input:
    path xml from bigstitcher_xml
    val dapi_pattern from params.dapi_pattern

    output:
    path "*.ijm" into ijm_scripts

    script:
    """
    python ${workflow.projectDir}/generate_macro_for_tile_shift_estimation.py -xml ${xml} -img_dir "/data/" -pattern_str ${dapi_pattern} -xml_folder "/xml_folder/"
    """
}


process calculate_pairwise_shifts {
    echo true
    container "/lustre/scratch117/cellgen/team283/BigStitcher_stitching/fiji.sif"
    containerOptions "-B " + params.img_dir + ":/data/," + params.out_dir + "BigStitcher_xmls:/xml_folder/,/lustre:/lustre:ro"

    queue "imaging"

    input:
    file macro from ijm_scripts

    script:
    """
    #ls /xml_folder/
    #ls /data/
    /Fiji.app/ImageJ-linux64 --ij2 --headless --console --cpus-per-task=12 -macro ${macro}
    """
}
