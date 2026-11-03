-- =====================================================================
-- SAP BDC Connect + Snowflake partner workshop
-- Setup 99: readiness check
-- Generated file. All data is synthetic.
-- =====================================================================
-- Run as ACCOUNTADMIN after setup/00-02. Returns one row per check: PASS, WARN or FAIL.
-- The agent check asks the Lab 0 question, so it uses a little Cortex credit.

use role accountadmin;
use warehouse LAB_WH;

declare
  res resultset;
  n int; r int; txt varchar; raw varchar;
begin
  create or replace temporary table SC360_ADMIN.GIT.CHECK_RESULTS (seq int, check_name varchar, status varchar, detail varchar);

  -- 1. Git repository reachable
  begin
    execute immediate 'ls @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/data/manifest.csv';
    insert into SC360_ADMIN.GIT.CHECK_RESULTS values (1, 'Git repository readable', 'PASS', 'data/manifest.csv found');
  exception when other then
    insert into SC360_ADMIN.GIT.CHECK_RESULTS values (1, 'Git repository readable', 'FAIL', 'Run setup/00_connect_git.sql');
  end;

  -- 2-3. Simulated L0 and non-SAP sources loaded
  select count(*), coalesce(sum(row_count), 0) into :n, :r
    from SC360_L0.information_schema.tables where table_type = 'BASE TABLE';
  insert into SC360_ADMIN.GIT.CHECK_RESULTS select 2, 'SC360_L0 loaded (21 tables, 398 rows)',
    iff(:n = 21 and :r = 398, 'PASS', 'FAIL'), :n || ' tables, ' || :r || ' rows';
  select count(*), coalesce(sum(row_count), 0) into :n, :r
    from SC360_EXT.information_schema.tables where table_type = 'BASE TABLE';
  insert into SC360_ADMIN.GIT.CHECK_RESULTS select 3, 'SC360_EXT loaded (14 tables, 7850 rows)',
    iff(:n = 14 and :r = 7850, 'PASS', 'FAIL'), :n || ' tables, ' || :r || ' rows';

  -- 4. L0 is read-only, as a catalog-linked database would be (a zero-row insert must fail)
  begin
    insert into SC360_L0.PLANT.A_PLANT select * from SC360_L0.PLANT.A_PLANT where 1 = 0;
    insert into SC360_ADMIN.GIT.CHECK_RESULTS values (4, 'SC360_L0 is read-only', 'FAIL', 'INSERT was allowed; re-run setup/01');
  exception when other then
    insert into SC360_ADMIN.GIT.CHECK_RESULTS values (4, 'SC360_L0 is read-only', 'PASS', 'INSERT rejected as expected');
  end;

  -- 5. Reference stack
  show dynamic tables in database SC360_REF;
  select count(*) into :n from table(result_scan(last_query_id()));
  insert into SC360_ADMIN.GIT.CHECK_RESULTS select 5, 'SC360_REF: 15 Dynamic Tables',
    iff(:n = 15, 'PASS', 'FAIL'), :n || ' found; run setup/02_reference_build.sql';

  -- 6. Reference agent answers the Lab 0 question
  begin
    select snowflake.cortex.data_agent_run(
             'SC360_REF.ANALYTICS.SAP_SC360_ANALYST_AGENT',
             $${"messages":[{"role":"user","content":[{"type":"text","text":"If Festo AG stops delivering, which open customer orders are at risk and what is their total value?"}]}]}$$
           ) into :raw;
    select listagg(c.value:text::varchar, ' ') into :txt
      from (select parse_json(:raw) j) p, lateral flatten(p.j:content) c where c.value:type = 'text';
    insert into SC360_ADMIN.GIT.CHECK_RESULTS select 6, 'Reference agent answers the Festo question',
      iff(contains(:txt, '1,475') or contains(:txt, '1.475') or contains(:txt, '1.48'), 'PASS',
          iff(coalesce(:txt, '') = '', 'FAIL', 'WARN')),
      left(coalesce(nullif(:txt, ''), :raw), 300);
  exception when other then
    insert into SC360_ADMIN.GIT.CHECK_RESULTS values (6, 'Reference agent answers the Festo question', 'FAIL',
      'Cortex Agents not reachable. See docs/troubleshooting.md (region / cross-region inference).');
  end;

  -- 7. Data metric functions available (Enterprise Edition or higher)
  begin
    execute immediate 'select snowflake.core.null_count(select PLANT from SC360_L0.PLANT.A_PLANT)';
    insert into SC360_ADMIN.GIT.CHECK_RESULTS values (7, 'Data metric functions available', 'PASS', 'Lab 5 will work');
  exception when other then
    insert into SC360_ADMIN.GIT.CHECK_RESULTS values (7, 'Data metric functions available', 'WARN',
      'Needs Enterprise Edition. Lab 5 step 2 will be demo-only for you.');
  end;

  -- 8. Simulated CSN semantic views (one per data product, used in Lab 3)
  show semantic views in schema SC360_L0.CSN;
  select count(*) into :n from table(result_scan(last_query_id()));
  insert into SC360_ADMIN.GIT.CHECK_RESULTS select 8, 'SC360_L0.CSN: 16 CSN semantic views',
    iff(:n = 16, 'PASS', 'FAIL'), :n || ' found; re-run setup/01';

  -- 9. Change tracking on every L0 and EXT table (needed for incremental Dynamic Tables in Lab 2)
  show tables in database SC360_L0;
  select count_if("change_tracking" <> 'ON'), count(*) into :n, :r from table(result_scan(last_query_id()));
  show tables in database SC360_EXT;
  select :n + count_if("change_tracking" <> 'ON'), :r + count(*) into :n, :r from table(result_scan(last_query_id()));
  insert into SC360_ADMIN.GIT.CHECK_RESULTS select 9, 'Change tracking on L0 and EXT tables',
    iff(:n = 0, 'PASS', 'FAIL'), (:r - :n) || ' of ' || :r || ' tables ON; re-run setup/01';

  res := (select check_name, status, detail from SC360_ADMIN.GIT.CHECK_RESULTS order by seq);
  return table(res);
end;
