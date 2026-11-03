-- =====================================================================
-- SAP BDC Connect + Snowflake partner workshop
-- Lab 2 step 3: find the gap (TARGET_LAG = DOWNSTREAM with nothing downstream)
-- All data is synthetic.
-- =====================================================================
-- Run each statement on its own.

use role SC360_ENGINEER;
use warehouse LAB_WH;

-- 3a. What lag and refresh mode did each Dynamic Table get?
show dynamic tables in schema SC360_LAB.ANALYTICS;
select "name", "target_lag", "refresh_mode", "scheduling_state",
       left("refresh_mode_reason", 80) as refresh_mode_reason
from table(result_scan(last_query_id()))
order by "refresh_mode", "name";
-- Expected: all 15 DOWNSTREAM; 9 INCREMENTAL, 6 FULL ("complex query").
-- DOWNSTREAM means "refresh only when something downstream needs it". Nothing
-- reads these tables on a schedule, so after the first build none of them refreshes.

-- 3b. Give the supplier quality table an explicit lag. Rule of thumb: about half the
-- share's publication cadence. A catalog-linked database syncs every 86,400 s
-- (once a day) by default, so 12 hours.
alter dynamic table SC360_LAB.ANALYTICS.DT_SUPPLIER_QUALITY set target_lag = '12 hours';

-- 3c. Refresh it now instead of waiting.
alter dynamic table SC360_LAB.ANALYTICS.DT_SUPPLIER_QUALITY refresh;

-- 3d. Read the refresh history. Expected: two rows.
--   trigger CREATION, action INCREMENTAL, 102 rows inserted (the first build);
--   trigger MANUAL,   action NO_DATA,     0 rows (nothing changed in L0, so no work done).
select name, refresh_action, refresh_trigger, state,
       refresh_start_time, statistics:numInsertedRows::int as rows_inserted
from table(SC360_LAB.information_schema.dynamic_table_refresh_history(
       name => 'SC360_LAB.ANALYTICS.DT_SUPPLIER_QUALITY'))
order by refresh_start_time;

-- 3e. Clean up: set the lag back, so your account does not refresh twice a day after
-- the workshop.
alter dynamic table SC360_LAB.ANALYTICS.DT_SUPPLIER_QUALITY set target_lag = 'DOWNSTREAM';
