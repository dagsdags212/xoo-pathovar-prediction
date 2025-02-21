
# Retrieve all SRA records related to Xoo.
query_xoo_all_reads() {
  # Should return 1044 records (as of Feb. 21, 2025).
  esearch -db sra -query "Xanthomonas oryzae pv. oryzae" \
    | esummary
}

# Filter SRA records to only include long reads (ont,pacbio).
query_xoo_long_reads() {
  local tmpfile=/tmp/xoo_sra_metadata.xml

  # Save to temporary file if it does not exist.
  [ -f ${tmpfile} ] || query_xoo_all_reads > ${tmpfile}

  cat ${tmpfile} | xtract -pattern DocumentSummary -sep ',' -element Id,Bioproject,Biosample,Platform,CreateDate \
    | awk -F ',' '{ if($4 ~ /OXFORD_NANOPORE|PACBIO_SMRT/) print $0 }'
}

fetch_xoo_long_read_runinfo() {
  query_xoo_long_reads | cut -d, -f1 \
    | efetch -db sra -format runinfo \
    | cut -d, -f 1,4-5,7-8,10,19,22,24,26,29
}
