# SME Playbook – Case Study 1 (Grandeur Properties)

## Objective

Design a production-grade Microsoft Fabric pipeline to ingest global property listing data reliably and efficiently.

---

## Pipeline Overview

The pipeline performs:

1. Identify trusted office files using the `office_*.csv` naming rule
2. Validate trusted file schema before load
3. Load curated business columns into Lakehouse using Upsert
4. Exclude sensitive columns from the trusted analytics table
5. Add ingestion timestamp (`insert_time`)
6. Archive valid processed files
7. Route schema-drift, wrongly named CSV, and non-CSV files to quarantine
8. Delete files from Landing only after archive or quarantine success
9. Send notification on completion

---

## Design Principles

### Idempotency

* Re-running pipeline should not create duplicates
* Achieved using Upsert with `property_id`

---

### Data Integrity

* No duplicate records
* Latest data overwrites previous state
* Invalid or unsupported files do not enter the trusted Lakehouse table

---

### Auditability

* Each record contains `insert_time`
* Enables tracking of ingestion
* Quarantine handling preserves traceability for rejected or unsupported files

---

### File Lifecycle

Landing → Archive → Delete for valid files
Landing → Quarantine → Delete for unsupported files

* Archive ensures recoverability
* Quarantine isolates unsupported or drifted inputs
* Delete ensures clean ingestion zone

---

### Scalability

* Wildcard ingestion (`office_*.csv`)
* Supports new offices without changes

---

## Validation Strategy

### Day 1

* Row count = expected
* Unique property_id
* Timestamp present

### Day 2

* Updates reflected correctly
* No duplicates
* Row count stable

### Additional Input Handling

* Wrongly named CSV files should not enter the trusted Lakehouse path
* Non-CSV files should be quarantined
* Schema-drift office files should be quarantined

---

## Known Challenges

Refer to:
`docs/design-challenges.md`

---

## Expected Behavior

* Pipeline must handle:

  * new files automatically
  * corrected files via upsert
  * partial failures safely
  * repeated runs without duplication
  * unexpected file names safely
  * non-CSV files outside the curated load path
  * schema-drift files outside the curated load path

---

## Production Goals

* Reliable ingestion
* No data loss
* Clear audit trail
* Easy troubleshooting
* Scalable design

---

## Interview References

For interview preparation and portfolio walkthroughs, also use:

- `docs/interview-guide.md`
- `docs/interview-quick-reference.md`
