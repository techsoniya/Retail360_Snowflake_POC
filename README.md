# Retail360: Enterprise Data Pipeline, Cortex Machine Learning & Natural Language Discovery Platform

An end-to-end, production-grade Retail Analytics and Machine Learning Data Platform engineered natively within **Snowflake**. This platform implements a fully automated Medallion Architecture (Raw -> Clean -> Core -> Mart) designed to ingest multi-format stream data, enforce rigorous data quality checks via decoupled rejection frameworks, maintain strict Type-2 Slowly Changing Dimensions (SCD), and perform advanced time-series forecasting and anomaly detection using native Snowflake Cortex ML. 

The entire data asset layer surfaces through two interactive, enterprise-facing Streamlit applications deployed directly inside Snowflake.

---

## 📺 Project Walkthrough & Interactive Demos

[![Watch the Platform Demo](https://img.shields.io/badge/Google_Drive-Video_Platform_Demo-blue?style=for-the-badge&logo=googledrive&logoColor=white)](YOUR_GOOGLE_DRIVE_VIDEO_LINK_HERE)

### 🚀 The Application Layer (Streamlit in Snowflake)

| 📈 Retail360 AI Control Tower | 🤖 Ask Retail360 (Conversational AI Analyst) |
| :--- | :--- |
| Surfaces operational dashboard KPIs (Forecast Days, 30-Day Projective Volume, High-Value Customer Metrics) backed by interactive time-series visualizations matching actual performance trends against predictive bounds. | A generative Text-to-SQL layer utilizing Snowflake Cortex Analyst to translate natural language prompts directly into verifiable SQL statements against core marts, with strict guardrails preventing PII leaks. |

---

## 🏗️ Platform Architecture & Data Flow

```text
  [ Ingestion Layer ]        [ Raw Layer ]          [ Clean Layer ]         [ Core Data Warehouse ]         [ Analytics & ML Marts ]
  
   +-----------------+        +-------------+        +------------+          +--------------------+          +-----------------------+
   | STG_RETAIL360   | ---->  | TRANSIENT   | ---->  | Validation | -------> |  DIM_* (SCD Type 2) |  ----->   | Analytical Views      |
   | (Internal Stage)|        | *_SRC       |        | SP Cleaners|          |                    |          | (Store, Customer 360) |
   +-----------------+        +-------------+        +------------+          +--------------------+          +-----------------------+
            |                        |                      |                          |                                 |
     [Snowpipes Continuous    [Snowflake Streams      [Automated Tasks          [Incremental Merges      [Native Snowflake Cortex ML]
       Pattern Matching]       Change Capture]         Delta Processing]         Fact/Dimension Tables]                  |
                                                            |                                                            v
                                                            v                                                +-----------------------+
                                                     +------------+                                          |  1. STREAMLIT APPS    |
                                                     | *_REJECT   |                                          |  2. CORTEX ANALYST    |
                                                     | REJECT_LOG |                                          +-----------------------+
                                                     +------------+
