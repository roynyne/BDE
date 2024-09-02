----------------------------PART_1----------------------------


--Q1 : What are the 3 most viewed videos for each country in the Gaming category for the trending_date = ‘'2024-04-01. Order the result by country and the rank, e.g:

SELECT COUNTRY, TITLE, CHANNELTITLE, VIEW_COUNT, RK
FROM (
SELECT 
COUNTRY, TITLE, CHANNELTITLE, VIEW_COUNT,
-- Rank the videos within each country based on view count, highest first
ROW_NUMBER() OVER (PARTITION BY COUNTRY ORDER BY VIEW_COUNT DESC) AS RK
FROM 
table_youtube_final
WHERE 
CATEGORY_TITLE = 'Gaming' -- Filter for the Gaming category
AND TRENDING_DATE = '2024-04-01' -- Filter for the specific trending date
) ranked_videos
WHERE 
RK <= 3 -- Only keep the top 3 videos for each country
ORDER BY 
COUNTRY, RK -- Order the results by country and rank
LIMIT 6; -- Limit the output to the first 6 rows as an example


--Q2 : For each country, count the number of distinct video with a title containing the word “BTS” (case insensitive) and order the result by count in a descending order, e.g:

SELECT 
COUNTRY, 
COUNT(DISTINCT VIDEO_ID) AS video_count
FROM 
table_youtube_final
WHERE 
LOWER(TITLE) LIKE '%bts%'  -- search for 'bts'
GROUP BY 
COUNTRY -- Group by country to get counts per country
ORDER BY 
video_count DESC; -- Order the results by video count in descending order


--Q3 : For each country, year and month (in a single column) and only for the year 2024, which video is the most viewed and what is its likes_ratio (defined as the percentage of likes against view_count) truncated to 2 decimals. Order the result by year_month and country. The output should like this:

SELECT 
COUNTRY, 
TO_CHAR(TRENDING_DATE, 'YYYY-MM') AS YEAR_MONTH, -- Extract year and month from the trending date
TITLE, 
CHANNELTITLE, 
CATEGORY_TITLE, 
VIEW_COUNT, 
TRUNC((LIKES::NUMERIC / VIEW_COUNT) * 100, 2) AS LIKES_RATIO -- Calculate the likes ratio and truncate to 2 decimals
FROM (
SELECT 
COUNTRY, TITLE, CHANNELTITLE, CATEGORY_TITLE, VIEW_COUNT, LIKES, TRENDING_DATE,
-- Rank the videos within each country and month based on view count
ROW_NUMBER() OVER (PARTITION BY COUNTRY, TO_CHAR(TRENDING_DATE, 'YYYY-MM') 
ORDER BY VIEW_COUNT DESC) AS RN
FROM table_youtube_final
WHERE 
EXTRACT(YEAR FROM TRENDING_DATE) = 2024 -- Filter for the year 2024
)
WHERE 
RN = 1 -- Only keep the most viewed video for each country and month
ORDER BY 
YEAR_MONTH, COUNTRY; -- Order by year_month and country


--Q4 : For each country, which category_title has the most distinct videos and what is its percentage (2 decimals) out of the total distinct number of videos of that country? Only look at the data from 2022. Order the result by category_title and country.

WITH category_counts AS (
-- Calculate the total distinct videos per category per country
SELECT 
COUNTRY, CATEGORY_TITLE, COUNT(DISTINCT VIDEO_ID) AS TOTAL_CATEGORY_VIDEO
FROM table_youtube_final
WHERE TRENDING_DATE >= '2022-01-01' -- Filter for data from the year 2022
GROUP BY COUNTRY, CATEGORY_TITLE
), total_country_counts AS (
-- Calculate the total distinct videos per country
SELECT 
COUNTRY, COUNT(DISTINCT VIDEO_ID) AS TOTAL_COUNTRY_VIDEO
FROM table_youtube_final
WHERE TRENDING_DATE >= '2022-01-01' -- Filter for data from the year 2022
GROUP BY COUNTRY
)
SELECT cc.COUNTRY, cc.CATEGORY_TITLE, cc.TOTAL_CATEGORY_VIDEO, tcc.TOTAL_COUNTRY_VIDEO,
-- Calculate the percentage of the category's distinct videos out of the total distinct videos for the country
TRUNC((cc.TOTAL_CATEGORY_VIDEO::NUMERIC / tcc.TOTAL_COUNTRY_VIDEO) * 100, 2) AS PERCENTAGE
FROM category_counts cc
JOIN total_country_counts tcc
ON cc.COUNTRY = tcc.COUNTRY
WHERE 
-- Find the category with the maximum distinct videos for each country
cc.TOTAL_CATEGORY_VIDEO = (
SELECT MAX(TOTAL_CATEGORY_VIDEO)
FROM category_counts c
WHERE c.COUNTRY = cc.COUNTRY
    )
ORDER BY cc.CATEGORY_TITLE, cc.COUNTRY;


--Q5 : Which channeltitle has produced the most distinct videos and what is this number? 

SELECT CHANNELTITLE, COUNT(DISTINCT VIDEO_ID) AS distinct_video_count
FROM table_youtube_final
GROUP BY CHANNELTITLE -- Group by channel title to count distinct videos per channel
ORDER BY distinct_video_count DESC -- Order by the count of distinct videos in descending order
LIMIT 1; -- Limit to the top channel
-- Vijay Television with 2049 Distinct Video Count
