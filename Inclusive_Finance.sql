-- DATA CLEANING

--Find Negative Amounts
Begin Transaction 
SELECT *
FROM Transactions
WHERE Amount < 0;

--Updating the negative Amount columns to an Absolute Amount column
update Transactions
Set Amount = ABS(Amount)
From Transactions;
Commit Transaction


--Find NULL Transaction Channels
SELECT COUNT(*) AS NullChannelCount
FROM Transactions_Clean
WHERE TransactionChannel IS NULL;


--Replace NULL channels with “Unknown”
UPDATE Transactions_Clean
SET TransactionChannel = 'Unknown'
WHERE TransactionChannel IS NULL;


--Validate Foreign Keys
SELECT t.*
FROM Transactions_Clean t
LEFT JOIN Users u ON t.UserID = u.UserID
WHERE u.UserID IS NULL;
/*If any rows appear, they’re invalid foreign keys.*/


--Check for NULL FeesCharged
SELECT COUNT(*) AS NullFeeCount
FROM Transactions_Clean
WHERE FeesCharged IS NULL;
/*check how many transactions have no fee info*/


--Replace NULL fees with 0.00 for analysis.
UPDATE Transactions_Clean
SET FeesCharged = 0.00
WHERE FeesCharged IS NULL;



-- DATA ANALYSIS

--Top 5 transaction channels by volume:
SELECT TransactionChannel, COUNT(*) AS TransactionCount
FROM Transactions_Clean
GROUP BY TransactionChannel
ORDER BY TransactionCount DESC;


--Average Amount by Transaction Type:
SELECT TransactionType, AVG(Amount) AS AvgAmount
FROM Transactions_Clean
GROUP BY TransactionType;


--Churn Rate by Income Level
SELECT IncomeLevel,
       SUM(CASE WHEN Churned = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS ChurnRate
FROM Users
GROUP BY IncomeLevel;


--Churn Rate by Income Level
SELECT 
    IncomeLevel,
    COUNT(*) AS TotalUsers,
    SUM(CASE WHEN Churned = 1 THEN 1 ELSE 0 END) AS ChurnedUsers,
    ROUND(
        SUM(CASE WHEN Churned = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS ChurnRatePct
FROM Users
GROUP BY IncomeLevel;

/*Insight:
1.	Low-income users churn the most.
2.	Might signal affordability issues or poor product fit.
3.	Great opportunity for tailored retention strategies
*/



--Churn vs KYC Completion
SELECT
    KYCCompleted,
    COUNT(*) AS TotalUsers,
    SUM(CASE WHEN Churned = 1 THEN 1 ELSE 0 END) AS ChurnedUsers,
    ROUND(
        SUM(CASE WHEN Churned = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS ChurnRatePct
FROM Users
GROUP BY KYCCompleted;

/*Insight:
1.	Users who fail KYC churn much more.
2.	Possible causes:
3.	Locked accounts
4.	Frustration with failed onboarding
5.	Big opportunity to improve onboarding journeys*/



--Churn Rate by KYC Failure Reason
SELECT 
    KYCFailureReason,
    COUNT(*) AS UsersWithIssue
FROM Users
WHERE KYCFailureReason IS NOT NULL
GROUP BY KYCFailureReason;


--Churn by Failure Reason
SELECT 
    KYCFailureReason,
    COUNT(*) AS TotalUsers,
    SUM(CASE WHEN Churned = 1 THEN 1 ELSE 0 END) AS ChurnedUsers,
    ROUND(
        SUM(CASE WHEN Churned = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS ChurnRatePct
FROM Users
WHERE KYCCompleted = 0
GROUP BY KYCFailureReason;

/*
Insight:
1.	High churn in users with ID issues.
2.	Priority for better KYC documentation support
*/



--Combined Churn Analysis: Income Level + KYC
SELECT
    IncomeLevel,
    KYCCompleted,
    COUNT(*) AS TotalUsers,
    SUM(CASE WHEN Churned = 1 THEN 1 ELSE 0 END) AS ChurnedUsers,
    ROUND(
        SUM(CASE WHEN Churned = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*),0),
        2
    ) AS ChurnRatePct
FROM Users
GROUP BY IncomeLevel, KYCCompleted
ORDER BY IncomeLevel, KYCCompleted;

/*
Insight:
1.	Churn skyrockets for low-income users who failed KYC.
2.	High-income users almost never churn if they pass KYC.
3.	Suggests tailored KYC support is crucial for lower-income segments.
*/


/*
RECOMMENDATIONS
1. Enhanced KYC Support: Low-income users should be assisted with ID docs or address verification.
2. Targeted Retention Programs: Prioritize outreach to failed-KYC users.
3. Product Affordability: Explore flexible fees or lower barriers for low-income groups.
*/