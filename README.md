# SAP BDC Connect + Snowflake: From System of Record to System of Reasoning

Hands-on lab material for a 4-hour partner workshop. You build, in your own Snowflake
account, the layers that turn SAP data products into a governed, AI-ready answer:

> *"If Festo AG stops delivering, which customer orders are at risk, and for each part
> should we switch supplier, block it, or send it for review?"*

| Layer | What you build | Lab |
|---|---|---|
| Access | Profile simulated SAP BDC data products (read-only, like catalog-linked databases) | 1 |
| Prepare | L1 views and L2 Dynamic Tables (medallion) | 1–2 |
| Define | A semantic view: the executable business ontology | 3 |
| Reason | Cortex Analyst and a Cortex Agent in Snowflake CoWork | 4 |
| Trust | Guard checks, data metric functions and a test harness | 5 |

## What is simulated

You do not need SAP or SAP Business Data Cloud (BDC). In a client account, SAP BDC data
products appear in Snowflake as catalog-linked databases created by the Zerocopy
connector, with no data copied. Here, the database `SC360_L0` plays that role: it has the
same schemas and tables, is loaded from files in this repo, and is read-only. Everything
you build on top of it (Dynamic Tables, semantic view, agent, data quality) is real.
See `docs/simulated_vs_real.md`.

## Prerequisites

- A Snowflake account where you can use `ACCOUNTADMIN`. A free trial works; choose
  **Enterprise** edition (Lab 5 uses data metric functions, which need Enterprise or higher).
- Cortex AI available in your region, or cross-region inference enabled.
- A browser. No local software, Python or Git client is needed.

## Setup (about 10 minutes, before the workshop)

1. Sign in to Snowsight as `ACCOUNTADMIN`.
2. Open a new SQL worksheet, paste the contents of [`setup/00_connect_git.sql`](setup/00_connect_git.sql) and run it.
   This connects your account to this repository.
3. Create a Workspace from this Git repository (Projects » Workspaces » From Git repository),
   so the lab files open in the editor.
4. Run the remaining setup files, in order:

   ```sql
   execute immediate from @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/setup/01_load_l0.sql;
   execute immediate from @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/setup/02_reference_build.sql;
   execute immediate from @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/setup/99_check.sql;
   ```

5. Expected: every row of `99_check.sql` shows **PASS**. A WARN on "Data metric functions"
   means your account is Standard edition; you can still do Labs 0–4.

## What setup creates

| Object | Purpose |
|---|---|
| `SC360_L0` | 16 simulated SAP BDC data products: 21 tables, 398 rows. Read-only |
| `SC360_L0.CSN` | 16 simulated CSN semantic views, one per data product (labels, keys, 0 relationships). Stands in for `SNOWFLAKE$` on a real CLD. Used in Lab 3 |
| `SC360_EXT` | Non-SAP operational and supplier data: 14 tables, 7,850 rows. Read-only |
| `SC360_REF` | The finished reference stack (Lab 0 and catch-up) |
| `SC360_LAB` | Empty; you build here in Labs 1–5 |
| `SC360_ADMIN` | Git repository object, file format and stage used by setup |
| Role `SC360_ENGINEER` | The role you use in the labs |
| Warehouse `LAB_WH` | XSMALL, auto-suspends after 60 seconds |

## Repository layout

```
setup/      00-02 setup, 98 reset to the start of any lab, 99 readiness check
data/       l0/ and ext/ CSV files, manifest.csv (row counts)
labs/       lab0_hook ... lab5_trust: one folder per lab
exercises/  group exercises (no keyboard)
docs/       lab guide, feature map, simulated vs real, troubleshooting
```

## Fell behind?

Reset your lab database to the start of any lab:

```sql
set reset_to_lab = 3;
execute immediate from @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/setup/98_reset_module.sql;
```

## Clean up after the workshop

```sql
use role accountadmin;
grant role SC360_DATA_PROVIDER to role accountadmin;  -- owner of the read-only data
drop database if exists SC360_LAB;
drop database if exists SC360_REF;
drop database if exists SC360_EXT;
drop database if exists SC360_L0;
drop database if exists SC360_ADMIN;
drop integration if exists SC360_GIT_API;
drop role if exists SC360_ENGINEER;
drop role if exists SC360_DATA_PROVIDER;
drop warehouse if exists LAB_WH;
```

## Data

All data in this repository is **synthetic**. Company, supplier and customer names are
used only to make the scenario realistic; the figures do not describe any real
organisation. See [LICENSE](LICENSE).
