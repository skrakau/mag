// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process QUAST_BINS {
    tag "$assembler-$name"

    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? "bioconda::quast=5.0.2" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/quast:5.0.2--py37pl526hb5aa323_2"
    } else {
        container "quay.io/biocontainers/quast:5.0.2--py37pl526hb5aa323_2"
    }

    input:
    tuple val(assembler), val(name), path(bins)

    output:
    path "QUAST/*", type: 'dir'
    path "QUAST/*-quast_summary.tsv", emit: quast_bin_summaries

    script:
    """
    BINS=\$(echo \"$bins\" | sed 's/[][]//g')
    IFS=', ' read -r -a bins <<< \"\$BINS\"
    for bin in \"\${bins[@]}\"; do
        metaquast.py --threads "${task.cpus}" --max-ref-number 0 --rna-finding --gene-finding -l "\${bin}" "\${bin}" -o "QUAST/\${bin}"
        if ! [ -f "QUAST/${assembler}-${name}-quast_summary.tsv" ]; then
            cp "QUAST/\${bin}/transposed_report.tsv" "QUAST/${assembler}-${name}-quast_summary.tsv"
        else
            tail -n +2 "QUAST/\${bin}/transposed_report.tsv" >> "QUAST/${assembler}-${name}-quast_summary.tsv"
        fi
    done
    """
}
