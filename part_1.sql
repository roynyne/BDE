----------------------------PART_1----------------------------


-- Create a new database named 'assignment_1'
CREATE DATABASE assignment_1;

-- Switch to the newly created database 'assignment_1'
USE DATABASE assignment_1;

-- Create a stage for data loading from an Azure Blob Storage location in "utsbderoy"
CREATE OR REPLACE STAGE stage_assignment
URL='azure://utsbderoy.blob.core.windows.net/assignment1'
CREDENTIALS=(AZURE_SAS_TOKEN='?sv=2022-11-02&ss=b&srt=co&sp=rwdlaciytfx&se=2024-12-31T07:40:34Z&st=2024-08-27T00:40:34Z&spr=https&sig=9CG3XucEcpoux1bUupMy2edoLLhIwTSNoInAsIq1%2FNI%3D')
;

-- List the files available in the specified stage
list @stage_assignment;

-- Define a file format for loading CSV files
CREATE OR REPLACE FILE FORMAT file_format_csv
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
NULL_IF = ('\\N', 'NULL', 'NUL', '')
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
;

-- Create an external table for the YouTube trending data, referencing files in the stage
CREATE OR REPLACE EXTERNAL TABLE ex_table_youtube_trending
WITH LOCATION = @stage_assignment
FILE_FORMAT = file_format_csv
PATTERN = '.*[.]csv';

-- Preview the first 10 rows of the external table
SELECT * FROM ASSIGNMENT_1.PUBLIC.ex_table_youtube_trending
LIMIT 10;

-- Select specific columns from the JSON-like data structure in the external table
SELECT
value:c1::varchar as VIDEO_ID,
value:c2::varchar as TITLE,
value:c3::varchar as PUBLISHEDAT,
value:c4::varchar as CHANNELID,
value:c5::varchar as CHANNELTITLE,
value:c6::varchar as CATEGORYID,
value:c7::varchar as TRENDING_DATE,
value:c8::varchar as VIEW_COUNT,
value:c9::varchar as LIKES,
value:c10::varchar as DISLIKES
FROM ex_table_youtube_trending
LIMIT 10;

-- Retrieve the metadata filename for each row in the external table
SELECT
metadata$filename
FROM ex_table_youtube_trending;

-- Extract the country information from the filename
SELECT
split_part(split_part(metadata$filename, '_', 1), '.', 1) AS country
FROM ex_table_youtube_trending;


-- Select columns, cast types appropriately, and include country information extracted from the filename
SELECT
value:c1::varchar as VIDEO_ID,
value:c2::varchar as TITLE,
value:c3::date as PUBLISHEDAT,
value:c4::varchar as CHANNELID,
value:c5::varchar as CHANNELTITLE,
value:c6::int as CATEGORYID,
value:c7::date as TRENDING_DATE,
value:c8::int as VIEW_COUNT,
value:c9::int as LIKES,
value:c10::int as DISLIKES,
split_part(split_part(metadata$filename, '_', 1), '.', 1)::varchar AS country
FROM ex_table_youtube_trending;


-- Create a new table to store the processed YouTube trending data
CREATE OR REPLACE TABLE table_youtube_trending as
SELECT
value:c1::varchar as VIDEO_ID,
value:c2::varchar as TITLE,
value:c3::date as PUBLISHEDAT,
value:c4::varchar as CHANNELID,
value:c5::varchar as CHANNELTITLE,
value:c6::int as CATEGORYID,
value:c7::date as TRENDING_DATE,
value:c8::int as VIEW_COUNT,
value:c9::int as LIKES,
value:c10::int as DISLIKES,
split_part(split_part(metadata$filename, '_', 1), '.', 1)::varchar AS COUNTRY
FROM ex_table_youtube_trending;


-- Verify the first 10 rows of the newly created table
SELECT *
FROM table_youtube_trending LIMIT 10;

-- Get the total number of rows in the 'table_youtube_trending' table
SELECT COUNT(*) FROM table_youtube_trending; --2,667,041 Rows


-- Create an external table for YouTube category data from JSON files in the specified stage
CREATE OR REPLACE EXTERNAL TABLE ex_table_youtube_category
WITH LOCATION = @stage_assignment
FILE_FORMAT = (TYPE=JSON)
PATTERN = '.*[.]json';

-- Preview the contents of the external table
SELECT *
FROM ex_table_youtube_category;

-- Extract category ID and title from the JSON structure using LATERAL FLATTEN
SELECT
l.value:id::varchar AS CATEGORYID,
l.value:snippet.title::varchar AS CATEGORY_TITLE,
FROM ex_table_youtube_category,
LATERAL FLATTEN(input => PARSE_JSON($1):items) l
;

-- Extract country information from the metadata filename and combine it with category data
SELECT
split_part(split_part(metadata$filename, '_', 1), '.', 1)::varchar AS COUNTRY,
l.value:id::varchar AS CATEGORYID,
l.value:snippet.title::varchar AS CATEGORY_TITLE
FROM 
ex_table_youtube_category,
LATERAL FLATTEN(input => PARSE_JSON($1):items) l;
    
-- Create a table to store processed YouTube category data
CREATE OR REPLACE TABLE table_youtube_category AS
SELECT
split_part(split_part(metadata$filename, '_', 1), '.', 1)::varchar AS COUNTRY,
l.value:id::varchar AS CATEGORYID,
l.value:snippet.title::varchar AS CATEGORY_TITLE
FROM 
ex_table_youtube_category,
LATERAL FLATTEN(input => PARSE_JSON($1):items) l;

    
-- Preview the first 10 rows of the newly created YouTube category table
SELECT * 
FROM table_youtube_category LIMIT 10;

-- Get the total number of rows in the 'table_youtube_category' table (311 rows after filtering)
SELECT COUNT(*) 
FROM table_youtube_category; --311 Rows


-- Create a final table combining YouTube trending and category data, adding a unique ID for each record using “UUID_STRING()” function
CREATE OR REPLACE TABLE table_youtube_final AS
SELECT
UUID_STRING() AS ID, 
yt.VIDEO_ID,
yt.TITLE, yt.PUBLISHEDAT, yt.CHANNELID, yt.CHANNELTITLE, yt.CATEGORYID,
yc.CATEGORY_TITLE, yt.TRENDING_DATE, yt.VIEW_COUNT, yt.LIKES, yt.DISLIKES,
yt.country AS COUNTRY
FROM
table_youtube_trending yt
LEFT JOIN
table_youtube_category yc
ON
yt.COUNTRY = yc.COUNTRY AND yt.CATEGORYID = yc.CATEGORYID;

-- Preview the first 10 rows of the final YouTube data table
SELECT * FROM table_youtube_final
LIMIT 10;

-- Get the total number of rows in the 'table_youtube_final' table
SELECT COUNT(*)
FROM table_youtube_final; --2,667,041 Rows
