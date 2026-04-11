# SME Playbook – Case Study 1 (Grandeur Properties)

## Objective

Design a production-grade Microsoft Fabric pipeline to ingest global property listing data reliably and efficiently.

---

## Pipeline Overview

The pipeline performs:

1. Ingest files from Landing zone using wildcard pattern
2. Load data into Lakehouse using Upsert
3. Add ingestion timestamp (`insert_time`)
4. Archive processed files
5. Delete files from Landing only after archive success
6. Send notification on success

---

## Design Principles

### Idempotency

* Re-running pipeline should not create duplicates
* Achieved using Upsert with `property_id`

---

### Data Integrity

* No duplicate records
* Latest data overwrites previous state

---

### Auditability

* Each record contains `insert_time`
* Enables tracking of ingestion

---

### File Lifecycle

Landing → Archive → Delete

* Archive ensures recoverability
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

---

## Production Goals

* Reliable ingestion
* No data loss
* Clear audit trail
* Easy troubleshooting
* Scalable design
