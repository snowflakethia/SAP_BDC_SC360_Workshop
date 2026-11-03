-- =====================================================================
-- SAP BDC Connect + Snowflake partner workshop
-- Lab 1 step 4: write one L1 view (template)
-- All data is synthetic.
-- =====================================================================
-- L1 rules (from the slide "The overlay"):
--   * one view over exactly one L0 object: no joins, no filters, no aggregation;
--   * named for the business object, not the SAP technical name;
--   * two allowed changes: typed dates (always with a format mask) and
--     normalised identifiers (UPPER(TRIM(...)));
--   * a COMMENT naming the SAP source, so lineage survives the rename.
--
-- In a client account each business area gets its own database
-- (for example SAP_L1_PROCUREMENT). Your lab role owns only SC360_LAB, so here the
-- layout is   SC360_LAB . L1_<data product> . <business object>.
--
-- Fill in the four TODOs, then run the whole file.

use role SC360_ENGINEER;
use warehouse LAB_WH;

create schema if not exists SC360_LAB.L1_MANUFACTURING_CODES
  comment = 'L1: business-object views over the Manufacturing Codes data product';

create or replace view SC360_LAB.L1_MANUFACTURING_CODES.SUPPLIER_QUALITY
  comment = 'TODO 1: name the SAP source and the L0 object, e.g. SAP source: ... L0: SC360_L0....'
as
select
    SUPPLIER                         as SUPPLIER,       -- TODO 2: normalise the key
    SUPPLIER_NAME,
    MATERIAL                         as MATERIAL,       -- TODO 3: normalise the key
    MATERIAL_DESC,
    TOTAL_DELIVERED,
    DEFECT_QTY,
    DEFECT_RATE_PCT,
    ON_TIME_DELIVERY_PCT,
    QUALITY_SCORE,
    PERIOD_DATE                      as PERIOD_DATE     -- TODO 4: what does profiling query 2c say?
                                                        --   Text 'YYYYMMDD'?  try_to_date(PERIOD_DATE, 'YYYYMMDD')
                                                        --   Already DATE?     keep it as it is
from SC360_L0.MANUFACTURING_CODES.A_SUPPLIER_QUALITY;

-- Check: expected 18 rows, 6 suppliers.
select count(*) as row_total, count(distinct SUPPLIER) as suppliers
from SC360_LAB.L1_MANUFACTURING_CODES.SUPPLIER_QUALITY;
