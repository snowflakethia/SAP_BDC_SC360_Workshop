-- =====================================================================
-- SAP BDC Connect + Snowflake partner workshop
-- Lab 2 step 4: ontology entity views (identity)
-- Generated file. All data is synthetic.
-- =====================================================================
-- Run as SC360_ENGINEER. Generated from the demo's sql/04 (the entity views only): only the database
-- names are changed, so you build the same objects the demo runs on.

use role SC360_ENGINEER;
use warehouse LAB_WH;

-- ---------------------------------------------------------------------
-- Ontology entities (conformed dimensions). One row per business key,
-- derived from every fact that carries the key, so each relationship below
-- references a true primary key. In SAP terms these play the role of the
-- master-data CDS entities (I_Product, I_Supplier, I_Plant) that the
-- transactional CDS views associate to.
-- ---------------------------------------------------------------------
create or replace view SC360_LAB.ANALYTICS.ENT_MATERIAL as
select material, max(material_desc) as material_desc from (
    select material, material_desc from SC360_LAB.ANALYTICS.DT_INVENTORY_OVERVIEW
    union all select material, material_desc from SC360_LAB.ANALYTICS.DT_SUPPLIER_QUALITY
    union all select material, material_desc from SC360_LAB.ANALYTICS.DT_PRODUCTION_ORDER_360
    union all select parent_material, parent_desc from SC360_LAB.ANALYTICS.DT_BOM_EXPLOSION
    union all select component_material, component_desc from SC360_LAB.ANALYTICS.DT_BOM_EXPLOSION
    union all select component_material, component_desc from SC360_LAB.ANALYTICS.DT_COMPONENT_COVER
    union all select material, material_desc from SC360_LAB.ANALYTICS.DT_ORDER_FULFILLMENT
) where material is not null group by material;

-- TODO: write ENT_SUPPLIER, one row per supplier, following the pattern of the
-- two views around it. Which Dynamic Tables carry a SUPPLIER column? (Hint: two do.)
--
-- create or replace view SC360_LAB.ANALYTICS.ENT_SUPPLIER as
-- select supplier, max(supplier_name) as supplier_name from (
--     select ... from SC360_LAB.ANALYTICS.<dynamic table 1>
--     union all select ... from SC360_LAB.ANALYTICS.<dynamic table 2>
-- ) where supplier is not null group by supplier;

create or replace view SC360_LAB.ANALYTICS.ENT_PLANT as
select plant, max(plant_name) as plant_name from (
    select plant, plant_name from SC360_LAB.ANALYTICS.DT_INVENTORY_OVERVIEW
    union all select plant, plant_name from SC360_LAB.ANALYTICS.DT_PRODUCTION_ORDER_360
    union all select plant, plant_name from SC360_LAB.ANALYTICS.DT_COMPONENT_COVER
    union all select plant, plant_name from SC360_LAB.ANALYTICS.DT_ORDER_FULFILLMENT
) where plant is not null group by plant;

-- Fails with "does not exist" until ENT_SUPPLIER is written.
-- Expected: 42 materials, 15 suppliers, 5 plants.
select (select count(*) from SC360_LAB.ANALYTICS.ENT_MATERIAL) as materials,
       (select count(*) from SC360_LAB.ANALYTICS.ENT_SUPPLIER) as suppliers,
       (select count(*) from SC360_LAB.ANALYTICS.ENT_PLANT)    as plants;
