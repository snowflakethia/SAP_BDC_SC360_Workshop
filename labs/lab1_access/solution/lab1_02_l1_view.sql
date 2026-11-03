-- =====================================================================
-- SAP BDC Connect + Snowflake partner workshop
-- Lab 1 step 4: one L1 view (solution)
-- All data is synthetic.
-- =====================================================================
-- Also used by setup/98_reset_module.sql to rebuild the start of Lab 2.

use role SC360_ENGINEER;
use warehouse LAB_WH;

create schema if not exists SC360_LAB.L1_MANUFACTURING_CODES
  comment = 'L1: business-object views over the Manufacturing Codes data product';

create or replace view SC360_LAB.L1_MANUFACTURING_CODES.SUPPLIER_QUALITY
  comment = 'SAP source: supplier evaluation by material (data product Manufacturing Codes). L0: SC360_L0.MANUFACTURING_CODES.A_SUPPLIER_QUALITY'
as
select
    upper(trim(SUPPLIER))            as SUPPLIER,
    SUPPLIER_NAME,
    upper(trim(MATERIAL))            as MATERIAL,
    MATERIAL_DESC,
    TOTAL_DELIVERED,
    DEFECT_QTY,
    DEFECT_RATE_PCT,
    ON_TIME_DELIVERY_PCT,
    QUALITY_SCORE,
    PERIOD_DATE                      -- already DATE in this share (query 2c), so no cast.
                                     -- On a share that delivers 'YYYYMMDD' text:
                                     --   try_to_date(PERIOD_DATE, 'YYYYMMDD') as PERIOD_DATE
from SC360_L0.MANUFACTURING_CODES.A_SUPPLIER_QUALITY;

select count(*) as row_total, count(distinct SUPPLIER) as suppliers
from SC360_LAB.L1_MANUFACTURING_CODES.SUPPLIER_QUALITY;
