-- =====================================================================
-- SAP BDC Connect + Snowflake partner workshop
-- Setup 00: connect Snowflake to the lab repository on GitHub
-- =====================================================================
-- Run as ACCOUNTADMIN in a Snowsight SQL worksheet (paste this file).
-- Creates:
--   API integration SC360_GIT_API     allows HTTPS reads from the lab repo's GitHub org
--   Git repository SC360_ADMIN.GIT.SC360_LAB_REPO   a read-only clone of the lab repo
--   Warehouse LAB_WH                  XSMALL, auto-suspend 60 s
-- The repo is public, so no Git credentials or secrets are needed.
-- Safe to re-run.

use role accountadmin;

create warehouse if not exists LAB_WH
  warehouse_size = XSMALL auto_suspend = 60 auto_resume = true initially_suspended = true;
use warehouse LAB_WH;

create database if not exists SC360_ADMIN;
create schema if not exists SC360_ADMIN.GIT;

create or replace api integration SC360_GIT_API
  api_provider = git_https_api
  api_allowed_prefixes = ('https://github.com/snowflakethia/')
  enabled = true;

create or replace git repository SC360_ADMIN.GIT.SC360_LAB_REPO
  api_integration = SC360_GIT_API
  origin = 'https://github.com/snowflakethia/SAP_BDC_SC360_Workshop.git';

alter git repository SC360_ADMIN.GIT.SC360_LAB_REPO fetch;

-- Expected: a list of files under setup/, including 01_load_l0.sql.
ls @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/setup/;

-- Next steps (or run the three files from the Workspace you create from this repo):
--   execute immediate from @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/setup/01_load_l0.sql;
--   execute immediate from @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/setup/02_reference_build.sql;
--   execute immediate from @SC360_ADMIN.GIT.SC360_LAB_REPO/branches/main/setup/99_check.sql;
