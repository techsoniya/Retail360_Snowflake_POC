# Retail360: AI-Powered Enterprise Retail Analytics Platform on Snowflake

Retail360 is an enterprise-scale retail analytics platform built entirely within the **Snowflake Data Cloud**. The platform implements a fully automated Medallion Architecture with continuous data ingestion, enterprise data warehousing, native machine learning, and conversational AI analytics powered by Snowflake Cortex.

---

## 🌟 Highlights

*   **🚀 End-to-End Enterprise Data Pipeline:** Fully automated from source file arrival to final downstream insights.
*   **❄️ Built Natively on Snowflake:** ZERO reliance on external orchestration tools, compute nodes, or separate ML infrastructure.
*   **📊 Medallion Architecture:** Raw $\rightarrow$ Clean $\rightarrow$ Core $\rightarrow$ Mart logical isolation.
*   **🔄 Continuous Ingestion:** Automated event-driven file ingestion via Snowpipe.
*   **⚡ Change Data Capture (CDC):** Incremental data processing using Snowflake Streams.
*   **🤖 Native Machine Learning:** Time-series demand forecasting and anomaly detection via Snowflake Cortex ML Functions.
*   **💬 Conversational Analytics:** Natural language interfaces built on Snowflake Cortex Analyst (Text-to-SQL).
*   **📈 Streamlit in Snowflake (SiS):** Production-grade operations and executive dashboards deployed inside the data perimeter.
*   **🛡️ Data Quality & Governance:** Stream-driven row-level validation framework with automated reject isolation and Type-2 Slowly Changing Dimensions (SCD2).

---

## 📖 Project Overview

Retail360 demonstrates how modern organizations can architect a secure, cloud-native data platform directly inside the Snowflake ecosystem. 

Rather than relying on fragmented stacks (e.g., Airflow for orchestration, dbt for transformations, Python servers for ML), Retail360 leverages Snowflake's native feature set. Raw transaction, customer, and inventory records arrive as unstructured or semi-structured files, process incrementally through validation checks, manage history perfectly via SCD2 logic, and finally surface inside Streamlit applications. Business users can view predictions or safely ask complex analytics questions in plain text using Cortex Analyst, which securely translates natural language requests into governed SQL queries.

### 🎯 Core Engineering Focus
This repository serves as a showcase for production data engineering patterns, including:
*   Incremental ELT processing over batch re-computes.
*   Idempotent pipeline designs.
*   Defensive data validation structures (retaining good rows while isolating corrupted rows).
*   Granular Role-Based Access Control (RBAC) implementations.

---

## 🏆 Key Platform Capabilities

| Category | Capability | Snowflake Implementation Component |
| :--- | :--- | :--- |
| **Data Ingestion** | Continuous, multi-format file processing | Internal Stages, File Formats, Snowpipe |
| **Change Data Capture** | Row-level delta tracking | Snowflake Streams |
| **Data Validation** | Row-level validation and quarantine separation | Stored Procedures, Reject Tables & Logs |
| **Automation** | Dependency-driven pipeline scheduling | Snowflake Tasks (DAG execution) |
| **Warehouse Modeling** | Relational Star Schema with historical tracking | Facts, Dimensions, SCD Type-2 MERGE |
| **Machine Learning** | Out-of-the-box forecasting & anomaly tracking | Cortex Forecast & Anomaly Detection |
| **Generative AI** | Governed natural language analytics | Cortex Analyst (YAML Semantic Model) |
| **Visualization** | Interactive executive interfaces | Streamlit in Snowflake (SiS) |

---

## 📊 Architecture & Data Flow

```text
       Source Systems (CSV • JSON • Parquet)
                        │
                        ▼
             Internal Snowflake Stage
                        │ (Continuous Pipe Event)
                        ▼
             ┌─────────────────────┐
             │      RAW LAYER      │ ◄─── Immutable Storage & Metadata
             └─────────────────────┘
                        │
                 Snowflake Stream (CDC Delta Capture)
                        │
                        ▼
             ┌─────────────────────┐
             │     CLEAN LAYER     │ ◄─── Row-Level Validation Engine
             └─────────────────────┘
                 │             │
          (Valid Records) (Invalid Records)
                 │             │
                 ▼             ▼
       ┌───────────────┐ ┌───────────────┐
       │ Clean Tables  │ │ Reject Logs   │
       └───────────────┘ └───────────────┘
                 │
           Stored Procedures (SCD2 MERGE Logic)
                 │
                 ▼
             ┌─────────────────────┐
             │   CORE WAREHOUSE    │ ◄─── Star Schema (Facts + SCD2 Dims)
             └─────────────────────┘
                        │
             Business Analytical Marts (Optimized Materialized Views)
                        │
         ┌──────────────┴──────────────┐
         ▼                             ▼
  AI Control Tower               Ask Retail360
(Streamlit Dashboard)           (Cortex Analyst)

```

##📈 Data Flow

```text

Retail Files
      │
      ▼
Snowpipe
      │
      ▼
RAW Layer
      │
      ▼
Streams
      │
      ▼
Validation Procedures
      │
 ┌────┴─────┐
 │          │
 ▼          ▼
Valid     Reject
Records   Records
 │          │
 ▼          ▼
Clean     Reject Log
 │
 ▼
Core Warehouse
 │
 ▼
Analytics Marts
 │
 ├────────► Streamlit Dashboard
 │
 └────────► Cortex Analyst

```
##🛠 Technology Stack

Retail360 leverages Snowflake's native ecosystem to build a modern, cloud-native analytics platform without relying on external orchestration or machine learning frameworks.

Category	Technologies
Cloud Data Platform	Snowflake
Programming	SQL, Python
Data Ingestion	Internal Stages, Snowpipe, File Formats
Data Processing	Streams, Tasks, Stored Procedures
Data Warehouse	Star Schema, Fact Tables, Dimension Tables, SCD Type-2
Analytics	Views, Business Marts
Machine Learning	Snowflake Cortex Forecasting, Cortex Anomaly Detection
Artificial Intelligence	Snowflake Cortex Analyst (Natural Language SQL)
Visualization	Streamlit in Snowflake
Governance	Reject Framework, Audit Logs, Validation Rules
🏛 Enterprise Architecture

Retail360 follows the Medallion Architecture, a widely adopted design pattern for building scalable and reliable data platforms.

Rather than transforming raw data directly into reports, the pipeline processes information through multiple layers, ensuring data quality, governance, traceability, and historical consistency.

```text

                    Retail Data Sources
          (CSV • JSON • Parquet • Batch Files)
                           │
                           ▼
                Internal Snowflake Stage
                           │
                     Snowpipe Ingestion
                           │
                           ▼
 ┌──────────────────────────────────────────────────────────────┐
 │                        RAW LAYER                             │
 │                                                              │
 │ • Immutable Source Data                                      │
 │ • Metadata Tracking                                          │
 │ • Original File Preservation                                 │
 └──────────────────────────────────────────────────────────────┘
                           │
                    Snowflake Streams
                           │
                           ▼
 ┌──────────────────────────────────────────────────────────────┐
 │                      CLEAN LAYER                             │
 │                                                              │
 │ • Validation Rules                                           │
 │ • Reject Framework                                           │
 │ • Data Standardization                                       │
 │ • Error Logging                                              │
 └──────────────────────────────────────────────────────────────┘
                           │
                  Stored Procedures + MERGE
                           │
                           ▼
 ┌──────────────────────────────────────────────────────────────┐
 │                    CORE WAREHOUSE                            │
 │                                                              │
 │ • Fact Tables                                                │
 │ • SCD Type-2 Dimensions                                      │
 │ • Incremental Processing                                     │
 │ • Historical Tracking                                        │
 └──────────────────────────────────────────────────────────────┘
                           │
                           ▼
 ┌──────────────────────────────────────────────────────────────┐
 │                  ANALYTICS MARTS                             │
 │                                                              │
 │ • Customer 360                                               │
 │ • Store Performance                                          │
 │ • Sales Intelligence                                         │
 │ • Product Analytics                                          │
 └──────────────────────────────────────────────────────────────┘
                           │
         ┌─────────────────┴──────────────────┐
         ▼                                    ▼
 AI Control Tower                  Ask Retail360
  (Streamlit)                     Cortex Analyst

```

##🏗 Medallion Architecture
###🥉 Bronze Layer (RAW)

The Raw layer acts as the immutable landing zone for all incoming retail datasets.

Incoming files are continuously loaded into Snowflake using Snowpipe, preserving the original structure and metadata for complete traceability.

####Responsibilities
Continuous ingestion
Metadata tracking
Source preservation
Schema isolation
Auditability
Snowflake Components
Internal Stages
File Formats
Snowpipe
Transient Tables
###🥈 Silver Layer (CLEAN)

The Clean layer transforms raw business data into trusted datasets through a validation-first approach.

Instead of rejecting an entire file because of a few bad records, Retail360 isolates invalid rows into dedicated reject tables while allowing valid records to continue through the pipeline.

This approach minimizes data loss while maintaining high data quality.

Validation Framework

####The platform validates:

Required fields
Null values
Invalid dates
Duplicate records
Negative sales values
Invalid customer IDs
Product inconsistencies
Business rule violations
Outputs

✅ Clean Records

❌ Reject Records

📋 Audit Logs

###🥇 Gold Layer (CORE)

The Core Warehouse represents the trusted source of truth for analytical reporting.

Business entities such as customers, products, and stores are modeled using Type-2 Slowly Changing Dimensions (SCD2), allowing the warehouse to preserve historical changes over time.

Transactional data is stored in optimized fact tables linked to these dimensions, enabling accurate point-in-time reporting.

Features
Historical tracking
Incremental MERGE operations
Star Schema modeling
Fact & Dimension tables
Referential integrity
Idempotent processing
💎 Platinum Layer (Analytics)

The final layer exposes curated business-ready datasets for dashboards, AI applications, and decision support.

These marts power executive reporting, customer insights, inventory analysis, sales trends, and machine learning models.

Business Views
Customer 360
Store Performance
Product Analytics
Sales KPIs
Inventory Insights
Revenue Trends
Forecast Results
Anomaly Reports

##🔄 End-to-End Pipeline

```text
Landing Files
      │
      ▼
Snowpipe
      │
      ▼
RAW Tables
      │
      ▼
Snowflake Streams
      │
      ▼
Validation Procedures
      │
 ┌────┴─────┐
 │          │
 ▼          ▼
Clean     Reject
Data      Records
 │          │
 ▼          ▼
Core     Reject Logs
Warehouse
 │
 ▼
Analytics Marts
 │
 ├────────► AI Control Tower
 │
 └────────► Cortex Analyst
```
##⚡ Enterprise Design Principles

Retail360 was built using modern enterprise data engineering practices rather than traditional batch ETL.

###✅ Incremental Processing

Only newly ingested records are processed using Snowflake Streams, reducing unnecessary compute and improving efficiency.

###✅ Idempotent Data Loads

MERGE operations ensure rerunning the pipeline does not introduce duplicate records.

###✅ Historical Data Preservation

SCD Type-2 dimensions maintain complete business history, supporting accurate point-in-time analysis.

###✅ Automated Orchestration

Snowflake Tasks coordinate ingestion, validation, transformation, and analytical refreshes without manual intervention.

### Data Quality by Design

A dedicated validation framework separates trusted business data from rejected records while maintaining comprehensive audit logs.

##⚙️ Enterprise Data Pipeline

Retail360 is built as a fully automated, event-driven data platform where every stage of the pipeline is designed to be modular, scalable, and resilient. Instead of relying on external orchestration tools, the platform leverages native Snowflake capabilities to manage ingestion, transformation, validation, orchestration, and analytics.

The pipeline follows a layered approach where each component has a clearly defined responsibility, enabling maintainability, observability, and reliable data processing.

##📥 Data Ingestion Layer

The ingestion layer is responsible for continuously importing retail datasets into Snowflake while preserving source fidelity.

Incoming business data is uploaded to Snowflake Internal Stages in multiple formats including CSV, JSON, and Parquet. Snowpipe continuously monitors these stages and automatically ingests newly arrived files without requiring manual execution.

###Key Responsibilities
Continuous file ingestion
Multi-format file support
Automatic schema mapping
Metadata capture
Source preservation
Incremental loading

###Snowflake Components Used
```text
Component	Purpose
Internal Stage	Stores incoming retail datasets
File Formats	Parses CSV, JSON and Parquet files
Snowpipe	Automatically ingests newly uploaded files
Raw Tables	Stores immutable source records
```

##🌊 Change Data Capture (CDC)

After data lands in the RAW layer, Snowflake Streams detect incremental changes made to the source tables.

Instead of processing the entire dataset repeatedly, only newly inserted or modified records are forwarded for validation and transformation. This significantly improves performance and reduces compute costs.

Benefits
Incremental processing
Lower warehouse utilization
Faster execution
Event-driven architecture
No duplicate processing
🧹 Data Quality Framework

One of the core objectives of Retail360 is ensuring that downstream analytics are built on trusted data.

Every incoming record passes through a comprehensive validation framework before entering the warehouse.

Unlike traditional ETL pipelines that reject an entire batch because of a few invalid records, Retail360 isolates only the problematic rows while allowing valid records to continue processing.

This design improves reliability without interrupting business operations.

Validation Rules

The platform validates:

Mandatory field completeness
Data type consistency
Date format validation
Negative revenue detection
Invalid quantities
Duplicate business keys
Missing customer references
Missing product references
Invalid status values
Business rule compliance
🚫 Reject Framework

Invalid records are never discarded silently.

Instead, every rejected record is redirected into dedicated reject tables together with detailed validation information.

This allows developers and business users to investigate data quality issues without impacting operational reporting.

Reject Framework Components
Component	Purpose
Reject Tables	Stores invalid records
Reject Log	Captures validation errors
Error Messages	Explains rejection reason
Audit Timestamp	Tracks processing time
Example Validation Flow
Incoming Record
       │
       ▼
Validation Engine
       │
 ┌─────┴─────┐
 │           │
 ▼           ▼
Valid      Invalid
 │           │
 ▼           ▼
Clean      Reject
Table      Table
               │
               ▼
        Reject Log
🔄 Stored Procedure Framework

Business transformations are encapsulated within modular stored procedures.

Each procedure performs a specific responsibility, making the platform easier to maintain, extend, and test.

Typical responsibilities include:

Data validation
Cleansing
Standardization
Dimension loading
Fact loading
Merge logic
Audit logging

This modular approach promotes code reuse while reducing operational complexity.

⏰ Automated Workflow Orchestration

Retail360 uses Snowflake Tasks to automate the complete data pipeline.

Each task executes only after its upstream dependency has completed successfully, ensuring reliable end-to-end processing.

Snowpipe
     │
     ▼
RAW Layer
     │
     ▼
Validation Task
     │
     ▼
Dimension Load
     │
     ▼
Fact Load
     │
     ▼
Analytics Mart Refresh
     │
     ▼
ML Refresh
Advantages
Fully automated execution
Dependency management
Reduced manual intervention
Consistent refresh cycles
Reliable scheduling
🏢 Enterprise Data Warehouse

The Core Warehouse represents the trusted source of truth for analytical reporting.

The warehouse follows a Star Schema design consisting of optimized fact and dimension tables that support high-performance analytical queries.

Dimension Tables

Examples include:

Customer
Product
Store
Date
Employee

These dimensions preserve historical business changes using Type-2 Slowly Changing Dimensions.

Fact Tables

Fact tables capture measurable business events such as:

Sales
Orders
Revenue
Inventory
Transactions

Each fact record references dimension tables, enabling consistent analytical reporting.

📜 Type-2 Slowly Changing Dimensions (SCD2)

Retail360 maintains historical versions of dimensional entities using the SCD Type-2 methodology.

Rather than overwriting records, changes create new versions while preserving historical information.

For example:

Customer	City	Current
Alice	Bangalore	No
Alice	Mumbai	Yes

This enables accurate point-in-time reporting and trend analysis.

Benefits
Historical tracking
Auditability
Business lineage
Time-travel analytics
Regulatory compliance
📊 Analytics Layer

The Analytics Layer transforms curated warehouse data into business-friendly marts designed for reporting, dashboards, and AI applications.

Example analytical domains include:

Customer 360
Store Performance
Product Performance
Sales Trends
Revenue Analysis
Inventory Monitoring
Regional Insights

These marts provide optimized datasets for both business users and machine learning models.

🤖 Machine Learning with Snowflake Cortex

Retail360 extends traditional analytics with native machine learning using Snowflake Cortex.

The platform applies forecasting and anomaly detection directly within Snowflake, eliminating the need to export data into external ML environments.

Forecasting

Historical sales trends are analyzed to generate future demand predictions.

Forecast outputs help business teams anticipate demand, optimize inventory, and support operational planning.

Example Use Cases
Sales forecasting
Inventory planning
Revenue projections
Seasonal demand analysis
Anomaly Detection

The platform continuously evaluates operational metrics to identify unusual behavior.

Detected anomalies may indicate:

Unexpected sales spikes
Revenue drops
Inventory shortages
Operational issues
Promotional impacts

These insights enable proactive business decision-making.

📈 Business Intelligence Layer

Retail360 delivers insights through two interactive Streamlit applications deployed directly inside Snowflake.

📊 Retail360 AI Control Tower

The AI Control Tower provides executives with a centralized operational dashboard.

Features
Executive KPIs
Sales trends
Revenue monitoring
Demand forecasting
Anomaly visualization
Customer metrics
Store performance
Interactive filtering
💬 Ask Retail360

Ask Retail360 is a conversational analytics interface powered by Snowflake Cortex Analyst.

Instead of writing SQL, users can ask business questions in natural language.

Example questions:

"Which store generated the highest revenue last month?"

"Show me the top 10 products by profit."

"Forecast next month's sales."

Cortex Analyst translates these requests into SQL while enforcing governance policies and preventing unauthorized access to sensitive data.

🎯 Engineering Principles

Retail360 was designed around production-ready engineering practices rather than simply demonstrating Snowflake features.

The platform emphasizes:

Modular architecture
Separation of concerns
Event-driven processing
Incremental data movement
Automated orchestration
Historical data preservation
Comprehensive validation
Scalable warehouse design
Native AI integration
Enterprise governance

📂 Repository Structure
retail360/
│
├── README.md
├── LICENSE
├── .gitignore
│
├── sql/
│   ├── 01_setup/
│   │   ├── databases.sql
│   │   ├── warehouses.sql
│   │   ├── schemas.sql
│   │   └── roles.sql
│   │
│   ├── 02_ingestion/
│   │   ├── stages.sql
│   │   ├── file_formats.sql
│   │   ├── raw_tables.sql
│   │   └── snowpipes.sql
│   │
│   ├── 03_clean/
│   │   ├── streams.sql
│   │   ├── validation_procedures.sql
│   │   ├── reject_framework.sql
│   │   └── clean_tables.sql
│   │
│   ├── 04_core/
│   │   ├── dimensions.sql
│   │   ├── facts.sql
│   │   ├── scd2_merge.sql
│   │   └── warehouse_views.sql
│   │
│   ├── 05_tasks/
│   │   ├── orchestration.sql
│   │   └── task_dependencies.sql
│   │
│   ├── 06_marts/
│   │   ├── customer360.sql
│   │   ├── sales_dashboard.sql
│   │   └── executive_views.sql
│   │
│   └── 07_cortex_ml/
│       ├── forecasting.sql
│       ├── anomaly_detection.sql
│       └── cortex_analyst.yaml
│
├── streamlit/
│   ├── ai_control_tower.py
│   └── ask_retail360.py
│
├── screenshots/
│
├── architecture/
│
└── assets/
🚀 Getting Started
Prerequisites

Before deploying Retail360, ensure you have access to:

Snowflake Account
ACCOUNTADMIN or equivalent administrative privileges
Streamlit in Snowflake enabled
Snowflake Cortex enabled
Cortex Analyst enabled
Snowflake ML functions enabled
A virtual warehouse with sufficient compute resources
⚙️ Deployment Guide

The project is designed for modular deployment. Execute the SQL scripts sequentially to provision infrastructure, configure ingestion, build the warehouse, and deploy analytical applications.

Step 1 — Provision Infrastructure
Run:
sql/01_setup/

This creates:

Database
Schemas
Warehouses
Roles
Grants
Step 2 — Configure Data Ingestion
Run:
sql/02_ingestion/

This provisions:

Internal Stages
File Formats
Raw Tables
Snowpipes
Step 3 — Deploy Validation Layer
Run:
sql/03_clean/

This creates:

Streams
Validation Procedures
Reject Tables
Clean Tables
Step 4 — Build Warehouse
Run:
sql/04_core/

Creates:

Dimension Tables
Fact Tables
SCD Type-2 Merge Logic
Step 5 — Enable Automation
Run:
sql/05_tasks/

Creates:

Scheduled Tasks
Dependency Chain
Step 6 — Build Business Marts
Run:
sql/06_marts/

Creates:

Customer 360
Store Analytics
Sales Dashboard
Executive Views
Step 7 — Deploy AI Layer
Run:
sql/07_cortex_ml/

Creates

Forecast Models
Anomaly Detection Models
Cortex Analyst Semantic Model
Step 8 — Deploy Streamlit Apps

Deploy the following applications inside Snowflake:

AI Control Tower
Ask Retail360
🔄 Pipeline Execution Flow
Upload Data
     │
     ▼
Snowpipe
     │
     ▼
RAW Layer
     │
     ▼
Streams
     │
     ▼
Validation
     │
     ▼
Reject Framework
     │
     ▼
Warehouse
     │
     ▼
Analytics Marts
     │
     ▼
Machine Learning
     │
     ▼
Streamlit Applications
📊 Monitoring & Observability

Retail360 includes several mechanisms to monitor platform health and ensure reliable pipeline execution.

Pipeline Monitoring
Snowpipe ingestion status
Stream processing
Task execution history
Warehouse utilization
Data freshness
Validation metrics
Audit Framework

Each execution cycle captures operational metadata, including:

Load timestamp
Source file
Records received
Records processed
Records rejected
Records loaded
Pipeline status

These audit records provide traceability and simplify troubleshooting.

🛡️ Security & Governance

Retail360 incorporates governance practices to protect sensitive business data and ensure controlled access.

Security Features
Role-Based Access Control (RBAC)
Principle of Least Privilege
Secure Views
Controlled Streamlit Access
Cortex Analyst Guardrails
Audit Logging
Data Validation
Historical Tracking
✅ Data Quality Assurance

The platform enforces quality controls throughout the pipeline.

Validation includes:

Mandatory fields
Duplicate detection
Invalid business rules
Null handling
Referential integrity
Numeric validation
Date validation
Status validation

Rather than discarding invalid records, the platform isolates them for review while allowing trusted records to continue through the pipeline.

⚡ Performance Optimizations

Retail360 is optimized for scalable analytical workloads.

Key optimizations include:

Incremental processing using Streams
Automated Snowpipe ingestion
MERGE-based loading
Warehouse partitioning
Task dependency orchestration
Optimized analytical views
Native Cortex execution
Reduced compute through change data capture
📚 Learning Outcomes

This project demonstrates practical experience with:

Enterprise Data Engineering
Snowflake Architecture
Medallion Data Modeling
Change Data Capture
Data Quality Engineering
Data Warehousing
Incremental ETL/ELT
Type-2 Slowly Changing Dimensions
Snowflake Cortex
Machine Learning
Business Intelligence
Streamlit in Snowflake
Cloud-native Analytics
AI-powered Data Discovery
🔮 Future Enhancements

Potential future improvements include:

Real-time streaming ingestion with Kafka
Snowpark Python feature engineering
dbt integration for transformation management
CI/CD deployment with GitHub Actions
Infrastructure as Code using Terraform
Automated data quality dashboards
Data lineage visualization
Cost optimization dashboards
Iceberg Tables support
Multi-region deployment
Containerized API integrations
🤝 Contributing

Contributions, feature requests, and suggestions are welcome.

If you'd like to contribute:

Fork the repository.
Create a feature branch.
Commit your changes with clear commit messages.
Open a pull request describing your changes.

Please ensure all SQL scripts follow the project's naming conventions and maintain compatibility with the existing architecture.

👩‍💻 Author

Soniya Kambli

Data Engineer | Snowflake Enthusiast | AI & Analytics Engineer

If you found this project interesting or helpful, consider giving it a ⭐ to support the repository.
