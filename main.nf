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

    /*input:*/

    output:
    path "*.xml" into bigstitcher_xml

    script:
    """
    python ${workflow.projectDir}/read_meta.py -czi_xml $czi_xml_path -out "./" -pattern_str ${params.dapi_pattern}
    """
}


process generate_ijm_for_fiji {
    echo true
    publishDir params.out_dir + "BigStitcher_ijms", mode:"copy"

    input:
    path xml from bigstitcher_xml

    output:
    path "*.ijm" into ijm_scripts

    script:
    """
    python ${workflow.projectDir}/generate_macro_for_tile_shift_estimation.py -xml ${xml} -img_dir "/data/" -pattern_str ${params.dapi_pattern} -xml_folder "/xml_folder/"
    """
}


process calculate_pairwise_shifts {
    echo true
    container "gitlab-registry.internal.sanger.ac.uk/tl10/img-fiji"
    containerOptions "-v " + params.img_dir + ":/data/ -v " + params.out_dir + "BigStitcher_xmls:/xml_folder/"

    input:
    path macro from ijm_scripts

    script:
    """
    #ls /xml_folder/
    #ls /data/
    /Fiji.app/ImageJ-linux64 --ij2 --headless --console --cpus-per-task=16 -macro $macro
    more $macro
    """
}
