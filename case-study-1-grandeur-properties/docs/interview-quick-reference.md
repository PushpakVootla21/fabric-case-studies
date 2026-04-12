# Interview Quick Reference – Grandeur Properties

## Best Opening

I built a Microsoft Fabric pipeline that ingests trusted `office_*.csv` files into a curated Lakehouse table using Upsert, validates schema before load, excludes sensitive fields, quarantines unsupported inputs, and only deletes landing files after archive or quarantine succeeds.

## End-to-End Flow

1. Files land in `Casestudy1/Landing/Incoming`
2. `Get_Landing_Files` reads the folder
3. `Filter_Valid_Office_Csv` keeps trusted `office_*.csv`
4. `Validate_File_Schema` protects the trusted load path
5. `Copy_to_LH` loads approved business columns only
6. Upsert uses `property_id`
7. `insert_time` is added with `@utcNow()`
8. Valid files go to archive, then delete
9. Schema-drift, wrong-name CSV, and non-CSV files go to quarantine, then delete
10. Teams notification provides lightweight run visibility

## Key Talking Points

- Trusted path is based on naming plus schema validation
- Sensitive fields are excluded at ingestion time
- Current-state Lakehouse design uses Upsert, not full reload
- Archive-before-delete prevents unsafe cleanup
- Quarantine preserves unsupported files for operator review
- Missing office files result in controlled partial loads

## What Was Implemented

- Valid `office_*.csv` ingestion
- Schema validation before trusted load
- Upsert on `property_id`
- `insert_time` ingestion timestamp
- PII exclusion from trusted load
- Schema-drift quarantine
- Different file name quarantine
- Non-CSV quarantine
- Archive-before-delete safety
- Partial-load behavior when an office file is missing

## Top Strengths

- Simple and explainable Fabric architecture
- Safer than a blind wildcard load
- Good case-study balance between simplicity and operational credibility
- Stronger privacy story because sensitive fields never enter the trusted table

## Honest Gaps to Mention

- Teams is not full observability
- Expected-office monitoring is not yet implemented
- Per-file run logging can be stronger
- Replay is supported operationally, but not via a formal manifest/control table
- Upsert supports current state, not history

## How to Explain Those Gaps Quickly

- Teams is useful run visibility, but not a full monitoring framework with centralized logs, alerts, and dashboards.
- Expected-office monitoring is not yet implemented, so the pipeline allows partial loads when one office file is missing.
- Per-file run logging can be stronger because the current design does not yet keep a full centralized file-level audit trail.
- Replay is operationally possible from archive or quarantine, but not yet controlled by a manifest or control table.
- Upsert keeps the latest version of each property record, but it does not preserve historical versions.

## Best Answers to Common Questions

### Why Upsert?

Because files can contain both new and updated property records, and I wanted a current-state target without full reloads.

### Why schema validation?

Because file naming alone is not enough to trust a file. Schema validation protects the curated table from malformed or drifted inputs.

### Why exclude PII during load?

Because it reduces exposure risk immediately and keeps the analytics layer intentionally limited to business-safe columns.

### What happens if archive fails?

Delete does not run, so the source file remains in landing for investigation or replay.

### What happens if one office file is missing?

The pipeline still processes available valid files and treats the run as a partial refresh.

## Strong Closing

This project shows that I can use Microsoft Fabric not just to move files, but to design a controlled ingestion pattern with validation, privacy boundaries, exception handling, and operational safety.
