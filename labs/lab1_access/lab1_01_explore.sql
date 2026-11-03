-- =====================================================================
-- SAP BDC Connect + Snowflake partner workshop
-- Lab 1 steps 1-3: explore and profile the simulated SAP data products (L0)
-- All data is synthetic.
-- =====================================================================
-- Run each statement on its own (select it, then Ctrl/Cmd + Enter), and write
-- what you find on the findings sheet (findings_sheet.md). Step 1b fails on purpose.

use role SC360_ENGINEER;
use warehouse LAB_WH;

-- ---------------------------------------------------------------------
-- Step 1. Browse L0: one schema per SAP data product
-- ---------------------------------------------------------------------
-- Expected: 16 data products, 21 tables, 398 rows.
select table_schema as data_product, table_name, row_count
from SC360_L0.information_schema.tables
where table_type = 'BASE TABLE'
order by data_product, table_name;

-- Step 1b. L0 is read-only, like a catalog-linked database.
-- Expected: this FAILS with "Insufficient privileges to operate on table 'A_PLANT'".
insert into SC360_L0.PLANT.A_PLANT select * from SC360_L0.PLANT.A_PLANT where 1 = 0;

-- ---------------------------------------------------------------------
-- Step 2. Four profiling queries
-- ---------------------------------------------------------------------

-- 2a. Blank rate per key column. An empty string counts as blank.
select 'BILL_OF_MATERIAL.A_BOM_ITEM.COMPONENT_MATERIAL' as key_column, count(*) as row_total,
       count_if(nullif(trim(COMPONENT_MATERIAL), '') is null) as blank_rows
from SC360_L0.BILL_OF_MATERIAL.A_BOM_ITEM
union all
select 'MANUFACTURING_CODES.A_SUPPLIER_QUALITY.SUPPLIER', count(*),
       count_if(nullif(trim(SUPPLIER), '') is null)
from SC360_L0.MANUFACTURING_CODES.A_SUPPLIER_QUALITY
union all
select 'MANUFACTURING_CODES.A_SUPPLIER_QUALITY.MATERIAL', count(*),
       count_if(nullif(trim(MATERIAL), '') is null)
from SC360_L0.MANUFACTURING_CODES.A_SUPPLIER_QUALITY
union all
select 'PRODUCTION_ORDER_CONFIRM.A_PROD_ORD_CONFIRMATION.MATERIAL', count(*),
       count_if(nullif(trim(MATERIAL), '') is null)
from SC360_L0.PRODUCTION_ORDER_CONFIRM.A_PROD_ORD_CONFIRMATION;

-- 2b. Distinct values of two code fields. Are they codes or labels? Who defines them?
select 'ORDER_STATUS' as code_field, ORDER_STATUS as value, count(*) as row_count
from SC360_L0.PRODUCTION_ORDER_CONFIRM.A_PROD_ORD_CONFIRMATION group by ORDER_STATUS
union all
select 'ON_TIME_FLAG', ON_TIME_FLAG, count(*)
from SC360_L0.DELIVERY_MGMT_CONFIG.A_DELIVERY group by ON_TIME_FLAG
order by code_field, value;

-- 2c. Are date columns typed as dates, or held as text?
select data_type, count(*) as date_like_columns
from SC360_L0.information_schema.columns
where table_schema <> 'INFORMATION_SCHEMA'
  and (column_name ilike '%DATE%' or column_name ilike 'VALID_%')
group by data_type;

-- On a real SAP BDC share, dates often arrive as 'YYYYMMDD' text. Try the cast both ways:
select try_to_date('20250315')               as no_format_mask,   -- a wrong date, and no error
       try_to_date('20250315', 'YYYYMMDD')   as with_format_mask;

-- A real catalog-linked database also carries technical columns. Its __TIMESTAMP column
-- is text with a comma before the fraction. Parse it:
select try_to_timestamp_ntz('2026-10-07T11:00:33,6632490Z') as plain_cast,
       try_to_timestamp_ntz(replace('2026-10-07T11:00:33,6632490Z', ',', '.'),
                            'YYYY-MM-DD"T"HH24:MI:SS.FF9"Z"') as with_mask;

-- 2d. Orphan keys: BOM components with no row in material stock.
select count(distinct b.COMPONENT_MATERIAL) as bom_components,
       count(distinct iff(s.MATERIAL is null, b.COMPONENT_MATERIAL, null)) as no_stock_row
from SC360_L0.BILL_OF_MATERIAL.A_BOM_ITEM b
left join SC360_L0.MANUFACTURING_CODES.A_MATERIAL_STOCK s on s.MATERIAL = b.COMPONENT_MATERIAL;

-- Which ones? (Keep the list: Lab 2's ENT_MATERIAL view answers it.)
select distinct b.COMPONENT_MATERIAL, b.COMPONENT_DESC
from SC360_L0.BILL_OF_MATERIAL.A_BOM_ITEM b
left join SC360_L0.MANUFACTURING_CODES.A_MATERIAL_STOCK s on s.MATERIAL = b.COMPONENT_MATERIAL
where s.MATERIAL is null
order by 1;
