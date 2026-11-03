-- =====================================================================
-- SAP BDC Connect + Snowflake partner workshop
-- Setup 02: reference build (the finished stack) in SC360_REF
-- Generated file. All data is synthetic.
-- =====================================================================
-- Run as ACCOUNTADMIN after setup/01_load_l0.sql. Takes about 2 minutes.
-- Builds the answer we work towards: 15 L2 Dynamic Tables, serving views,
-- the SAP_SUPPLY_CHAIN_360 semantic view and the reference Cortex Agent.
-- Used for the Lab 0 hook and as a catch-up point. Labs build their own copy in SC360_LAB.

use role accountadmin;
use warehouse LAB_WH;
create or replace database SC360_REF;
drop schema if exists SC360_REF.PUBLIC;

-- ---------------------------------------------------------------------
-- From demo step 03
-- ---------------------------------------------------------------------
-- =====================================================================
-- L2 (gold) — Analytics dynamic tables
-- Joined / enriched / aggregated analytics objects built on the raw L0
-- SAP BDC standard data products. Dynamic tables auto-refresh
-- (TARGET_LAG). Requires a warehouse named LAB_WH (or edit WAREHOUSE).
-- DT_SUPPLIER_QUALITY and DT_SUPPLY_CHAIN_GEO union L0 with the synthetic
-- SUPPLIER_EXT schema, so run 07a_supplier_ext_seed.sql first.
-- =====================================================================

create or replace schema SC360_REF.ANALYTICS COMMENT='L2: Dynamic tables - analytics-ready joined/enriched data';

create or replace dynamic table SC360_REF.ANALYTICS.DT_BOM_EXPLOSION(
	PARENT_MATERIAL,
	PARENT_DESC,
	BOM_NUMBER,
	BOM_LEVEL,
	COMPONENT_MATERIAL,
	COMPONENT_DESC,
	COMPONENT_QTY,
	COMPONENT_UOM,
	BASE_QTY,
	ITEM_CATEGORY,
	COMPONENT_COST
) target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
 as
SELECT
    b.PARENT_MATERIAL,
    b.PARENT_DESC,
    b.BOM_NUMBER,
    b.BOM_LEVEL,
    b.COMPONENT_MATERIAL,
    b.COMPONENT_DESC,
    b.COMPONENT_QTY,
    b.COMPONENT_UOM,
    b.BASE_QTY,
    b.ITEM_CATEGORY,
    b.COMPONENT_COST
FROM SC360_L0.BILL_OF_MATERIAL.A_BOM_ITEM b;
create or replace dynamic table SC360_REF.ANALYTICS.DT_DELIVERY_PERFORMANCE(
	DELIVERY_ID,
	SHIPPING_POINT,
	SHIPPING_POINT_DESC,
	MATERIAL,
	MATERIAL_DESC,
	DELIVERY_QTY,
	PLANNED_DELIVERY_DATE,
	ACTUAL_DELIVERY_DATE,
	ON_TIME_FLAG,
	DELAY_DAYS,
	DELIVERY_MONTH
) target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
 as
SELECT
    d.DELIVERY_ID,
    d.SHIPPING_POINT,
    sp.SHIPPING_POINT_DESC,
    d.MATERIAL,
    d.MATERIAL_DESC,
    d.DELIVERY_QTY,
    d.PLANNED_DELIVERY_DATE,
    d.ACTUAL_DELIVERY_DATE,
    d.ON_TIME_FLAG,
    d.DELAY_DAYS,
    d.DELIVERY_MONTH
FROM SC360_L0.DELIVERY_MGMT_CONFIG.A_DELIVERY d
JOIN SC360_L0.SHIPPING_POINT.A_SHIPPING_POINT sp ON d.SHIPPING_POINT = sp.SHIPPING_POINT;
create or replace dynamic table SC360_REF.ANALYTICS.DT_INVENTORY_OVERVIEW(
	MATERIAL,
	MATERIAL_DESC,
	PLANT,
	PLANT_NAME,
	STORAGE_LOCATION,
	STOCK_QTY,
	STOCK_VALUE,
	DAYS_OF_INVENTORY,
	TURNOVER_RATE,
	LAST_MOVEMENT_DATE,
	OBSOLETE_FLAG
) target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
 as
SELECT
    ms.MATERIAL,
    ms.MATERIAL_DESC,
    ms.PLANT,
    p.PLANT_NAME,
    ms.STORAGE_LOCATION,
    ms.STOCK_QTY,
    ms.STOCK_VALUE,
    ms.DAYS_OF_INVENTORY,
    ms.TURNOVER_RATE,
    ms.LAST_MOVEMENT_DATE,
    ms.OBSOLETE_FLAG
FROM SC360_L0.MANUFACTURING_CODES.A_MATERIAL_STOCK ms
JOIN SC360_L0.PLANT.A_PLANT p ON ms.PLANT = p.PLANT;
create or replace dynamic table SC360_REF.ANALYTICS.DT_MANUFACTURING_KPI(
	PLANT,
	PLANT_NAME,
	PERIOD_DATE,
	OEE_PCT,
	CYCLE_TIME_AVG,
	THROUGHPUT,
	SCRAP_RATE_PCT,
	ON_TIME_DELIVERY_PCT,
	INVENTORY_TURNOVER
) target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
 as
SELECT
    k.PLANT,
    p.PLANT_NAME,
    k.PERIOD_DATE,
    k.OEE_PCT,
    k.CYCLE_TIME_AVG,
    k.THROUGHPUT,
    k.SCRAP_RATE_PCT,
    k.ON_TIME_DELIVERY_PCT,
    k.INVENTORY_TURNOVER
FROM SC360_L0.MANUFACTURING_CODES.A_MANUFACTURING_KPI k
JOIN SC360_L0.PLANT.A_PLANT p ON k.PLANT = p.PLANT;
create or replace dynamic table SC360_REF.ANALYTICS.DT_PRODUCTION_ORDER_360(
	PRODUCTION_ORDER,
	ORDER_TYPE,
	PLANT,
	PLANT_NAME,
	MATERIAL,
	MATERIAL_DESC,
	PLANNED_QTY,
	CONFIRMED_QTY,
	SCRAP_QTY,
	YIELD_QTY,
	WORK_CENTER,
	CYCLE_TIME_DAYS,
	CREATED_DATE,
	BASIC_START_DATE,
	BASIC_FINISH_DATE,
	ORDER_STATUS
) target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
 as
SELECT
    po.PRODUCTION_ORDER,
    po.ORDER_TYPE,
    po.PLANT,
    p.PLANT_NAME,
    po.MATERIAL,
    po.MATERIAL_DESC,
    po.PLANNED_QTY,
    po.CONFIRMED_QTY,
    po.SCRAP_QTY,
    po.YIELD_QTY,
    po.WORK_CENTER,
    po.CYCLE_TIME_DAYS,
    po.CREATED_DATE,
    po.BASIC_START_DATE,
    po.BASIC_FINISH_DATE,
    po.ORDER_STATUS
FROM SC360_L0.PRODUCTION_ORDER_CONFIRM.A_PROD_ORD_CONFIRMATION po
JOIN SC360_L0.PLANT.A_PLANT p ON po.PLANT = p.PLANT;
create or replace dynamic table SC360_REF.ANALYTICS.DT_PROJECT_STATUS(
	PROJECT_ID,
	PROJECT_NAME,
	PLANT,
	PROJECT_STATUS,
	PLANNED_COST,
	ACTUAL_COST,
	BUDGET_VARIANCE_PCT,
	START_DATE,
	END_DATE,
	COMPLETION_PCT,
	WBS_ELEMENT,
	WBS_DESCRIPTION
) target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
 as
SELECT
    pj.PROJECT_ID,
    pj.PROJECT_NAME,
    pj.PLANT,
    pj.PROJECT_STATUS,
    pj.PLANNED_COST,
    pj.ACTUAL_COST,
    pj.BUDGET_VARIANCE_PCT,
    pj.START_DATE,
    pj.END_DATE,
    pj.COMPLETION_PCT,
    w.WBS_ELEMENT,
    w.WBS_DESCRIPTION
FROM SC360_L0.PROJECT.A_PROJECT pj
LEFT JOIN SC360_L0.PROJECT_NETWORK.A_PROJECT_WBS w ON pj.PROJECT_ID = w.PROJECT_ID;
create or replace dynamic table SC360_REF.ANALYTICS.DT_SUPPLIER_QUALITY(
	SUPPLIER,
	SUPPLIER_NAME,
	MATERIAL,
	MATERIAL_DESC,
	TOTAL_DELIVERED,
	DEFECT_QTY,
	DEFECT_RATE_PCT,
	ON_TIME_DELIVERY_PCT,
	QUALITY_SCORE,
	PERIOD_DATE
) target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
 COMMENT='The table contains records of supplier quality metrics, specifically quality scores and delivery performance. Each record represents a supplier and includes details about the materials they provide, delivery performance, and quality metrics. Includes alternate-source demo enrichment from SUPPLIER_EXT.'
 as
SELECT SUPPLIER, SUPPLIER_NAME, MATERIAL, MATERIAL_DESC, TOTAL_DELIVERED, DEFECT_QTY,
       DEFECT_RATE_PCT, ON_TIME_DELIVERY_PCT, QUALITY_SCORE, PERIOD_DATE
FROM SC360_L0.MANUFACTURING_CODES.A_SUPPLIER_QUALITY
UNION ALL
SELECT SUPPLIER, SUPPLIER_NAME, MATERIAL, MATERIAL_DESC, TOTAL_DELIVERED, DEFECT_QTY,
       DEFECT_RATE_PCT, ON_TIME_DELIVERY_PCT, QUALITY_SCORE, PERIOD_DATE
FROM SC360_EXT.SUPPLIER_EXT.A_SUPPLIER_QUALITY;
create or replace dynamic table SC360_REF.ANALYTICS.DT_SUPPLY_CHAIN_GEO(
	FLOW_ID,
	FLOW_TYPE,
	MATERIAL_CATEGORY,
	MONTHLY_VOLUME,
	MONTHLY_VALUE,
	SOURCE_NAME,
	SOURCE_TYPE,
	SOURCE_CITY,
	SOURCE_COUNTRY,
	SOURCE_LAT,
	SOURCE_LON,
	SOURCE_PLANT,
	TARGET_NAME,
	TARGET_TYPE,
	TARGET_CITY,
	TARGET_COUNTRY,
	TARGET_LAT,
	TARGET_LON,
	TARGET_PLANT
) target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
 as
WITH flows AS (
    SELECT FLOW_ID, FLOW_TYPE, MATERIAL_CATEGORY, MONTHLY_VOLUME, MONTHLY_VALUE, SOURCE_NODE, TARGET_NODE
    FROM SC360_L0.MANUFACTURING_CODES.A_SUPPLY_CHAIN_FLOWS
    UNION ALL
    SELECT FLOW_ID, FLOW_TYPE, MATERIAL_CATEGORY, MONTHLY_VOLUME, MONTHLY_VALUE, SOURCE_NODE, TARGET_NODE
    FROM SC360_EXT.SUPPLIER_EXT.A_SUPPLY_CHAIN_FLOWS
), nodes AS (
    SELECT NODE_ID, NODE_NAME, NODE_TYPE, CITY, COUNTRY, LATITUDE, LONGITUDE, PLANT
    FROM SC360_L0.MANUFACTURING_CODES.A_SUPPLY_CHAIN_NODES
    UNION ALL
    SELECT NODE_ID, NODE_NAME, NODE_TYPE, CITY, COUNTRY, LATITUDE, LONGITUDE, PLANT
    FROM SC360_EXT.SUPPLIER_EXT.A_SUPPLY_CHAIN_NODES
)
SELECT
    f.FLOW_ID,
    f.FLOW_TYPE,
    f.MATERIAL_CATEGORY,
    f.MONTHLY_VOLUME,
    f.MONTHLY_VALUE,
    src.NODE_NAME   AS SOURCE_NAME,
    src.NODE_TYPE   AS SOURCE_TYPE,
    src.CITY        AS SOURCE_CITY,
    src.COUNTRY     AS SOURCE_COUNTRY,
    src.LATITUDE    AS SOURCE_LAT,
    src.LONGITUDE   AS SOURCE_LON,
    src.PLANT       AS SOURCE_PLANT,
    tgt.NODE_NAME   AS TARGET_NAME,
    tgt.NODE_TYPE   AS TARGET_TYPE,
    tgt.CITY        AS TARGET_CITY,
    tgt.COUNTRY     AS TARGET_COUNTRY,
    tgt.LATITUDE    AS TARGET_LAT,
    tgt.LONGITUDE   AS TARGET_LON,
    tgt.PLANT       AS TARGET_PLANT
FROM flows f
JOIN nodes src ON f.SOURCE_NODE = src.NODE_ID
JOIN nodes tgt ON f.TARGET_NODE = tgt.NODE_ID;
create or replace dynamic table SC360_REF.ANALYTICS.DT_WORK_CENTER_UTILIZATION(
	WORK_CENTER,
	WORK_CENTER_DESC,
	PLANT,
	PLANT_NAME,
	AVAILABLE_CAPACITY_HRS,
	USED_CAPACITY_HRS,
	UTILIZATION_PCT,
	PERIOD_DATE
) target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
 as
SELECT
    wc.WORK_CENTER,
    w.WORK_CENTER_DESC,
    wc.PLANT,
    p.PLANT_NAME,
    wc.AVAILABLE_CAPACITY_HRS,
    wc.USED_CAPACITY_HRS,
    ROUND(100.0 * wc.USED_CAPACITY_HRS / NULLIF(wc.AVAILABLE_CAPACITY_HRS, 0), 1) AS UTILIZATION_PCT,
    wc.PERIOD_DATE
FROM SC360_L0.WORK_CENTER.A_WORK_CENTER_CAPACITY wc
JOIN SC360_L0.WORK_CENTER.A_WORK_CENTER w ON wc.WORK_CENTER = w.WORK_CENTER AND wc.PLANT = w.PLANT
JOIN SC360_L0.PLANT.A_PLANT p ON wc.PLANT = p.PLANT;

-- ---------------------------------------------------------------------------
-- LINEAGE_COUNTS — one-row snapshot of L0 / L2 row counts for the
-- "BDC Sources & Lineage" page. Bundled into the Native App (SHARED_DATA) so
-- the SPCS service can show counts without access to the L0 schemas.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE SC360_REF.ANALYTICS.LINEAGE_COUNTS AS
SELECT
  (SELECT COUNT(*) FROM SC360_L0.PLANT.A_PLANT) AS PLANT,
  (SELECT COUNT(*) FROM SC360_L0.WORK_CENTER.A_WORK_CENTER) AS WORK_CENTER,
  (SELECT COUNT(*) FROM SC360_L0.WORK_CENTER.A_WORK_CENTER_CAPACITY) AS WC_CAPACITY,
  (SELECT COUNT(*) FROM SC360_L0.MANUFACTURING_CODES.A_MANUFACTURING_KPI) AS MFG_KPI,
  (SELECT COUNT(*) FROM SC360_L0.MANUFACTURING_CODES.A_MATERIAL_STOCK) AS MATERIAL_STOCK,
  (SELECT COUNT(*) FROM SC360_L0.MANUFACTURING_CODES.A_SUPPLIER_QUALITY) AS SUPPLIER_QUALITY,
  (SELECT COUNT(*) FROM SC360_L0.MANUFACTURING_CODES.A_SUPPLY_CHAIN_FLOWS) AS SC_FLOWS,
  (SELECT COUNT(*) FROM SC360_L0.MANUFACTURING_CODES.A_SUPPLY_CHAIN_NODES) AS SC_NODES,
  (SELECT COUNT(*) FROM SC360_L0.BILL_OF_MATERIAL.A_BOM_ITEM) AS BOM_ITEM,
  (SELECT COUNT(*) FROM SC360_L0.BOM_GROUP.A_BOM_GROUP) AS BOM_GROUP,
  (SELECT COUNT(*) FROM SC360_L0.DELIVERY_MGMT_CONFIG.A_DELIVERY) AS DELIVERY,
  (SELECT COUNT(*) FROM SC360_L0.PRODUCTION_ORDER_CONFIRM.A_PROD_ORD_CONFIRMATION) AS PROD_CONF,
  (SELECT COUNT(*) FROM SC360_L0.PRODUCTION_VERSION.A_PRODUCTION_VERSION) AS PROD_VERSION,
  (SELECT COUNT(*) FROM SC360_L0.PROJECT.A_PROJECT) AS PROJECT,
  (SELECT COUNT(*) FROM SC360_L0.PROJECT_CONFIG_DATA.A_PROJECT_CONFIG) AS PROJECT_CONFIG,
  (SELECT COUNT(*) FROM SC360_L0.PROJECT_NETWORK.A_PROJECT_WBS) AS PROJECT_WBS,
  (SELECT COUNT(*) FROM SC360_L0.SALES_BOM.A_SALES_BOM) AS SALES_BOM,
  (SELECT COUNT(*) FROM SC360_L0.SHIPPING_POINT.A_SHIPPING_POINT) AS SHIPPING_POINT,
  (SELECT COUNT(*) FROM SC360_L0.STORAGE_LOCATION.A_STORAGE_LOCATION) AS STORAGE_LOCATION,
  (SELECT COUNT(*) FROM SC360_L0.CHANGE_MASTER.A_CHANGE_MASTER) AS CHANGE_MASTER,
  (SELECT COUNT(*) FROM SC360_L0.CHANGE_RECORD.A_CHANGE_RECORD) AS CHANGE_RECORD,
  (SELECT COUNT(*) FROM SC360_REF.ANALYTICS.DT_PRODUCTION_ORDER_360) AS DT_PROD_ORDER,
  (SELECT COUNT(*) FROM SC360_REF.ANALYTICS.DT_MANUFACTURING_KPI) AS DT_MFG_KPI,
  (SELECT COUNT(*) FROM SC360_REF.ANALYTICS.DT_BOM_EXPLOSION) AS DT_BOM,
  (SELECT COUNT(*) FROM SC360_REF.ANALYTICS.DT_INVENTORY_OVERVIEW) AS DT_INVENTORY,
  (SELECT COUNT(*) FROM SC360_REF.ANALYTICS.DT_DELIVERY_PERFORMANCE) AS DT_DELIVERY,
  (SELECT COUNT(*) FROM SC360_REF.ANALYTICS.DT_WORK_CENTER_UTILIZATION) AS DT_WC_UTIL,
  (SELECT COUNT(*) FROM SC360_REF.ANALYTICS.DT_PROJECT_STATUS) AS DT_PROJECT,
  (SELECT COUNT(*) FROM SC360_REF.ANALYTICS.DT_SUPPLIER_QUALITY) AS DT_SUPPLIER_QUALITY,
  (SELECT COUNT(*) FROM SC360_REF.ANALYTICS.DT_SUPPLY_CHAIN_GEO) AS DT_SC_GEO,
  -- Synthetic supplier extension (sql/07a), reported separately from L0.
  (SELECT COUNT(*) FROM SC360_EXT.SUPPLIER_EXT.A_SUPPLIER) AS EXT_SUPPLIERS,
  (SELECT COUNT(*) FROM SC360_EXT.SUPPLIER_EXT.A_SUPPLIER_QUALITY) AS EXT_SUPPLIER_QUALITY,
  (SELECT COUNT(*) FROM SC360_EXT.SUPPLIER_EXT.A_SUPPLY_CHAIN_FLOWS) AS EXT_SC_FLOWS,
  (SELECT COUNT(*) FROM SC360_EXT.SUPPLIER_EXT.A_SUPPLY_CHAIN_NODES) AS EXT_SC_NODES;


-- ---------------------------------------------------------------------
-- From demo step 02
-- ---------------------------------------------------------------------
-- =====================================================================
-- Serving layer — APP_REF views
-- Stable, app-facing views over the L2 ANALYTICS dynamic tables plus two
-- raw reference objects (A_PLANT, A_SUPPLY_CHAIN_NODES). This is the
-- interface the dashboard / Native App reads from. A_SUPPLY_CHAIN_NODES
-- unions L0 with the synthetic SUPPLIER_EXT nodes (sql/07a); it is also the
-- source scripts/migrate_data.py bundles, so the app graph sees all nodes.
-- =====================================================================

create or replace schema SC360_REF.APP_REF;

create or replace view SC360_REF.APP_REF.A_PLANT(
	PLANT,
	PLANT_NAME,
	FACTORY_CALENDAR,
	COUNTRY_KEY,
	CITY,
	COMPANY_CODE,
	VALUATION_AREA,
	CREATED_DATE
) as SELECT * FROM SC360_L0.PLANT.A_PLANT;
create or replace view SC360_REF.APP_REF.A_SUPPLY_CHAIN_NODES(
	NODE_ID,
	NODE_NAME,
	NODE_TYPE,
	CITY,
	COUNTRY,
	LATITUDE,
	LONGITUDE,
	PLANT
) as
SELECT NODE_ID, NODE_NAME, NODE_TYPE, CITY, COUNTRY, LATITUDE, LONGITUDE, PLANT
FROM SC360_L0.MANUFACTURING_CODES.A_SUPPLY_CHAIN_NODES
UNION ALL
SELECT NODE_ID, NODE_NAME, NODE_TYPE, CITY, COUNTRY, LATITUDE, LONGITUDE, PLANT
FROM SC360_EXT.SUPPLIER_EXT.A_SUPPLY_CHAIN_NODES;
create or replace view SC360_REF.APP_REF.DT_BOM_EXPLOSION(
	PARENT_MATERIAL,
	PARENT_DESC,
	BOM_NUMBER,
	BOM_LEVEL,
	COMPONENT_MATERIAL,
	COMPONENT_DESC,
	COMPONENT_QTY,
	COMPONENT_UOM,
	BASE_QTY,
	ITEM_CATEGORY,
	COMPONENT_COST
) as SELECT * FROM SC360_REF.ANALYTICS.DT_BOM_EXPLOSION;
create or replace view SC360_REF.APP_REF.DT_DELIVERY_PERFORMANCE(
	DELIVERY_ID,
	SHIPPING_POINT,
	SHIPPING_POINT_DESC,
	MATERIAL,
	MATERIAL_DESC,
	DELIVERY_QTY,
	PLANNED_DELIVERY_DATE,
	ACTUAL_DELIVERY_DATE,
	ON_TIME_FLAG,
	DELAY_DAYS,
	DELIVERY_MONTH
) as SELECT * FROM SC360_REF.ANALYTICS.DT_DELIVERY_PERFORMANCE;
create or replace view SC360_REF.APP_REF.DT_INVENTORY_OVERVIEW(
	MATERIAL,
	MATERIAL_DESC,
	PLANT,
	PLANT_NAME,
	STORAGE_LOCATION,
	STOCK_QTY,
	STOCK_VALUE,
	DAYS_OF_INVENTORY,
	TURNOVER_RATE,
	LAST_MOVEMENT_DATE,
	OBSOLETE_FLAG
) as SELECT * FROM SC360_REF.ANALYTICS.DT_INVENTORY_OVERVIEW;
create or replace view SC360_REF.APP_REF.DT_MANUFACTURING_KPI(
	PLANT,
	PLANT_NAME,
	PERIOD_DATE,
	OEE_PCT,
	CYCLE_TIME_AVG,
	THROUGHPUT,
	SCRAP_RATE_PCT,
	ON_TIME_DELIVERY_PCT,
	INVENTORY_TURNOVER
) as SELECT * FROM SC360_REF.ANALYTICS.DT_MANUFACTURING_KPI;
create or replace view SC360_REF.APP_REF.DT_PRODUCTION_ORDER_360(
	PRODUCTION_ORDER,
	ORDER_TYPE,
	PLANT,
	PLANT_NAME,
	MATERIAL,
	MATERIAL_DESC,
	PLANNED_QTY,
	CONFIRMED_QTY,
	SCRAP_QTY,
	YIELD_QTY,
	WORK_CENTER,
	CYCLE_TIME_DAYS,
	CREATED_DATE,
	BASIC_START_DATE,
	BASIC_FINISH_DATE,
	ORDER_STATUS
) as SELECT * FROM SC360_REF.ANALYTICS.DT_PRODUCTION_ORDER_360;
create or replace view SC360_REF.APP_REF.DT_PROJECT_STATUS(
	PROJECT_ID,
	PROJECT_NAME,
	PLANT,
	PROJECT_STATUS,
	PLANNED_COST,
	ACTUAL_COST,
	BUDGET_VARIANCE_PCT,
	START_DATE,
	END_DATE,
	COMPLETION_PCT,
	WBS_ELEMENT,
	WBS_DESCRIPTION
) as SELECT * FROM SC360_REF.ANALYTICS.DT_PROJECT_STATUS;
create or replace view SC360_REF.APP_REF.DT_SUPPLIER_QUALITY(
	SUPPLIER,
	SUPPLIER_NAME,
	MATERIAL,
	MATERIAL_DESC,
	TOTAL_DELIVERED,
	DEFECT_QTY,
	DEFECT_RATE_PCT,
	ON_TIME_DELIVERY_PCT,
	QUALITY_SCORE,
	PERIOD_DATE
) as SELECT * FROM SC360_REF.ANALYTICS.DT_SUPPLIER_QUALITY;
create or replace view SC360_REF.APP_REF.DT_SUPPLY_CHAIN_GEO(
	FLOW_ID,
	FLOW_TYPE,
	MATERIAL_CATEGORY,
	MONTHLY_VOLUME,
	MONTHLY_VALUE,
	SOURCE_NAME,
	SOURCE_TYPE,
	SOURCE_CITY,
	SOURCE_COUNTRY,
	SOURCE_LAT,
	SOURCE_LON,
	SOURCE_PLANT,
	TARGET_NAME,
	TARGET_TYPE,
	TARGET_CITY,
	TARGET_COUNTRY,
	TARGET_LAT,
	TARGET_LON,
	TARGET_PLANT
) as SELECT * FROM SC360_REF.ANALYTICS.DT_SUPPLY_CHAIN_GEO;
create or replace view SC360_REF.APP_REF.DT_WORK_CENTER_UTILIZATION(
	WORK_CENTER,
	WORK_CENTER_DESC,
	PLANT,
	PLANT_NAME,
	AVAILABLE_CAPACITY_HRS,
	USED_CAPACITY_HRS,
	UTILIZATION_PCT,
	PERIOD_DATE
) as SELECT * FROM SC360_REF.ANALYTICS.DT_WORK_CENTER_UTILIZATION;


-- ---------------------------------------------------------------------
-- From demo step 06
-- ---------------------------------------------------------------------
-- =====================================================================
-- L2 (gold) — Operations extension: fulfillment, operating rate,
-- equipment health, component cover and serial genealogy.
-- Source: SC360_EXT.OPS_EXT (demo enrichment keyed to SAP master
-- data — plants, work centers, materials, BOM, suppliers). Generated by
-- tools/gen_ops_ext.py. Values are representative, not customer data.
-- =====================================================================

-- Customer order lines with root cause and late cost.
create or replace dynamic table SC360_REF.ANALYTICS.DT_ORDER_FULFILLMENT
  target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
  comment = 'Order-level OTIF with late cause and cost (penalty 0.5%/day capped 5% + expedite). Demo enrichment.'
as
SELECT o.SALES_ORDER, o.ITEM, o.SOLD_TO, o.MATERIAL, o.MATERIAL_DESC, o.PLANT, p.PLANT_NAME, o.SHIPPING_POINT,
       o.ORDER_QTY, o.NET_VALUE_USD, o.REQUESTED_SHIP_DATE, o.ACTUAL_SHIP_DATE,
       o.ON_TIME, o.IN_FULL, (o.ON_TIME AND o.IN_FULL) AS OTIF, o.DELAY_DAYS,
       COALESCE(o.LATE_CAUSE, 'ON_TIME') AS LATE_CAUSE,
       CASE o.LATE_CAUSE WHEN 'EQUIPMENT' THEN 'Equipment outage' WHEN 'MATERIAL_SHORTAGE' THEN 'Component shortage'
            WHEN 'PERFORMANCE' THEN 'Rate below plan' WHEN 'QUALITY_HOLD' THEN 'Quality hold'
            WHEN 'LOGISTICS' THEN 'Logistics / carrier' ELSE 'On time' END AS LATE_CAUSE_LABEL,
       o.PENALTY_USD, o.EXPEDITE_USD, o.LATE_COST_USD, o.ORDER_STATUS, o.MARGIN_PER_UNIT_USD,
       DATE_TRUNC('month', o.REQUESTED_SHIP_DATE) AS SHIP_MONTH
FROM SC360_EXT.OPS_EXT.A_SALES_ORDER_ITEM o
JOIN SC360_L0.PLANT.A_PLANT p ON p.PLANT = o.PLANT;

-- Monthly loss tree per plant: nameplate = planned + equipment + material + performance + produced.
create or replace dynamic table SC360_REF.ANALYTICS.DT_OPERATING_RATE
  target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
  comment = 'Operating-rate loss tree per plant and month (units). Demo enrichment.'
as
SELECT r.PLANT, r.PLANT_NAME, r.PERIOD_DATE, r.NAMEPLATE_UNITS, r.PLANNED_DOWNTIME_UNITS, r.EQUIPMENT_LOSS_UNITS,
       r.MATERIAL_SHORTAGE_UNITS, r.PERFORMANCE_LOSS_UNITS, r.PRODUCED_UNITS, r.OPERATING_RATE_PCT,
       IFF(r.EQUIPMENT_LOSS_UNITS >= r.MATERIAL_SHORTAGE_UNITS, 'Equipment', 'Components') AS BINDING_CONSTRAINT
FROM SC360_EXT.OPS_EXT.A_OPERATING_RATE r;

-- Equipment daily health joined to work center; value at risk uses avg margin of systems built at the plant.
create or replace dynamic table SC360_REF.ANALYTICS.DT_EQUIPMENT_HEALTH
  target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
  comment = 'Daily tool health (vibration, temperature, 48h failure probability). Demo enrichment.'
as
SELECT e.EQUIPMENT_ID, e.EQUIPMENT_NAME, e.EQUIPMENT_TYPE, e.WORK_CENTER, w.WORK_CENTER_DESC, e.PLANT, p.PLANT_NAME,
       e.CRITICALITY, e.REPAIR_COST_PER_HR, h.READING_DATE, h.VIBRATION_MM_S, h.TEMPERATURE_C,
       h.FAILURE_PROB_48H, h.ANOMALY_FLAG
FROM SC360_EXT.OPS_EXT.A_EQUIPMENT e
JOIN SC360_EXT.OPS_EXT.A_EQUIPMENT_HEALTH_DAILY h ON h.EQUIPMENT_ID = e.EQUIPMENT_ID
JOIN SC360_L0.WORK_CENTER.A_WORK_CENTER w ON w.WORK_CENTER = e.WORK_CENTER
JOIN SC360_L0.PLANT.A_PLANT p ON p.PLANT = e.PLANT;

create or replace dynamic table SC360_REF.ANALYTICS.DT_EQUIPMENT_OUTAGE
  target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
  comment = 'Outage events with repair cost. Demo enrichment.'
as
SELECT o.OUTAGE_ID, o.EQUIPMENT_ID, e.EQUIPMENT_NAME, o.WORK_CENTER, o.PLANT, p.PLANT_NAME, o.START_DATE,
       o.EVENT_TYPE, o.DOWNTIME_HRS, o.ROOT_CAUSE, o.REPAIR_COST_USD
FROM SC360_EXT.OPS_EXT.A_EQUIPMENT_OUTAGE o
JOIN SC360_EXT.OPS_EXT.A_EQUIPMENT e ON e.EQUIPMENT_ID = o.EQUIPMENT_ID
JOIN SC360_L0.PLANT.A_PLANT p ON p.PLANT = o.PLANT;

create or replace dynamic table SC360_REF.ANALYTICS.DT_COMPONENT_COVER
  target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
  comment = 'Component days of cover vs supplier lead time per plant. Demo enrichment.'
as
SELECT c.PLANT, p.PLANT_NAME, c.COMPONENT_MATERIAL, c.COMPONENT_DESC, c.SUPPLIER, s.SUPPLIER_NAME, c.ON_HAND_QTY,
       c.DAILY_USAGE, c.DAYS_OF_COVER, c.SUPPLIER_LEAD_TIME_DAYS, c.OPEN_PO_QTY, c.STATUS,
       (c.DAYS_OF_COVER < c.SUPPLIER_LEAD_TIME_DAYS) AS COVER_BELOW_LEAD_TIME
FROM SC360_EXT.OPS_EXT.A_COMPONENT_COVER c
JOIN SC360_L0.PLANT.A_PLANT p ON p.PLANT = c.PLANT
LEFT JOIN (SELECT DISTINCT SUPPLIER, SUPPLIER_NAME FROM SC360_EXT.OPS_EXT.A_COMPONENT_LOT) s ON s.SUPPLIER = c.SUPPLIER;

-- Digital thread: serial -> component lot -> supplier inspection -> final test -> customer order.
create or replace dynamic table SC360_REF.ANALYTICS.DT_SERIAL_GENEALOGY
  target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
  comment = 'System serial genealogy to component lots, suppliers and final test. Demo enrichment.'
as
SELECT g.SERIAL_NO, g.MATERIAL, g.PLANT, g.SALES_ORDER, so.SOLD_TO, g.COMPONENT_MATERIAL, l.COMPONENT_DESC, g.LOT_ID,
       l.SUPPLIER, l.SUPPLIER_NAME, l.SUPPLIER_SOURCE, l.RECEIVED_DATE, l.INSPECTION_RESULT, l.DEVIATION_NOTE,
       t.TEST_DATE, t.RESULT AS FINAL_TEST_RESULT, t.DEFECT_CODE, t.REWORK_HRS, t.SENSITIVITY_NM
FROM SC360_EXT.OPS_EXT.A_SERIAL_GENEALOGY g
JOIN SC360_EXT.OPS_EXT.A_COMPONENT_LOT l ON l.LOT_ID = g.LOT_ID
JOIN SC360_EXT.OPS_EXT.A_FINAL_TEST t ON t.SERIAL_NO = g.SERIAL_NO
JOIN SC360_EXT.OPS_EXT.A_SALES_ORDER_ITEM so ON so.SALES_ORDER = g.SALES_ORDER;

-- Serving views (APP_REF) — the interface the app and Native App read.
create or replace view SC360_REF.APP_REF.DT_ORDER_FULFILLMENT as select * from SC360_REF.ANALYTICS.DT_ORDER_FULFILLMENT;
create or replace view SC360_REF.APP_REF.DT_OPERATING_RATE as select * from SC360_REF.ANALYTICS.DT_OPERATING_RATE;
create or replace view SC360_REF.APP_REF.DT_EQUIPMENT_HEALTH as select * from SC360_REF.ANALYTICS.DT_EQUIPMENT_HEALTH;
create or replace view SC360_REF.APP_REF.DT_EQUIPMENT_OUTAGE as select * from SC360_REF.ANALYTICS.DT_EQUIPMENT_OUTAGE;
create or replace view SC360_REF.APP_REF.DT_COMPONENT_COVER as select * from SC360_REF.ANALYTICS.DT_COMPONENT_COVER;
create or replace view SC360_REF.APP_REF.DT_SERIAL_GENEALOGY as select * from SC360_REF.ANALYTICS.DT_SERIAL_GENEALOGY;


-- ---------------------------------------------------------------------
-- From demo step 04
-- ---------------------------------------------------------------------
-- =====================================================================
-- Semantic layer — SAP_SUPPLY_CHAIN_360 semantic view
-- Powers both the Native App "Ask the Agent" page and the account-level
-- SAP_SC360_ANALYST_AGENT Cortex Agent (see 05_cortex_agent.sql).
-- =====================================================================

-- ---------------------------------------------------------------------
-- Ontology entities (conformed dimensions). One row per business key,
-- derived from every fact that carries the key, so each relationship below
-- references a true primary key. In SAP terms these play the role of the
-- master-data CDS entities (I_Product, I_Supplier, I_Plant) that the
-- transactional CDS views associate to.
-- ---------------------------------------------------------------------
create or replace view SC360_REF.ANALYTICS.ENT_MATERIAL as
select material, max(material_desc) as material_desc from (
    select material, material_desc from SC360_REF.ANALYTICS.DT_INVENTORY_OVERVIEW
    union all select material, material_desc from SC360_REF.ANALYTICS.DT_SUPPLIER_QUALITY
    union all select material, material_desc from SC360_REF.ANALYTICS.DT_PRODUCTION_ORDER_360
    union all select parent_material, parent_desc from SC360_REF.ANALYTICS.DT_BOM_EXPLOSION
    union all select component_material, component_desc from SC360_REF.ANALYTICS.DT_BOM_EXPLOSION
    union all select component_material, component_desc from SC360_REF.ANALYTICS.DT_COMPONENT_COVER
    union all select material, material_desc from SC360_REF.ANALYTICS.DT_ORDER_FULFILLMENT
) where material is not null group by material;

create or replace view SC360_REF.ANALYTICS.ENT_SUPPLIER as
select supplier, max(supplier_name) as supplier_name from (
    select supplier, supplier_name from SC360_REF.ANALYTICS.DT_SUPPLIER_QUALITY
    union all select supplier, supplier_name from SC360_REF.ANALYTICS.DT_COMPONENT_COVER
) where supplier is not null group by supplier;

create or replace view SC360_REF.ANALYTICS.ENT_PLANT as
select plant, max(plant_name) as plant_name from (
    select plant, plant_name from SC360_REF.ANALYTICS.DT_INVENTORY_OVERVIEW
    union all select plant, plant_name from SC360_REF.ANALYTICS.DT_PRODUCTION_ORDER_360
    union all select plant, plant_name from SC360_REF.ANALYTICS.DT_COMPONENT_COVER
    union all select plant, plant_name from SC360_REF.ANALYTICS.DT_ORDER_FULFILLMENT
) where plant is not null group by plant;

create or replace semantic view SC360_REF.ANALYTICS.SAP_SUPPLY_CHAIN_360
	tables (
		MANUFACTURING_KPI as SC360_REF.ANALYTICS.DT_MANUFACTURING_KPI comment='Monthly manufacturing performance metrics by plant including OEE, throughput, scrap rate, on-time delivery, and inventory turnover.',
		PRODUCTION_ORDER as SC360_REF.ANALYTICS.DT_PRODUCTION_ORDER_360 primary key (PRODUCTION_ORDER) comment='Production orders with planning, confirmation, yield, and scrap data. Includes cycle time and order status tracking across plants and work centers.',
		BOM_EXPLOSION as SC360_REF.ANALYTICS.DT_BOM_EXPLOSION comment='Multi-level bill of materials showing parent-component relationships, quantities, units of measure, and costs for all manufactured products.',
		WORK_CENTER_UTILIZATION as SC360_REF.ANALYTICS.DT_WORK_CENTER_UTILIZATION comment='Monthly work center capacity and utilization data. Tracks available vs used hours to identify production bottlenecks across plants.',
		INVENTORY_OVERVIEW as SC360_REF.ANALYTICS.DT_INVENTORY_OVERVIEW primary key (MATERIAL) unique (MATERIAL,PLANT) comment='Current stock positions by material, plant, and storage location. Includes days of inventory, turnover rates, and obsolescence flags.',
		DELIVERY_PERFORMANCE as SC360_REF.ANALYTICS.DT_DELIVERY_PERFORMANCE primary key (DELIVERY_ID) comment='Outbound delivery tracking with on-time performance, delay analysis, and shipping point metrics for logistics monitoring.',
		SUPPLIER_QUALITY as SC360_REF.ANALYTICS.DT_SUPPLIER_QUALITY comment='Quarterly supplier performance scoring including defect rates, on-time delivery percentages, and composite quality scores per material.',
		PROJECT_STATUS as SC360_REF.ANALYTICS.DT_PROJECT_STATUS comment='Capital and operational project tracking with budget variance, completion percentage, and WBS element breakdown.',
		SUPPLY_CHAIN_GEO as SC360_REF.ANALYTICS.DT_SUPPLY_CHAIN_GEO comment='Geographic supply chain flow data showing material movements between suppliers, plants, and distribution centers with coordinates for map visualization.',
    ORDER_FULFILLMENT as SC360_REF.ANALYTICS.DT_ORDER_FULFILLMENT primary key (SALES_ORDER) comment='Customer sales order lines with on-time-in-full (OTIF), delay days, root cause of lateness and late cost (penalty plus expedite). Demo enrichment keyed to SAP plants and materials.',
    OPERATING_RATE as SC360_REF.ANALYTICS.DT_OPERATING_RATE comment='Monthly operating-rate loss tree per plant in system units: nameplate split into planned downtime, equipment outage loss, component shortage loss, performance loss and produced units. Demo enrichment.',
    EQUIPMENT_HEALTH as SC360_REF.ANALYTICS.DT_EQUIPMENT_HEALTH comment='Daily health readings per production tool (vibration, temperature, 48-hour failure probability, anomaly flag). Demo enrichment keyed to SAP work centers.',
    EQUIPMENT_OUTAGE as SC360_REF.ANALYTICS.DT_EQUIPMENT_OUTAGE primary key (OUTAGE_ID) comment='Equipment outage events with downtime hours, root cause and repair cost. Demo enrichment.',
    COMPONENT_COVER as SC360_REF.ANALYTICS.DT_COMPONENT_COVER comment='Component days of cover versus supplier lead time per plant, with open PO quantity and status (Critical/Watch/OK). Demo enrichment keyed to the SAP BOM.',
    MATERIAL as SC360_REF.ANALYTICS.ENT_MATERIAL primary key (MATERIAL) comment='Ontology entity: one row per SAP material (finished good, assembly or component). Conformed across inventory, BOM, production, supplier quality, component cover and customer orders.',
    SUPPLIER as SC360_REF.ANALYTICS.ENT_SUPPLIER primary key (SUPPLIER) comment='Ontology entity: one row per SAP supplier (vendor) account.',
    PLANT as SC360_REF.ANALYTICS.ENT_PLANT primary key (PLANT) comment='Ontology entity: one row per SAP plant.'
  )
	relationships (
		DT_PRODUCTION_ORDER_360_TO_DT_INVENTORY_OVERVIEW as PRODUCTION_ORDER(MATERIAL,PLANT) references INVENTORY_OVERVIEW(MATERIAL,PLANT),
		DT_DELIVERY_PERFORMANCE_TO_DT_INVENTORY_OVERVIEW as DELIVERY_PERFORMANCE(MATERIAL) references INVENTORY_OVERVIEW(MATERIAL),
		DT_SUPPLIER_QUALITY_TO_DT_INVENTORY_OVERVIEW as SUPPLIER_QUALITY(MATERIAL) references INVENTORY_OVERVIEW(MATERIAL),
		SUPPLIER_SUPPLIES as SUPPLIER_QUALITY(SUPPLIER) references SUPPLIER(SUPPLIER),
		SUPPLIED_MATERIAL as SUPPLIER_QUALITY(MATERIAL) references MATERIAL(MATERIAL),
		BOM_COMPONENT as BOM_EXPLOSION(COMPONENT_MATERIAL) references MATERIAL(MATERIAL),
		PRODUCED_MATERIAL as PRODUCTION_ORDER(MATERIAL) references MATERIAL(MATERIAL),
		PRODUCED_AT_PLANT as PRODUCTION_ORDER(PLANT) references PLANT(PLANT),
		COVER_COMPONENT as COMPONENT_COVER(COMPONENT_MATERIAL) references MATERIAL(MATERIAL),
		COVER_SUPPLIER as COMPONENT_COVER(SUPPLIER) references SUPPLIER(SUPPLIER),
		COVER_PLANT as COMPONENT_COVER(PLANT) references PLANT(PLANT),
		ORDERED_MATERIAL as ORDER_FULFILLMENT(MATERIAL) references MATERIAL(MATERIAL),
		ORDERED_AT_PLANT as ORDER_FULFILLMENT(PLANT) references PLANT(PLANT)
	)
	facts (
		MANUFACTURING_KPI.OEE_PCT as OEE_PCT comment='Overall Equipment Effectiveness percentage — composite of availability, performance, and quality. Higher is better; world-class is 85%+.',
		MANUFACTURING_KPI.CYCLE_TIME_AVG as CYCLE_TIME_AVG comment='Average manufacturing cycle time in days from order start to completion.',
		MANUFACTURING_KPI.SCRAP_RATE_PCT as SCRAP_RATE_PCT comment='Percentage of production scrapped or rejected due to quality defects.',
		MANUFACTURING_KPI.ON_TIME_DELIVERY_PCT as ON_TIME_DELIVERY_PCT comment='Percentage of orders delivered on or before the planned delivery date.',
		MANUFACTURING_KPI.INVENTORY_TURNOVER as INVENTORY_TURNOVER comment='Number of times inventory is consumed and replenished per period. Higher values indicate leaner inventory.',
		PRODUCTION_ORDER.PLANNED_QTY as PLANNED_QTY comment='Planned production quantity for the order in the base unit of measure.',
		PRODUCTION_ORDER.CONFIRMED_QTY as CONFIRMED_QTY comment='Quantity confirmed as completed and posted to inventory.',
		PRODUCTION_ORDER.SCRAP_QTY as SCRAP_QTY comment='Quantity scrapped or rejected during production operations.',
		PRODUCTION_ORDER.YIELD_QTY as YIELD_QTY comment='Good output quantity after accounting for scrap (confirmed minus scrap).',
		PRODUCTION_ORDER.CYCLE_TIME_DAYS as CYCLE_TIME_DAYS comment='Actual cycle time in days from order start to confirmed completion.',
		BOM_EXPLOSION.COMPONENT_QTY as COMPONENT_QTY comment='Required quantity of the component per base quantity of the parent material.',
		BOM_EXPLOSION.BASE_QTY as BASE_QTY comment='Quantity of the parent material to which the component quantity ratio applies.',
		BOM_EXPLOSION.COMPONENT_COST as COMPONENT_COST comment='Standard cost of the component in USD used for BOM cost rollup.',
		WORK_CENTER_UTILIZATION.AVAILABLE_CAPACITY_HRS as AVAILABLE_CAPACITY_HRS comment='Total available machine or labor hours for the work center in the period.',
		WORK_CENTER_UTILIZATION.USED_CAPACITY_HRS as USED_CAPACITY_HRS comment='Actual hours consumed by production orders at the work center.',
		WORK_CENTER_UTILIZATION.UTILIZATION_PCT as UTILIZATION_PCT comment='Utilization rate as percentage of available capacity (used / available * 100). Values above 85% indicate potential bottlenecks.',
		INVENTORY_OVERVIEW.STOCK_QTY as STOCK_QTY comment='Current unrestricted-use stock quantity in the base unit of measure.',
		INVENTORY_OVERVIEW.STOCK_VALUE as STOCK_VALUE comment='Current stock value in USD calculated at standard cost.',
		INVENTORY_OVERVIEW.TURNOVER_RATE as TURNOVER_RATE comment='Annual inventory turnover rate. Higher values indicate faster-moving stock.',
		DELIVERY_PERFORMANCE.DELIVERY_QTY as DELIVERY_QTY comment='Quantity of material delivered in the delivery unit of measure.',
		SUPPLIER_QUALITY.DEFECT_RATE_PCT as DEFECT_RATE_PCT comment='Defect rate as a percentage of total units delivered. Lower is better.',
		SUPPLIER_QUALITY.ON_TIME_DELIVERY_PCT as ON_TIME_DELIVERY_PCT comment='Percentage of supplier deliveries received on or before the agreed purchase order delivery date.',
		SUPPLIER_QUALITY.QUALITY_SCORE as QUALITY_SCORE comment='Composite supplier quality score from 0 to 100. Higher is better.',
		PROJECT_STATUS.PLANNED_COST as PLANNED_COST comment='Total planned budget for the project in USD.',
		PROJECT_STATUS.ACTUAL_COST as ACTUAL_COST comment='Total actual costs incurred to date against the project in USD.',
		PROJECT_STATUS.BUDGET_VARIANCE_PCT as BUDGET_VARIANCE_PCT comment='Budget variance as a percentage of planned cost. Positive = over budget, negative = under budget.',
		PROJECT_STATUS.COMPLETION_PCT as COMPLETION_PCT comment='Percentage of total project scope completed to date (0-100).',
		SUPPLY_CHAIN_GEO.MONTHLY_VALUE as MONTHLY_VALUE comment='Average monthly value of goods flowing between source and target in USD.',
		SUPPLY_CHAIN_GEO.SOURCE_LAT as SOURCE_LAT comment='Latitude coordinate of the source location for map visualization.',
		SUPPLY_CHAIN_GEO.SOURCE_LON as SOURCE_LON comment='Longitude coordinate of the source location for map visualization.',
		SUPPLY_CHAIN_GEO.TARGET_LAT as TARGET_LAT comment='Latitude coordinate of the target location for map visualization.',
		SUPPLY_CHAIN_GEO.TARGET_LON as TARGET_LON comment='Longitude coordinate of the target location for map visualization.',
    ORDER_FULFILLMENT.ORDER_QTY as ORDER_QTY comment='Systems ordered on the sales order line.',
    ORDER_FULFILLMENT.NET_VALUE_USD as NET_VALUE_USD comment='Net order value in USD.',
    ORDER_FULFILLMENT.DELAY_DAYS as DELAY_DAYS comment='Days the order shipped after the requested ship date (0 if on time).',
    ORDER_FULFILLMENT.PENALTY_USD as PENALTY_USD comment='Late-delivery penalty: 0.5% of order value per day late, capped at 5%.',
    ORDER_FULFILLMENT.EXPEDITE_USD as EXPEDITE_USD comment='Expedite freight paid to recover a late order.',
    ORDER_FULFILLMENT.LATE_COST_USD as LATE_COST_USD comment='Total late cost = penalty + expedite.',
    OPERATING_RATE.NAMEPLATE_UNITS as NAMEPLATE_UNITS comment='Nameplate capacity in systems for the plant-month.',
    OPERATING_RATE.PLANNED_DOWNTIME_UNITS as PLANNED_DOWNTIME_UNITS comment='Capacity lost to planned maintenance.',
    OPERATING_RATE.EQUIPMENT_LOSS_UNITS as EQUIPMENT_LOSS_UNITS comment='Capacity lost to unplanned equipment outages.',
    OPERATING_RATE.MATERIAL_SHORTAGE_UNITS as MATERIAL_SHORTAGE_UNITS comment='Capacity lost to component shortages.',
    OPERATING_RATE.PERFORMANCE_LOSS_UNITS as PERFORMANCE_LOSS_UNITS comment='Capacity lost to running below planned rate with no outage.',
    OPERATING_RATE.PRODUCED_UNITS as PRODUCED_UNITS comment='Systems actually produced.',
    OPERATING_RATE.OPERATING_RATE_PCT as OPERATING_RATE_PCT comment='Produced / nameplate x 100.',
    EQUIPMENT_HEALTH.VIBRATION_MM_S as VIBRATION_MM_S comment='Vibration velocity in mm/s; rising values precede bearing and stage failures.',
    EQUIPMENT_HEALTH.TEMPERATURE_C as TEMPERATURE_C comment='Tool temperature in degrees C.',
    EQUIPMENT_HEALTH.FAILURE_PROB_48H as FAILURE_PROB_48H comment='Modelled probability of failure within 48 hours (0-1).',
    EQUIPMENT_OUTAGE.DOWNTIME_HRS as DOWNTIME_HRS comment='Hours the tool was down.',
    EQUIPMENT_OUTAGE.REPAIR_COST_USD as REPAIR_COST_USD comment='Repair cost in USD.',
    COMPONENT_COVER.ON_HAND_QTY as ON_HAND_QTY comment='Component units on hand at the plant.',
    COMPONENT_COVER.DAILY_USAGE as DAILY_USAGE comment='Average component units consumed per day.',
    COMPONENT_COVER.DAYS_OF_COVER as DAYS_OF_COVER comment='On-hand quantity / daily usage, in days.',
    COMPONENT_COVER.SUPPLIER_LEAD_TIME_DAYS as SUPPLIER_LEAD_TIME_DAYS comment='Supplier replenishment lead time in days. Cover below lead time means a shortage is locked in.',
    COMPONENT_COVER.OPEN_PO_QTY as OPEN_PO_QTY comment='Open purchase order quantity for the component.'
  )
	dimensions (
		MANUFACTURING_KPI.PLANT as PLANT comment='SAP plant code (e.g. SJ01=San Jose, AU01=Austin, DR01=Dresden, SG01=Singapore, PN01=Penang).',
		MANUFACTURING_KPI.PLANT_NAME as PLANT_NAME comment='Full plant name (San Jose HQ, Austin Fab, Dresden Fab, Singapore Hub, Penang Assembly).',
		MANUFACTURING_KPI.THROUGHPUT as THROUGHPUT comment='Total units produced at the plant in the reporting period.',
		MANUFACTURING_KPI.PERIOD_DATE as PERIOD_DATE comment='Monthly reporting period date. Use for time-series trend analysis.',
		PRODUCTION_ORDER.PRODUCTION_ORDER as PRODUCTION_ORDER comment='Unique SAP production order number (12-digit identifier).',
		PRODUCTION_ORDER.ORDER_TYPE as ORDER_TYPE comment='SAP order type code (PP01=standard production, PP02=rework order).',
		PRODUCTION_ORDER.PLANT as PLANT comment='SAP plant code where the production order is being executed.',
		PRODUCTION_ORDER.PLANT_NAME as PLANT_NAME comment='Full name of the manufacturing plant executing the order.',
		PRODUCTION_ORDER.MATERIAL as MATERIAL comment='SAP material number for the item being produced.',
		PRODUCTION_ORDER.MATERIAL_DESC as MATERIAL_DESC comment='Material description — the product or component name being manufactured.',
		PRODUCTION_ORDER.WORK_CENTER as WORK_CENTER comment='SAP work center code where production operations are performed.',
		PRODUCTION_ORDER.ORDER_STATUS as ORDER_STATUS comment='Current lifecycle status of the order (Created, Released, Delivered).',
		PRODUCTION_ORDER.CREATED_DATE as CREATED_DATE comment='Date the production order was created in SAP.',
		PRODUCTION_ORDER.BASIC_START_DATE as BASIC_START_DATE comment='Planned start date for production operations.',
		PRODUCTION_ORDER.BASIC_FINISH_DATE as BASIC_FINISH_DATE comment='Planned completion date for the production order.',
		BOM_EXPLOSION.PARENT_MATERIAL as PARENT_MATERIAL comment='SAP material number of the parent assembly or finished good.',
		BOM_EXPLOSION.PARENT_DESC as PARENT_DESC comment='Description of the parent material or top-level assembly.',
		BOM_EXPLOSION.BOM_NUMBER as BOM_NUMBER comment='SAP Bill of Materials header number.',
		BOM_EXPLOSION.BOM_LEVEL as BOM_LEVEL comment='Hierarchy level in the BOM structure (0=top-level, 1=sub-assembly, 2+=components).',
		BOM_EXPLOSION.COMPONENT_MATERIAL as COMPONENT_MATERIAL comment='SAP material number of the component or sub-assembly.',
		BOM_EXPLOSION.COMPONENT_DESC as COMPONENT_DESC comment='Description of the component material used in the assembly.',
		BOM_EXPLOSION.COMPONENT_UOM as COMPONENT_UOM comment='Unit of measure for the component quantity (EA=each, KG=kilogram, M=meter).',
		BOM_EXPLOSION.ITEM_CATEGORY as ITEM_CATEGORY comment='BOM item category (Stock=warehouse-managed, Non-Stock=direct procurement).',
		WORK_CENTER_UTILIZATION.WORK_CENTER as WORK_CENTER comment='SAP work center code (e.g. WC001=Lithography, WC002=Etching).',
		WORK_CENTER_UTILIZATION.WORK_CENTER_DESC as WORK_CENTER_DESC comment='Work center description (Lithography, Etching, Assembly, Test, Packaging).',
		WORK_CENTER_UTILIZATION.PLANT as PLANT comment='SAP plant code where the work center is located.',
		WORK_CENTER_UTILIZATION.PLANT_NAME as PLANT_NAME comment='Full name of the plant where the work center operates.',
		WORK_CENTER_UTILIZATION.PERIOD_DATE as PERIOD_DATE comment='Monthly period for capacity and utilization reporting.',
		INVENTORY_OVERVIEW.MATERIAL as MATERIAL comment='SAP material number — primary identifier for the stocked item.',
		INVENTORY_OVERVIEW.MATERIAL_DESC as MATERIAL_DESC comment='Description of the material held in inventory.',
		INVENTORY_OVERVIEW.PLANT as PLANT comment='SAP plant code where the stock is physically held.',
		INVENTORY_OVERVIEW.PLANT_NAME as PLANT_NAME comment='Full name of the plant holding the inventory.',
		INVENTORY_OVERVIEW.STORAGE_LOCATION as STORAGE_LOCATION comment='SAP storage location code within the plant.',
		INVENTORY_OVERVIEW.DAYS_OF_INVENTORY as DAYS_OF_INVENTORY comment='Number of days of supply based on current stock and average daily consumption.',
		INVENTORY_OVERVIEW.OBSOLETE_FLAG as OBSOLETE_FLAG comment='Indicates whether the material is flagged as obsolete (Y=obsolete, N=active).',
		INVENTORY_OVERVIEW.LAST_MOVEMENT_DATE as LAST_MOVEMENT_DATE comment='Date of the most recent inventory movement.',
		DELIVERY_PERFORMANCE.DELIVERY_ID as DELIVERY_ID comment='SAP outbound delivery document number (unique per shipment).',
		DELIVERY_PERFORMANCE.SHIPPING_POINT as SHIPPING_POINT comment='SAP shipping point code — the organizational unit from which the delivery originates.',
		DELIVERY_PERFORMANCE.SHIPPING_POINT_DESC as SHIPPING_POINT_DESC comment='Description of the shipping point.',
		DELIVERY_PERFORMANCE.MATERIAL as MATERIAL comment='SAP material number of the item included in the delivery.',
		DELIVERY_PERFORMANCE.MATERIAL_DESC as MATERIAL_DESC comment='Description of the delivered material.',
		DELIVERY_PERFORMANCE.ON_TIME_FLAG as ON_TIME_FLAG comment='Indicates whether the delivery met the planned date (Y=on-time, N=late).',
		DELIVERY_PERFORMANCE.DELAY_DAYS as DELAY_DAYS comment='Number of calendar days the delivery was late. Zero for on-time deliveries.',
		DELIVERY_PERFORMANCE.PLANNED_DELIVERY_DATE as PLANNED_DELIVERY_DATE comment='Originally planned delivery date.',
		DELIVERY_PERFORMANCE.ACTUAL_DELIVERY_DATE as ACTUAL_DELIVERY_DATE comment='Actual date the delivery was completed.',
		DELIVERY_PERFORMANCE.DELIVERY_MONTH as DELIVERY_MONTH comment='First day of the delivery month — used for monthly period aggregations.',
		SUPPLIER_QUALITY.SUPPLIER as SUPPLIER comment='SAP supplier (vendor) account number.',
		SUPPLIER_QUALITY.SUPPLIER_NAME as SUPPLIER_NAME comment='Full registered name of the supplier.',
		SUPPLIER_QUALITY.MATERIAL as MATERIAL comment='SAP material number of the item procured from this supplier.',
		SUPPLIER_QUALITY.MATERIAL_DESC as MATERIAL_DESC comment='Description of the material supplied.',
		SUPPLIER_QUALITY.TOTAL_DELIVERED as TOTAL_DELIVERED comment='Total units delivered by the supplier in the reporting period.',
		SUPPLIER_QUALITY.DEFECT_QTY as DEFECT_QTY comment='Number of defective or non-conforming units received from the supplier.',
		SUPPLIER_QUALITY.PERIOD_DATE as PERIOD_DATE comment='Quarterly reporting period date for supplier quality measurement.',
		PROJECT_STATUS.PROJECT_ID as PROJECT_ID comment='Unique SAP project definition identifier.',
		PROJECT_STATUS.PROJECT_NAME as PROJECT_NAME comment='Full descriptive name of the project.',
		PROJECT_STATUS.PLANT as PLANT comment='SAP plant associated with the project.',
		PROJECT_STATUS.PROJECT_STATUS as PROJECT_STATUS comment='Current lifecycle status of the project (Active, Completed, Planned).',
		PROJECT_STATUS.WBS_ELEMENT as WBS_ELEMENT comment='Work Breakdown Structure element code.',
		PROJECT_STATUS.WBS_DESCRIPTION as WBS_DESCRIPTION comment='Description of the WBS element (Engineering, Procurement, Installation, etc.).',
		PROJECT_STATUS.START_DATE as START_DATE comment='Planned start date for the project.',
		PROJECT_STATUS.END_DATE as END_DATE comment='Planned end date or completion deadline for the project.',
		SUPPLY_CHAIN_GEO.FLOW_ID as FLOW_ID comment='Unique identifier for the supply chain flow lane between a source and target location.',
		SUPPLY_CHAIN_GEO.FLOW_TYPE as FLOW_TYPE comment='Type of supply chain flow (Procurement, Manufacturing, Distribution, Returns).',
		SUPPLY_CHAIN_GEO.MATERIAL_CATEGORY as MATERIAL_CATEGORY comment='Category of materials transported in this flow (Raw Materials, Components, Finished Goods).',
		SUPPLY_CHAIN_GEO.MONTHLY_VOLUME as MONTHLY_VOLUME comment='Average monthly unit volume flowing between the source and target locations.',
		SUPPLY_CHAIN_GEO.SOURCE_NAME as SOURCE_NAME comment='Name of the source location (supplier name, plant name, or distribution center).',
		SUPPLY_CHAIN_GEO.SOURCE_TYPE as SOURCE_TYPE comment='Type of source location (Supplier, Plant, Distribution Center).',
		SUPPLY_CHAIN_GEO.SOURCE_CITY as SOURCE_CITY comment='City where the source location is based.',
		SUPPLY_CHAIN_GEO.SOURCE_COUNTRY as SOURCE_COUNTRY comment='Country where the source location is based.',
		SUPPLY_CHAIN_GEO.SOURCE_PLANT as SOURCE_PLANT comment='SAP plant code of the source location (if a plant).',
		SUPPLY_CHAIN_GEO.TARGET_NAME as TARGET_NAME comment='Name of the target or destination location.',
		SUPPLY_CHAIN_GEO.TARGET_TYPE as TARGET_TYPE comment='Type of target location (Plant, Distribution Center, Customer).',
		SUPPLY_CHAIN_GEO.TARGET_CITY as TARGET_CITY comment='City where the target location is based.',
		SUPPLY_CHAIN_GEO.TARGET_COUNTRY as TARGET_COUNTRY comment='Country where the target location is based.',
		SUPPLY_CHAIN_GEO.TARGET_PLANT as TARGET_PLANT comment='SAP plant code of the target location (if a plant).',
    ORDER_FULFILLMENT.SALES_ORDER as SALES_ORDER comment='SAP sales order number.',
    ORDER_FULFILLMENT.MATERIAL as MATERIAL comment='SAP material number of the system ordered (links to MATERIAL).',
    ORDER_FULFILLMENT.PLANT as PLANT comment='SAP plant code that builds and ships the order (links to PLANT).',
    ORDER_FULFILLMENT.SOLD_TO as SOLD_TO comment='Customer (sold-to party), e.g. TSMC, Samsung Foundry, Intel.',
    ORDER_FULFILLMENT.MATERIAL_DESC as MATERIAL_DESC comment='Inspection system ordered.',
    ORDER_FULFILLMENT.PLANT_NAME as PLANT_NAME comment='Plant that builds and ships the order.',
    ORDER_FULFILLMENT.REQUESTED_SHIP_DATE as REQUESTED_SHIP_DATE comment='Customer requested ship date.',
    ORDER_FULFILLMENT.ACTUAL_SHIP_DATE as ACTUAL_SHIP_DATE comment='Actual ship date (null if still open).',
    ORDER_FULFILLMENT.SHIP_MONTH as SHIP_MONTH comment='Month of the requested ship date.',
    ORDER_FULFILLMENT.OTIF as OTIF comment='TRUE when the order shipped on time and in full.',
    ORDER_FULFILLMENT.ON_TIME as ON_TIME comment='TRUE when the order shipped on or before the requested date.',
    ORDER_FULFILLMENT.LATE_CAUSE_LABEL as LATE_CAUSE_LABEL comment='Root cause of lateness: Component shortage, Equipment outage, Quality hold, Rate below plan, Logistics / carrier, or On time.',
    ORDER_FULFILLMENT.ORDER_STATUS as ORDER_STATUS comment='Shipped, Open, or Open - at risk.',
    OPERATING_RATE.PLANT_NAME as PLANT_NAME comment='Plant name for the loss tree.',
    OPERATING_RATE.PERIOD_DATE as PERIOD_DATE comment='Month of the loss tree.',
    OPERATING_RATE.BINDING_CONSTRAINT as BINDING_CONSTRAINT comment='Whether Equipment or Components cost more capacity that month.',
    EQUIPMENT_HEALTH.EQUIPMENT_ID as EQUIPMENT_ID comment='Tool identifier, e.g. EQ-LIT2-1.',
    EQUIPMENT_HEALTH.EQUIPMENT_NAME as EQUIPMENT_NAME comment='Tool name, e.g. Stepper LIT2-1.',
    EQUIPMENT_HEALTH.EQUIPMENT_TYPE as EQUIPMENT_TYPE comment='Tool type (Stepper, Plasma Etcher, CVD Chamber, ...).',
    EQUIPMENT_HEALTH.WORK_CENTER_DESC as WORK_CENTER_DESC comment='Work center the tool belongs to.',
    EQUIPMENT_HEALTH.PLANT_NAME as PLANT_NAME comment='Plant where the tool is installed.',
    EQUIPMENT_HEALTH.CRITICALITY as CRITICALITY comment='Asset criticality A (highest) to C.',
    EQUIPMENT_HEALTH.READING_DATE as READING_DATE comment='Date of the health reading. Use the latest date for current risk.',
    EQUIPMENT_HEALTH.ANOMALY_FLAG as ANOMALY_FLAG comment='TRUE when the reading is anomalous (failure probability above 35%).',
    EQUIPMENT_OUTAGE.OUTAGE_ID as OUTAGE_ID comment='Outage event id.',
    EQUIPMENT_OUTAGE.EQUIPMENT_NAME as EQUIPMENT_NAME comment='Tool that went down.',
    EQUIPMENT_OUTAGE.PLANT_NAME as PLANT_NAME comment='Plant of the outage.',
    EQUIPMENT_OUTAGE.START_DATE as START_DATE comment='Date the outage started.',
    EQUIPMENT_OUTAGE.EVENT_TYPE as EVENT_TYPE comment='Failure, Corrective, or Planned PM.',
    EQUIPMENT_OUTAGE.ROOT_CAUSE as ROOT_CAUSE comment='Root cause recorded for the outage.',
    COMPONENT_COVER.PLANT_NAME as PLANT_NAME comment='Plant holding the component.',
    COMPONENT_COVER.COMPONENT_DESC as COMPONENT_DESC comment='Component description, e.g. High-Res CCD Array.',
    COMPONENT_COVER.SUPPLIER_NAME as SUPPLIER_NAME comment='Supplier of the component.',
    COMPONENT_COVER.STATUS as STATUS comment='Critical (<7 days), Watch (<15 days) or OK.',
    COMPONENT_COVER.COMPONENT_MATERIAL as COMPONENT_MATERIAL comment='SAP material number of the component.',
    COMPONENT_COVER.SUPPLIER as SUPPLIER comment='SAP supplier account of the component.',
    COMPONENT_COVER.PLANT as PLANT comment='SAP plant code holding the component.',
    MATERIAL.MATERIAL as MATERIAL comment='SAP material number (ontology key).',
    MATERIAL.MATERIAL_DESC as MATERIAL_DESC comment='Material description.',
    SUPPLIER.SUPPLIER as SUPPLIER comment='SAP supplier account number (ontology key).',
    SUPPLIER.SUPPLIER_NAME as SUPPLIER_NAME comment='Supplier name, e.g. Festo AG.',
    PLANT.PLANT as PLANT comment='SAP plant code (ontology key).',
    PLANT.PLANT_NAME as PLANT_NAME comment='Plant name.'
  )
	comment='Unified semantic model for SAP Supply Chain analytics covering production planning, bill of materials, work center capacity, inventory management, logistics delivery performance, supplier quality, project management, and manufacturing KPIs. Built from 16 SAP BDC Supply Chain data products with 177 entities.'
	ai_sql_generation 'This semantic view covers SAP supply chain data across 14 fact tables plus 3 ontology entities (MATERIAL, SUPPLIER, PLANT). The entities are the shared keys: SUPPLIER_QUALITY links to SUPPLIER and MATERIAL; BOM_EXPLOSION.COMPONENT_MATERIAL links to MATERIAL; PRODUCTION_ORDER links to MATERIAL and PLANT; COMPONENT_COVER links to MATERIAL, SUPPLIER and PLANT; ORDER_FULFILLMENT links to MATERIAL and PLANT. To traverse supplier -> component -> parent assembly, join SUPPLIER_QUALITY.MATERIAL to BOM_EXPLOSION.COMPONENT_MATERIAL and read PARENT_MATERIAL/PARENT_DESC; the BOM is multi-level, so walk parents recursively. To find customer orders at risk from a supplier, match ORDER_FULFILLMENT.MATERIAL to any BOM ancestor of that supplier''s components and keep open orders (ACTUAL_SHIP_DATE IS NULL). Alternate suppliers for a component are other SUPPLIER_QUALITY rows with the same MATERIAL. For alternate-supplier or replacement decisions, always score each alternate by AVG(QUALITY_SCORE) per supplier and material (never filter individual rows), LEFT JOIN from the affected components so every component is kept, and classify: Candidate if the average is at least the quality bar (default 90), Blocked if below the bar, Review if no alternate supplier exists. Supplier names are stored in full (e.g. Festo AG); match with ILIKE. Use MANUFACTURING_KPI for OEE, cycle time, scrap rate, and plant-level KPI trends. Use PRODUCTION_ORDER for order-level yield, scrap, and cycle time by material or work center. Use BOM_EXPLOSION for component cost rollup and bill-of-materials analysis. Use WORK_CENTER_UTILIZATION to identify bottlenecks (utilization > 85%). Use INVENTORY_OVERVIEW as the hub table for material/plant-level stock, value, and turnover. INVENTORY_OVERVIEW is linked to PRODUCTION_ORDER, DELIVERY_PERFORMANCE, and SUPPLIER_QUALITY via MATERIAL (and PLANT where applicable). Use DELIVERY_PERFORMANCE for on-time delivery rates and delay analysis. Use SUPPLIER_QUALITY for supplier scorecards and defect trends. Use PROJECT_STATUS for budget variance and project completion. Use SUPPLY_CHAIN_GEO for geographic flow visualization. Use ORDER_FULFILLMENT for customer OTIF, late orders, late cause and late cost. Use OPERATING_RATE for the capacity loss tree and the binding constraint per plant. Use EQUIPMENT_HEALTH (latest READING_DATE per tool) for failure risk; EQUIPMENT_OUTAGE for downtime history and repair cost. Use COMPONENT_COVER for component shortages and days of cover vs lead time. Order, equipment and component tables are representative demo enrichment.'
	ai_verified_queries (
    SUPPLIER_STOP_ORDERS_AT_RISK AS (
QUESTION 'If Festo AG stops delivering, which open customer orders are at risk?'
VERIFIED_AT 1792540800
VERIFIED_BY '(source=ontology)'
ONBOARDING_QUESTION true
SQL 'WITH RECURSIVE FESTO_PARTS AS (SELECT DISTINCT MATERIAL FROM SC360_REF.ANALYTICS.DT_SUPPLIER_QUALITY WHERE SUPPLIER_NAME ILIKE ''%Festo AG%''), PARENTS (MATERIAL, PARENT_MATERIAL) AS (SELECT B.COMPONENT_MATERIAL, B.PARENT_MATERIAL FROM SC360_REF.ANALYTICS.DT_BOM_EXPLOSION B JOIN FESTO_PARTS F ON B.COMPONENT_MATERIAL = F.MATERIAL UNION ALL SELECT P.MATERIAL, B.PARENT_MATERIAL FROM PARENTS P JOIN SC360_REF.ANALYTICS.DT_BOM_EXPLOSION B ON B.COMPONENT_MATERIAL = P.PARENT_MATERIAL) SELECT O.SALES_ORDER, O.SOLD_TO, O.MATERIAL_DESC AS PRODUCT, O.PLANT_NAME, O.ORDER_STATUS, O.NET_VALUE_USD FROM SC360_REF.ANALYTICS.DT_ORDER_FULFILLMENT O WHERE O.ACTUAL_SHIP_DATE IS NULL AND O.MATERIAL IN (SELECT PARENT_MATERIAL FROM PARENTS) ORDER BY O.NET_VALUE_USD DESC'),
    ALTERNATE_SUPPLIER_DECISION AS (
QUESTION 'For each component supplied by Festo AG, which alternate supplier can replace it at a quality bar of 90?'
VERIFIED_AT 1792540800
VERIFIED_BY '(source=ontology)'
ONBOARDING_QUESTION true
SQL 'WITH FESTO_PARTS AS (SELECT DISTINCT MATERIAL, MATERIAL_DESC FROM SC360_REF.ANALYTICS.DT_SUPPLIER_QUALITY WHERE SUPPLIER_NAME ILIKE ''%Festo AG%''), ALTS AS (SELECT MATERIAL, SUPPLIER_NAME, ROUND(AVG(QUALITY_SCORE), 1) AS AVG_QUALITY FROM SC360_REF.ANALYTICS.DT_SUPPLIER_QUALITY WHERE SUPPLIER_NAME NOT ILIKE ''%Festo AG%'' GROUP BY MATERIAL, SUPPLIER_NAME) SELECT F.MATERIAL_DESC AS COMPONENT, A.SUPPLIER_NAME AS ALTERNATE_SUPPLIER, A.AVG_QUALITY, CASE WHEN A.SUPPLIER_NAME IS NULL THEN ''Review'' WHEN A.AVG_QUALITY >= 90 THEN ''Candidate'' ELSE ''Blocked'' END AS OUTCOME FROM FESTO_PARTS F LEFT JOIN ALTS A ON A.MATERIAL = F.MATERIAL ORDER BY OUTCOME, COMPONENT'),
    OTIF_BY_LATE_CAUSE AS (
QUESTION 'What is driving late customer orders and what does it cost?'
VERIFIED_AT 1791504000
VERIFIED_BY '(source=ops_ext)'
ONBOARDING_QUESTION true
SQL 'SELECT LATE_CAUSE_LABEL, COUNT(*) AS ORDERS, SUM(LATE_COST_USD) AS LATE_COST_USD FROM SC360_REF.ANALYTICS.DT_ORDER_FULFILLMENT WHERE NOT ON_TIME GROUP BY LATE_CAUSE_LABEL ORDER BY LATE_COST_USD DESC'),
    TOOLS_AT_RISK AS (
QUESTION 'Which tools have the highest failure risk right now?'
VERIFIED_AT 1791504000
VERIFIED_BY '(source=ops_ext)'
ONBOARDING_QUESTION true
SQL 'SELECT EQUIPMENT_NAME, PLANT_NAME, FAILURE_PROB_48H, ANOMALY_FLAG FROM SC360_REF.ANALYTICS.DT_EQUIPMENT_HEALTH QUALIFY ROW_NUMBER() OVER (PARTITION BY EQUIPMENT_ID ORDER BY READING_DATE DESC) = 1 ORDER BY FAILURE_PROB_48H DESC LIMIT 10'),
    CRITICAL_COMPONENTS AS (
QUESTION 'Which components are below supplier lead time on cover?'
VERIFIED_AT 1791504000
VERIFIED_BY '(source=ops_ext)'
ONBOARDING_QUESTION false
SQL 'SELECT PLANT_NAME, COMPONENT_DESC, SUPPLIER_NAME, DAYS_OF_COVER, SUPPLIER_LEAD_TIME_DAYS FROM SC360_REF.ANALYTICS.DT_COMPONENT_COVER WHERE DAYS_OF_COVER < SUPPLIER_LEAD_TIME_DAYS ORDER BY DAYS_OF_COVER'),
    OPERATING_RATE_BY_PLANT AS (
QUESTION 'What is the operating rate and binding constraint by plant?'
VERIFIED_AT 1791504000
VERIFIED_BY '(source=ops_ext)'
ONBOARDING_QUESTION false
SQL 'SELECT PLANT_NAME, ROUND(100 * SUM(PRODUCED_UNITS) / SUM(NAMEPLATE_UNITS), 1) AS OPERATING_RATE_PCT, SUM(EQUIPMENT_LOSS_UNITS) AS EQUIPMENT_LOSS, SUM(MATERIAL_SHORTAGE_UNITS) AS COMPONENT_LOSS FROM SC360_REF.ANALYTICS.DT_OPERATING_RATE GROUP BY PLANT_NAME ORDER BY OPERATING_RATE_PCT'),
		MONTHLY_OEE_BY_PLANT AS ( 
QUESTION 'What is the monthly OEE trend by plant?' 
VERIFIED_AT 1774984280
VERIFIED_BY '(source=existing_sv)'
ONBOARDING_QUESTION false
SQL 'SELECT PLANT_NAME, PERIOD_DATE, OEE_PCT FROM SC360_REF.ANALYTICS.DT_MANUFACTURING_KPI ORDER BY PLANT_NAME, PERIOD_DATE'),
		PRODUCTION_YIELD_BY_PRODUCT AS ( 
QUESTION 'What is the production yield rate by product?' 
VERIFIED_AT 1774984280
VERIFIED_BY '(source=existing_sv)'
ONBOARDING_QUESTION false
SQL 'SELECT MATERIAL_DESC, ROUND(100.0 * SUM(YIELD_QTY) / NULLIF(SUM(PLANNED_QTY), 0), 1) AS YIELD_PCT FROM SC360_REF.ANALYTICS.DT_PRODUCTION_ORDER_360 GROUP BY MATERIAL_DESC ORDER BY YIELD_PCT DESC'),
		WORK_CENTER_BOTTLENECKS AS ( 
QUESTION 'Which work centers have the highest utilization and may be bottlenecks?' 
VERIFIED_AT 1774984280
VERIFIED_BY '(source=existing_sv)'
ONBOARDING_QUESTION false
SQL 'SELECT WORK_CENTER_DESC, PLANT_NAME, ROUND(AVG(UTILIZATION_PCT), 1) AS AVG_UTILIZATION FROM SC360_REF.ANALYTICS.DT_WORK_CENTER_UTILIZATION GROUP BY WORK_CENTER_DESC, PLANT_NAME HAVING AVG(UTILIZATION_PCT) > 85 ORDER BY AVG_UTILIZATION DESC'),
		ON_TIME_DELIVERY_RATE AS ( 
QUESTION 'What is the overall on-time delivery rate?' 
VERIFIED_AT 1774984280
VERIFIED_BY '(source=existing_sv)'
ONBOARDING_QUESTION false
SQL 'SELECT ROUND(100.0 * SUM(CASE WHEN ON_TIME_FLAG = ''Y'' THEN 1 ELSE 0 END) / COUNT(*), 1) AS OTD_PCT, COUNT(*) AS TOTAL_DELIVERIES FROM SC360_REF.ANALYTICS.DT_DELIVERY_PERFORMANCE'),
		INVENTORY_OBSOLESCENCE AS ( 
QUESTION 'What is the breakdown of inventory items and value by obsolete status?' 
VERIFIED_AT 1774984280
VERIFIED_BY '(source=existing_sv)'
ONBOARDING_QUESTION false
SQL 'SELECT OBSOLETE_FLAG, COUNT(*) AS ITEMS, SUM(STOCK_VALUE) AS TOTAL_VALUE FROM SC360_REF.ANALYTICS.DT_INVENTORY_OVERVIEW GROUP BY OBSOLETE_FLAG'),
		TOP_BOM_COST_COMPONENTS AS ( 
QUESTION 'What are the most expensive components across all BOMs?' 
VERIFIED_AT 1774984280
VERIFIED_BY '(source=existing_sv)'
ONBOARDING_QUESTION false
SQL 'SELECT COMPONENT_DESC, SUM(COMPONENT_COST) AS TOTAL_COST FROM SC360_REF.ANALYTICS.DT_BOM_EXPLOSION GROUP BY COMPONENT_DESC ORDER BY TOTAL_COST DESC LIMIT 10'),
		SUPPLIER_QUALITY_RANKING AS ( 
QUESTION 'How do suppliers rank by quality score?' 
VERIFIED_AT 1774984280
VERIFIED_BY '(source=existing_sv)'
ONBOARDING_QUESTION false
SQL 'SELECT SUPPLIER_NAME, ROUND(AVG(QUALITY_SCORE), 1) AS AVG_QUALITY, ROUND(AVG(DEFECT_RATE_PCT), 2) AS AVG_DEFECT_RATE, ROUND(AVG(ON_TIME_DELIVERY_PCT), 1) AS AVG_OTD FROM SC360_REF.ANALYTICS.DT_SUPPLIER_QUALITY GROUP BY SUPPLIER_NAME ORDER BY AVG_QUALITY DESC'),
		PROJECTS_OVER_BUDGET AS ( 
QUESTION 'Which projects are over budget?' 
VERIFIED_AT 1774984280
VERIFIED_BY '(source=existing_sv)'
ONBOARDING_QUESTION false
SQL 'SELECT DISTINCT PROJECT_NAME, PROJECT_STATUS, PLANNED_COST, ACTUAL_COST, BUDGET_VARIANCE_PCT, COMPLETION_PCT FROM SC360_REF.ANALYTICS.DT_PROJECT_STATUS WHERE BUDGET_VARIANCE_PCT > 0 ORDER BY BUDGET_VARIANCE_PCT DESC')
	);


-- ---------------------------------------------------------------------
-- From demo step 05
-- ---------------------------------------------------------------------
-- =====================================================================
-- Cortex Agent — SAP_SC360_ANALYST_AGENT
-- Account-level agent for Snowflake Intelligence. Uses the
-- cortex_analyst_text_to_sql tool over the SAP_SUPPLY_CHAIN_360 semantic view.
-- Prereqs: 04_semantic_view.sql + SNOWFLAKE.CORTEX_USER on the executing role.
-- =====================================================================

CREATE OR REPLACE AGENT SC360_REF.ANALYTICS.SAP_SC360_ANALYST_AGENT
WITH PROFILE='{"display_name":"SC360 Reference Analyst","color":"blue"}'
COMMENT='Cortex Agent for SAP Supply Chain 360 natural language analytics. Answers questions about manufacturing KPIs, production orders, inventory, delivery performance, supplier quality, BOM costs, and project status using the SAP_SUPPLY_CHAIN_360 semantic view.'
FROM SPECIFICATION $$
{
  "models": {
    "orchestration": "auto"
  },
  "orchestration": {
    "budget": {
      "seconds": 60,
      "tokens": 32000
    }
  },
  "instructions": {
    "response": "You are an SAP Supply Chain analytics expert. Answer questions about  manufacturing KPIs, production yield, inventory levels, delivery performance,  supplier quality, bill of materials costs, and project budget status. Provide  clear, concise answers with the key metric values highlighted. When trends are  relevant, describe direction (improving/declining). Always include the time  period when answering trend questions.\n",
    "orchestration": "For any question about OEE, cycle time, throughput, scrap rate,  or plant-level manufacturing KPIs, use the Analyst tool. For production order  yield, scrap, or cycle time by material, use the Analyst tool. For inventory  stock levels, values, or days-of-inventory, use the Analyst tool. For on-time  delivery rates or delay analysis, use the Analyst tool. For supplier quality  scores or defect rates, use the Analyst tool. For bill of materials component  costs, use the Analyst tool. For project budget variance or completion status,  use the Analyst tool. For customer order OTIF, late orders, late cause or late cost, use the Analyst tool (ORDER_FULFILLMENT). For operating rate, capacity loss tree or whether equipment or components is the binding constraint, use the Analyst tool (OPERATING_RATE). For tool failure risk, anomalies, outages or repair cost, use the Analyst tool (EQUIPMENT_HEALTH, EQUIPMENT_OUTAGE). For component shortages, days of cover or supplier lead time, use the Analyst tool (COMPONENT_COVER). When explaining a late order, trace cause -> units lost -> ship slip -> cost.\n",
    "sample_questions": [
      {
        "question": "What is the monthly OEE trend by plant?"
      },
      {
        "question": "What is the production yield rate by product?"
      },
      {
        "question": "Which work centers have the highest utilization and may be bottlenecks?"
      },
      {
        "question": "What is the overall on-time delivery rate?"
      },
      {
        "question": "What is the breakdown of inventory items and value by obsolete status?"
      },
      {
        "question": "What are the most expensive components across all BOMs?"
      },
      {
        "question": "How do suppliers rank by quality score?"
      },
      {
        "question": "Which projects are over budget?"
      },
      {
        "question": "What is driving late customer orders and what does it cost?"
      },
      {
        "question": "Which tools have the highest failure risk right now?"
      },
      {
        "question": "Which components are below supplier lead time on cover?"
      }
    ]
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "SAP_SC360_Analyst",
        "description": "Converts natural language questions into SQL queries against the  SAP Supply Chain 360 semantic view. Covers manufacturing KPIs (OEE, cycle  time, throughput, scrap), production orders, bill of materials, work center  utilization, inventory management, delivery performance, supplier quality,  project status, geographic supply chain flows, customer order fulfillment (OTIF, late cause and cost), operating-rate loss tree, equipment health and outages, and component days of cover.\n"
      }
    }
  ],
  "skills": [],
  "tool_resources": {
    "SAP_SC360_Analyst": {
      "semantic_view": "SC360_REF.ANALYTICS.SAP_SUPPLY_CHAIN_360",
      "execution_environment": {"type": "warehouse", "warehouse": "LAB_WH"}
    }
  }
}
$$;


-- Read access for the lab role, so it can compare its own build with the reference.
grant usage on database SC360_REF to role SC360_ENGINEER;
grant usage on all schemas in database SC360_REF to role SC360_ENGINEER;
grant select on all tables in database SC360_REF to role SC360_ENGINEER;
grant select on all dynamic tables in database SC360_REF to role SC360_ENGINEER;
grant select on all views in database SC360_REF to role SC360_ENGINEER;
grant select, references on semantic view SC360_REF.ANALYTICS.SAP_SUPPLY_CHAIN_360 to role SC360_ENGINEER;
grant usage on agent SC360_REF.ANALYTICS.SAP_SC360_ANALYST_AGENT to role SC360_ENGINEER;

select 'OK: reference stack built in SC360_REF' as status;
