
-- ==============================================================================
-- Hotel Revenue Analytics: End-to-End Data Engineering Pipeline
-- Description: This script loads raw hotel booking data, performs exploratory 
-- data analysis (EDA), unions multiple years of historical data, and joins 
-- dimensional tables (market segments and meal costs) to build a master dataset 
-- for Power BI visualization.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- STEP 1: INITIAL BULK LOAD & EXPLORATION
-- ------------------------------------------------------------------------------

-- Load the comprehensive historical dataset
LOAD DATA LOCAL INFILE './data/hotel_revenue_historical_full.csv' 
INTO TABLE portfolio_projects.hotel_revenue_historical_full 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

-- Verify total row count for data integrity
SELECT COUNT(*) AS total_rows 
FROM portfolio_projects.hotel_revenue_historical_full;

-- Analyze booking distribution by year
SELECT arrival_date_year, COUNT(*) AS total_bookings
FROM portfolio_projects.hotel_revenue_historical_full
GROUP BY arrival_date_year
ORDER BY arrival_date_year;

-- Calculate preliminary gross revenue by year
SELECT 
    arrival_date_year, 
    SUM((stays_in_week_nights + stays_in_weekend_nights) * adr) AS gross_revenue
FROM portfolio_projects.hotel_revenue_historical_full
GROUP BY arrival_date_year;

-- ------------------------------------------------------------------------------
-- STEP 2: STAGING TABLES CREATION (2018, 2019, 2020)
-- ------------------------------------------------------------------------------

-- Initialize staging tables mirroring the main schema
CREATE TABLE portfolio_projects.hotel_data_2018 LIKE portfolio_projects.hotel_revenue_historical_full;
CREATE TABLE portfolio_projects.hotel_data_2019 LIKE portfolio_projects.hotel_revenue_historical_full;
CREATE TABLE portfolio_projects.hotel_data_2020 LIKE portfolio_projects.hotel_revenue_historical_full;

-- Ingest yearly data into respective staging tables
LOAD DATA LOCAL INFILE './data/hotel_revenue_historical_full2018.csv' 
INTO TABLE portfolio_projects.hotel_data_2018
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE './data/hotel_revenue_historical_full2019.csv' 
INTO TABLE portfolio_projects.hotel_data_2019
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE './data/hotel_revenue_historical_full2020.csv' 
INTO TABLE portfolio_projects.hotel_data_2020
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS;

-- ------------------------------------------------------------------------------
-- STEP 3: DIMENSIONAL TABLES SETUP
-- ------------------------------------------------------------------------------

-- Create and load Market Segment reference table (for discount rates)
CREATE TABLE portfolio_projects.market_segment (
    Discount DECIMAL(5,2),
    market_segment VARCHAR(50)
);

LOAD DATA LOCAL INFILE './data/market_segment.csv' 
INTO TABLE portfolio_projects.market_segment
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS;

-- Create and load Meal Cost reference table
CREATE TABLE portfolio_projects.meal (
    Cost DECIMAL(5,2),
    meal VARCHAR(50)
);

LOAD DATA LOCAL INFILE './data/meal.csv' 
INTO TABLE portfolio_projects.meal
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS;

-- ------------------------------------------------------------------------------
-- STEP 4: MASTER DATA MODELING (UNION & JOINS)
-- ------------------------------------------------------------------------------

-- Consolidate yearly tables into a single Master table
CREATE TABLE portfolio_projects.hotel_revenue_master AS
SELECT * FROM portfolio_projects.hotel_data_2018
UNION ALL
SELECT * FROM portfolio_projects.hotel_data_2019
UNION ALL
SELECT * FROM portfolio_projects.hotel_data_2020;

-- Final output: Join Master table with dimensions to calculate net financial impact
SELECT * FROM portfolio_projects.hotel_revenue_master hrm
LEFT JOIN portfolio_projects.market_segment ms
    ON hrm.market_segment = ms.market_segment
LEFT JOIN portfolio_projects.meal m
    ON hrm.meal = m.meal;