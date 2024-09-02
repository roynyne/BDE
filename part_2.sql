----------------------------PART_2----------------------------


--Q1 : In “table_youtube_category” which category_title has duplicates if we don’t take into account the categoryid (return only a single row)?

SELECT CATEGORY_TITLE
FROM table_youtube_category
GROUP BY CATEGORY_TITLE
HAVING COUNT(*) > 1
LIMIT 1;


--Q2 : In “table_youtube_category” which category_title only appears in one country?

SELECT category_title
FROM table_youtube_category
GROUP BY category_title
HAVING COUNT(DISTINCT country) = 1;


--Q3 : In “table_youtube_final”, what is the categoryid of the missing category_titles?

SELECT DISTINCT CATEGORYID
FROM table_youtube_final
WHERE category_title IS NULL;


--Q4 : Update the table_youtube_final to replace the NULL values in category_title with the answer from the previous question.

-- First, replace NULL with 'Unknown'.
UPDATE table_youtube_final
SET category_title = 'Unknown'
WHERE category_title IS NULL;

-- Then, update 'Unknown' to '29' if needed (assuming '29' is the placeholder for the missing categories).
UPDATE table_youtube_final
SET category_title = '29'
WHERE category_title = 'Unknown';

-- Verify the update by selecting rows where CATEGORY_TITLE is '29'.
SELECT *
FROM table_youtube_final WHERE CATEGORY_TITLE = '29';


--Q5 : In “table_youtube_final”, which video doesn’t have a channeltitle (return only the title)?

SELECT Title
FROM table_youtube_final
WHERE Channeltitle IS NULL;


--Q6 : Delete from “table_youtube_final“, any record with video_id = “#NAME?”

-- First, identify records with video_id = '#NAME?'.
SELECT *
FROM table_youtube_final
WHERE video_id = '#NAME?';

-- Then, delete those records.
DELETE FROM table_youtube_final
WHERE video_id = '#NAME?';


--Q7 : Create a new table called “table_youtube_duplicates”  containing only the “bad” duplicates by using the row_number() function.

-- A "bad" duplicate is defined as having the same video_id, country, and trending_date, with lower view_count.
CREATE OR REPLACE TABLE table_youtube_duplicates AS
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY video_id, country, trending_date ORDER BY view_count DESC) AS rn
    FROM table_youtube_final
) t
WHERE t.rn > 1;

-- Verify the content of "table_youtube_duplicates".
SELECT * 
FROM 
table_youtube_duplicates
LIMIT 10;

--Q8 : Delete the duplicates in “table_youtube_final“ by using “table_youtube_duplicates”.

-- First, check the number of records before deleting duplicates.
SELECT COUNT(*) FROM table_youtube_final; --2,634,960 Rows

-- Check the number of bad duplicates.
SELECT COUNT(*)
FROM table_youtube_duplicates; --37,466 (2,634,960 - 37,466 = 2,597,494 Rows Expected)

-- Create a backup table to store the unique records.
CREATE OR REPLACE TABLE backup_table AS
SELECT *
FROM (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY VIDEO_ID, COUNTRY, TRENDING_DATE ORDER BY VIEW_COUNT DESC) AS rn
FROM table_youtube_final
)
WHERE rn = 1;

-- Replace the original "table_youtube_final" with the cleaned data from "backup_table".
CREATE OR REPLACE TABLE table_youtube_final AS
SELECT * 
FROM backup_table;

-- Verify the new row count after removing duplicates.
SELECT COUNT(*) FROM table_youtube_final; --2,597,494 Rows

-- Final check of the cleaned "table_youtube_final".
SELECT * FROM table_youtube_final;
