// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process CAT {
    tag "${assembler}-${name}-${db_name}"

    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:assembler) }

    conda (params.enable_conda ? "bioconda::cat=4.6" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/cat:4.6--0"
    } else {
        container "quay.io/biocontainers/cat:4.6--0"
    }

    input:
    tuple val(assembler), val(name), path("bins/*")
    tuple val(db_name), path("database/*"), path("taxonomy/*")

    output:
    path("*.names.txt")
    path("raw/*.ORF2LCA.txt")
    path("raw/*.predicted_proteins.faa")
    path("raw/*.predicted_proteins.gff")
    path("raw/*.log")
    path("raw/*.bin2classification.txt")
    path '*.version.txt'                , emit: version

    script:
    def software = getSoftwareName(task.process)
    """
    CAT bins -b "bins/" -d database/ -t taxonomy/ -n "${task.cpus}" -s .fa --top 6 -o "${assembler}-${name}" --I_know_what_Im_doing
    CAT add_names -i "${assembler}-${name}.ORF2LCA.txt" -o "${assembler}-${name}.ORF2LCA.names.txt" -t taxonomy/
    CAT add_names -i "${assembler}-${name}.bin2classification.txt" -o "${assembler}-${name}.bin2classification.names.txt" -t taxonomy/
    mkdir raw
    mv "*.ORF2LCA.txt" raw/
    mv "*.predicted_proteins.faa" raw/
    mv "*.predicted_proteins.gff" raw/
    mv "*.log" raw/
    mv "*.bin2classification.txt" raw/

    CAT --version | sed "s/CAT v//; s/(.*//" > ${software}.version.txt
    """
}
