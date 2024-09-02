--Q : If you were to launch a new Youtube channel tomorrow, which category (excluding “Music” and “Entertainment”) of video will you be trying to create to have them appear in the top trend of Youtube? Will this strategy work in every country?

--Analyze the data to identify which categories (excluding "Music" and "Entertainment") have the most distinct videos in the top trends.

SELECT 
CATEGORY_TITLE, 
COUNT(DISTINCT VIDEO_ID) AS distinct_video_count
FROM 
table_youtube_final
WHERE 
CATEGORY_TITLE NOT IN ('Music', 'Entertainment')  -- Exclude 'Music' and 'Entertainment' categories
GROUP BY 
CATEGORY_TITLE -- Group by category to count distinct videos per category
ORDER BY 
distinct_video_count DESC -- Order by the number of distinct videos in descending order
LIMIT 5; -- Limit the results to the top 5 categories

--Check Category Performance by Country

SELECT 
COUNTRY, 
CATEGORY_TITLE, 
COUNT(DISTINCT VIDEO_ID) AS distinct_video_count
FROM 
table_youtube_final
WHERE 
CATEGORY_TITLE NOT IN ('Music', 'Entertainment') -- Exclude 'Music' and 'Entertainment' categories
GROUP BY 
COUNTRY, CATEGORY_TITLE -- Group by country and category to see how categories perform in each country
ORDER BY 
distinct_video_count DESC; -- Order by the number of distinct videos in descending order
