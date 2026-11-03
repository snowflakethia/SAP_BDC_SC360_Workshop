# What is simulated and what is real

SAP BDC Connect for Snowflake is not available on trial accounts, so this workshop simulates
the SAP side. Everything you build on top of it is real Snowflake. This page lists every
difference, so you know what changes in a client account.

## The SAP side (simulated)

| In a client account | In this workshop | What changes for real |
|---|---|---|
| A **Zerocopy Connector** links Snowflake to SAP Business Data Cloud (BDC). | None. Your instructor shows a real one in the Module 2 demo. | An ORGADMIN accepts the terms once; an admin creates and connects the connector. |
| Each shared data product is mounted as a **catalog-linked database** (CLD). Nothing is copied. | Database `SC360_L0`: one schema per data product (16 schemas, 21 tables, 398 rows), loaded from CSV files in this repo. | You get one database per data product, not one database with 16 schemas. Module 3 shows how L1 consolidates them. |
| A CLD is **read-only**. | `SC360_L0` is owned by the role `SC360_DATA_PROVIDER`, which no user holds. An `INSERT` fails (setup check 4). | Same behaviour. |
| A CLD's tables are refreshed by SAP. New tables and schema changes are discovered every `SYNC_INTERVAL_SECONDS` (default 1 day). | Static synthetic data. Nothing changes unless you re-run setup. | Data changes under you; design L2 refresh (`TARGET_LAG`) with that in mind. |
| A real CLD carries SAP's own column names (quoted, mixed case, such as `"PlantCategory"`) and technical columns such as `__OPERATION_TYPE` and a text `__TIMESTAMP`. Dates can arrive as text. | Plain upper-case names; dates already typed `DATE`; no technical columns. Lab 1 shows the real timestamp format as a literal. | Expect to type dates and normalise IDs in L1 (Lab 1), and to profile before you promise. |
| Dynamic Tables over a CLD need **change tracking** on its tables to refresh incrementally. | Setup switches change tracking on for every `SC360_L0` and `SC360_EXT` table (setup check 9), so Lab 2 gets the same 9 incremental / 6 full split as the demo. | Not yet verified on a real CLD, which is read-only. Check `refresh_mode` and `refresh_mode_reason` on your first Dynamic Table over a share. |
| SAP generates a read-only **CSN semantic view** in the CLD's `SNOWFLAKE$` schema: SAP labels, primary keys, dimensions, **0 relationships**. | `SC360_L0.CSN.<data product>`: one view per data product (16 views over 21 tables), same shape, 0 relationships. The name `SNOWFLAKE$` is reserved, so the lab uses `CSN`. | Same content and the same gap. The real view is called `SEMANTIC_MODEL`. |
| Columns that SAP marks as personal data are **masked for every role**, including ACCOUNTADMIN, until a role is unmasked with a tag. | Not simulated. The lab data is synthetic and contains no personal data. | Plan which role may see PII before building on it. |
| Reads of a data product may carry the **SAP data-sharing fee** (non-SOLEX BDC Connect accounts). | No SAP fees. | Module 3 shows where the fee boundary sits (L2) and why `TARGET_LAG` sets the fee there. Confirm rates with SAP. |
| **Share-back**: Snowflake publishes Iceberg tables to BDC as a data product. | Not in the labs. Your instructor may show it live. | Requires Iceberg V3 tables with primary keys, a share, and `SYSTEM$SAP_PUBLISH_DATA_PRODUCT`. |

## The Snowflake side (real)

| Built in | What | Real? |
|---|---|---|
| Lab 1 | L1 views over `SC360_L0` | Real |
| Lab 2 | L2 Dynamic Tables and serving views | Real |
| Lab 3 | The enterprise semantic view (entities, relationships, metrics) | Real |
| Lab 4 | The Cortex Agent and Snowflake CoWork (formerly Snowflake Intelligence) | Real |
| Lab 5 | Data metric functions and governance | Real (needs Enterprise Edition) |

## The non-SAP data (simulated)

`SC360_EXT` (14 tables, 7,850 rows) stands in for operational and supplier systems that a
client would load through normal ingestion (batch or streaming). In a client account these
are tables you load and own, not catalog-linked databases.

## One known difference to remember

Data metric functions cannot be attached to tables in a real share, but they *could* be
attached to the simulated `SC360_L0` tables. Lab 5 attaches them at L2, as you would in
production.

## Sources

- https://docs.snowflake.com/en/user-guide/data-integration/zero-copy/about-sap-snowflake
- https://docs.snowflake.com/en/user-guide/data-integration/zero-copy/sap-sql/setup
- https://docs.snowflake.com/en/user-guide/data-integration/zero-copy/sap-sql/explore-data-products
- https://docs.snowflake.com/en/user-guide/data-integration/zero-copy/sap-sql/publish-data
