# Validation Playbook

## Project

**Grandeur Properties Global Listing Intelligence Pipeline**

This playbook defines a repeatable validation flow for proving that the Microsoft Fabric pipeline behaves correctly in a production-style setup. It is designed for portfolio reviews, demo walkthroughs, and implementation handover.

## Validation Objectives

- Confirm that only valid `office_*.csv` files are ingested into the Lakehouse table
- Confirm that valid files are archived after successful ingestion
- Confirm that unexpected files are routed to quarantine
- Confirm that landing files are deleted only after successful archive or quarantine handling
- Confirm that Upsert updates existing property rows instead of creating duplicates
- Confirm that `insert_time` is populated for loaded records
- Confirm that file-routing behavior is consistent for valid office CSV, differently named CSV, and non-CSV inputs
- Confirm that schema-drift office files are routed to quarantine
- Confirm that sensitive fields are excluded from the trusted target table
- Confirm that a missing office file results in a controlled partial load rather than a full stop

## Pre-Run Setup

Before running the validation, confirm the following:

- The target table `grandeur.dailyupdate` exists in the Lakehouse
- The landing, archive, and quarantine folders exist
- The pipeline uses explicit mappings for the curated columns
- The pipeline adds `insert_time` using `@utcNow()`
- Sensitive fields are excluded from the trusted Lakehouse mapping
- The Teams activity is configured with dynamic content for run metadata

## Test Scenario 1: Valid Office File Ingestion

### Input

- Drop a valid file such as `office_london.csv` into the landing folder
- Ensure the file follows the expected schema and naming convention

### Expected Result

- The file is ingested into `grandeur.dailyupdate`
- `insert_time` is populated for every loaded row
- The file is moved to the processed archive path
- The file is removed from landing after archive success

## Test Scenario 2: Unexpected CSV File Handling

### Input

- Drop an unexpected file such as `manual_fix.csv` into the landing folder

### Expected Result

- The file is not ingested into the Lakehouse table
- The file is routed to the quarantine path
- The file is deleted from landing only after quarantine copy succeeds

## Test Scenario 3: Non-CSV File Handling

### Input

- Drop a non-CSV file such as `notes.txt` into the landing folder

### Expected Result

- The file is not ingested into the Lakehouse table
- The file is routed to the quarantine path
- The file is deleted from landing only after quarantine copy succeeds

## Test Scenario 4: Upsert Update Behavior

### Input

1. Run the pipeline with a valid office file containing a new `property_id`
2. Run the pipeline again with a valid office file containing the same `property_id` and updated business values

### Expected Result

- The target table keeps a single row for that `property_id`
- The latest values overwrite the prior values according to Upsert behavior
- `insert_time` reflects the most recent successful ingestion of that record

## Test Scenario 5: Schema Drift Handling

### Input

- Drop a validly named office file that contains schema drift, such as a renamed or missing required column

### Expected Result

- The file is not ingested into the trusted Lakehouse table
- The file is routed to the quarantine path
- The file is deleted from landing only after quarantine copy succeeds

## Test Scenario 6: Different File Name Handling

### Input

- Drop a differently named CSV such as `singapore_office.csv` into the landing folder

### Expected Result

- The file is not ingested into the trusted Lakehouse table
- The file is routed to the quarantine path
- The behavior is visible in the demo and validation evidence

## Test Scenario 7: Archive-Before-Delete Control

### Input

- Simulate or observe a run where archive or quarantine copy does not succeed

### Expected Result

- The landing file is not deleted
- The pipeline shows a partial or failed operational state
- The run can be investigated without losing the original source file

## Test Scenario 8: Missing Office File / Partial Load

### Input

- Run the pipeline with one expected office file intentionally absent
- Keep at least one other valid `office_*.csv` file in landing

### Expected Result

- Available valid office files are still processed
- The missing office file does not cause unsupported files to enter the trusted path
- The resulting run should be explained as a partial refresh during demo or handover
- The Teams notification still shows the run metadata, but additional completeness alerting remains a future improvement

## SQL Validation Queries

Use the SQL checks in `sql/validation_queries.sql` after pipeline execution to validate:

- Total row count
- Distinct `property_id` count
- Null `insert_time` count
- Duplicate `property_id` count
- Known update checks for selected records
- Trusted target excludes sensitive columns

## Demo Walkthrough Sequence

For a portfolio or interview demo, use this sequence:

1. Show the landing, archive, and quarantine folders before execution
2. Show a valid file, a schema-drift file, a differently named CSV, and a non-CSV file in landing
3. Trigger the pipeline
4. Show the pipeline run status
5. Show the Lakehouse table results
6. Run the SQL validation queries
7. Show the archive and quarantine folders
8. Show that landing has been cleared according to the implemented control flow
9. Show the Microsoft Teams notification with pipeline name, pipeline ID, run ID, timestamp, and status
10. Explain whether the run was full or partial when demonstrating a missing-office scenario

## Evidence to Capture

Capture screenshots or logs for the following:

- Pipeline design
- File discovery and filtering logic
- Valid-file `ForEach` flow
- Schema validation notebook step
- Lakehouse table contents
- Archive folder contents
- Quarantine folder contents
- Empty or controlled landing state after completion
- Teams notification with resolved run metadata
- Evidence that schema-drift, differently named CSV, and non-CSV inputs were quarantined correctly
- Evidence of controlled partial-load behavior when an expected office file is missing

Recommended screenshot set from this repo:

- `screenshots/01-pipeline-canvas-overview.png`
- `screenshots/02-getmetadata-and-filters.png`
- `screenshots/03-foreach-valid-file-flow.png`
- `screenshots/04-schema-validation-notebook-step.png`
- `screenshots/05-copy-to-lakehouse-upsert.png`
- `screenshots/06-archive-processed-files.png`
- `screenshots/07-delete-from-landing.png`
- `screenshots/08-teams-notification-step.png`
- `screenshots/10-lakehouse-table-output.png`
- `screenshots/11-archive-folder-output.png`
- `screenshots/12-quarantine-folder-output.png`

## Conclusion

This validation playbook helps demonstrate that the pipeline is not only functional, but also operationally controlled. It proves ingestion selectivity, safe file lifecycle handling, Upsert correctness, metadata enrichment, and traceable monitoring behavior.
