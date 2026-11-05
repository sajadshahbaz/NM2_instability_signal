#!/usr/bin/env bash
set -euo pipefail
: "${METADATA:?set METADATA}"; : "${FASTQ_DIR:?set FASTQ_DIR}"; : "${GENOME:?set GENOME}"; : "${ANNOTATION:?set ANNOTATION}"; : "${OUT:?set OUT}"
THREADS="${THREADS:-8}"; HERE="$(cd "$(dirname "$0")" && pwd)"; mkdir -p "$OUT"/{qc,reference,salmon,expression,provenance}
exec > >(tee -a "$OUT/provenance/pipeline.log") 2>&1
echo "NM2 preprocessing start $(date -Is)"
python3 "$HERE/00_validate_inputs.py" --metadata "$METADATA" --fastq-dir "$FASTQ_DIR" --expected 111 --out "$OUT/provenance/fastq_manifest.tsv"
python3 "$HERE/01_fastp_qc.py" --manifest "$OUT/provenance/fastq_manifest.tsv" --out-dir "$OUT/qc/fastp" --threads 4 --multiqc-dir "$OUT/qc/multiqc"
python3 "$HERE/02_build_salmon_reference.py" --genome "$GENOME" --annotation "$ANNOTATION" --out-dir "$OUT/reference" --prefix Rvar --threads "$THREADS" --k 31
python3 "$HERE/03_salmon_quantify.py" --manifest "$OUT/provenance/fastq_manifest.tsv" --trimmed-dir "$OUT/qc/fastp" --index "$OUT/reference/Rvar.salmon_index" --out-dir "$OUT/salmon" --threads "$THREADS"
Rscript --vanilla "$HERE/04_tximport_deseq2_vst.R" "$METADATA" "$OUT/salmon" "$OUT/reference/Rvar.tx2gene.tsv" "$OUT/expression"
Rscript --vanilla "$HERE/05_expression_qc.R" "$OUT/expression/dds_all_preview.rds" "$METADATA" "$OUT/qc/expression"
Rscript --vanilla "$HERE/06_apply_nm2_expression_filter.R" "$OUT/expression/vst_counts_all_groups.tsv" "$OUT/expression/x_count.csv" "$OUT/expression"
{ fastp --version || true; multiqc --version || true; salmon --version || true; R --version | head -1 || true; python3 --version || true; } > "$OUT/provenance/software_versions.txt"
find "$OUT" -type f ! -path '*/provenance/checksums.sha256' -print0 | sort -z | xargs -0 sha256sum > "$OUT/provenance/checksums.sha256"
echo "NM2 preprocessing PASS $(date -Is)"
