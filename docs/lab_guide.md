# Lab guide

Each lab has its own folder under `labs/` with a README (steps, expected results,
troubleshooting) and the SQL files. This page is the overview. Run everything as
`SC360_ENGINEER` unless a step says otherwise.

| Lab | Module | Time | Folder | You build | Status |
|---|---|---|---|---|---|
| 0 | 0 · The hook | 5 min | [`lab0_hook`](../labs/lab0_hook/README.md) | Nothing: ask the finished agent | Ready |
| 1 | 3 · Prepare | 15 min | [`lab1_access`](../labs/lab1_access/README.md) | Profile of L0; one L1 view | Ready |
| 2 | 3 · Prepare | 20 min | [`lab2_prepare`](../labs/lab2_prepare/README.md) | 15 L2 Dynamic Tables, 17 serving views, 3 entity views | Ready |
| 3 | 4 · Define | 25 min | `lab3_define` | The semantic view | Coming |
| 4 | 5 · Reason | 20 min | `lab4_reason` | The Cortex Agent | Coming |
| 5 | 6 · Trust | 12 min | `lab5_trust` | Guard checks and data quality | Coming |

## Where each lab sits

```
SC360_L0 (read-only, simulated SAP BDC)  ─┐
SC360_EXT (non-SAP, read-only)           ─┤
                                          ├─► Lab 1  SC360_LAB.L1_MANUFACTURING_CODES   (L1 views)
                                          └─► Lab 2  SC360_LAB.ANALYTICS                (L2 Dynamic Tables, ENT_* views)
                                                     SC360_LAB.APP_REF                  (serving views)
                                                ─► Lab 3  semantic view  ─► Lab 4  agent  ─► Lab 5  trust
```

## Check yourself

| After | Run | Expected |
|---|---|---|
| Lab 1 | `select count(*) from SC360_LAB.L1_MANUFACTURING_CODES.SUPPLIER_QUALITY;` | 18 |
| Lab 2 | `show dynamic tables in schema SC360_LAB.ANALYTICS;` | 15 rows: 9 `INCREMENTAL`, 6 `FULL` |
| Lab 2 | `select count(*) from SC360_LAB.ANALYTICS.ENT_SUPPLIER;` | 15 |

## Fell behind?

Reset `SC360_LAB` to the start of any lab. The reset re-runs the earlier labs' files and
solutions, so you continue from exactly the state the next lab expects.

```sql
set reset_to_lab = 3;   -- 1 to 5
execute immediate from @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/setup/98_reset_module.sql;
use role SC360_ENGINEER;
```

| Reset to | Builds | Takes about |
|---|---|---|
| 1 | An empty `SC360_LAB` | 2 s |
| 2 | Lab 1's L1 view | 2 s |
| 3 | Lab 1 and all of Lab 2 | 35 s |
