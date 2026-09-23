# Engineering Decisions

## SCD Type 2 for customers

Customer segment and status are business attributes that can affect historical reporting, so customer history is preserved.

## Type 1 behavior for accounts/products

The demo keeps these dimensions simpler to focus the project on one explicit historization pattern.

## Reconciliation after ETL

Technical success is not the same as business completeness. Reconciliation is therefore executed as a separate control.

## Metadata-driven DQ

Rules are data rather than hard-coded branches in the ETL package.

## Autonomous operational logging

Technical errors and rejected rows are written independently so diagnostic evidence can survive rollbacks.

## Idempotency

Fact transaction references are unique and dimension loads use business keys to make reruns deterministic.

## APEX separation

The UI does not own the core business logic. It consumes database packages and reporting views.
