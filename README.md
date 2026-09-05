# Microsoft Fabric Case Studies

Portfolio-focused Microsoft Fabric implementation case studies covering Lakehouse ingestion, validation-first data quality, and production-style pipeline design.

## Available Projects

### [Validation-First Lakehouse Ingestion — Grandeur Properties](./case-study-1-grandeur-properties/README.md)

A Fabric Data Factory pipeline that discovers `office_*.csv` extracts, validates schema before load in a Fabric Notebook, upserts approved records into a curated Lakehouse table keyed on `property_id`, and routes schema-drift or unsupported files to quarantine — with archive-before-delete file lifecycle handling.

📄 [Live case study](https://pushpakvootla.cloud/projects/validation-first-fabric-lakehouse-ingestion) · 🗂️ [Pipeline JSON](./case-study-1-grandeur-properties/pipeline-json/pl_casestudy_1.json) · 📓 [Docs](./case-study-1-grandeur-properties/docs)
