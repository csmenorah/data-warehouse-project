# SQL data-warehouse-project

## 📃 Project Requirements



Building a Data Warehouse (Data Engineering Project)



### Objective

To develop a modern data warehouse using SQL Server to consolidate sales data, enabling analytical reporting and informed decision-making.



### Specifications

• Data Sources: Import data from two source systems (ERP and CRM) provided as CSV files.

• Data Quality: Cleanse and resolve data quality issues prior to analysis.

• Integration: Combine both sources into a single, user-friendly data model designed for analytical queries.

• Scope: Focus on the latest dataset only; historization of data is not required.

• Documentation: Provide clear documentation of the data model to support both business stakeholders and analytics teams.

---

## 🏗️ Data Architecture

The data warehouse follows the **Medallion Architecture** pattern, organizing data into **Bronze**, **Silver**, and **Gold** layers:

![Data Warehouse Architecture](docs/Data%20Warehouse%20Project%20Layers-Architecture.drawio.png)

1. **Bronze Layer (Raw Data)**: Stores raw data ingested directly from the source systems (ERP and CRM CSV files) into SQL Server tables via full-load batch processing (`TRUNCATE` & `INSERT`) without any transformations.
2. **Silver Layer (Clean & Standardized Data)**: Cleanses, standardizes, normalizes, and enriches data from the Bronze layer using stored procedures to prepare it for analysis.
3. **Gold Layer (Business-Ready Data)**: Integrates and aggregates cleansed data into analytical views modeled as a **Star Schema** (fact and dimension views) for BI & reporting, ad-hoc SQL queries, and machine learning.

### Layer Breakdown & Specifications

The diagram below outlines the definition, objectives, object types, load methods, transformations, data modeling, and target audience for each layer:

![Data Warehouse Layers Layout](docs/Data%20Warehouse%20Project%20Layers-Layout.drawio.png)

### Tools Use
1. SQLSERVER Docker "Image mcr.microsoft.com/mssql/server" 
2. Notion for Project Management
3. Draw.io for Project Architure Design
4. GitHub for Code Repository
5. VS Code for Database Workbench

