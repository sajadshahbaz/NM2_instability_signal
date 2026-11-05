#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# NM2 Figure 2 reproducible composite assembly
# ============================================================
#
# Purpose
# -------
# Rebuild the final manuscript Figure 2 reproducibly from:
#
#   A) locked standalone conceptual synthetic-regime panel
#
#   B) regenerated locked Figure 2B output
#
#   C) regenerated corrected Q25/Q90 Figure 2C output
#
# Scientific inputs
# -----------------
# 04_results/figure2b/figure2B_final_lock.png
# 04_results/figure2c/figure2C_final_lock.png
# 04_results/figure2c/figure2C_summary_stats.tsv
#
# Locked graphical input
# ------------------------
# 01_data/precomputed/figure_assets/figure2A_conceptual_locked.png
#
# Output
# ------
# A candidate composite is created first:
#
# 04_results/figure2_final_assembly/
#     Fig2_synthetic_validation_CANDIDATE.tiff
#
# The canonical manuscript figure is NOT overwritten by this script.
#
# Requirements
# ------------
# ImageMagick 6.x:
#   convert
#   identify
#
# Python 3:
#   used only for numerical TSV validation
#
# ============================================================


# ------------------------------------------------------------
# 0. Repository root
# ------------------------------------------------------------

if [[ -z "${NM2_ROOT:-}" ]]; then
    NM2_ROOT="$(pwd)"
fi

ROOT="${NM2_ROOT}"

A="${ROOT}/01_data/precomputed/figure_assets/figure2A_conceptual_locked.png"

B="${ROOT}/04_results/figure2b/figure2B_final_lock.png"
C="${ROOT}/04_results/figure2c/figure2C_final_lock.png"

SUMMARY="${ROOT}/04_results/figure2c/figure2C_summary_stats.tsv"

WORK="${ROOT}/04_results/figure2_final_assembly"

B_NORM="${WORK}/figure2B_normalized.png"
C_NORM="${WORK}/figure2C_normalized.png"

B_CELL="${WORK}/figure2B_cell.png"
C_CELL="${WORK}/figure2C_cell.png"

LOWER="${WORK}/figure2_BC_row.png"

CANDIDATE="${WORK}/Fig2_synthetic_validation_CANDIDATE.tiff"
PREVIEW="${WORK}/Fig2_synthetic_validation_CANDIDATE.png"

REPORT="${WORK}/figure2_composite_manifest.txt"

mkdir -p "${WORK}"


# ------------------------------------------------------------
# 1. Helper functions
# ------------------------------------------------------------

fail() {
    echo
    echo "FAIL: $1"
    echo
    exit 1
}

section() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}


# ------------------------------------------------------------
# 2. Start
# ------------------------------------------------------------

section "NM2 FIGURE 2 REPRODUCIBLE ASSEMBLY"

echo "Repository root:"
echo "${ROOT}"
echo


# ------------------------------------------------------------
# 3. Check required software
# ------------------------------------------------------------

section "CHECKING SOFTWARE"

command -v convert >/dev/null 2>&1 \
    || fail "ImageMagick 'convert' not found."

command -v identify >/dev/null 2>&1 \
    || fail "ImageMagick 'identify' not found."

command -v sha256sum >/dev/null 2>&1 \
    || fail "'sha256sum' not found."

command -v python3 >/dev/null 2>&1 \
    || fail "'python3' not found."

echo "ImageMagick:"
convert -version | head -1

echo
echo "Python:"
python3 --version

echo
echo "PASS: required software available."


# ------------------------------------------------------------
# 4. Validate required files
# ------------------------------------------------------------

section "CHECKING INPUT FILES"

for f in \
    "${A}" \
    "${B}" \
    "${C}" \
    "${SUMMARY}"
do
    if [[ ! -f "${f}" ]]; then
        fail "Required input missing: ${f}"
    fi

    echo "FOUND:"
    echo "  ${f}"
done

echo
echo "PASS: all required inputs found."


# ------------------------------------------------------------
# 5. Record input hashes before doing anything
# ------------------------------------------------------------

section "INPUT SHA256"

sha256sum "${A}"
sha256sum "${B}"
sha256sum "${C}"
sha256sum "${SUMMARY}"


# ------------------------------------------------------------
# 6. Validate Figure 2C numerical results
# ------------------------------------------------------------

section "VALIDATING CORRECTED FIGURE 2C"

echo "Figure 2C summary:"
echo

cat "${SUMMARY}"

echo

python3 - "${SUMMARY}" <<'PY'
import csv
import math
import sys

path = sys.argv[1]

expected = {
    "coherent": (
        0.0,
        0.0,
    ),
    "null": (
        0.000485714285714286,
        0.000506400997952892,
    ),
    "opposing": (
        0.13835,
        0.0180914483955958,
    ),
    "phase": (
        0.13945,
        0.0202870187882087,
    ),
}

with open(path, newline="", encoding="utf-8") as handle:
    reader = csv.DictReader(handle, delimiter="\t")

    observed = {}

    for row in reader:
        observed[row["scenario"]] = (
            float(row["mean_fraction"]),
            float(row["sd_fraction"]),
        )

missing = sorted(set(expected) - set(observed))

if missing:
    raise SystemExit(
        "FAIL: missing Figure 2C scenarios: "
        + ", ".join(missing)
    )

for scenario, expected_values in expected.items():

    observed_values = observed[scenario]

    for observed_value, expected_value in zip(
        observed_values,
        expected_values,
    ):

        if not math.isclose(
            observed_value,
            expected_value,
            rel_tol=1e-12,
            abs_tol=1e-12,
        ):
            raise SystemExit(
                f"FAIL: numerical mismatch for {scenario}: "
                f"observed={observed_values}, "
                f"expected={expected_values}"
            )

print(
    "PASS: Figure 2C summary matches locked corrected "
    "Q25/Q90 results."
)

print(
    "Rounded manuscript values:"
)

print("  coherent : 0.000")
print("  null     : 0.00049 ± 0.00051")
print("  opposing : 0.138 ± 0.018")
print("  phase    : 0.139 ± 0.020")
PY


# ------------------------------------------------------------
# 7. Validate locked standalone conceptual Panel A
# ------------------------------------------------------------

section "VALIDATING LOCKED CONCEPTUAL PANEL A"

EXPECTED_A_SHA256="82bd92bd3aabacab66ef59329f9c9c0ce56279fd9beb688ca00cf7e439446ab8"

A_SHA256="$(
    sha256sum "${A}" | awk '{print $1}'
)"

A_DIMENSIONS="$(
    identify -format '%wx%h' "${A}"
)"

echo "Panel A:"
identify "${A}"

echo
echo "Panel A SHA256:"
echo "  ${A_SHA256}"

if [[ "${A_SHA256}" != "${EXPECTED_A_SHA256}" ]]; then
    fail "Panel A SHA256 does not match locked standalone asset."
fi

if [[ "${A_DIMENSIONS}" != "4652x1370" ]]; then
    fail "Unexpected Panel A dimensions: ${A_DIMENSIONS}"
fi

echo
echo "PASS: locked standalone conceptual Panel A verified."


# ------------------------------------------------------------
# 9. Normalize regenerated B and corrected C
# ------------------------------------------------------------

section "NORMALIZING PANELS B AND C"

LOWER_HEIGHT=1320

convert \
    "${B}" \
    -resize "x${LOWER_HEIGHT}" \
    "${B_NORM}"

convert \
    "${C}" \
    -resize "x${LOWER_HEIGHT}" \
    "${C_NORM}"

echo "Panel B normalized:"
identify "${B_NORM}"

echo
echo "Panel C normalized:"
identify "${C_NORM}"

echo
echo "PASS: B and C normalized without changing aspect ratio."


# ------------------------------------------------------------
# 10. Construct fixed lower-row cells
# ------------------------------------------------------------

section "BUILDING LOWER B+C ROW"

# Total target width matches historical Figure 2:
#
# 2500 + 2152 = 4652 pixels

CELL_B_WIDTH=2500
CELL_C_WIDTH=2152

# ------------------------------------------------------------
# Panel B cell
# ------------------------------------------------------------

convert \
    "${B_NORM}" \
    -gravity center \
    -background white \
    -extent "${CELL_B_WIDTH}x${LOWER_HEIGHT}" \
    -gravity northwest \
    -font DejaVu-Sans-Bold \
    -pointsize 72 \
    -fill black \
    -annotate +35+85 "b)" \
    "${B_CELL}"

# ------------------------------------------------------------
# Panel C cell
# ------------------------------------------------------------

convert \
    "${C_NORM}" \
    -gravity center \
    -background white \
    -extent "${CELL_C_WIDTH}x${LOWER_HEIGHT}" \
    -gravity northwest \
    -font DejaVu-Sans-Bold \
    -pointsize 72 \
    -fill black \
    -annotate +35+85 "c)" \
    "${C_CELL}"

echo "Panel B cell:"
identify "${B_CELL}"

echo
echo "Panel C cell:"
identify "${C_CELL}"


# ------------------------------------------------------------
# 11. Join B and C horizontally
# ------------------------------------------------------------

convert \
    "${B_CELL}" \
    "${C_CELL}" \
    +append \
    "${LOWER}"

LOWER_DIMENSIONS="$(
    identify -format '%wx%h' "${LOWER}"
)"

echo
echo "Lower row:"
identify "${LOWER}"

if [[ "${LOWER_DIMENSIONS}" != "4652x1320" ]]; then
    fail "Unexpected B+C row dimensions: ${LOWER_DIMENSIONS}"
fi

echo
echo "PASS: B+C row constructed."


# ------------------------------------------------------------
# 12. Assemble complete Figure 2
# ------------------------------------------------------------

section "ASSEMBLING FIGURE 2"

# A = 4652 x 1370
# lower = 4652 x 1320
#
# final = 4652 x 2690
#
# This is intentionally slightly shorter than the historical
# 2888-pixel TIFF because obsolete lower-panel whitespace is
# not retained.

convert \
    "${A}" \
    "${LOWER}" \
    -background white \
    -gravity center \
    -append \
    -units PixelsPerInch \
    -density 600 \
    -compress Zip \
    "${CANDIDATE}"

echo "Candidate TIFF:"
identify "${CANDIDATE}"


# ------------------------------------------------------------
# 13. Generate PNG preview
# ------------------------------------------------------------

convert \
    "${CANDIDATE}" \
    "${PREVIEW}"

echo
echo "Preview:"
identify "${PREVIEW}"


# ------------------------------------------------------------
# 14. Validate final dimensions
# ------------------------------------------------------------

section "FINAL IMAGE QC"

FINAL_DIMENSIONS="$(
    identify -format '%wx%h' "${CANDIDATE}"
)"

echo "Final candidate dimensions:"
echo "  ${FINAL_DIMENSIONS}"

if [[ "${FINAL_DIMENSIONS}" != "4652x2690" ]]; then
    fail "Unexpected final candidate dimensions."
fi

echo

FINAL_DENSITY="$(
    identify -format '%x x %y' "${CANDIDATE}"
)"

echo "Stored density:"
echo "  ${FINAL_DENSITY}"

echo
echo "Candidate SHA256:"
sha256sum "${CANDIDATE}"

echo
echo "Preview SHA256:"
sha256sum "${PREVIEW}"


# ------------------------------------------------------------
# 15. Write reproducibility manifest
# ------------------------------------------------------------

section "WRITING MANIFEST"

{
    echo "NM2 Figure 2 reproducible composite manifest"
    echo "============================================"
    echo

    echo "Generated:"
    date --iso-8601=seconds
    echo

    echo "Repository root:"
    echo "."
    echo

    echo "Assembly script:"
    echo "02_methods/R/figure_generation/assemble_figure2_composite.sh"
    echo

    echo "Scientific interpretation:"
    echo "Panel A: locked conceptual graphical asset."
    echo "Panel B: regenerated synthetic pooled-vs-structured analysis."
    echo "Panel C: regenerated corrected Q25/Q90 masking analysis."
    echo

    echo "Corrected Figure 2C values:"
    echo "coherent = 0"
    echo "null = 0.000485714285714286"
    echo "opposing = 0.13835"
    echo "phase = 0.13945"
    echo

    echo "Software:"
    convert -version | head -1
    python3 --version
    echo

    echo "INPUT SHA256"
    echo "------------"

    printf '%s  %s\n' "$(sha256sum "${A}" | awk '{print $1}')" \
        "01_data/precomputed/figure_assets/figure2A_conceptual_locked.png"
    printf '%s  %s\n' "$(sha256sum "${B}" | awk '{print $1}')" \
        "04_results/figure2b/figure2B_final_lock.png"
    printf '%s  %s\n' "$(sha256sum "${C}" | awk '{print $1}')" \
        "04_results/figure2c/figure2C_final_lock.png"
    printf '%s  %s\n' "$(sha256sum "${SUMMARY}" | awk '{print $1}')" \
        "04_results/figure2c/figure2C_summary_stats.tsv"

    echo

    echo "DERIVED SHA256"
    echo "--------------"

    printf '%s  %s\n' "$(sha256sum "${B_NORM}" | awk '{print $1}')" \
        "04_results/figure2_final_assembly/figure2B_normalized.png"
    printf '%s  %s\n' "$(sha256sum "${C_NORM}" | awk '{print $1}')" \
        "04_results/figure2_final_assembly/figure2C_normalized.png"
    printf '%s  %s\n' "$(sha256sum "${B_CELL}" | awk '{print $1}')" \
        "04_results/figure2_final_assembly/figure2B_cell.png"
    printf '%s  %s\n' "$(sha256sum "${C_CELL}" | awk '{print $1}')" \
        "04_results/figure2_final_assembly/figure2C_cell.png"
    printf '%s  %s\n' "$(sha256sum "${LOWER}" | awk '{print $1}')" \
        "04_results/figure2_final_assembly/figure2_BC_row.png"
    printf '%s  %s\n' "$(sha256sum "${CANDIDATE}" | awk '{print $1}')" \
        "04_results/figure2_final_assembly/Fig2_synthetic_validation_CANDIDATE.tiff"
    printf '%s  %s\n' "$(sha256sum "${PREVIEW}" | awk '{print $1}')" \
        "04_results/figure2_final_assembly/Fig2_synthetic_validation_CANDIDATE.png"

    echo

    echo "DIMENSIONS"
    echo "----------"

    identify -format \
        "01_data/precomputed/figure_assets/figure2A_conceptual_locked.png %m %wx%h\n" "${A}"
    identify -format \
        "04_results/figure2b/figure2B_final_lock.png %m %wx%h\n" "${B}"
    identify -format \
        "04_results/figure2c/figure2C_final_lock.png %m %wx%h\n" "${C}"
    identify -format \
        "04_results/figure2_final_assembly/figure2B_normalized.png %m %wx%h\n" "${B_NORM}"
    identify -format \
        "04_results/figure2_final_assembly/figure2C_normalized.png %m %wx%h\n" "${C_NORM}"
    identify -format \
        "04_results/figure2_final_assembly/figure2_BC_row.png %m %wx%h\n" "${LOWER}"
    identify -format \
        "04_results/figure2_final_assembly/Fig2_synthetic_validation_CANDIDATE.tiff %m %wx%h\n" "${CANDIDATE}"

} > "${REPORT}"

echo "Manifest written:"
echo "${REPORT}"


# ------------------------------------------------------------
# 16. Final status
# ------------------------------------------------------------

section "PASS"

echo "Figure 2 candidate successfully rebuilt."
echo
echo "Panel A:"
echo "  verified locked standalone conceptual asset"
echo
echo "Panel B:"
echo "  regenerated locked synthetic analysis"
echo
echo "Panel C:"
echo "  corrected Q25/Q90 analysis"
echo "  opposing = 0.138"
echo "  phase    = 0.139"
echo
echo "Candidate TIFF:"
echo "  ${CANDIDATE}"
echo
echo "Preview PNG:"
echo "  ${PREVIEW}"
echo
echo "Manifest:"
echo "  ${REPORT}"
echo
echo "IMPORTANT:"
echo "  Canonical 03_figures/main/Fig2_synthetic_validation.tiff"
echo "  has NOT been overwritten."
echo
echo "Next step: visual QC, then controlled promotion to canonical."
echo
