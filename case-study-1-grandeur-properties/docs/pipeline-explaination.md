# Pipeline Explanation – Case Study 1

## Overview
This pipeline implements a batch ingestion pattern in Microsoft Fabric using a Lakehouse architecture.

## Activities

### 1. Copy_to_LH
- Reads CSV files using wildcard pattern: `office_*.csv`
- Source: Landing (Files section)
- Adds ingestion timestamp using `@utcNow()`
- Loads data into Lakehouse table using **Upsert**
- Key used: `property_id`

### 2. Copy_to_Archive
- Copies processed files from Landing to Archive
- Ensures raw data retention for audit and reprocessing

### 3. Delete_data_in_landing
- Deletes files from Landing **only after archive success**
- Prevents data loss and ensures safe cleanup

### 4. MicrosoftTeams_Notification
- Sends success notification after pipeline completion
- Includes pipeline name, run ID, and execution timestamp

## Key Design Decisions

- **Wildcard ingestion** allows onboarding new offices without pipeline changes
- **Upsert** ensures no duplicate records and supports updates
- **Archive before delete** prevents accidental data loss
- **Timestamp column** helps track ingestion time