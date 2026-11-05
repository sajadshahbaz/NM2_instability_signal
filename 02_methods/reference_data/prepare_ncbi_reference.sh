#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# NM2 external NCBI reference preparation
# ============================================================
#
# Downloads the version-locked Ramazzottius varieornatus
# reference resources required by the Figure 5 annotation
# workflow.
#
# These public NCBI files are intentionally not tracked by Git.
#
# Required assembly:
#   GCA_001949185.1
#
# Required files:
#   cds_from_genomic.fna
#   protein.faa
# ============================================================

ACCESSION="GCA_001949185.1"

ROOT="${NM2_ROOT:-$(pwd)}"
ROOT="$(cd "${ROOT}" && pwd)"

RAW_ROOT="${ROOT}/01_data/raw/ncbi_dataset"
DATA_DIR="${RAW_ROOT}/ncbi_dataset/data/${ACCESSION}"

CDS="${DATA_DIR}/cds_from_genomic.fna"
PROTEIN="${DATA_DIR}/protein.faa"

ZIP="${RAW_ROOT}/${ACCESSION}_dataset.zip"

echo "NM2 NCBI reference preparation"
echo "=============================="
echo
echo "Repository root: ${ROOT}"
echo "Assembly:        ${ACCESSION}"
echo

# ------------------------------------------------------------
# 1. Check required software
# ------------------------------------------------------------

command -v datasets >/dev/null 2>&1 || {
    echo "ERROR: NCBI datasets CLI is not available." >&2
    exit 1
}

command -v unzip >/dev/null 2>&1 || {
    echo "ERROR: unzip is not available." >&2
    exit 1
}

echo "NCBI datasets:"
datasets version
echo

# ------------------------------------------------------------
# 2. Reuse complete existing reference if available
# ------------------------------------------------------------

if [[ -s "${CDS}" && -s "${PROTEIN}" ]]; then
    echo "PASS: required NCBI reference files already exist."
    echo
    echo "CDS:"
    echo "  01_data/raw/ncbi_dataset/ncbi_dataset/data/${ACCESSION}/cds_from_genomic.fna"
    echo "Protein:"
    echo "  01_data/raw/ncbi_dataset/ncbi_dataset/data/${ACCESSION}/protein.faa"
    echo
    echo "SHA256:"
    sha256sum "${CDS}" "${PROTEIN}" | sed "s#${ROOT}/##"
    exit 0
fi

# ------------------------------------------------------------
# 3. Download exact versioned assembly
# ------------------------------------------------------------

mkdir -p "${RAW_ROOT}"

rm -f "${ZIP}"
rm -rf "${RAW_ROOT}/ncbi_dataset"

echo "Downloading version-locked NCBI assembly ${ACCESSION}..."
echo

datasets download genome accession "${ACCESSION}" \
    --include cds,protein \
    --filename "${ZIP}"

[[ -s "${ZIP}" ]] || {
    echo "ERROR: NCBI dataset archive was not created." >&2
    exit 1
}

# ------------------------------------------------------------
# 4. Extract
# ------------------------------------------------------------

echo
echo "Extracting NCBI dataset..."

unzip -q "${ZIP}" -d "${RAW_ROOT}"

# ------------------------------------------------------------
# 5. Validate exact required files
# ------------------------------------------------------------

for fp in "${CDS}" "${PROTEIN}"; do
    if [[ ! -s "${fp}" ]]; then
        echo "ERROR: required reference file missing or empty:" >&2
        echo "  ${fp}" >&2
        exit 1
    fi
done

# Download archive is no longer required.
rm -f "${ZIP}"

echo
echo "PASS: required NCBI reference prepared."
echo
echo "Assembly:"
echo "  ${ACCESSION}"
echo
echo "CDS:"
echo "  01_data/raw/ncbi_dataset/ncbi_dataset/data/${ACCESSION}/cds_from_genomic.fna"
echo
echo "Protein:"
echo "  01_data/raw/ncbi_dataset/ncbi_dataset/data/${ACCESSION}/protein.faa"
echo
echo "SHA256:"
sha256sum "${CDS}" "${PROTEIN}" | sed "s#${ROOT}/##"
