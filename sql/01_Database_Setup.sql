CREATE TABLE netflix_titles (
    show_id VARCHAR(20) PRIMARY KEY,
    type VARCHAR(20),
    title TEXT,
    director TEXT,
    cast_members TEXT,
    country TEXT,
    date_added DATE,
    release_year INT,
    rating VARCHAR(20),
    duration VARCHAR(50),
    listed_in TEXT,
    description TEXT
);

CREATE TABLE movies_engagement (
    source TEXT,
    report VARCHAR(20),
    title TEXT,
    available_globally VARCHAR(10),
    release_date DATE,
    hours_viewed BIGINT,
    runtime VARCHAR(50),
    views BIGINT,
    runtime_minutes NUMERIC
);

CREATE TABLE shows_engagement (
    source TEXT,
    report VARCHAR(20),
    title TEXT,
    available_globally VARCHAR(10),
    release_date DATE,
    hours_viewed BIGINT,
    runtime VARCHAR(50),
    views BIGINT,
    runtime_minutes NUMERIC
);

SELECT
    'Movies' AS content_type,
    COUNT(*) AS total_records,
    COUNT(DISTINCT title) AS unique_titles,
    ROUND(SUM(views) / 1000000.0, 2) AS total_views_millions,
    ROUND(SUM(hours_viewed) / 1000000.0, 2) AS total_hours_millions
FROM movies_engagement

UNION ALL

SELECT
    'TV Shows',
    COUNT(*),
    COUNT(DISTINCT title),
    ROUND(SUM(views) / 1000000.0, 2),
    ROUND(SUM(hours_viewed) / 1000000.0, 2)
FROM shows_engagement;

SELECT
    title,
    SUM(views) AS total_views,
    SUM(hours_viewed) AS total_hours_viewed
FROM (
    SELECT title, views, hours_viewed FROM movies_engagement
    UNION ALL
    SELECT title, views, hours_viewed FROM shows_engagement
) AS content
GROUP BY title
ORDER BY total_views DESC
LIMIT 10;


SELECT
    report,
    content_type,
    SUM(views) AS total_views,
    SUM(hours_viewed) AS total_hours_viewed
FROM (
    SELECT report, views, hours_viewed, 'Movies' AS content_type
    FROM movies_engagement

    UNION ALL

    SELECT report, views, hours_viewed, 'TV Shows'
    FROM shows_engagement
) AS engagement
GROUP BY report, content_type
ORDER BY report, content_type;



SELECT
    available_globally,
    COUNT(*) AS total_records,
    COUNT(DISTINCT title) AS unique_titles,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM (
    SELECT title, available_globally FROM movies_engagement
    UNION ALL
    SELECT title, available_globally FROM shows_engagement
) AS content
GROUP BY available_globally
ORDER BY total_records DESC; 





SELECT
    'Movies' AS content_type,
    ROUND(AVG(views), 2) AS avg_views,
    ROUND(AVG(hours_viewed), 2) AS avg_hours_viewed
FROM movies_engagement

UNION ALL

SELECT
    'TV Shows',
    ROUND(AVG(views), 2),
    ROUND(AVG(hours_viewed), 2)
FROM shows_engagement;



SELECT
    TRIM(genre) AS genre,
    COUNT(*) AS total_titles
FROM netflix_titles,
LATERAL unnest(string_to_array(listed_in, ',')) AS genre
WHERE listed_in <> 'Unknown'
GROUP BY TRIM(genre)
ORDER BY total_titles DESC
LIMIT 10;



SELECT
    type,
    COUNT(*) AS total_titles,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM netflix_titles
GROUP BY type
ORDER BY total_titles DESC;



SELECT
    EXTRACT(YEAR FROM date_added) AS year,
    COUNT(*) AS titles_added,
    COUNT(*) FILTER (WHERE type = 'Movie') AS movies_added,
    COUNT(*) FILTER (WHERE type = 'TV Show') AS shows_added
FROM netflix_titles
WHERE date_added IS NOT NULL
GROUP BY EXTRACT(YEAR FROM date_added)
ORDER BY year;


SELECT
    TRIM(country_name) AS country,
    COUNT(*) AS total_titles
FROM netflix_titles,
LATERAL unnest(string_to_array(country, ',')) AS country_name
WHERE country <> 'Unknown'
GROUP BY TRIM(country_name)
ORDER BY total_titles DESC
LIMIT 10;



SELECT
    rating,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY rating
ORDER BY total_titles DESC;


SELECT
    release_year,
    COUNT(*) AS total_titles,
    COUNT(*) FILTER (WHERE type = 'Movie') AS movies,
    COUNT(*) FILTER (WHERE type = 'TV Show') AS tv_shows
FROM netflix_titles
GROUP BY release_year
ORDER BY total_titles DESC
LIMIT 10;


SELECT
    COUNT(DISTINCT e.title) AS engagement_titles,
    COUNT(DISTINCT n.title) AS matched_catalog_titles
FROM (
    SELECT title FROM movies_engagement
    UNION
    SELECT title FROM shows_engagement
) e
LEFT JOIN netflix_titles n
    ON LOWER(TRIM(e.title)) = LOWER(TRIM(n.title));


SELECT
    'Movies' AS content_type,
    COUNT(DISTINCT e.title) AS engagement_titles,
    COUNT(DISTINCT n.title) AS matched_titles
FROM movies_engagement e
LEFT JOIN netflix_titles n
    ON LOWER(TRIM(e.title)) = LOWER(TRIM(n.title))

UNION ALL

SELECT
    'TV Shows',
    COUNT(DISTINCT e.title),
    COUNT(DISTINCT n.title)
FROM shows_engagement e
LEFT JOIN netflix_titles n
    ON LOWER(TRIM(e.title)) = LOWER(TRIM(n.title));


SELECT
    report,
    SUM(views) AS total_views,
    SUM(hours_viewed) AS total_hours_viewed
FROM (
    SELECT report, views, hours_viewed FROM movies_engagement
    UNION ALL
    SELECT report, views, hours_viewed FROM shows_engagement
) AS combined
GROUP BY report
ORDER BY report;


CREATE OR REPLACE VIEW vw_engagement_by_period AS
SELECT
    report,
    SUM(views) AS total_views,
    SUM(hours_viewed) AS total_hours_viewed
FROM (
    SELECT report, views, hours_viewed FROM movies_engagement
    UNION ALL
    SELECT report, views, hours_viewed FROM shows_engagement
) AS combined
GROUP BY report;


CREATE OR REPLACE VIEW vw_top_10_content AS
SELECT
    title,
    SUM(views) AS total_views,
    SUM(hours_viewed) AS total_hours_viewed
FROM (
    SELECT title, views, hours_viewed FROM movies_engagement
    UNION ALL
    SELECT title, views, hours_viewed FROM shows_engagement
) AS combined
GROUP BY title
ORDER BY total_views DESC
LIMIT 10;


CREATE OR REPLACE VIEW vw_content_type_distribution AS
SELECT
    type,
    COUNT(*) AS total_titles,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM netflix_titles
GROUP BY type;

CREATE OR REPLACE VIEW vw_top_genres AS
SELECT
    TRIM(genre) AS genre,
    COUNT(*) AS total_titles
FROM netflix_titles,
LATERAL unnest(string_to_array(listed_in, ',')) AS genre
WHERE listed_in <> 'Unknown'
GROUP BY TRIM(genre)
ORDER BY total_titles DESC
LIMIT 10;


CREATE OR REPLACE VIEW vw_country_distribution AS
SELECT
    TRIM(country_name) AS country,
    COUNT(*) AS total_titles
FROM netflix_titles,
LATERAL unnest(string_to_array(country, ',')) AS country_name
WHERE country <> 'Unknown'
GROUP BY TRIM(country_name)
ORDER BY total_titles DESC
LIMIT 10;

CREATE OR REPLACE VIEW vw_content_ratings AS
SELECT
    rating,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY rating
ORDER BY total_titles DESC;



CREATE OR REPLACE VIEW vw_content_added_trend AS
SELECT
    EXTRACT(YEAR FROM date_added)::INT AS year,
    COUNT(*) AS titles_added,
    COUNT(*) FILTER (WHERE type = 'Movie') AS movies_added,
    COUNT(*) FILTER (WHERE type = 'TV Show') AS shows_added
FROM netflix_titles
WHERE date_added IS NOT NULL
GROUP BY EXTRACT(YEAR FROM date_added)
ORDER BY year;



CREATE OR REPLACE VIEW vw_content_performance AS
SELECT
    'Movies' AS content_type,
    COUNT(*) AS total_records,
    COUNT(DISTINCT title) AS unique_titles,
    ROUND(AVG(views), 2) AS avg_views,
    ROUND(AVG(hours_viewed), 2) AS avg_hours_viewed
FROM movies_engagement

UNION ALL

SELECT
    'TV Shows',
    COUNT(*),
    COUNT(DISTINCT title),
    ROUND(AVG(views), 2),
    ROUND(AVG(hours_viewed), 2)
FROM shows_engagement;


CREATE OR REPLACE VIEW vw_global_availability AS
SELECT
    available_globally,
    COUNT(*) AS total_records,
    COUNT(DISTINCT title) AS unique_titles,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM (
    SELECT title, available_globally FROM movies_engagement
    UNION ALL
    SELECT title, available_globally FROM shows_engagement
) AS content
GROUP BY available_globally;



SELECT * FROM vw_engagement_by_period;

SELECT * FROM vw_top_10_content;

SELECT * FROM vw_content_type_distribution;

SELECT * FROM vw_top_genres;

SELECT * FROM vw_country_distribution;

SELECT * FROM vw_content_ratings;

SELECT * FROM vw_content_added_trend;

SELECT * FROM vw_content_performance;

SELECT * FROM vw_global_availability;










SELECT
    available_globally,
    COUNT(*) AS total_records,
    COUNT(DISTINCT title) AS unique_titles,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2
    ) AS percentage
FROM (
    SELECT title, available_globally FROM movies_engagement
    UNION ALL
    SELECT title, available_globally FROM shows_engagement
) AS content
GROUP BY available_globally;