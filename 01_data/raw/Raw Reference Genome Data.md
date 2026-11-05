# Raw Reference Genome Data

## Reference Assembly

The annotation-related NM2 analyses use the following public reference assembly:

```text
Organism: Ramazzottius varieornatus
Assembly accession: GCA_001949185.1
Source: NCBI GenBank
```

## Role in the NM2 Workflow

The manuscript-level NM2 workflow operates on distributed processed expression matrices and metadata. It does not require genome assembly or RNA-seq alignment from raw sequencing reads.

The final Figure 5 annotation workflow additionally requires two NCBI-derived reference files:

```text
cds_from_genomic.fna
protein.faa
```

These files support gene-to-reference mapping, protein extraction, annotation matching, and downstream functional characterization.

## External Reference Preparation

The NCBI reference FASTA files are public external resources and are intentionally not committed to Git.

The repository provides a version-locked preparation script:

```bash
bash 02_methods/reference_data/prepare_ncbi_reference.sh
```

The script retrieves the required data for exactly:

```text
GCA_001949185.1
```

and prepares:

```text
01_data/raw/ncbi_dataset/ncbi_dataset/data/GCA_001949185.1/cds_from_genomic.fna
01_data/raw/ncbi_dataset/ncbi_dataset/data/GCA_001949185.1/protein.faa
```

The preparation step requires the NCBI Datasets command-line client and `unzip`.

The script validates that both required files exist and are non-empty. If a complete reference is already present, it is reused rather than downloaded again.

## Git Boundary

The downloaded raw-reference tree is ignored under:

```text
01_data/raw/ncbi_dataset/
```

The external reference therefore remains outside the version-controlled repository while the acquisition procedure and assembly accession remain version controlled.

## Scope

The complete genomic FASTA, GenBank file, GFF, and GTF are not required by the current manuscript master runner.

Only the CDS and protein FASTA resources above are required by the final Figure 5 annotation workflow.
