# Pipeline Explanation – Case Study 1

## Overview
This pipeline implements a batch ingestion pattern in Microsoft Fabric using a Lakehouse architecture.

## Activities

### 1. Get_Landing_Files
- Reads landing contents from the incoming folder
- Returns the file list for downstream filtering

### 2. Filter_Valid_Office_Csv
- Keeps trusted office files that match `office_*.csv`

### 3. ForEach_Valid_File
- Processes trusted office files one by one
- Runs schema validation before trusted load

### 4. Validate_File_Schema
- Checks required columns before `Copy_to_LH`
- Sends schema-drift files to quarantine instead of trusted load

### 5. Copy_to_LH
- Loads approved business columns into the Lakehouse table
- Excludes sensitive columns from the trusted target
- Adds ingestion timestamp using `@utcNow()`
- Uses **Upsert** with key `property_id`

### 6. Copy_to_Archive_Processed
- Copies valid processed files to Archive
- Preserves replay capability for trusted files

### 7. Delete_From_Landing
- Deletes trusted files from Landing **only after archive success**

### 8. Wrong-Name and Non-CSV Quarantine Branches
- Route differently named CSV files and non-CSV files to Quarantine
- Delete landing copies only after quarantine succeeds

### 9. MicrosoftTeams_Notification
- Sends pipeline notification after completion
- Includes execution metadata for monitoring

## Operational Behavior

- If a trusted office file is missing for a run, the pipeline still processes the available valid files.
- If schema validation fails, the file is treated as an exception and kept out of the trusted load path.
- If archive or quarantine copy does not succeed, the related landing file is not deleted.
- The Teams notification provides lightweight run visibility, but it is not a full alerting or incident-management solution.

## Recovery Guidance

- If a trusted file loads but archive fails, investigate the archive error first because the landing file remains available for replay or manual recovery.
- If a file is quarantined because of schema drift, wrong naming, or unsupported format, fix the source issue and then replay the corrected file through the trusted path.
- If a run completes with missing office files, treat the result as a partial refresh and confirm whether downstream consumers need to wait for the missing delivery.

## Key Design Decisions

- **Wildcard ingestion** allows onboarding new offices without pipeline changes
- **Schema validation** prevents invalid trusted office files from loading
- **Upsert** ensures no duplicate records and supports updates
- **PII exclusion** keeps sensitive columns out of the trusted Lakehouse table
- **Archive before delete** prevents accidental data loss
- **Timestamp column** helps track ingestion time
- **Exception routing** keeps differently named, schema-drift, and non-CSV files out of the curated load path
