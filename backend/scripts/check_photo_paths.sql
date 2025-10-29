-- Check photo paths in database
-- Run with: psql -U auto_tm -d auto_tm -f scripts/check_photo_paths.sql

-- See all photo paths
SELECT 
    uuid,
    path,
    "originalPath",
    "createdAt"
FROM photos 
ORDER BY "createdAt" DESC 
LIMIT 5;

-- Count photos with backslashes (old format)
SELECT 
    COUNT(*) as total_photos,
    SUM(CASE WHEN path::text LIKE '%\\%' THEN 1 ELSE 0 END) as with_backslashes,
    SUM(CASE WHEN path::text LIKE '%/uploads/%' THEN 1 ELSE 0 END) as normalized
FROM photos;
