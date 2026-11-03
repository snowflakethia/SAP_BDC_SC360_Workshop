# Lab 1 — Explore and profile L0, then write one L1 view

**Time:** 15 minutes · **Role:** `SC360_ENGINEER` · **Where:** a Snowsight worksheet, or the
Workspace you created from this repo

In a client account, each SAP BDC data product arrives as its own read-only, catalog-linked
database. Before you build on it, you find out what the data actually looks like. Then you
write the first layer above it: one **L1 view**.

> `SC360_L0` stands in for those catalog-linked databases. See `docs/simulated_vs_real.md`.

## Steps

1. Open [`lab1_01_explore.sql`](lab1_01_explore.sql). Run the statements one at a time.
2. **Browse L0** (step 1): 16 data products, one schema each.
3. **Try to write to it** (step 1b). The `INSERT` must fail.
4. **Profile** (step 2): run the four queries and write each result on the
   [findings sheet](findings_sheet.md):
   - 2a blank rate per key column
   - 2b distinct values of two code fields
   - 2c how date columns are typed, and what happens when a text date is cast without a format mask
   - 2d orphan keys between the bill of materials and material stock
5. **Write the L1 view** (step 4): open [`lab1_02_l1_view.sql`](lab1_02_l1_view.sql), complete
   the four `TODO`s, then run the file.
6. **Check** your view against [`solution/lab1_02_l1_view.sql`](solution/lab1_02_l1_view.sql).

## Expected results

| Step | Expected |
|---|---|
| 1 Browse | 16 schemas, 21 tables, 398 rows |
| 1b Insert | Fails: `Insufficient privileges to operate on table 'A_PLANT'` |
| 2a Blank keys | 0 blank rows in every key column checked (30, 18, 18 and 20 rows) |
| 2b Code fields | `ORDER_STATUS`: Created 2, Released 4, Delivered 14. `ON_TIME_FLAG`: Y 17, N 8 |
| 2c Date types | 19 date-like columns, all typed `DATE` |
| 2c Mask trap | `try_to_date('20250315')` returns **1970-08-23**; with `'YYYYMMDD'` it returns 2025-03-15 |
| 2c Timestamp | A plain cast of the real-CLD timestamp returns **NULL**; replacing the comma and adding a mask returns 2026-10-07 11:00:33.663 |
| 2d Orphans | 30 BOM components, **10** with no row in material stock |
| 4 L1 view | `SC360_LAB.L1_MANUFACTURING_CODES.SUPPLIER_QUALITY`: 18 rows, 6 suppliers |

## What the profile tells you

- **This simulated share is clean**: keys are filled and dates are typed. Real shares often are
  not. SAP dates can arrive as `YYYYMMDD` text, and a cast without a format mask returns a wrong
  date with **no error**. That is why the L1 rule says a date cast must always carry a mask.
- **Codes are labels, not SAP codes** (`Delivered`, `Y`). Someone has to define what each one
  means. The semantic view does that in Lab 3.
- **10 of 30 components have no stock row.** Material stock covers 23 materials; the bill of
  materials references 30 components. Whether that gap is expected (not stocked) or a defect is a
  question for the client. Either way, a join from the BOM to stock silently drops those 10. Lab
  2's `ENT_MATERIAL` view keeps them: one row per material, whichever table it appears in.

## The L1 rules you applied

- One view over exactly one L0 object: no joins, no filters, no aggregation.
- Named for the business object (`SUPPLIER_QUALITY`), not the SAP technical name.
- Two allowed changes: typed dates (always with a mask) and `UPPER(TRIM())` keys.
- A `COMMENT` that names the SAP source, so lineage survives the rename.

In a client account each business area gets its own database (for example
`SAP_L1_PROCUREMENT.<data product>.<business object>`), and the views are **generated** from
`INFORMATION_SCHEMA`, not hand-written. Your lab role owns only `SC360_LAB`, so here the layout is
`SC360_LAB.L1_<data product>.<business object>`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `INSERT` succeeded | Your session uses a role that owns L0. Run `use role SC360_ENGINEER;`, then re-run `setup/99_check.sql` (check 4) |
| `Object does not exist` on `SC360_L0` | Run `use role SC360_ENGINEER;`. If it still fails, re-run `setup/01_load_l0.sql` |
| Insufficient privileges on `SC360_LAB` | You are not using `SC360_ENGINEER`, or `SC360_LAB` was recreated by another role. Run `setup/98_reset_module.sql` with `reset_to_lab = 1` |
| Fell behind | `set reset_to_lab = 2;` then run `setup/98_reset_module.sql`. It builds the solution view for you |
