# Lab 0 — The hook: ask the finished system first

**Time:** 5 minutes · **Role:** your default role (ACCOUNTADMIN) · **Where:** Snowflake CoWork

Before building anything, see the answer the workshop builds towards. This agent was
created by `setup/02_reference_build.sql` in `SC360_REF`. In Labs 1–4 you build your own
copy of every layer underneath it.

> Snowflake CoWork was previously called Snowflake Intelligence.

## Steps

1. Open Snowflake CoWork: in Snowsight select **AI & ML » Agents**, then open
   Snowflake CoWork. Or go to `https://ai.snowflake.com` and sign in to your account.
2. Choose the agent **SC360 Reference Analyst**.
3. Ask this question, word for word:

   > If Festo AG stops delivering, which open customer orders are at risk and what is their total value?

4. Write the answer down on your worksheet. You check it again at the end of Lab 4.

## Expected result

| | |
|---|---|
| Orders at risk | **2** open customer orders |
| Total value | **$1,475,000** (about $1.5M) |
| Orders | SO-4500226, Infineon Technologies, ICOS F160 Die Sorter, Penang Assembly, $964,000 |
| | SO-4500488, GlobalFoundries, KLA eSL10 e-Beam Review, Austin Fab, $511,000 |

The wording varies between runs; the numbers should not.

## Look closer (if you have time)

Expand the agent's reasoning or SQL. Notice that it:

- found Festo AG's **4 components** from supplier quality data;
- walked the bill of materials **upwards** (component → the products that contain it) to
  **4 products**. The walk is recursive, so it would follow deeper assemblies too;
- kept only **open** orders (not yet shipped) for those products.

Nobody wrote that query for this question. The meaning it relies on (who Festo is, what
"part of" means, what "at risk" means) was declared once, in the semantic view. That is
what Modules 3–5 build.

Optional follow-up question:

> For each component supplied by Festo AG, which alternate supplier can replace it at a quality bar of 90?

Expected: 2 candidates, 1 blocked (Scanning Optics Assembly: Jenoptik scores 89.4,
below the bar of 90), 1 for review (Detector Assembly has no qualified alternate).

## Prefer SQL?

The same agent can be called from a worksheet:

```sql
select snowflake.cortex.data_agent_run(
  'SC360_REF.ANALYTICS.SAP_SC360_ANALYST_AGENT',
  $${"messages":[{"role":"user","content":[{"type":"text",
     "text":"If Festo AG stops delivering, which open customer orders are at risk and what is their total value?"}]}]}$$
) as response;
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| The agent is not listed in Snowflake CoWork | Your account may have a CoWork object that curates agents. Run `show snowflake intelligences;` If one exists, run `alter snowflake intelligence <name> add agent SC360_REF.ANALYTICS.SAP_SC360_ANALYST_AGENT;` |
| "missing an execution environment" or no warehouse | Re-run `setup/02_reference_build.sql`; it pins warehouse `LAB_WH`. In CoWork, check a warehouse is selected |
| Model or Cortex not available | Enable cross-region inference: `alter account set cortex_enabled_cross_region = 'ANY_REGION';` (ACCOUNTADMIN) |
| Different numbers | Re-run `setup/99_check.sql`. If check 2 or 3 fails, the data did not load fully; re-run `setup/01_load_l0.sql` then `02` |
