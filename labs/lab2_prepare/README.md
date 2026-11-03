# Lab 2 — Build L2 with Dynamic Tables

**Time:** 20 minutes · **Role:** `SC360_ENGINEER` · **Where:** your Workspace or a Snowsight worksheet

L2 is where data is materialised: Dynamic Tables that join SAP and non-SAP data by business
process. Reads on L2 no longer touch the share, so they carry no SAP data-sharing fee (see the
fee boundary slide). You build the same L2 the demo runs on. The SQL files are generated from
the demo scripts; only the database names differ.

> Starting late? `set reset_to_lab = 2;` then run `setup/98_reset_module.sql`.

## Steps

1. **Build** (5 min). Run these two files in full:
   - [`lab2_01_dynamic_tables.sql`](lab2_01_dynamic_tables.sql): 15 Dynamic Tables in
     `SC360_LAB.ANALYTICS` (9 over SAP data products, 6 over the non-SAP operations data).
     Takes about 35 seconds.
   - [`lab2_02_serving_views.sql`](lab2_02_serving_views.sql): 17 serving views in `SC360_LAB.APP_REF`.
2. **Look at one** (3 min). In Snowsight open **Catalog » Database Explorer » SC360_LAB »
   ANALYTICS » Dynamic Tables » DT_SUPPLIER_QUALITY**. Check the **Graph** tab (two sources:
   one SAP, one non-SAP), the **refresh mode** and the **target lag**.
3. **Find the gap** (5 min). Run [`lab2_03_target_lag.sql`](lab2_03_target_lag.sql) one
   statement at a time.
4. **Entity views** (5 min). Open [`lab2_04_entity_views.sql`](lab2_04_entity_views.sql).
   `ENT_MATERIAL` and `ENT_PLANT` are written; write `ENT_SUPPLIER` (the `TODO`), then run the
   file. Solution: [`solution/lab2_04_entity_views.sql`](solution/lab2_04_entity_views.sql).
5. **Discuss** (3 min, at your table):
   - This build skips L1: the Dynamic Tables read L0 directly. When would this client need L1?
   - What `TARGET_LAG` would you set for supplier quality, and why?

## Expected results

| Step | Expected |
|---|---|
| 1 | 15 Dynamic Tables, all owned by `SC360_ENGINEER`; 17 views in `APP_REF` |
| 2–3a | All 15 have `target_lag = DOWNSTREAM`. **9 INCREMENTAL, 6 FULL** |
| 3a FULL ones | `DT_COMPONENT_COVER`, `DT_EQUIPMENT_HEALTH`, `DT_EQUIPMENT_OUTAGE`, `DT_SERIAL_GENEALOGY`, `DT_SUPPLY_CHAIN_GEO`, `DT_WORK_CENTER_UTILIZATION`. Reason: "contains a complex query. Refresh mode has been automatically set to FULL" |
| 3c Manual refresh | `No new data` |
| 3d History | 2 rows: `CREATION` / `INCREMENTAL` / 102 rows, then `MANUAL` / `NO_DATA` / 0 rows |
| 4 Entities | 42 materials, 15 suppliers, 5 plants |

## What you just saw

- **`REFRESH_MODE = AUTO` hides a choice.** Snowflake picked FULL for 6 tables because the
  queries are "complex" (joins of several tables, a CTE with `UNION ALL`). Always read
  `refresh_mode_reason`. If incremental matters, set `REFRESH_MODE = INCREMENTAL` explicitly:
  `DT_WORK_CENTER_UTILIZATION` builds fine that way.
- **`DOWNSTREAM` with nothing downstream means no schedule.** These tables were built once and
  will not refresh until something downstream asks, or you set a lag. That is the gap.
- **Lag is a cost lever.** A catalog-linked database syncs once a day by default
  (`SYNC_INTERVAL_SECONDS = 86400`). A lag tighter than that buys nothing: it pays for refreshes
  that find no new data. Rule of thumb: about half the share's cadence.
- **Keep `CURRENT_DATE()` out of Dynamic Tables.** A non-deterministic function forces FULL
  refresh. Put date-relative logic ("last 30 days", month to date) in a view on top.
- **Entity views give identity.** `ENT_MATERIAL` has one row per material (42), across
  inventory, BOM, production, supplier quality, component cover and orders. Lab 1 found 10
  components with no stock row; here they are present. Lab 3 uses these views as the keys of
  the semantic view.

## Look closer (if you have time)

Dependency is the other half of the ontology. Walk the bill of materials upwards from every
Festo AG component to the products that contain it:

```sql
with recursive festo as (
    select distinct MATERIAL from SC360_LAB.ANALYTICS.DT_SUPPLIER_QUALITY
    where SUPPLIER_NAME = 'Festo AG'
), parents (component, parent, depth) as (
    select b.COMPONENT_MATERIAL, b.PARENT_MATERIAL, 1
    from SC360_LAB.ANALYTICS.DT_BOM_EXPLOSION b join festo f on b.COMPONENT_MATERIAL = f.MATERIAL
    union all
    select p.component, b.PARENT_MATERIAL, p.depth + 1
    from parents p join SC360_LAB.ANALYTICS.DT_BOM_EXPLOSION b on b.COMPONENT_MATERIAL = p.parent
)
select c.material_desc as festo_component, p.depth, m.material_desc as contained_in
from parents p
join SC360_LAB.ANALYTICS.ENT_MATERIAL c on c.material = p.component
join SC360_LAB.ANALYTICS.ENT_MATERIAL m on m.material = p.parent
order by festo_component, p.depth;
```

Expected: 4 components in 4 products (for example Scanning Optics Assembly → Surfscan SP7XP).
In this data each sits one level below a finished product; the recursion is what makes the
same query work on a deeper BOM. This is the path the agent walked in Lab 0.

## Troubleshooting

| Symptom | Fix |
|---|---|
| All 15 tables FULL, reason "Insufficient privileges … to automatically enable CHANGE_TRACKING" | Change tracking is off on L0. Re-run `setup/01_load_l0.sql`, then check 9 of `setup/99_check.sql` |
| `Object does not exist` on `ENT_SUPPLIER` | Expected until you write the `TODO` in step 4 |
| `Insufficient privileges` creating a schema | Run `use role SC360_ENGINEER;`. If `SC360_LAB` is owned by another role, reset with `reset_to_lab = 2` |
| Fell behind | `set reset_to_lab = 3;` then run `setup/98_reset_module.sql`: it builds all of Lab 2 for you (about 35 s) |
