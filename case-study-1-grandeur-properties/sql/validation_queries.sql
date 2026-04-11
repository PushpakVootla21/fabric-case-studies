-- Total row count
SELECT COUNT(*) AS total_rows
FROM granduer.dailyupdate;

-- Unique property_id count
SELECT COUNT(DISTINCT property_id) AS unique_property_ids
FROM granduer.dailyupdate;

-- Null timestamp check
SELECT COUNT(*) AS null_ingestion_timestamps
FROM granduer.dailyupdate
WHERE insert_time IS NULL;

-- Duplicate property_id check
SELECT property_id, COUNT(*) AS cnt
FROM granduer.dailyupdate
GROUP BY property_id
HAVING COUNT(*) > 1;

-- Check Day 2 change 1
SELECT property_id, offer_received
FROM granduer.dailyupdate
WHERE property_id = 'GB-BLG-19001';

-- Check Day 2 change 2
SELECT property_id, viewings_completed
FROM granduer.dailyupdate
WHERE property_id = 'AE-PLM-18901';

-- Check Day 2 change 3
SELECT property_id, listing_price
FROM granduer.dailyupdate
WHERE property_id = 'US-PKA-35001';