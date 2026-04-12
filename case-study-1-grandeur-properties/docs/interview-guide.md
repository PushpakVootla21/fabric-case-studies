# Interview Guide – Grandeur Properties Case Study

## Purpose

This guide is designed as an end-to-end interview reference for the Grandeur Properties Microsoft Fabric case study.

Use it for:

- portfolio walkthroughs
- SME or architect interviews
- data engineering interviews
- mock review sessions
- demo preparation

It is written from the perspective of a strong Microsoft Fabric Data Engineering candidate explaining the solution to a senior interviewer.

---

## 1. Project Summary

### One-line summary

I built a Microsoft Fabric pipeline that ingests trusted office CSV files into a curated Lakehouse table using Upsert, validates schema before load, excludes sensitive fields, quarantines unsupported inputs, and applies archive-before-delete controls for safe file lifecycle handling.

### 30-second answer

This case study solves a file-based ingestion problem for a global real estate company. The pipeline identifies trusted `office_*.csv` inputs, validates the schema, loads approved business columns into a Lakehouse table using Upsert on `property_id`, excludes sensitive data from the analytics layer, archives valid files, quarantines invalid or unsupported files, and only deletes landing files after archive or quarantine succeeds.

### 2-minute answer

The business problem was that multiple offices were sending periodic CSV extracts of property listings, and manual handling created duplicate risk, weak auditability, and unsafe file management. I designed a Microsoft Fabric pipeline around a controlled landing zone, trusted file selection using the `office_*.csv` naming rule, schema validation before load, and a curated Lakehouse target table. The trusted load uses Upsert on `property_id` so new records insert and existing records update without full reloads. I added `insert_time` for ingestion traceability and intentionally excluded sensitive fields like `agent_personal_email` and `internal_crm_ref` from the trusted analytics table. Valid files follow landing to archive to delete, while schema-drift, wrongly named CSV, and non-CSV files follow landing to quarantine to delete. The result is a case-study implementation that is simple, explainable, and operationally safer than a blind wildcard load.

---

## 2. End-to-End Walkthrough

If an interviewer says "walk me through the pipeline end to end," use this order.

### Step 1. Landing intake

- Regional offices drop files into `Casestudy1/Landing/Incoming`
- The landing zone is a transient intake layer, not the analytics layer
- This keeps source delivery separate from curated analytical storage

### Step 2. File discovery

- `Get_Landing_Files` reads the folder contents
- The pipeline does not immediately trust every file in landing
- This is important because operational folders often receive unsupported or accidental files

### Step 3. Trusted file selection

- `Filter_Valid_Office_Csv` keeps only files that match `office_*.csv`
- This creates a trusted path for expected business inputs
- Wrongly named CSV files and non-CSV files are separated into exception handling paths

### Step 4. Schema validation

- Each trusted office file enters `ForEach_Valid_File`
- `Validate_File_Schema` runs before the trusted load
- If required columns are missing or renamed, the file does not reach the curated table
- Instead, it is quarantined for review

### Step 5. Curated Lakehouse load

- `Copy_to_LH` loads approved business columns only
- Upsert is used with `property_id` as the business key
- `insert_time` is added with `@utcNow()`
- Sensitive fields such as `agent_personal_email` and `internal_crm_ref` are excluded from the trusted load

### Step 6. Archive and cleanup for valid files

- Valid processed files move to `Casestudy1/Archive/Processed`
- `Delete_From_Landing` runs only after archive success
- This preserves replay and recovery capability

### Step 7. Quarantine handling for exception files

- Schema-drift files are quarantined
- Wrongly named CSV files are quarantined
- Non-CSV files are quarantined
- Files are deleted from landing only after quarantine succeeds

### Step 8. Notification

- Teams notification provides lightweight run visibility
- It is useful for demos and basic operational awareness
- It is not positioned as a complete monitoring framework

---

## 3. Why Each Design Decision Was Made

### Why use `office_*.csv`?

- It supports scalable onboarding of new offices without adding pipeline branches
- It enforces a simple naming contract
- It keeps the design easier to explain and maintain

### Why validate schema before load?

- File naming alone is not enough to trust a file
- A validly named file can still have missing or renamed columns
- Schema validation protects the curated Lakehouse table from bad structure

### Why use Upsert?

- Source files can contain both new and changed property records
- Full reload is unnecessary and less efficient for this use case
- Upsert on `property_id` is enough for a current-state analytical table

### Why exclude sensitive fields at ingestion time?

- It reduces exposure risk immediately
- It avoids loading sensitive data into the trusted analytics layer and removing it later
- It makes the privacy boundary explicit in the pipeline design

### Why archive before delete?

- It prevents accidental data loss during partial failures
- It preserves replay and investigation options
- It is a simple but important production-grade safety control

### Why quarantine unsupported files?

- Unsupported inputs should not silently disappear
- Quarantine preserves evidence and supports operator review
- It separates trusted business data from exception handling

### Why allow partial loads when an office file is missing?

- For the case study, ingestion continuity is prioritized
- Blocking all valid files because one office is missing would make the pipeline less practical
- I position expected-file monitoring as the next production improvement

---

## 4. Typical Interview Questions and Strong Answers

### Q1. What business problem does this pipeline solve?

It standardizes ingestion of global office-generated property listing files into a single curated Lakehouse table. It reduces duplicate risk, improves auditability, keeps sensitive fields out of analytics, and applies safe file lifecycle controls so processed files are archived or quarantined before deletion.

### Q2. Why is this a good fit for Microsoft Fabric?

Fabric lets me combine orchestration, Lakehouse storage, notebook-based validation, and monitoring-oriented activities in one platform. For a case study like this, it keeps the implementation cohesive and easier to demonstrate end to end.

### Q3. Why did you choose a Lakehouse target table?

The Lakehouse table is a clean curated layer for analytics and reporting. It supports a straightforward current-state data model, integrates naturally with Fabric orchestration, and works well for Upsert-based ingestion in this case study.

### Q4. How do you prevent duplicate data?

I use Upsert on `property_id`, so repeated business keys update instead of inserting duplicate rows. I also validate trusted files before load and keep unsupported files out of the curated path.

### Q5. How do you handle updated records?

If the same `property_id` appears again in a later valid office file, the Upsert logic updates the existing row in the target table. That gives me a current-state view of listings.

### Q6. Is this fully idempotent?

It is idempotent for a current-state case study in the sense that rerunning the same trusted business keys does not create duplicate rows. However, I would still distinguish between duplicate-resistant Upsert behavior and a more formal replay/manifest-controlled production idempotency model.

### Q7. Why did you keep `insert_time`?

`insert_time` gives me a pipeline-side ingestion timestamp. That improves operational traceability and helps explain when the curated record was last loaded.

### Q8. Why didn’t you load personal email and internal CRM reference values?

Those are not needed in the trusted analytics layer for this case study. Excluding them at ingestion time reduces exposure and keeps the Lakehouse table aligned to analytical business attributes only.

### Q9. How do you handle schema drift?

Trusted office files are validated before the trusted load. If required columns are missing or renamed, the file is quarantined instead of loaded. That keeps the curated table protected while still preserving the file for remediation.

### Q10. How do you handle bad file names?

Files that are still CSV but do not follow the `office_*.csv` contract are not treated as trusted inputs. They are routed to quarantine and deleted from landing only after quarantine succeeds.

### Q11. How do you handle non-CSV files?

They are explicitly separated from the trusted ingestion path and quarantined. This prevents unsupported files from entering the curated workflow.

### Q12. What happens if archive fails after the load succeeds?

The landing file is not deleted. That is an intentional dependency-chain safety control. It means the run may be partially complete, but the source file remains available for investigation or replay.

### Q13. What happens if an office file is missing?

The pipeline processes the available valid files and treats the result as a partial load. For the case study, that is acceptable. In a stronger production model, I would add expected-office monitoring and explicit completeness alerts.

### Q14. How would you scale this?

The naming rule already supports onboarding new offices without pipeline redesign as long as they follow the contract. Beyond that, I would move toward source registration, control tables, expected-file monitoring, and better per-file logging.

### Q15. What would you improve first for production?

My first improvements would be expected-office completeness monitoring, better alerting for quarantined files and archive failures, and a per-file run log or manifest to strengthen replay and supportability.

---

## 5. Challenge-by-Challenge Interview Answers

### Singapore expansion

If a new office starts sending `office_singapore.csv` with the same schema, the current pipeline picks it up automatically. That is one of the advantages of the trusted wildcard naming contract.

### Late correction

If a corrected record arrives with the same `property_id`, Upsert updates the existing row. For this case study, that is enough because the target is current-state rather than historical.

### Schema drift

Schema drift does not enter the trusted table. The file is quarantined for review. This is one of the most important controls because naming alone is not enough to trust a file.

### Broken chain / archive failure

The delete step is dependent on archive or quarantine success. So if archive fails, the source file remains in landing and the design avoids unsafe deletion.

### Missing office file

The current design continues with available valid files. I present that as a continuity-first decision for the case study and a candidate area for future completeness monitoring.

### Different file name

Wrongly named CSV files do not enter the trusted load path. They are quarantined because they violate the naming contract.

### Non-CSV file

Unsupported formats are quarantined so they remain outside the curated path and can be reviewed by operators.

---

## 6. Production Gaps You Should Mention Honestly

Interviewers usually appreciate honest and well-framed limits. These are the strongest ones to mention.

- The current design is production-aware, but not a full enterprise control framework
- Teams notification is lightweight visibility, not a full monitoring stack
- Missing-office handling is defined, but not yet supported by expected-file alerts
- Per-file run logging can be stronger
- Upsert gives current-state behavior, but not historical change tracking
- Replay and recovery are supported operationally by archive/quarantine retention, but not yet by a formal manifest or control table

### How to explain these gaps clearly

#### Teams is not full observability

The Teams step gives useful run visibility, but observability in a stronger production environment usually means centralized logs, failure alerts, trend monitoring, dashboards, and searchable run history. So I describe Teams as lightweight operational visibility, not a complete monitoring solution.

#### Expected-office monitoring is not yet implemented

The pipeline processes whatever valid `office_*.csv` files arrive, but it does not formally check whether every expected office submitted a file for that run window. So if one office is missing, the pipeline still completes as a partial refresh, but there is no explicit completeness alert yet.

#### Per-file run logging can be stronger

The design controls the file flow correctly, but it does not yet maintain a strong centralized file-level log with details such as file name, run ID, status, row counts, quarantine reason, archive path, and processing timestamp. In production, that kind of file-level audit trail makes support and troubleshooting much easier.

#### Replay is supported operationally, but not through a formal manifest or control table

Replay is possible because files are preserved in archive or quarantine, so an operator can investigate and reprocess them if needed. But the design does not yet use a manifest or control table that records exactly which files were picked up in a run, which ones succeeded, which ones failed, and which ones are safe to replay. That means recovery is supported, but it is still more manual than formal.

#### Upsert supports current state, not history

Upsert on `property_id` gives a current-state analytical table. That is good for reporting on the latest version of each property, but it overwrites old values. So if the business later asks for historical comparisons or record-version history, the current design would need to be extended beyond a simple Type 1 Upsert pattern.

If asked whether the design is production-ready, a strong answer is:

It is production-minded and operationally safer than a naive file load, but I would still add completeness monitoring, stronger exception logging, and a clearer recovery/run-control model before calling it enterprise-hardened.

---

## 7. Demo Script You Can Use Live

### Opening

I’ll walk you through how I used Microsoft Fabric to build a controlled file-ingestion pipeline for a global property listings use case.

### Demo flow

1. Show the landing folder with a mix of files
2. Point out trusted `office_*.csv` files and exception files
3. Open the pipeline canvas and explain the control-flow branches
4. Show the schema-validation notebook step
5. Show the trusted load mapping and explain PII exclusion
6. Show the Lakehouse output
7. Show archive and quarantine folders
8. Show landing cleanup behavior
9. Show Teams notification
10. Close with the key production improvements you would add next

### Closing line

The key thing I wanted to demonstrate was not just loading CSVs, but building a controlled Fabric pipeline that handles trusted data, unsupported data, sensitive fields, and operational safety in a realistic way.

---

## 8. Tricky Questions and Safe Answers

### "Why not just use one wildcard copy activity?"

Because a blind wildcard load is too trusting. I wanted a control layer that separates trusted office inputs from unsupported or malformed inputs before data reaches the curated table.

### "Why not fail the whole pipeline if one office file is missing?"

That depends on business expectations. For this case study, I chose continuity-first behavior so valid files are not blocked by one missing delivery. I would add expected-office monitoring if the business required completeness guarantees.

### "Why not keep PII and mask it later?"

Because loading sensitive data into the trusted analytics table expands the exposure surface. Excluding it at ingestion time is a cleaner privacy boundary.

### "Why didn’t you implement a full logging framework?"

I kept the case study scoped and explainable, but I explicitly called out per-file logging and stronger observability as the next hardening step. I wanted the repo to be honest about what is implemented today versus what would be added next.

### "Is Upsert on `property_id` enough?"

For a current-state target, yes. If the business needed history, auditing of changes over time, or deterministic freshness rules across conflicting updates, I would extend the design beyond a simple Type 1 Upsert.

---

## 9. What Not to Say

- Do not say the design is fully enterprise-complete
- Do not claim Teams is full observability
- Do not say wildcard naming alone guarantees trust
- Do not say schema drift is solved forever
- Do not say missing-office partial load is always acceptable for every business

Better phrasing:

- "For this scoped case study, the design is intentionally simple but controlled"
- "This is production-minded, with clear next steps for hardening"
- "The trusted path is protected by naming plus schema validation, not naming alone"

---

## 10. Final Close

If an interviewer asks for your final assessment of the project, use this:

This case study demonstrates a solid Microsoft Fabric ingestion pattern with trusted file selection, schema validation, curated Upsert loading, PII exclusion, quarantine handling, and archive-before-delete safety. It is intentionally scoped to stay explainable, but it still reflects real production concerns such as data quality, privacy, operational control, and recovery. The clearest next improvements would be expected-file monitoring, stronger exception logging, and more formal replay controls.
