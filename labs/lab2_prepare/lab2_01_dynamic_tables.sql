-- =====================================================================
-- SAP BDC Connect + Snowflake partner workshop
-- Lab 2 step 1: L2 Dynamic Tables in SC360_LAB.ANALYTICS
-- Generated file. All data is synthetic.
-- =====================================================================
-- Run as SC360_ENGINEER. Generated from the demo's sql/03 and sql/06: only the database
-- names are changed, so you build the same objects the demo runs on.

use role SC360_ENGINEER;
use warehouse LAB_WH;

-- Part 1 (demo sql/03): 9 Dynamic Tables over the SAP data products
-- =====================================================================
-- L2 (gold) — Analytics dynamic tables
-- Joined / enriched / aggregated analytics objects built on the raw L0
-- SAP BDC standard data products. Dynamic tables auto-refresh
-- (TARGET_LAG). Requires a warehouse named LAB_WH (or edit WAREHOUSE).
-- DT_SUPPLIER_QUALITY and DT_SUPPLY_CHAIN_GEO union L0 with the synthetic
-- SUPPLIER_EXT schema, so run 07a_supplier_ext_seed.sql first.
-- =====================================================================

create or replace schema SC360_LAB.ANALYTICS COMMENT='L2: Dynamic tables - analytics-ready joined/enriched data';

create or replace dynamic table SC360_LAB.ANALYTICS.DT_BOM_EXPLOSION(
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
create or replace dynamic table SC360_LAB.ANALYTICS.DT_DELIVERY_PERFORMANCE(
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
create or replace dynamic table SC360_LAB.ANALYTICS.DT_INVENTORY_OVERVIEW(
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
create or replace dynamic table SC360_LAB.ANALYTICS.DT_MANUFACTURING_KPI(
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
create or replace dynamic table SC360_LAB.ANALYTICS.DT_PRODUCTION_ORDER_360(
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
create or replace dynamic table SC360_LAB.ANALYTICS.DT_PROJECT_STATUS(
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
create or replace dynamic table SC360_LAB.ANALYTICS.DT_SUPPLIER_QUALITY(
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
create or replace dynamic table SC360_LAB.ANALYTICS.DT_SUPPLY_CHAIN_GEO(
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
create or replace dynamic table SC360_LAB.ANALYTICS.DT_WORK_CENTER_UTILIZATION(
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

-- Part 2 (demo sql/06): 6 Dynamic Tables over the non-SAP operations data
-- =====================================================================
-- L2 (gold) — Operations extension: fulfillment, operating rate,
-- equipment health, component cover and serial genealogy.
-- Source: SC360_EXT.OPS_EXT (demo enrichment keyed to SAP master
-- data — plants, work centers, materials, BOM, suppliers). Generated by
-- tools/gen_ops_ext.py. Values are representative, not customer data.
-- =====================================================================

-- Customer order lines with root cause and late cost.
create or replace dynamic table SC360_LAB.ANALYTICS.DT_ORDER_FULFILLMENT
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
create or replace dynamic table SC360_LAB.ANALYTICS.DT_OPERATING_RATE
  target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
  comment = 'Operating-rate loss tree per plant and month (units). Demo enrichment.'
as
SELECT r.PLANT, r.PLANT_NAME, r.PERIOD_DATE, r.NAMEPLATE_UNITS, r.PLANNED_DOWNTIME_UNITS, r.EQUIPMENT_LOSS_UNITS,
       r.MATERIAL_SHORTAGE_UNITS, r.PERFORMANCE_LOSS_UNITS, r.PRODUCED_UNITS, r.OPERATING_RATE_PCT,
       IFF(r.EQUIPMENT_LOSS_UNITS >= r.MATERIAL_SHORTAGE_UNITS, 'Equipment', 'Components') AS BINDING_CONSTRAINT
FROM SC360_EXT.OPS_EXT.A_OPERATING_RATE r;

-- Equipment daily health joined to work center; value at risk uses avg margin of systems built at the plant.
create or replace dynamic table SC360_LAB.ANALYTICS.DT_EQUIPMENT_HEALTH
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

create or replace dynamic table SC360_LAB.ANALYTICS.DT_EQUIPMENT_OUTAGE
  target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = LAB_WH
  comment = 'Outage events with repair cost. Demo enrichment.'
as
SELECT o.OUTAGE_ID, o.EQUIPMENT_ID, e.EQUIPMENT_NAME, o.WORK_CENTER, o.PLANT, p.PLANT_NAME, o.START_DATE,
       o.EVENT_TYPE, o.DOWNTIME_HRS, o.ROOT_CAUSE, o.REPAIR_COST_USD
FROM SC360_EXT.OPS_EXT.A_EQUIPMENT_OUTAGE o
JOIN SC360_EXT.OPS_EXT.A_EQUIPMENT e ON e.EQUIPMENT_ID = o.EQUIPMENT_ID
JOIN SC360_L0.PLANT.A_PLANT p ON p.PLANT = o.PLANT;

create or replace dynamic table SC360_LAB.ANALYTICS.DT_COMPONENT_COVER
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
create or replace dynamic table SC360_LAB.ANALYTICS.DT_SERIAL_GENEALOGY
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

show dynamic tables in schema SC360_LAB.ANALYTICS;
