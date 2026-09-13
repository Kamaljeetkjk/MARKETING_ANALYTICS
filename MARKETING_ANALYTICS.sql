CREATE DATABASE MARKETING_ANALYTICS;
USE MARKETING_ANALYTICS;


-----Creating table Structure for datasets

CREATE TABLE Countries (
    countryID INT PRIMARY KEY,
    Country VARCHAR(100),
    City VARCHAR(100)
);

CREATE TABLE Customers (
    Custid INT PRIMARY KEY,
    CustName VARCHAR(100),
    Email VARCHAR(150),
    Gender VARCHAR(20),
    Age INT,
    Locid INT,
    FOREIGN KEY (Locid) REFERENCES Countries(countryID)
);

CREATE TABLE Products (
    Productid INT PRIMARY KEY,
    Prd_name VARCHAR(100),
    Category VARCHAR(100),
    Price DECIMAL(10, 2)
);

CREATE TABLE Customer_journey (
    Journeyid INT PRIMARY KEY,
    custid INT,
    productid INT,
    Visitdate DATE,
    Stage VARCHAR(50),
    Action VARCHAR(50),
    Duration DECIMAL(10, 2),
    FOREIGN KEY (custid) REFERENCES Customers(Custid),
    FOREIGN KEY (productid) REFERENCES Products(Productid)
);


ALTER TABLE [dbo].[Customer_journey] 
DROP CONSTRAINT [PK__Customer__4158BDC79C38FE78];

CREATE TABLE Engagement_data (
    EngagementID INT PRIMARY KEY,
    ContentID INT,
    ContentType VARCHAR(50),
    Likes INT,
    Eng_date DATE,
    CampaignID INT,
    ProductID INT,
    View_Clicks_Comb VARCHAR(50),
    FOREIGN KEY (ProductID) REFERENCES Products(Productid)
);

CREATE TABLE Cust_Review (
    Reviewid INT PRIMARY KEY,
    Custid INT,
    Productid INT,
    ReviewDate DATE,
    Rating INT,
    Review_text VARCHAR(MAX),
    FOREIGN KEY (Custid) REFERENCES Customers(Custid),
    FOREIGN KEY (Productid) REFERENCES Products(Productid)
);


select * from Countries;
select * from Cust_Review;
select * from Customer_journey;
select * from Customers;
select * from Engagement_data;
select* from Products;



---Importing datasets


--Checking the data type 

SELECT 
    TABLE_NAME AS [Table Name], 
    COLUMN_NAME AS [Column Name], 
    DATA_TYPE AS [Data Type],
    CHARACTER_MAXIMUM_LENGTH AS [Max Length]
FROM 
    INFORMATION_SCHEMA.COLUMNS
ORDER BY 
    TABLE_SCHEMA, 
    TABLE_NAME, 
    ORDINAL_POSITION;


----1. Customer Segmentation & Average Ratings
SELECT 
    CASE 
        WHEN c.Age < 30 THEN 'Young (<30)'
        WHEN c.Age BETWEEN 30 AND 50 THEN 'Adult (30-50)'
        ELSE 'Senior (>50)'
    END AS Customer_Segment,
    COUNT(DISTINCT c.Custid) AS Total_Customers,
    ROUND(AVG(CAST(r.Rating AS FLOAT)), 2) AS Avg_Rating
FROM Customers c
LEFT JOIN Cust_Review r ON c.Custid = r.Custid
GROUP BY 
    CASE 
        WHEN c.Age < 30 THEN 'Young (<30)'
        WHEN c.Age BETWEEN 30 AND 50 THEN 'Adult (30-50)'
        ELSE 'Senior (>50)'
    END;



----2. Top 5 Countries Based on Average Rating 
  
SELECT TOP 5
    co.Country,
    ROUND(AVG(CAST(r.Rating AS FLOAT)), 2) AS Avg_Rating
FROM Countries co
JOIN Customers c ON co.countryID = c.Locid
JOIN Cust_Review r ON c.Custid = r.Custid
GROUP BY co.Country
ORDER BY Avg_Rating DESC;

----3. Find Inactive Customers (No Reviews Written)   


SELECT 
    c.Custid, 
    c.CustName,
    c.Email
FROM Customers c
LEFT JOIN Cust_Review r ON c.Custid = r.Custid
WHERE r.Reviewid IS NULL;



SELECT COUNT(DISTINCT Custid) AS Total_Customers FROM Customers;
SELECT COUNT(DISTINCT Custid) AS Customers_Who_Reviewed FROM Cust_Review;

----4. Correlation: Checkout Completion vs. Review Ratings   
SELECT 
    j.Stage AS Journey_Stage,
    ROUND(AVG(CAST(r.Rating AS FLOAT)), 2) AS Avg_Rating,
    COUNT(DISTINCT j.custid) AS Total_Customers
FROM customer_journey j
JOIN Cust_Review r ON j.custid = r.Custid AND j.productid = r.Productid
WHERE j.Stage IN ('Checkout', 'ProductPage', 'Homepage')
GROUP BY j.Stage
ORDER BY Avg_Rating DESC;


----5. Average Journey Duration by Customer 


SELECT 
    custid,
    ROUND(AVG(CAST(Duration AS FLOAT)), 2) AS Avg_Duration_Seconds,
    COUNT(Duration) AS Total_Timed_Actions
FROM customer_journey
WHERE Duration IS NOT NULL
GROUP BY custid
ORDER BY Avg_Duration_Seconds DESC;


--1. Unify & Clean Fragmented Journey Data

WITH Customer_Journey_Summary AS (
    SELECT 
        custid,
        Journeyid,
        stage,
        Action,
        Duration,
        VisitDate,
     
        CASE 
            WHEN Action = 'Purchase' THEN 1 
            ELSE 0 
        END AS is_purchase
    FROM Customer_Journey
)
SELECT 
    custid,
    COUNT(DISTINCT Journeyid) AS total_touchpoints,
    ROUND(AVG(Duration), 2) AS avg_journey_duration,
    SUM(is_purchase) AS total_purchases
FROM Customer_Journey_Summary
GROUP BY custid;

--2. Funnel Analysis: Checkout Completion vs. Drop-Offs by Stage
SELECT 
    stage,
    COUNT(DISTINCT custid) AS total_users,
    SUM(CASE WHEN Action = 'Purchase' THEN 1 ELSE 0 END) AS total_purchases,
    SUM(CASE WHEN Action = 'Drop-off' THEN 1 ELSE 0 END) AS total_dropoffs,
    ROUND(AVG(Duration), 2) AS avg_stage_duration_seconds
FROM Customer_Journey
GROUP BY stage
ORDER BY total_users DESC;

--3. Average Journey Duration per Customer (Fast vs. Slow Conversions)
SELECT 
    custid,
    ROUND(AVG(Duration), 2) AS avg_duration_mins,
    COUNT(Journeyid) AS total_sessions
FROM Customer_Journey
GROUP BY custid
ORDER BY avg_duration_mins DESC;

--4. Stage-Wise Drop-Off Rate (Pinpointing Bottlenecks)
SELECT 
    stage,
    COUNT(*) AS total_interactions,
    SUM(CASE WHEN Action = 'Drop-off' THEN 1 ELSE 0 END) AS dropoff_count,
    ROUND(
        (SUM(CASE WHEN Action = 'Drop-off' THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS dropoff_rate_percentage
FROM Customer_Journey
GROUP BY stage
ORDER BY dropoff_rate_percentage DESC;



select * from Countries;
select * from Cust_Review;
select * from Customer_journey;
select * from Customers;
select * from Engagement_data;
select* from Products;
