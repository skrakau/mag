// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process KRONA_DB {

    conda (params.enable_conda ? "bioconda::krona=2.7.1" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/krona:2.7.1--pl526_4"
    } else {
        container "quay.io/biocontainers/krona:2.7.1--pl526_4"
    }

    output:
    path("taxonomy/taxonomy.tab")

    script:
    """
    ktUpdateTaxonomy.sh taxonomy
    """
}
