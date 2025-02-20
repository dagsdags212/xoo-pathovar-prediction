# Conda environement.
ENV ?= thesis

# Base name for output files.
OUTNAME ?= xoo_asm

# directory for storing generated files.
OUTDIR ?= metadata

# Xoo assembly metadata in XML format.
ASM_METADATA_XML = ${OUTDIR}/${OUTNAME}_metadata.xml

# List of assembly accessions.
ASM_ACCESSION_LIST = ${OUTDIR}/${OUTNAME}_accessions.txt

# Xoo assembly metadata in XML format.
ASM_METADATA_TSV = ${OUTDIR}/${OUTNAME}_metadata.tsv

# List of dependencies.
DEPS := esearch efetch efilter esummary xtract


help::
	@echo ""
	@echo "metadata.mk: retrieve metadata related to Xoo assemblies hosted at NCBI"
	@echo ""
	@echo "Usage:"
	@echo "  make -f metadata.mk [options] <command>"
	@echo ""
	@echo "Commands:"
	@echo "  accessions        generate a list of assembly accessions for Xoo"
	@echo "  metadata          include assembly-related metadata"
	@echo ""
	@echo "Options:"
	@echo "  OUTNAME           base name for output files"
	@echo "  OUTDIR            path to an output directory"
	@echo "  ENV               specify name of conda environment"
	@echo ""

# Summarize metadata for all Xoo assemblies.
${ASM_METADATA_XML}:
	@mkdir -p $(dir $@)
	@echo "Querying NCBI for Xoo assemblies"
	esearch -db assembly -query "Xanthomonas oryzae pv. oryzae" \
	  | efilter -status latest \
	  | esummary > $@
	@echo "Assembly metadata (in XML) written to: $(realpath $@)"

# Extract a list of assembly accessions.
${ASM_ACCESSION_LIST}: ${ASM_METADATA_XML}
	@echo "Extracting assembly accessions from $<"
	cat $< | xtract -pattern DocumentSummary -element AssemblyAccession | uniq | sort > $@
	@echo "Accession list written to: $(realpath $@)"

# Generate accession list.
accessions: ${ASM_ACCESSION_LIST}

parallel_flags := --delay 2 --progress
${ASM_METADATA_TSV}: ${ASM_ACCESSION_LIST}
	@[ -f $@ ] && rm -f $@
	@echo "Parsing metadata for each assembly $<"
	cat $<
	  | parallel ${parallel_flags} "datasets summary genome accession {} | jq -r '.reports[] | [.accession, .assembly_info.bioproject_accession, .assembly_info.sequencing_tech, .assembly_info.assembly_level, .assembly_info.biosample.geo_loc_name, .assembly_info.biosample.strain, .assembly_stats.contig_n50, .assembly_stats.gc_percent, .assembly_stats.genome_coverage, .assembly_stats.number_of_contigs] | @tsv' >> $@"
	@echo "Assembly metadata (in TSV) written to: $(realpath $@)"

metadata: ${ASM_METADATA_TSV}

.PHONY: help accessions metadata
