-- =====================================================================
-- SAP BDC Connect + Snowflake partner workshop
-- Setup 98: reset your lab database to the start of a lab
-- Generated file. All data is synthetic.
-- =====================================================================
-- Use this if you fall behind or break something. It replaces SC360_LAB with
-- the state the named lab expects at its first step, by re-running the earlier
-- labs' files and solutions. SC360_L0, SC360_EXT and SC360_REF are not touched.
--
-- How to run (example: restart Lab 2):
--   set reset_to_lab = 2;
--   execute immediate from @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/setup/98_reset_module.sql;

use role accountadmin;
use warehouse LAB_WH;

declare
  bad_lab exception (-20002, 'reset_to_lab must be a number from 1 to 5.');
  lab int default $reset_to_lab;
begin
  if (lab < 1 or lab > 5) then
    raise bad_lab;
  end if;

  -- Start of Lab 1: an empty SC360_LAB owned by the lab role.
  create or replace database SC360_LAB;
  drop schema if exists SC360_LAB.PUBLIC;
  grant ownership on database SC360_LAB to role SC360_ENGINEER copy current grants;

  -- The lab files switch to SC360_ENGINEER, so everything below is owned by the lab role.
  -- Start of Lab 2: everything Lab 1 builds.
  if (lab >= 2) then
    execute immediate from @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/labs/lab1_access/solution/lab1_02_l1_view.sql;
  end if;
  -- Start of Lab 3: everything Lab 2 builds.
  if (lab >= 3) then
    execute immediate from @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/labs/lab2_prepare/lab2_01_dynamic_tables.sql;
    execute immediate from @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/labs/lab2_prepare/lab2_02_serving_views.sql;
    execute immediate from @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/labs/lab2_prepare/solution/lab2_04_entity_views.sql;
  end if;

  -- Labs 4-5: added as those labs are finalised (semantic view, agent).

  use role accountadmin;
  return 'SC360_LAB reset to the start of Lab ' || lab || '. Switch to role SC360_ENGINEER to continue.';
end;
