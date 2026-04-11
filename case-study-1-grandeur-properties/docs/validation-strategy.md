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

## Pre-Run Setup

Before running the validation, confirm the following:

- The target table `grandeur.dailyupdate` exists in the Lakehouse
- The landing, archive, and quarantine folders exist
- The pipeline uses explicit mappings for the curated columns
- The pipeline adds `insert_time` using `@utcNow()`
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
- The file is routed according to the non-CSV handling branch, if implemented
- If a non-CSV branch is not implemented, the file should remain untouched and this behavior should be documented

## Test Scenario 4: Upsert Update Behavior

### Input

1. Run the pipeline with a valid office file containing a new `property_id`
2. Run the pipeline again with a valid office file containing the same `property_id` and updated business values

### Expected Result

- The target table keeps a single row for that `property_id`
- The latest values overwrite the prior values according to Upsert behavior
- `insert_time` reflects the most recent successful ingestion of that record

## Test Scenario 5: Archive-Before-Delete Control

### Input

- Simulate or observe a run where archive or quarantine copy does not succeed

### Expected Result

- The landing file is not deleted
- The pipeline shows a partial or failed operational state
- The run can be investigated without losing the original source file

## SQL Validation Queries

Use the SQL checks in `sql/validation_queries.sql` after pipeline execution to validate:

- Total row count
- Distinct `property_id` count
- Null `insert_time` count
- Duplicate `property_id` count
- Known update checks for selected records

## Demo Walkthrough Sequence

For a portfolio or interview demo, use this sequence:

1. Show the landing, archive, and quarantine folders before execution
2. Show a valid file and an unexpected file in landing
3. Trigger the pipeline
4. Show the pipeline run status
5. Show the Lakehouse table results
6. Run the SQL validation queries
7. Show the archive and quarantine folders
8. Show that landing has been cleared according to the implemented control flow
9. Show the Microsoft Teams notification with pipeline name, pipeline ID, run ID, timestamp, and status

## Evidence to Capture

Capture screenshots or logs for the following:

- Pipeline design
- Successful pipeline run
- Lakehouse table contents
- Archive folder contents
- Quarantine folder contents
- Empty or controlled landing state after completion
- Teams notification with resolved run metadata

## Conclusion

This validation playbook helps demonstrate that the pipeline is not only functional, but also operationally controlled. It proves ingestion selectivity, safe file lifecycle handling, Upsert correctness, metadata enrichment, and traceable monitoring behavior.
