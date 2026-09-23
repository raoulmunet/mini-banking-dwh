# Architecture

The project is intentionally organized in layers.

## 1. Staging

Raw-ish source data lands in:

- `STG_CUSTOMER`
- `STG_ACCOUNT`
- `STG_TRANSACTION`

## 2. Data Quality

`PKG_DQ` executes metadata rules before warehouse promotion.

## 3. ETL Control

`PKG_BATCH` records batch/job status, row counts, rejects and errors.

## 4. DWH

`PKG_DWH_LOAD` loads dimensions and facts.

`DIM_CUSTOMER` uses SCD Type 2.

## 5. Reconciliation

`PKG_RECON` compares valid staging transactions with `FACT_TRANSACTION`.

## 6. Lineage

`PKG_LINEAGE` traverses Oracle dependency metadata.

## 7. Presentation

Views expose stable datasets for APEX or other reporting clients.
