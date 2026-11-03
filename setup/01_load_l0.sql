-- =====================================================================
-- SAP BDC Connect + Snowflake partner workshop
-- Setup 01: simulated SAP BDC data products (L0) and non-SAP sources
-- Generated file. All data is synthetic.
-- =====================================================================
-- Run as ACCOUNTADMIN after setup/00_connect_git.sql.
-- Creates:
--   SC360_L0   16 schemas, 21 tables, 398 rows. Stands in for the catalog-linked
--              databases that the SAP BDC Zerocopy connector mounts in a client account.
--   SC360_EXT  2 schemas, 14 tables, 7850 rows of non-SAP operational and supplier data.
--   SC360_LAB  empty database where you build L1, L2, the semantic view and the agent.
--   Role SC360_ENGINEER: read-only on SC360_L0 and SC360_EXT, owner of SC360_LAB.
--   Role SC360_DATA_PROVIDER: owns SC360_L0 and SC360_EXT; held by no user, so the
--              data cannot be changed (mirrors a read-only catalog-linked database).
--   Warehouse LAB_WH (XSMALL, auto-suspend 60 s).
-- Safe to re-run: every object is replaced. Re-running drops SC360_REF dependants,
-- so re-run setup/02 afterwards.

use role accountadmin;

create warehouse if not exists LAB_WH
  warehouse_size = XSMALL auto_suspend = 60 auto_resume = true initially_suspended = true;
use warehouse LAB_WH;

-- SC360_DATA_PROVIDER owns the simulated data products. No user holds it after setup,
-- so (like a real catalog-linked database) nobody can change L0 or EXT.
create role if not exists SC360_DATA_PROVIDER;
grant role SC360_DATA_PROVIDER to role ACCOUNTADMIN;

create role if not exists SC360_ENGINEER;
grant role SC360_ENGINEER to role SYSADMIN;
begin
  let me varchar := current_user();
  execute immediate 'grant role SC360_ENGINEER to user "' || :me || '"';
end;

create database if not exists SC360_ADMIN;
create schema if not exists SC360_ADMIN.GIT;
create or replace file format SC360_ADMIN.GIT.CSV_LOAD
  TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' NULL_IF = ('\\N') EMPTY_FIELD_AS_NULL = FALSE PARSE_HEADER = TRUE ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE;

-- Copy the data files out of the Git repository into an internal stage, then load.
create or replace stage SC360_ADMIN.GIT.DATA;
copy files into @SC360_ADMIN.GIT.DATA/ from @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/data/ pattern = '.*[.]csv';

create or replace database SC360_L0;
drop schema if exists SC360_L0.PUBLIC;
create schema SC360_L0.BILL_OF_MATERIAL;
create schema SC360_L0.BOM_GROUP;
create schema SC360_L0.CHANGE_MASTER;
create schema SC360_L0.CHANGE_RECORD;
create schema SC360_L0.DELIVERY_MGMT_CONFIG;
create schema SC360_L0.MANUFACTURING_CODES;
create schema SC360_L0.PLANT;
create schema SC360_L0.PRODUCTION_ORDER_CONFIRM;
create schema SC360_L0.PRODUCTION_VERSION;
create schema SC360_L0.PROJECT;
create schema SC360_L0.PROJECT_CONFIG_DATA;
create schema SC360_L0.PROJECT_NETWORK;
create schema SC360_L0.SALES_BOM;
create schema SC360_L0.SHIPPING_POINT;
create schema SC360_L0.STORAGE_LOCATION;
create schema SC360_L0.WORK_CENTER;

create table SC360_L0.BILL_OF_MATERIAL.A_BOM_ITEM (
  BOM_NUMBER VARCHAR(12),
  BOM_LEVEL NUMBER(2,0),
  PARENT_MATERIAL VARCHAR(18),
  PARENT_DESC VARCHAR(100),
  COMPONENT_MATERIAL VARCHAR(18),
  COMPONENT_DESC VARCHAR(100),
  COMPONENT_QTY NUMBER(10,2),
  COMPONENT_UOM VARCHAR(5),
  BASE_QTY NUMBER(10,2),
  ITEM_CATEGORY VARCHAR(10),
  COMPONENT_COST NUMBER(14,2)
);
copy into SC360_L0.BILL_OF_MATERIAL.A_BOM_ITEM
  from @SC360_ADMIN.GIT.DATA/l0/BILL_OF_MATERIAL/A_BOM_ITEM.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.BILL_OF_MATERIAL.A_BOM_ITEM set change_tracking = true;

create table SC360_L0.BOM_GROUP.A_BOM_GROUP (
  BOM_GROUP VARCHAR(10),
  BOM_GROUP_DESC VARCHAR(100),
  MATERIAL_TYPE VARCHAR(10)
);
copy into SC360_L0.BOM_GROUP.A_BOM_GROUP
  from @SC360_ADMIN.GIT.DATA/l0/BOM_GROUP/A_BOM_GROUP.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.BOM_GROUP.A_BOM_GROUP set change_tracking = true;

create table SC360_L0.CHANGE_MASTER.A_CHANGE_MASTER (
  CHANGE_NUMBER VARCHAR(12),
  CHANGE_DESC VARCHAR(200),
  REASON_FOR_CHANGE VARCHAR(200),
  STATUS VARCHAR(20),
  CREATED_DATE DATE,
  VALID_FROM DATE
);
copy into SC360_L0.CHANGE_MASTER.A_CHANGE_MASTER
  from @SC360_ADMIN.GIT.DATA/l0/CHANGE_MASTER/A_CHANGE_MASTER.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.CHANGE_MASTER.A_CHANGE_MASTER set change_tracking = true;

create table SC360_L0.CHANGE_RECORD.A_CHANGE_RECORD (
  CHANGE_NUMBER VARCHAR(12),
  OBJECT_TYPE VARCHAR(20),
  OBJECT_KEY VARCHAR(20),
  FIELD_NAME VARCHAR(50),
  OLD_VALUE VARCHAR(200),
  NEW_VALUE VARCHAR(200),
  CHANGED_DATE DATE
);
copy into SC360_L0.CHANGE_RECORD.A_CHANGE_RECORD
  from @SC360_ADMIN.GIT.DATA/l0/CHANGE_RECORD/A_CHANGE_RECORD.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.CHANGE_RECORD.A_CHANGE_RECORD set change_tracking = true;

create table SC360_L0.DELIVERY_MGMT_CONFIG.A_DELIVERY (
  DELIVERY_ID VARCHAR(12),
  SHIPPING_POINT VARCHAR(4),
  MATERIAL VARCHAR(18),
  MATERIAL_DESC VARCHAR(100),
  DELIVERY_QTY NUMBER(10,2),
  PLANNED_DELIVERY_DATE DATE,
  ACTUAL_DELIVERY_DATE DATE,
  ON_TIME_FLAG VARCHAR(1),
  DELAY_DAYS NUMBER(4,0),
  DELIVERY_MONTH DATE
);
copy into SC360_L0.DELIVERY_MGMT_CONFIG.A_DELIVERY
  from @SC360_ADMIN.GIT.DATA/l0/DELIVERY_MGMT_CONFIG/A_DELIVERY.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.DELIVERY_MGMT_CONFIG.A_DELIVERY set change_tracking = true;

create table SC360_L0.MANUFACTURING_CODES.A_MANUFACTURING_KPI (
  PLANT VARCHAR(4),
  PERIOD_DATE DATE,
  OEE_PCT NUMBER(5,1),
  CYCLE_TIME_AVG NUMBER(6,1),
  THROUGHPUT NUMBER(8,0),
  SCRAP_RATE_PCT NUMBER(5,2),
  ON_TIME_DELIVERY_PCT NUMBER(5,1),
  INVENTORY_TURNOVER NUMBER(5,1)
);
copy into SC360_L0.MANUFACTURING_CODES.A_MANUFACTURING_KPI
  from @SC360_ADMIN.GIT.DATA/l0/MANUFACTURING_CODES/A_MANUFACTURING_KPI.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.MANUFACTURING_CODES.A_MANUFACTURING_KPI set change_tracking = true;

create table SC360_L0.MANUFACTURING_CODES.A_MATERIAL_STOCK (
  MATERIAL VARCHAR(18),
  MATERIAL_DESC VARCHAR(100),
  PLANT VARCHAR(4),
  STORAGE_LOCATION VARCHAR(4),
  STOCK_QTY NUMBER(12,2),
  STOCK_VALUE NUMBER(14,2),
  DAYS_OF_INVENTORY NUMBER(6,0),
  TURNOVER_RATE NUMBER(6,2),
  LAST_MOVEMENT_DATE DATE,
  OBSOLETE_FLAG VARCHAR(1)
);
copy into SC360_L0.MANUFACTURING_CODES.A_MATERIAL_STOCK
  from @SC360_ADMIN.GIT.DATA/l0/MANUFACTURING_CODES/A_MATERIAL_STOCK.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.MANUFACTURING_CODES.A_MATERIAL_STOCK set change_tracking = true;

create table SC360_L0.MANUFACTURING_CODES.A_SUPPLIER_QUALITY (
  SUPPLIER VARCHAR(10),
  SUPPLIER_NAME VARCHAR(100),
  MATERIAL VARCHAR(18),
  MATERIAL_DESC VARCHAR(100),
  TOTAL_DELIVERED NUMBER(10,0),
  DEFECT_QTY NUMBER(10,0),
  DEFECT_RATE_PCT NUMBER(5,2),
  ON_TIME_DELIVERY_PCT NUMBER(5,1),
  QUALITY_SCORE NUMBER(5,1),
  PERIOD_DATE DATE
);
copy into SC360_L0.MANUFACTURING_CODES.A_SUPPLIER_QUALITY
  from @SC360_ADMIN.GIT.DATA/l0/MANUFACTURING_CODES/A_SUPPLIER_QUALITY.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.MANUFACTURING_CODES.A_SUPPLIER_QUALITY set change_tracking = true;

create table SC360_L0.MANUFACTURING_CODES.A_SUPPLY_CHAIN_FLOWS (
  FLOW_ID VARCHAR(10),
  SOURCE_NODE VARCHAR(10),
  TARGET_NODE VARCHAR(10),
  FLOW_TYPE VARCHAR(20),
  MATERIAL_CATEGORY VARCHAR(50),
  MONTHLY_VOLUME NUMBER(8,0),
  MONTHLY_VALUE NUMBER(14,2)
);
copy into SC360_L0.MANUFACTURING_CODES.A_SUPPLY_CHAIN_FLOWS
  from @SC360_ADMIN.GIT.DATA/l0/MANUFACTURING_CODES/A_SUPPLY_CHAIN_FLOWS.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.MANUFACTURING_CODES.A_SUPPLY_CHAIN_FLOWS set change_tracking = true;

create table SC360_L0.MANUFACTURING_CODES.A_SUPPLY_CHAIN_NODES (
  NODE_ID VARCHAR(10),
  NODE_NAME VARCHAR(100),
  NODE_TYPE VARCHAR(20),
  CITY VARCHAR(50),
  COUNTRY VARCHAR(50),
  LATITUDE NUMBER(9,6),
  LONGITUDE NUMBER(9,6),
  PLANT VARCHAR(4)
);
copy into SC360_L0.MANUFACTURING_CODES.A_SUPPLY_CHAIN_NODES
  from @SC360_ADMIN.GIT.DATA/l0/MANUFACTURING_CODES/A_SUPPLY_CHAIN_NODES.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.MANUFACTURING_CODES.A_SUPPLY_CHAIN_NODES set change_tracking = true;

create table SC360_L0.PLANT.A_PLANT (
  PLANT VARCHAR(4),
  PLANT_NAME VARCHAR(100),
  FACTORY_CALENDAR VARCHAR(10),
  COUNTRY_KEY VARCHAR(3),
  CITY VARCHAR(50),
  COMPANY_CODE VARCHAR(10),
  VALUATION_AREA VARCHAR(10),
  CREATED_DATE DATE
);
copy into SC360_L0.PLANT.A_PLANT
  from @SC360_ADMIN.GIT.DATA/l0/PLANT/A_PLANT.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.PLANT.A_PLANT set change_tracking = true;

create table SC360_L0.PRODUCTION_ORDER_CONFIRM.A_PROD_ORD_CONFIRMATION (
  PRODUCTION_ORDER VARCHAR(12),
  ORDER_TYPE VARCHAR(4),
  PLANT VARCHAR(4),
  MATERIAL VARCHAR(18),
  MATERIAL_DESC VARCHAR(100),
  PLANNED_QTY NUMBER(12,2),
  CONFIRMED_QTY NUMBER(12,2),
  SCRAP_QTY NUMBER(12,2),
  YIELD_QTY NUMBER(12,2),
  WORK_CENTER VARCHAR(10),
  CYCLE_TIME_DAYS NUMBER(6,1),
  CREATED_DATE DATE,
  BASIC_START_DATE DATE,
  BASIC_FINISH_DATE DATE,
  ORDER_STATUS VARCHAR(20)
);
copy into SC360_L0.PRODUCTION_ORDER_CONFIRM.A_PROD_ORD_CONFIRMATION
  from @SC360_ADMIN.GIT.DATA/l0/PRODUCTION_ORDER_CONFIRM/A_PROD_ORD_CONFIRMATION.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.PRODUCTION_ORDER_CONFIRM.A_PROD_ORD_CONFIRMATION set change_tracking = true;

create table SC360_L0.PRODUCTION_VERSION.A_PRODUCTION_VERSION (
  MATERIAL VARCHAR(18),
  PLANT VARCHAR(4),
  PRODUCTION_VERSION VARCHAR(10),
  VERSION_TEXT VARCHAR(200),
  BOM_NUMBER VARCHAR(12),
  ROUTING_NUMBER VARCHAR(12),
  VALID_FROM DATE,
  VALID_TO DATE,
  LOT_SIZE_MIN NUMBER(10,2),
  LOT_SIZE_MAX NUMBER(10,2)
);
copy into SC360_L0.PRODUCTION_VERSION.A_PRODUCTION_VERSION
  from @SC360_ADMIN.GIT.DATA/l0/PRODUCTION_VERSION/A_PRODUCTION_VERSION.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.PRODUCTION_VERSION.A_PRODUCTION_VERSION set change_tracking = true;

create table SC360_L0.PROJECT.A_PROJECT (
  PROJECT_ID VARCHAR(20),
  PROJECT_NAME VARCHAR(200),
  PLANT VARCHAR(4),
  PROJECT_STATUS VARCHAR(20),
  PLANNED_COST NUMBER(14,2),
  ACTUAL_COST NUMBER(14,2),
  BUDGET_VARIANCE_PCT NUMBER(6,2),
  START_DATE DATE,
  END_DATE DATE,
  COMPLETION_PCT NUMBER(5,1)
);
copy into SC360_L0.PROJECT.A_PROJECT
  from @SC360_ADMIN.GIT.DATA/l0/PROJECT/A_PROJECT.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.PROJECT.A_PROJECT set change_tracking = true;

create table SC360_L0.PROJECT_CONFIG_DATA.A_PROJECT_CONFIG (
  PROJECT_ID VARCHAR(20),
  CONFIG_KEY VARCHAR(50),
  CONFIG_VALUE VARCHAR(200),
  DESCRIPTION VARCHAR(200)
);
copy into SC360_L0.PROJECT_CONFIG_DATA.A_PROJECT_CONFIG
  from @SC360_ADMIN.GIT.DATA/l0/PROJECT_CONFIG_DATA/A_PROJECT_CONFIG.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.PROJECT_CONFIG_DATA.A_PROJECT_CONFIG set change_tracking = true;

create table SC360_L0.PROJECT_NETWORK.A_PROJECT_WBS (
  PROJECT_ID VARCHAR(20),
  WBS_ELEMENT VARCHAR(20),
  WBS_DESCRIPTION VARCHAR(200),
  PARENT_WBS VARCHAR(20),
  LEVEL NUMBER(2,0)
);
copy into SC360_L0.PROJECT_NETWORK.A_PROJECT_WBS
  from @SC360_ADMIN.GIT.DATA/l0/PROJECT_NETWORK/A_PROJECT_WBS.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.PROJECT_NETWORK.A_PROJECT_WBS set change_tracking = true;

create table SC360_L0.SALES_BOM.A_SALES_BOM (
  SALES_BOM_NUMBER VARCHAR(12),
  MATERIAL VARCHAR(18),
  MATERIAL_DESC VARCHAR(100),
  COMPONENT_MATERIAL VARCHAR(18),
  COMPONENT_DESC VARCHAR(100),
  COMPONENT_QTY NUMBER(10,2),
  ITEM_CATEGORY VARCHAR(10)
);
copy into SC360_L0.SALES_BOM.A_SALES_BOM
  from @SC360_ADMIN.GIT.DATA/l0/SALES_BOM/A_SALES_BOM.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.SALES_BOM.A_SALES_BOM set change_tracking = true;

create table SC360_L0.SHIPPING_POINT.A_SHIPPING_POINT (
  SHIPPING_POINT VARCHAR(4),
  SHIPPING_POINT_DESC VARCHAR(100),
  FACTORY_CALENDAR VARCHAR(10),
  COUNTRY VARCHAR(3),
  DEPARTURE_ZONE VARCHAR(10),
  PLANT VARCHAR(4)
);
copy into SC360_L0.SHIPPING_POINT.A_SHIPPING_POINT
  from @SC360_ADMIN.GIT.DATA/l0/SHIPPING_POINT/A_SHIPPING_POINT.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.SHIPPING_POINT.A_SHIPPING_POINT set change_tracking = true;

create table SC360_L0.STORAGE_LOCATION.A_STORAGE_LOCATION (
  PLANT VARCHAR(4),
  STORAGE_LOCATION VARCHAR(4),
  STORAGE_LOC_DESC VARCHAR(100),
  CREATED_DATE DATE
);
copy into SC360_L0.STORAGE_LOCATION.A_STORAGE_LOCATION
  from @SC360_ADMIN.GIT.DATA/l0/STORAGE_LOCATION/A_STORAGE_LOCATION.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.STORAGE_LOCATION.A_STORAGE_LOCATION set change_tracking = true;

create table SC360_L0.WORK_CENTER.A_WORK_CENTER (
  WORK_CENTER VARCHAR(10),
  WORK_CENTER_DESC VARCHAR(100),
  PLANT VARCHAR(4),
  WORK_CENTER_CATEGORY VARCHAR(4),
  USAGE VARCHAR(3),
  RESPONSIBLE_COST_CENTER VARCHAR(10),
  AVAILABLE_CAPACITY_HRS NUMBER(10,2),
  CREATED_DATE DATE
);
copy into SC360_L0.WORK_CENTER.A_WORK_CENTER
  from @SC360_ADMIN.GIT.DATA/l0/WORK_CENTER/A_WORK_CENTER.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.WORK_CENTER.A_WORK_CENTER set change_tracking = true;

create table SC360_L0.WORK_CENTER.A_WORK_CENTER_CAPACITY (
  WORK_CENTER VARCHAR(10),
  PLANT VARCHAR(4),
  PERIOD_DATE DATE,
  AVAILABLE_CAPACITY_HRS NUMBER(10,2),
  USED_CAPACITY_HRS NUMBER(10,2)
);
copy into SC360_L0.WORK_CENTER.A_WORK_CENTER_CAPACITY
  from @SC360_ADMIN.GIT.DATA/l0/WORK_CENTER/A_WORK_CENTER_CAPACITY.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_L0.WORK_CENTER.A_WORK_CENTER_CAPACITY set change_tracking = true;

create or replace database SC360_EXT;
drop schema if exists SC360_EXT.PUBLIC;
create schema SC360_EXT.OPS_EXT;
create schema SC360_EXT.SUPPLIER_EXT;

create table SC360_EXT.OPS_EXT.A_COMPONENT_COVER (
  PLANT VARCHAR,
  COMPONENT_MATERIAL VARCHAR,
  COMPONENT_DESC VARCHAR,
  SUPPLIER VARCHAR,
  ON_HAND_QTY NUMBER(38,0),
  DAILY_USAGE FLOAT,
  DAYS_OF_COVER FLOAT,
  SUPPLIER_LEAD_TIME_DAYS NUMBER(38,0),
  OPEN_PO_QTY NUMBER(38,0),
  STATUS VARCHAR
);
copy into SC360_EXT.OPS_EXT.A_COMPONENT_COVER
  from @SC360_ADMIN.GIT.DATA/ext/OPS_EXT/A_COMPONENT_COVER.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_EXT.OPS_EXT.A_COMPONENT_COVER set change_tracking = true;

create table SC360_EXT.OPS_EXT.A_COMPONENT_LOT (
  LOT_ID VARCHAR,
  COMPONENT_MATERIAL VARCHAR,
  COMPONENT_DESC VARCHAR,
  SUPPLIER VARCHAR,
  SUPPLIER_NAME VARCHAR,
  SUPPLIER_SOURCE VARCHAR,
  RECEIVED_DATE DATE,
  QTY NUMBER(38,0),
  UNIT_COST FLOAT,
  INSPECTION_RESULT VARCHAR,
  DEVIATION_NOTE VARCHAR
);
copy into SC360_EXT.OPS_EXT.A_COMPONENT_LOT
  from @SC360_ADMIN.GIT.DATA/ext/OPS_EXT/A_COMPONENT_LOT.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_EXT.OPS_EXT.A_COMPONENT_LOT set change_tracking = true;

create table SC360_EXT.OPS_EXT.A_EQUIPMENT (
  EQUIPMENT_ID VARCHAR,
  EQUIPMENT_NAME VARCHAR,
  EQUIPMENT_TYPE VARCHAR,
  WORK_CENTER VARCHAR,
  PLANT VARCHAR,
  CRITICALITY VARCHAR,
  INSTALL_YEAR NUMBER(38,0),
  REPAIR_COST_PER_HR NUMBER(38,0)
);
copy into SC360_EXT.OPS_EXT.A_EQUIPMENT
  from @SC360_ADMIN.GIT.DATA/ext/OPS_EXT/A_EQUIPMENT.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_EXT.OPS_EXT.A_EQUIPMENT set change_tracking = true;

create table SC360_EXT.OPS_EXT.A_EQUIPMENT_HEALTH_DAILY (
  EQUIPMENT_ID VARCHAR,
  READING_DATE DATE,
  VIBRATION_MM_S FLOAT,
  TEMPERATURE_C FLOAT,
  FAILURE_PROB_48H FLOAT,
  ANOMALY_FLAG BOOLEAN
);
copy into SC360_EXT.OPS_EXT.A_EQUIPMENT_HEALTH_DAILY
  from @SC360_ADMIN.GIT.DATA/ext/OPS_EXT/A_EQUIPMENT_HEALTH_DAILY.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_EXT.OPS_EXT.A_EQUIPMENT_HEALTH_DAILY set change_tracking = true;

create table SC360_EXT.OPS_EXT.A_EQUIPMENT_OUTAGE (
  EQUIPMENT_ID VARCHAR,
  PLANT VARCHAR,
  WORK_CENTER VARCHAR,
  START_DATE DATE,
  DOWNTIME_HRS FLOAT,
  EVENT_TYPE VARCHAR,
  ROOT_CAUSE VARCHAR,
  OUTAGE_ID VARCHAR,
  REPAIR_COST_USD FLOAT
);
copy into SC360_EXT.OPS_EXT.A_EQUIPMENT_OUTAGE
  from @SC360_ADMIN.GIT.DATA/ext/OPS_EXT/A_EQUIPMENT_OUTAGE.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_EXT.OPS_EXT.A_EQUIPMENT_OUTAGE set change_tracking = true;

create table SC360_EXT.OPS_EXT.A_FINAL_TEST (
  SERIAL_NO VARCHAR,
  MATERIAL VARCHAR,
  PLANT VARCHAR,
  TEST_DATE DATE,
  RESULT VARCHAR,
  DEFECT_CODE VARCHAR,
  REWORK_HRS FLOAT,
  SENSITIVITY_NM FLOAT
);
copy into SC360_EXT.OPS_EXT.A_FINAL_TEST
  from @SC360_ADMIN.GIT.DATA/ext/OPS_EXT/A_FINAL_TEST.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_EXT.OPS_EXT.A_FINAL_TEST set change_tracking = true;

create table SC360_EXT.OPS_EXT.A_OPERATING_RATE (
  PLANT VARCHAR,
  PLANT_NAME VARCHAR,
  PERIOD_DATE DATE,
  NAMEPLATE_UNITS NUMBER(38,0),
  PLANNED_DOWNTIME_UNITS FLOAT,
  EQUIPMENT_LOSS_UNITS FLOAT,
  MATERIAL_SHORTAGE_UNITS FLOAT,
  PERFORMANCE_LOSS_UNITS FLOAT,
  PRODUCED_UNITS FLOAT,
  OPERATING_RATE_PCT FLOAT
);
copy into SC360_EXT.OPS_EXT.A_OPERATING_RATE
  from @SC360_ADMIN.GIT.DATA/ext/OPS_EXT/A_OPERATING_RATE.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_EXT.OPS_EXT.A_OPERATING_RATE set change_tracking = true;

create table SC360_EXT.OPS_EXT.A_SALES_ORDER_ITEM (
  SALES_ORDER VARCHAR,
  ITEM NUMBER(38,0),
  SOLD_TO VARCHAR,
  MATERIAL VARCHAR,
  MATERIAL_DESC VARCHAR,
  PLANT VARCHAR,
  SHIPPING_POINT VARCHAR,
  ORDER_QTY NUMBER(38,0),
  NET_VALUE_USD FLOAT,
  REQUESTED_SHIP_DATE DATE,
  ACTUAL_SHIP_DATE DATE,
  ON_TIME BOOLEAN,
  IN_FULL BOOLEAN,
  DELAY_DAYS NUMBER(38,0),
  LATE_CAUSE VARCHAR,
  PENALTY_USD FLOAT,
  EXPEDITE_USD NUMBER(38,0),
  LATE_COST_USD FLOAT,
  ORDER_STATUS VARCHAR,
  MARGIN_PER_UNIT_USD FLOAT
);
copy into SC360_EXT.OPS_EXT.A_SALES_ORDER_ITEM
  from @SC360_ADMIN.GIT.DATA/ext/OPS_EXT/A_SALES_ORDER_ITEM.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_EXT.OPS_EXT.A_SALES_ORDER_ITEM set change_tracking = true;

create table SC360_EXT.OPS_EXT.A_SERIAL_GENEALOGY (
  SERIAL_NO VARCHAR,
  MATERIAL VARCHAR,
  PLANT VARCHAR,
  SALES_ORDER VARCHAR,
  COMPONENT_MATERIAL VARCHAR,
  LOT_ID VARCHAR
);
copy into SC360_EXT.OPS_EXT.A_SERIAL_GENEALOGY
  from @SC360_ADMIN.GIT.DATA/ext/OPS_EXT/A_SERIAL_GENEALOGY.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_EXT.OPS_EXT.A_SERIAL_GENEALOGY set change_tracking = true;

create table SC360_EXT.SUPPLIER_EXT.A_SUPPLIER (
  SUPPLIER VARCHAR,
  SUPPLIER_NAME VARCHAR,
  CITY VARCHAR,
  COUNTRY VARCHAR,
  LATITUDE FLOAT,
  LONGITUDE FLOAT,
  SUPPLIER_CATEGORY VARCHAR,
  QUALITY_BASE FLOAT,
  OTD_BASE FLOAT
);
copy into SC360_EXT.SUPPLIER_EXT.A_SUPPLIER
  from @SC360_ADMIN.GIT.DATA/ext/SUPPLIER_EXT/A_SUPPLIER.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_EXT.SUPPLIER_EXT.A_SUPPLIER set change_tracking = true;

create table SC360_EXT.SUPPLIER_EXT.A_SUPPLIER_QUALITY (
  SUPPLIER VARCHAR,
  SUPPLIER_NAME VARCHAR,
  MATERIAL VARCHAR,
  MATERIAL_DESC VARCHAR(100),
  TOTAL_DELIVERED NUMBER(38,0),
  DEFECT_QTY NUMBER(38,0),
  DEFECT_RATE_PCT FLOAT,
  ON_TIME_DELIVERY_PCT FLOAT,
  QUALITY_SCORE FLOAT,
  PERIOD_DATE DATE
);
copy into SC360_EXT.SUPPLIER_EXT.A_SUPPLIER_QUALITY
  from @SC360_ADMIN.GIT.DATA/ext/SUPPLIER_EXT/A_SUPPLIER_QUALITY.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_EXT.SUPPLIER_EXT.A_SUPPLIER_QUALITY set change_tracking = true;

create table SC360_EXT.SUPPLIER_EXT.A_SUPPLIER_SOURCING (
  COMPONENT_MATERIAL VARCHAR,
  SUPPLIER VARCHAR,
  SOURCE_RANK NUMBER(38,0),
  SUPPLY_SHARE FLOAT,
  SUPPLIER_SOURCE VARCHAR
);
copy into SC360_EXT.SUPPLIER_EXT.A_SUPPLIER_SOURCING
  from @SC360_ADMIN.GIT.DATA/ext/SUPPLIER_EXT/A_SUPPLIER_SOURCING.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_EXT.SUPPLIER_EXT.A_SUPPLIER_SOURCING set change_tracking = true;

create table SC360_EXT.SUPPLIER_EXT.A_SUPPLY_CHAIN_FLOWS (
  FLOW_ID VARCHAR,
  FLOW_TYPE VARCHAR(7),
  MATERIAL_CATEGORY VARCHAR,
  MONTHLY_VOLUME NUMBER(38,0),
  MONTHLY_VALUE FLOAT,
  SOURCE_NODE VARCHAR,
  TARGET_NODE VARCHAR(8)
);
copy into SC360_EXT.SUPPLIER_EXT.A_SUPPLY_CHAIN_FLOWS
  from @SC360_ADMIN.GIT.DATA/ext/SUPPLIER_EXT/A_SUPPLY_CHAIN_FLOWS.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_EXT.SUPPLIER_EXT.A_SUPPLY_CHAIN_FLOWS set change_tracking = true;

create table SC360_EXT.SUPPLIER_EXT.A_SUPPLY_CHAIN_NODES (
  NODE_ID VARCHAR,
  NODE_NAME VARCHAR,
  NODE_TYPE VARCHAR(8),
  CITY VARCHAR,
  COUNTRY VARCHAR,
  LATITUDE FLOAT,
  LONGITUDE FLOAT,
  PLANT VARCHAR
);
copy into SC360_EXT.SUPPLIER_EXT.A_SUPPLY_CHAIN_NODES
  from @SC360_ADMIN.GIT.DATA/ext/SUPPLIER_EXT/A_SUPPLY_CHAIN_NODES.csv
  file_format = (format_name = SC360_ADMIN.GIT.CSV_LOAD)
  match_by_column_name = case_insensitive on_error = abort_statement;
alter table SC360_EXT.SUPPLIER_EXT.A_SUPPLY_CHAIN_NODES set change_tracking = true;

-- Simulated CSN semantic views. On a real catalog-linked database, SAP BDC generates
-- one read-only semantic view per data product in the SNOWFLAKE$ schema from the CSN
-- metadata. That schema name is reserved, so the lab uses SC360_L0.CSN instead.
-- Like the real ones: labels on every column, primary keys, 0 relationships.
create schema SC360_L0.CSN comment = 'Simulated SNOWFLAKE$ schema: CSN-generated semantic views';

create semantic view SC360_L0.CSN.BILL_OF_MATERIAL
  tables (
    BOM_ITEM as SC360_L0.BILL_OF_MATERIAL.A_BOM_ITEM
      comment = 'BOM Item'
  )
  dimensions (
    BOM_ITEM.BOM_NUMBER as BOM_NUMBER comment = 'BOM Number',
    BOM_ITEM.BOM_LEVEL as BOM_LEVEL comment = 'BOM Level',
    BOM_ITEM.PARENT_MATERIAL as PARENT_MATERIAL comment = 'Parent Material',
    BOM_ITEM.PARENT_DESC as PARENT_DESC comment = 'Parent Desc',
    BOM_ITEM.COMPONENT_MATERIAL as COMPONENT_MATERIAL comment = 'Component Material',
    BOM_ITEM.COMPONENT_DESC as COMPONENT_DESC comment = 'Component Desc',
    BOM_ITEM.COMPONENT_QTY as COMPONENT_QTY comment = 'Component Qty',
    BOM_ITEM.COMPONENT_UOM as COMPONENT_UOM comment = 'Component UOM',
    BOM_ITEM.BASE_QTY as BASE_QTY comment = 'Base Qty',
    BOM_ITEM.ITEM_CATEGORY as ITEM_CATEGORY comment = 'Item Category',
    BOM_ITEM.COMPONENT_COST as COMPONENT_COST comment = 'Component Cost'
  )
  comment = 'Simulated CSN semantic view for data product Bill Of Material';

create semantic view SC360_L0.CSN.BOM_GROUP
  tables (
    BOM_GROUP as SC360_L0.BOM_GROUP.A_BOM_GROUP primary key (BOM_GROUP)
      comment = 'BOM Group'
  )
  dimensions (
    BOM_GROUP.BOM_GROUP as BOM_GROUP comment = 'BOM Group',
    BOM_GROUP.BOM_GROUP_DESC as BOM_GROUP_DESC comment = 'BOM Group Desc',
    BOM_GROUP.MATERIAL_TYPE as MATERIAL_TYPE comment = 'Material Type'
  )
  comment = 'Simulated CSN semantic view for data product BOM Group';

create semantic view SC360_L0.CSN.CHANGE_MASTER
  tables (
    CHANGE_MASTER as SC360_L0.CHANGE_MASTER.A_CHANGE_MASTER primary key (CHANGE_NUMBER)
      comment = 'Change Master'
  )
  dimensions (
    CHANGE_MASTER.CHANGE_NUMBER as CHANGE_NUMBER comment = 'Change Number',
    CHANGE_MASTER.CHANGE_DESC as CHANGE_DESC comment = 'Change Desc',
    CHANGE_MASTER.REASON_FOR_CHANGE as REASON_FOR_CHANGE comment = 'Reason For Change',
    CHANGE_MASTER.STATUS as STATUS comment = 'Status',
    CHANGE_MASTER.CREATED_DATE as CREATED_DATE comment = 'Created Date',
    CHANGE_MASTER.VALID_FROM as VALID_FROM comment = 'Valid From'
  )
  comment = 'Simulated CSN semantic view for data product Change Master';

create semantic view SC360_L0.CSN.CHANGE_RECORD
  tables (
    CHANGE_RECORD as SC360_L0.CHANGE_RECORD.A_CHANGE_RECORD
      comment = 'Change Record'
  )
  dimensions (
    CHANGE_RECORD.CHANGE_NUMBER as CHANGE_NUMBER comment = 'Change Number',
    CHANGE_RECORD.OBJECT_TYPE as OBJECT_TYPE comment = 'Object Type',
    CHANGE_RECORD.OBJECT_KEY as OBJECT_KEY comment = 'Object Key',
    CHANGE_RECORD.FIELD_NAME as FIELD_NAME comment = 'Field Name',
    CHANGE_RECORD.OLD_VALUE as OLD_VALUE comment = 'Old Value',
    CHANGE_RECORD.NEW_VALUE as NEW_VALUE comment = 'New Value',
    CHANGE_RECORD.CHANGED_DATE as CHANGED_DATE comment = 'Changed Date'
  )
  comment = 'Simulated CSN semantic view for data product Change Record';

create semantic view SC360_L0.CSN.DELIVERY_MGMT_CONFIG
  tables (
    DELIVERY as SC360_L0.DELIVERY_MGMT_CONFIG.A_DELIVERY primary key (DELIVERY_ID)
      comment = 'Delivery'
  )
  dimensions (
    DELIVERY.DELIVERY_ID as DELIVERY_ID comment = 'Delivery ID',
    DELIVERY.SHIPPING_POINT as SHIPPING_POINT comment = 'Shipping Point',
    DELIVERY.MATERIAL as MATERIAL comment = 'Material',
    DELIVERY.MATERIAL_DESC as MATERIAL_DESC comment = 'Material Desc',
    DELIVERY.DELIVERY_QTY as DELIVERY_QTY comment = 'Delivery Qty',
    DELIVERY.PLANNED_DELIVERY_DATE as PLANNED_DELIVERY_DATE comment = 'Planned Delivery Date',
    DELIVERY.ACTUAL_DELIVERY_DATE as ACTUAL_DELIVERY_DATE comment = 'Actual Delivery Date',
    DELIVERY.ON_TIME_FLAG as ON_TIME_FLAG comment = 'On Time Flag',
    DELIVERY.DELAY_DAYS as DELAY_DAYS comment = 'Delay Days',
    DELIVERY.DELIVERY_MONTH as DELIVERY_MONTH comment = 'Delivery Month'
  )
  comment = 'Simulated CSN semantic view for data product Delivery Mgmt Config';

create semantic view SC360_L0.CSN.MANUFACTURING_CODES
  tables (
    MANUFACTURING_KPI as SC360_L0.MANUFACTURING_CODES.A_MANUFACTURING_KPI
      comment = 'Manufacturing Kpi',
    MATERIAL_STOCK as SC360_L0.MANUFACTURING_CODES.A_MATERIAL_STOCK primary key (MATERIAL)
      comment = 'Material Stock',
    SUPPLIER_QUALITY as SC360_L0.MANUFACTURING_CODES.A_SUPPLIER_QUALITY
      comment = 'Supplier Quality',
    SUPPLY_CHAIN_FLOWS as SC360_L0.MANUFACTURING_CODES.A_SUPPLY_CHAIN_FLOWS primary key (FLOW_ID)
      comment = 'Supply Chain Flows',
    SUPPLY_CHAIN_NODES as SC360_L0.MANUFACTURING_CODES.A_SUPPLY_CHAIN_NODES primary key (NODE_ID)
      comment = 'Supply Chain Nodes'
  )
  dimensions (
    MANUFACTURING_KPI.MANUFACTURING_KPI_PLANT as PLANT comment = 'Plant',
    MANUFACTURING_KPI.MANUFACTURING_KPI_PERIOD_DATE as PERIOD_DATE comment = 'Period Date',
    MANUFACTURING_KPI.OEE_PCT as OEE_PCT comment = 'OEE PCT',
    MANUFACTURING_KPI.CYCLE_TIME_AVG as CYCLE_TIME_AVG comment = 'Cycle Time Avg',
    MANUFACTURING_KPI.THROUGHPUT as THROUGHPUT comment = 'Throughput',
    MANUFACTURING_KPI.SCRAP_RATE_PCT as SCRAP_RATE_PCT comment = 'Scrap Rate PCT',
    MANUFACTURING_KPI.MANUFACTURING_KPI_ON_TIME_DELIVERY_PCT as ON_TIME_DELIVERY_PCT comment = 'On Time Delivery PCT',
    MANUFACTURING_KPI.INVENTORY_TURNOVER as INVENTORY_TURNOVER comment = 'Inventory Turnover',
    MATERIAL_STOCK.MATERIAL_STOCK_MATERIAL as MATERIAL comment = 'Material',
    MATERIAL_STOCK.MATERIAL_STOCK_MATERIAL_DESC as MATERIAL_DESC comment = 'Material Desc',
    MATERIAL_STOCK.MATERIAL_STOCK_PLANT as PLANT comment = 'Plant',
    MATERIAL_STOCK.STORAGE_LOCATION as STORAGE_LOCATION comment = 'Storage Location',
    MATERIAL_STOCK.STOCK_QTY as STOCK_QTY comment = 'Stock Qty',
    MATERIAL_STOCK.STOCK_VALUE as STOCK_VALUE comment = 'Stock Value',
    MATERIAL_STOCK.DAYS_OF_INVENTORY as DAYS_OF_INVENTORY comment = 'Days Of Inventory',
    MATERIAL_STOCK.TURNOVER_RATE as TURNOVER_RATE comment = 'Turnover Rate',
    MATERIAL_STOCK.LAST_MOVEMENT_DATE as LAST_MOVEMENT_DATE comment = 'Last Movement Date',
    MATERIAL_STOCK.OBSOLETE_FLAG as OBSOLETE_FLAG comment = 'Obsolete Flag',
    SUPPLIER_QUALITY.SUPPLIER as SUPPLIER comment = 'Supplier',
    SUPPLIER_QUALITY.SUPPLIER_NAME as SUPPLIER_NAME comment = 'Supplier Name',
    SUPPLIER_QUALITY.SUPPLIER_QUALITY_MATERIAL as MATERIAL comment = 'Material',
    SUPPLIER_QUALITY.SUPPLIER_QUALITY_MATERIAL_DESC as MATERIAL_DESC comment = 'Material Desc',
    SUPPLIER_QUALITY.TOTAL_DELIVERED as TOTAL_DELIVERED comment = 'Total Delivered',
    SUPPLIER_QUALITY.DEFECT_QTY as DEFECT_QTY comment = 'Defect Qty',
    SUPPLIER_QUALITY.DEFECT_RATE_PCT as DEFECT_RATE_PCT comment = 'Defect Rate PCT',
    SUPPLIER_QUALITY.SUPPLIER_QUALITY_ON_TIME_DELIVERY_PCT as ON_TIME_DELIVERY_PCT comment = 'On Time Delivery PCT',
    SUPPLIER_QUALITY.QUALITY_SCORE as QUALITY_SCORE comment = 'Quality Score',
    SUPPLIER_QUALITY.SUPPLIER_QUALITY_PERIOD_DATE as PERIOD_DATE comment = 'Period Date',
    SUPPLY_CHAIN_FLOWS.FLOW_ID as FLOW_ID comment = 'Flow ID',
    SUPPLY_CHAIN_FLOWS.SOURCE_NODE as SOURCE_NODE comment = 'Source Node',
    SUPPLY_CHAIN_FLOWS.TARGET_NODE as TARGET_NODE comment = 'Target Node',
    SUPPLY_CHAIN_FLOWS.FLOW_TYPE as FLOW_TYPE comment = 'Flow Type',
    SUPPLY_CHAIN_FLOWS.MATERIAL_CATEGORY as MATERIAL_CATEGORY comment = 'Material Category',
    SUPPLY_CHAIN_FLOWS.MONTHLY_VOLUME as MONTHLY_VOLUME comment = 'Monthly Volume',
    SUPPLY_CHAIN_FLOWS.MONTHLY_VALUE as MONTHLY_VALUE comment = 'Monthly Value',
    SUPPLY_CHAIN_NODES.NODE_ID as NODE_ID comment = 'Node ID',
    SUPPLY_CHAIN_NODES.NODE_NAME as NODE_NAME comment = 'Node Name',
    SUPPLY_CHAIN_NODES.NODE_TYPE as NODE_TYPE comment = 'Node Type',
    SUPPLY_CHAIN_NODES.CITY as CITY comment = 'City',
    SUPPLY_CHAIN_NODES.COUNTRY as COUNTRY comment = 'Country',
    SUPPLY_CHAIN_NODES.LATITUDE as LATITUDE comment = 'Latitude',
    SUPPLY_CHAIN_NODES.LONGITUDE as LONGITUDE comment = 'Longitude',
    SUPPLY_CHAIN_NODES.SUPPLY_CHAIN_NODES_PLANT as PLANT comment = 'Plant'
  )
  comment = 'Simulated CSN semantic view for data product Manufacturing Codes';

create semantic view SC360_L0.CSN.PLANT
  tables (
    PLANT as SC360_L0.PLANT.A_PLANT primary key (PLANT)
      comment = 'Plant'
  )
  dimensions (
    PLANT.PLANT as PLANT comment = 'Plant',
    PLANT.PLANT_NAME as PLANT_NAME comment = 'Plant Name',
    PLANT.FACTORY_CALENDAR as FACTORY_CALENDAR comment = 'Factory Calendar',
    PLANT.COUNTRY_KEY as COUNTRY_KEY comment = 'Country Key',
    PLANT.CITY as CITY comment = 'City',
    PLANT.COMPANY_CODE as COMPANY_CODE comment = 'Company Code',
    PLANT.VALUATION_AREA as VALUATION_AREA comment = 'Valuation Area',
    PLANT.CREATED_DATE as CREATED_DATE comment = 'Created Date'
  )
  comment = 'Simulated CSN semantic view for data product Plant';

create semantic view SC360_L0.CSN.PRODUCTION_ORDER_CONFIRM
  tables (
    PROD_ORD_CONFIRMATION as SC360_L0.PRODUCTION_ORDER_CONFIRM.A_PROD_ORD_CONFIRMATION primary key (PRODUCTION_ORDER)
      comment = 'Prod Ord Confirmation'
  )
  dimensions (
    PROD_ORD_CONFIRMATION.PRODUCTION_ORDER as PRODUCTION_ORDER comment = 'Production Order',
    PROD_ORD_CONFIRMATION.ORDER_TYPE as ORDER_TYPE comment = 'Order Type',
    PROD_ORD_CONFIRMATION.PLANT as PLANT comment = 'Plant',
    PROD_ORD_CONFIRMATION.MATERIAL as MATERIAL comment = 'Material',
    PROD_ORD_CONFIRMATION.MATERIAL_DESC as MATERIAL_DESC comment = 'Material Desc',
    PROD_ORD_CONFIRMATION.PLANNED_QTY as PLANNED_QTY comment = 'Planned Qty',
    PROD_ORD_CONFIRMATION.CONFIRMED_QTY as CONFIRMED_QTY comment = 'Confirmed Qty',
    PROD_ORD_CONFIRMATION.SCRAP_QTY as SCRAP_QTY comment = 'Scrap Qty',
    PROD_ORD_CONFIRMATION.YIELD_QTY as YIELD_QTY comment = 'Yield Qty',
    PROD_ORD_CONFIRMATION.WORK_CENTER as WORK_CENTER comment = 'Work Center',
    PROD_ORD_CONFIRMATION.CYCLE_TIME_DAYS as CYCLE_TIME_DAYS comment = 'Cycle Time Days',
    PROD_ORD_CONFIRMATION.CREATED_DATE as CREATED_DATE comment = 'Created Date',
    PROD_ORD_CONFIRMATION.BASIC_START_DATE as BASIC_START_DATE comment = 'Basic Start Date',
    PROD_ORD_CONFIRMATION.BASIC_FINISH_DATE as BASIC_FINISH_DATE comment = 'Basic Finish Date',
    PROD_ORD_CONFIRMATION.ORDER_STATUS as ORDER_STATUS comment = 'Order Status'
  )
  comment = 'Simulated CSN semantic view for data product Production Order Confirm';

create semantic view SC360_L0.CSN.PRODUCTION_VERSION
  tables (
    PRODUCTION_VERSION as SC360_L0.PRODUCTION_VERSION.A_PRODUCTION_VERSION primary key (MATERIAL)
      comment = 'Production Version'
  )
  dimensions (
    PRODUCTION_VERSION.MATERIAL as MATERIAL comment = 'Material',
    PRODUCTION_VERSION.PLANT as PLANT comment = 'Plant',
    PRODUCTION_VERSION.PRODUCTION_VERSION as PRODUCTION_VERSION comment = 'Production Version',
    PRODUCTION_VERSION.VERSION_TEXT as VERSION_TEXT comment = 'Version Text',
    PRODUCTION_VERSION.BOM_NUMBER as BOM_NUMBER comment = 'BOM Number',
    PRODUCTION_VERSION.ROUTING_NUMBER as ROUTING_NUMBER comment = 'Routing Number',
    PRODUCTION_VERSION.VALID_FROM as VALID_FROM comment = 'Valid From',
    PRODUCTION_VERSION.VALID_TO as VALID_TO comment = 'Valid To',
    PRODUCTION_VERSION.LOT_SIZE_MIN as LOT_SIZE_MIN comment = 'Lot Size Min',
    PRODUCTION_VERSION.LOT_SIZE_MAX as LOT_SIZE_MAX comment = 'Lot Size Max'
  )
  comment = 'Simulated CSN semantic view for data product Production Version';

create semantic view SC360_L0.CSN.PROJECT
  tables (
    PROJECT as SC360_L0.PROJECT.A_PROJECT primary key (PROJECT_ID)
      comment = 'Project'
  )
  dimensions (
    PROJECT.PROJECT_ID as PROJECT_ID comment = 'Project ID',
    PROJECT.PROJECT_NAME as PROJECT_NAME comment = 'Project Name',
    PROJECT.PLANT as PLANT comment = 'Plant',
    PROJECT.PROJECT_STATUS as PROJECT_STATUS comment = 'Project Status',
    PROJECT.PLANNED_COST as PLANNED_COST comment = 'Planned Cost',
    PROJECT.ACTUAL_COST as ACTUAL_COST comment = 'Actual Cost',
    PROJECT.BUDGET_VARIANCE_PCT as BUDGET_VARIANCE_PCT comment = 'Budget Variance PCT',
    PROJECT.START_DATE as START_DATE comment = 'Start Date',
    PROJECT.END_DATE as END_DATE comment = 'End Date',
    PROJECT.COMPLETION_PCT as COMPLETION_PCT comment = 'Completion PCT'
  )
  comment = 'Simulated CSN semantic view for data product Project';

create semantic view SC360_L0.CSN.PROJECT_CONFIG_DATA
  tables (
    PROJECT_CONFIG as SC360_L0.PROJECT_CONFIG_DATA.A_PROJECT_CONFIG
      comment = 'Project Config'
  )
  dimensions (
    PROJECT_CONFIG.PROJECT_ID as PROJECT_ID comment = 'Project ID',
    PROJECT_CONFIG.CONFIG_KEY as CONFIG_KEY comment = 'Config Key',
    PROJECT_CONFIG.CONFIG_VALUE as CONFIG_VALUE comment = 'Config Value',
    PROJECT_CONFIG.DESCRIPTION as DESCRIPTION comment = 'Description'
  )
  comment = 'Simulated CSN semantic view for data product Project Config Data';

create semantic view SC360_L0.CSN.PROJECT_NETWORK
  tables (
    PROJECT_WBS as SC360_L0.PROJECT_NETWORK.A_PROJECT_WBS
      comment = 'Project WBS'
  )
  dimensions (
    PROJECT_WBS.PROJECT_ID as PROJECT_ID comment = 'Project ID',
    PROJECT_WBS.WBS_ELEMENT as WBS_ELEMENT comment = 'WBS Element',
    PROJECT_WBS.WBS_DESCRIPTION as WBS_DESCRIPTION comment = 'WBS Description',
    PROJECT_WBS.PARENT_WBS as PARENT_WBS comment = 'Parent WBS',
    PROJECT_WBS.LEVEL as LEVEL comment = 'Level'
  )
  comment = 'Simulated CSN semantic view for data product Project Network';

create semantic view SC360_L0.CSN.SALES_BOM
  tables (
    SALES_BOM as SC360_L0.SALES_BOM.A_SALES_BOM
      comment = 'Sales BOM'
  )
  dimensions (
    SALES_BOM.SALES_BOM_NUMBER as SALES_BOM_NUMBER comment = 'Sales BOM Number',
    SALES_BOM.MATERIAL as MATERIAL comment = 'Material',
    SALES_BOM.MATERIAL_DESC as MATERIAL_DESC comment = 'Material Desc',
    SALES_BOM.COMPONENT_MATERIAL as COMPONENT_MATERIAL comment = 'Component Material',
    SALES_BOM.COMPONENT_DESC as COMPONENT_DESC comment = 'Component Desc',
    SALES_BOM.COMPONENT_QTY as COMPONENT_QTY comment = 'Component Qty',
    SALES_BOM.ITEM_CATEGORY as ITEM_CATEGORY comment = 'Item Category'
  )
  comment = 'Simulated CSN semantic view for data product Sales BOM';

create semantic view SC360_L0.CSN.SHIPPING_POINT
  tables (
    SHIPPING_POINT as SC360_L0.SHIPPING_POINT.A_SHIPPING_POINT primary key (SHIPPING_POINT)
      comment = 'Shipping Point'
  )
  dimensions (
    SHIPPING_POINT.SHIPPING_POINT as SHIPPING_POINT comment = 'Shipping Point',
    SHIPPING_POINT.SHIPPING_POINT_DESC as SHIPPING_POINT_DESC comment = 'Shipping Point Desc',
    SHIPPING_POINT.FACTORY_CALENDAR as FACTORY_CALENDAR comment = 'Factory Calendar',
    SHIPPING_POINT.COUNTRY as COUNTRY comment = 'Country',
    SHIPPING_POINT.DEPARTURE_ZONE as DEPARTURE_ZONE comment = 'Departure Zone',
    SHIPPING_POINT.PLANT as PLANT comment = 'Plant'
  )
  comment = 'Simulated CSN semantic view for data product Shipping Point';

create semantic view SC360_L0.CSN.STORAGE_LOCATION
  tables (
    STORAGE_LOCATION as SC360_L0.STORAGE_LOCATION.A_STORAGE_LOCATION
      comment = 'Storage Location'
  )
  dimensions (
    STORAGE_LOCATION.PLANT as PLANT comment = 'Plant',
    STORAGE_LOCATION.STORAGE_LOCATION as STORAGE_LOCATION comment = 'Storage Location',
    STORAGE_LOCATION.STORAGE_LOC_DESC as STORAGE_LOC_DESC comment = 'Storage Loc Desc',
    STORAGE_LOCATION.CREATED_DATE as CREATED_DATE comment = 'Created Date'
  )
  comment = 'Simulated CSN semantic view for data product Storage Location';

create semantic view SC360_L0.CSN.WORK_CENTER
  tables (
    WORK_CENTER as SC360_L0.WORK_CENTER.A_WORK_CENTER primary key (WORK_CENTER)
      comment = 'Work Center',
    WORK_CENTER_CAPACITY as SC360_L0.WORK_CENTER.A_WORK_CENTER_CAPACITY
      comment = 'Work Center Capacity'
  )
  dimensions (
    WORK_CENTER.WORK_CENTER_WORK_CENTER as WORK_CENTER comment = 'Work Center',
    WORK_CENTER.WORK_CENTER_DESC as WORK_CENTER_DESC comment = 'Work Center Desc',
    WORK_CENTER.WORK_CENTER_PLANT as PLANT comment = 'Plant',
    WORK_CENTER.WORK_CENTER_CATEGORY as WORK_CENTER_CATEGORY comment = 'Work Center Category',
    WORK_CENTER.USAGE as USAGE comment = 'Usage',
    WORK_CENTER.RESPONSIBLE_COST_CENTER as RESPONSIBLE_COST_CENTER comment = 'Responsible Cost Center',
    WORK_CENTER.WORK_CENTER_AVAILABLE_CAPACITY_HRS as AVAILABLE_CAPACITY_HRS comment = 'Available Capacity HRS',
    WORK_CENTER.CREATED_DATE as CREATED_DATE comment = 'Created Date',
    WORK_CENTER_CAPACITY.WORK_CENTER_CAPACITY_WORK_CENTER as WORK_CENTER comment = 'Work Center',
    WORK_CENTER_CAPACITY.WORK_CENTER_CAPACITY_PLANT as PLANT comment = 'Plant',
    WORK_CENTER_CAPACITY.PERIOD_DATE as PERIOD_DATE comment = 'Period Date',
    WORK_CENTER_CAPACITY.WORK_CENTER_CAPACITY_AVAILABLE_CAPACITY_HRS as AVAILABLE_CAPACITY_HRS comment = 'Available Capacity HRS',
    WORK_CENTER_CAPACITY.USED_CAPACITY_HRS as USED_CAPACITY_HRS comment = 'Used Capacity HRS'
  )
  comment = 'Simulated CSN semantic view for data product Work Center';

-- Change tracking is switched on above, while ACCOUNTADMIN still owns the tables.
-- Lab Dynamic Tables need it for incremental refresh, and the lab role cannot
-- switch it on itself once the provider role owns the data.

-- Hand the data products to the provider role, then grant read-only access.
grant ownership on all tables in database SC360_L0 to role SC360_DATA_PROVIDER revoke current grants;
grant ownership on all semantic views in database SC360_L0 to role SC360_DATA_PROVIDER revoke current grants;
grant ownership on all schemas in database SC360_L0 to role SC360_DATA_PROVIDER revoke current grants;
grant ownership on database SC360_L0 to role SC360_DATA_PROVIDER revoke current grants;
grant ownership on all tables in database SC360_EXT to role SC360_DATA_PROVIDER revoke current grants;
grant ownership on all schemas in database SC360_EXT to role SC360_DATA_PROVIDER revoke current grants;
grant ownership on database SC360_EXT to role SC360_DATA_PROVIDER revoke current grants;

-- Read-only access for the lab role (and, through SYSADMIN, for ACCOUNTADMIN).
grant usage on database SC360_L0 to role SC360_ENGINEER;
grant usage on all schemas in database SC360_L0 to role SC360_ENGINEER;
grant select on all tables in database SC360_L0 to role SC360_ENGINEER;
grant select, references on all semantic views in database SC360_L0 to role SC360_ENGINEER;
grant usage on database SC360_EXT to role SC360_ENGINEER;
grant usage on all schemas in database SC360_EXT to role SC360_ENGINEER;
grant select on all tables in database SC360_EXT to role SC360_ENGINEER;
revoke role SC360_DATA_PROVIDER from role ACCOUNTADMIN;

-- The build target for Labs 1-5.
create database if not exists SC360_LAB;
grant ownership on database SC360_LAB to role SC360_ENGINEER copy current grants;
grant usage, operate on warehouse LAB_WH to role SC360_ENGINEER;
grant execute data metric function on account to role SC360_ENGINEER;
grant database role SNOWFLAKE.DATA_METRIC_USER to role SC360_ENGINEER;
grant database role SNOWFLAKE.CORTEX_USER to role SC360_ENGINEER;

-- Count check. Fails loudly if any file did not load.
declare
  load_mismatch exception (-20001, 'SC360 load check failed: row or table counts differ from data/manifest.csv. See docs/troubleshooting.md.');
  l0_tables int; l0_rows int; ext_tables int; ext_rows int;
begin
  select count(*), coalesce(sum(row_count), 0) into :l0_tables, :l0_rows
    from SC360_L0.information_schema.tables where table_type = 'BASE TABLE';
  select count(*), coalesce(sum(row_count), 0) into :ext_tables, :ext_rows
    from SC360_EXT.information_schema.tables where table_type = 'BASE TABLE';
  if (l0_tables <> 21 or l0_rows <> 398 or ext_tables <> 14 or ext_rows <> 7850) then
    raise load_mismatch;
  end if;
  return 'OK: SC360_L0 ' || l0_tables || ' tables / ' || l0_rows || ' rows; SC360_EXT '
         || ext_tables || ' tables / ' || ext_rows || ' rows.';
end;
