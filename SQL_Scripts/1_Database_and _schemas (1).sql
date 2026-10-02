
-- 0. CONTEXT

-- use role accountadmin;
--Nope 
USE ROLE SYSADMIN;
--We cant use Role ACCOUNTADMIN to create everything, not a good practice because as a data engineer we will assigned different roles with different permisssion and as accountadmin has access to literally everything, this isnt a good practice , not everyone can be an accountadmin as then all will hace access to change things and critical data , so we will use sysadin to create most things 

-- Optional but recommended:
create or replace database RETAIL360_DEMO;
use database RETAIL360_DEMO;


-- 1. SCHEMAS

create schema if not exists INGEST;
create schema if not exists RAW;
create schema if not exists CLEAN;
create schema if not exists CORE;
create schema if not exists AUDIT;
create schema RETAIL360_DEMO.MART;