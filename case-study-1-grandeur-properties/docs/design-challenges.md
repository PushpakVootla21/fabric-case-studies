# Design Challenges

## Project

**Grandeur Properties Global Listing Intelligence Pipeline**

This document outlines the scoped Microsoft Fabric pipeline design challenges for the Grandeur Properties case study. Each challenge is written in a practical, interview-ready format that explains the current pipeline behavior, the design implications, and the recommended improvement path.

## 1. Singapore Expansion

### Scenario

Grandeur Properties opens a new Singapore office and starts dropping a file named `office_singapore.csv` into the landing area.

### What Happens in the Current Pipeline

The current pipeline uses the wildcard pattern `office_*.csv`, so the Singapore file is automatically included in ingestion as long as it follows the same schema and naming convention as the existing office files.

The Copy activity reads the file, loads approved columns into the Lakehouse table, applies Upsert using `property_id`, adds the ingestion timestamp, and continues with archive and delete steps in the normal sequence.

### Whether Pipeline Change Is Required

No pipeline change is required if Singapore follows the existing file contract.

### Risks

- The file may use a different column structure or naming standard than other offices
- Regional data conventions may differ, such as address formats or currency representation
- A naming deviation such as `singapore_office.csv` would prevent pickup by the wildcard rule

### Better Future Improvement

Introduce a formal source onboarding checklist with schema validation and naming convention checks before a new office goes live. A metadata-driven configuration layer could also be added so new offices can be registered through configuration rather than relying only on file naming discipline.

## 2. Late Correction

### Scenario

An office submits a corrected version of a property record after the original file has already been processed. For example, a listing price or availability status is updated after the initial load.

### What Happens in the Current Pipeline

If the corrected record arrives in a later file with the same `property_id`, the current pipeline Upsert logic updates the existing Lakehouse record. This allows the latest version of the business entity to overwrite the earlier version in the curated table.

The pipeline ingestion timestamp will also reflect when the corrected version was loaded.

### Whether Pipeline Change Is Required

No immediate pipeline change is required for basic correction handling, because Upsert already supports record updates.

### Risks

- The current design may overwrite previous values without preserving a full change history
- It may be difficult to distinguish source-system correction time from pipeline ingestion time
- Auditors or analysts may need historical record versions, which the current target design may not retain

### Better Future Improvement

Add change-history support through audit columns or a slowly changing dimension pattern, depending on reporting needs. This would allow the business to keep both the current state and the prior state of a property record when corrections arrive late.

## 3. Schema Drift

### Scenario

One office adds a new column to its CSV extract or changes an existing column name or order without coordination.

### What Happens in the Current Pipeline

The current pipeline validates trusted office files before `Copy_to_LH`. If schema drift occurs, the file does not enter the curated load path and is routed to quarantine for review.

### Whether Pipeline Change Is Required

No immediate pipeline change is required for the scoped case study, because schema validation and quarantine handling already protect the trusted load path.

### Risks

- Drifted files still require manual review before correction or replay
- Downstream reporting can be incomplete if an office file is quarantined and not quickly remediated
- Additional support effort is required when source teams change extracts independently

### Better Future Improvement

Add stronger alerting, rejected-file logging, and a more formal schema evolution process so quarantined schema-drift files are surfaced and resolved faster.

## 4. Broken Chain / Archive Failure

### Scenario

The data load into the Lakehouse completes successfully, but the archive activity fails because of a permissions issue, path error, or temporary storage problem.

### What Happens in the Current Pipeline

The pipeline is designed so that the delete step runs only after archive success. If the archive activity fails, the landing files are not deleted.

This means the pipeline stops in a partially completed state:

- Data may already exist in the Lakehouse table
- Source files remain in the landing area
- Cleanup does not complete

### Whether Pipeline Change Is Required

No immediate structural change is required, because the current dependency logic already protects against unsafe deletion. However, operational handling should be improved.

### Risks

- The same landing file could be reprocessed on rerun if there is no replay control
- Duplicate updates or repeated ingestion attempts may occur
- Operators may need manual intervention to determine whether the file should be archived, replayed, or quarantined
- Partial success can create confusion if monitoring is weak

### Better Future Improvement

Add stronger operational resilience through retry policies, failure alerts, file status logging, and idempotent replay controls. A quarantine area for archive failures would also help separate recoverable operational issues from normal processing.

## 5. Missing Office File

### Scenario

One expected office file does not arrive for the scheduled pipeline run. For example, London and Dubai files are present, but the New York office file is missing.

### What Happens in the Current Pipeline

The current wildcard-based pipeline processes whatever files are available that match `office_*.csv`. If one office file is missing, the pipeline still runs against the available files.

This design favors ingestion continuity rather than blocking the entire load because of one missing contributor.

### Whether Pipeline Change Is Required

Not necessarily, depending on business expectations. If partial loads are acceptable, no change is required. If all offices must be present before reporting is refreshed, then additional control logic is needed.

### Risks

- Downstream users may assume the dataset is complete when one office is absent
- KPIs and executive reports may be understated or misleading
- Missing deliveries may go unnoticed if there is no expected-file monitoring

### Better Future Improvement

Add completeness checks based on expected office submissions for each run window. This could include control tables, delivery SLAs, alerting for missing files, and run-status indicators that clearly show whether the refresh is full or partial.

## 6. Different File Name

### Scenario

An office drops a CSV file that contains valid-looking data but uses the wrong name, such as `singapore_office.csv` or `manual_fix.csv`.

### What Happens in the Current Pipeline

Because the ingestion rule is based on the wildcard `office_*.csv`, a differently named file is not picked up by the trusted load path, is not loaded into the Lakehouse table, and is routed to quarantine for review.

### Whether Pipeline Change Is Required

No change is required for the scoped case study, because the current design already keeps differently named CSV files out of the trusted load path and routes them to quarantine.

### Risks

- Source teams may think the file was processed when it was not
- Missing data may go unnoticed if quarantine monitoring is weak
- Manual review is still required to decide whether the file should be renamed, replayed, or rejected

### Better Future Improvement

Add stronger alerting and exception logging around the quarantine branch so misnamed files are surfaced immediately to operators.

## 7. Non-CSV File Routing

### Scenario

A non-CSV file such as `notes.txt` or `readme.docx` is placed in the landing area.

### What Happens in the Current Pipeline

Because the ingestion rule only targets `office_*.csv`, non-CSV files are not loaded into the Lakehouse table and are instead routed to quarantine for controlled handling.

### Whether Pipeline Change Is Required

No change is required for the scoped case study, because the current implementation already keeps non-CSV files out of the trusted ingestion path and routes them to quarantine.

### Risks

- Landing folders may become cluttered with irrelevant files
- Support teams may still need manual intervention to classify and clean up non-business inputs
- Operators may not know the business intent of the file unless quarantine review is monitored closely

### Better Future Improvement

Add stronger exception categorization and alerting for quarantined non-CSV files so support teams can resolve them faster.

## Summary

These scoped challenges show that the current pipeline design is strong for a practical case study and covers core enterprise patterns such as wildcard ingestion, Upsert processing, PII exclusion, schema validation, archive-before-delete controls, and trusted-file selection through naming rules. At the same time, they highlight the next level of maturity required for production-scale data engineering:

- Better source onboarding governance
- Historical tracking for late corrections
- Stronger schema-drift monitoring and alerting
- Improved failure recovery and replay controls
- Completeness monitoring for expected file arrivals
- Stronger monitoring and alerting for quarantined misnamed and unsupported files

From an interview perspective, the key message is that the current design is intentionally simple but sound, while the future improvements show how the same architecture can evolve into a more robust enterprise-grade Microsoft Fabric pipeline.
