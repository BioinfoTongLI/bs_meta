#!/usr/bin/env/ nextflow

// Copyright (C) 2020 Tong LI <tongli.bioinfo@protonmail.com>

/*Take pairwise correlated tiles and fuse them*/

params.bs_xml = "/home/ubuntu/Documents/bs_meta/BigStitcher_xmls/191114_hBrest_rep_b4-1-MIP_info_for_bs.xml"

params.img_dir = "/nfs/team283_imaging/0ExternalData/2020-05-lucyYates_SciLife/20190617_Breast_Cancer_InSitu_Sequencing_878_csm_names/R1_Mutation_raw/Raw_zen_files/MutPD9694d3_raw/Cycle4/"

params.out_dir = "/home/ubuntu/Documents/bs_meta/"

params.ch_names = Channel.from(["DAPI", "Fluorescein", "Texas Red_narrow", "AF750", "Cy3_narrow", "Cy5_narrow"])

process generate_macro_for_fuse {
    echo true
    publishDir params.out_dir + "BigStitcher_ijms", mode:"copy"
    /*input:*/

    queue 'imaging'

    output:
    path "*.ijm" into fuse_ijms

    script:
    """
    echo $params.bs_xml
    python ${workflow.projectDir}/generate_macro_for_fuse.py -xml ${params.bs_xml} -img_dir /data/ -xml_folder /xml_folder/ -out_dir /fused/
    """
}


process generate_xml_per_channel {
    echo true
    publishDir params.out_dir + "BigStitcher_confs", mode:"copy"

    queue 'imaging'

    input:
    path macro from fuse_ijms
    val ch_name from params.ch_names

    output:
    path "${xml_stem}*.xml" into xml_for_diff_chs
    path "${xml_stem}*.ijm" into ijm_for_diff_chs

    script:
    xml_stem = file(params.bs_xml).baseName
    """
    sed 's/DAPI/${ch_name}/g' ${params.bs_xml} > "./${xml_stem}.xml"
    sed 's/DAPI/${ch_name}/g' ${macro} > "./${xml_stem}_${ch_name}.ijm"
    """
}

process fuse {
    echo true
    container "gitlab-registry.internal.sanger.ac.uk/tl10/img-fiji"
    containerOptions "-v " + params.img_dir + ":/data/:ro -v " + params.out_dir + "fused/:/fused/"

    queue 'imaging'

    input:
    path xml from xml_for_diff_chs
    path ijm from ijm_for_diff_chs


    script:
    """
    #ls /data/
    mkdir /xml_folder/
    cp $xml /xml_folder/
    ls /xml_folder/
    #more /xml_folder/$xml
    more $ijm
    /Fiji.app/ImageJ-linux64 --ij2 --headless --console --cpus-per-task=16 -macro $ijm
    """
}
