
CREATE OR REPLACE TABLE HR_SUMMARY AS
SELECT 
    JOB_ID,
    COUNT(*) AS TOTAL_EMP
FROM PRACTICE_DB.PUBLIC.HR_DATA
GROUP BY JOB_ID;

CREATE OR REPLACE TASK hr_task
WAREHOUSE = COMPUTE_WH
SCHEDULE = '1 MINUTE'
AS
CREATE OR REPLACE TABLE HR_SUMMARY AS
SELECT JOB_ID, COUNT(*) 
FROM HR_DATA
GROUP BY JOB_ID;

ALTER TASK hr_task RESUME;


SELECT * FROM HR_SUMMARY;

ALTER TASK hr_task SUSPEND;

DROP TASK HR_TASK;


SHOW TASKS;

CREATE OR REPLACE STREAM hr_stream
ON TABLE HR_DATA;

CREATE OR REPLACE TABLE HR_SUMMARY (
    JOB_ID STRING,
    TOTAL_EMP INT
);


CREATE OR REPLACE TASK hr_task
WAREHOUSE = COMPUTE_WH
SCHEDULE = '1 MINUTE'
AS
MERGE INTO HR_SUMMARY tgt
USING (
    SELECT JOB_ID, COUNT(*) AS total_emp
    FROM hr_stream
    GROUP BY JOB_ID
) src
ON tgt.JOB_ID = src.JOB_ID
WHEN MATCHED THEN
    UPDATE SET tgt.TOTAL_EMP = tgt.TOTAL_EMP + src.total_emp
WHEN NOT MATCHED THEN
    INSERT (JOB_ID, TOTAL_EMP)
    VALUES (src.JOB_ID, src.total_emp);

ALTER TASK hr_task RESUME;


-- =====================================
-- 1. Top Salary Per Department
-- Write a query to find the highest-paid employee in each department.
-- =====================================

SELECT *
FROM HR_DATA
QUALIFY RANK() OVER(PARTITION BY DEPARTMENT_ID ORDER BY SALARY DESC) <= 2;



-- =====================================
-- 2. Second Highest Salary
-- Find the second highest salary across all employees (handle duplicates properly).
-- =====================================


SELECT * 
FROM HR_DATA
QUALIFY DENSE_RANK() OVER ( ORDER BY SALARY DESC) = 2;



-- =====================================
-- 3. Employees Earning Above Department Average
-- List employees who earn more than the average salary of their department.
-- =====================================

SELECT * 
FROM HR_DATA ED1
WHERE SALARY > 
(SELECT AVG(SALARY) FROM HR_DATA ED2
WHERE ED1.DEPARTMENT_ID = ED2.DEPARTMENT_ID);


SELECT *
FROM HR_DATA
QUALIFY SALARY > AVG(SALARY) OVER (PARTITION BY DEPARTMENT_ID);


-- =====================================
-- 4. Manager Hierarchy (Basic)
-- Get employee name with their manager name using self-join.
-- =====================================

SELECT H1.EMPLOYEE_ID, H1.FIRST_NAME, H2.EMPLOYEE_ID, H2.FIRST_NAME 
FROM HR_DATA H1 JOIN HR_DATA H2 
ON H1.MANAGER_ID = H2.EMPLOYEE_ID;


-- =====================================
-- 5. Running Salary Total
-- Calculate a running total of salary ordered by hire date.
-- =====================================

SELECT EMPLOYEE_ID, HIRE_DATE,
SUM(SALARY) OVER(ORDER BY HIRE_DATE, EMPLOYEE_ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM HR_DATA;

-- ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
-- 👉 “Take all rows from the beginning up to this row”
    
    -- =====================================
    -- 6. Department Salary Ranking
    -- Rank employees by salary within each department.
    -- =====================================
    
    SELECT EMPLOYEE_ID, DEPARTMENT_ID, SALARY,
    RANK() OVER(PARTITION BY DEPARTMENT_ID ORDER BY SALARY DESC) AS RK
    FROM HR_DATA
    ORDER BY 2, 1;

-- =====================================
-- 7. Employees Hired in Same Month
-- Find employees hired in the same month and year.
-- =====================================


-- SELECT TO_CHAR(HIRE_DATE, 'YYYY-MM'), COUNT(*)
-- FROM HR_DATA
-- GROUP BY TO_CHAR(HIRE_DATE, 'YYYY-MM');

SELECT *
FROM HR_DATA 
QUALIFY COUNT(*) OVER(PARTITION BY TO_CHAR(HIRE_DATE, 'YYYY-MM')) > 1;


-- =====================================

-- 🔹 Moderate → Advanced (Snowflake-Specific)

-- 8. Use QUALIFY Clause
-- Get top 2 highest-paid employees per department using QUALIFY.
-- =====================================


SELECT * 
FROM HR_DATA
QUALIFY RANK() OVER(PARTITION BY DEPARTMENT_ID ORDER BY SALARY DESC) 
<= 2;

-- =====================================
-- 9. Remove Duplicate Employees (Hypothetical)
-- Assume duplicates based on EMAIL — remove duplicates keeping latest hire date.
-- =====================================



-- =====================================
-- 10. Conditional Aggregation
-- Find count of employees:

-- With commission
-- Without commission
-- =====================================


SELECT COUNT(*)
FROM HR_DATA
WHERE COMMISSION_PCT IS NOT NULL;

SELECT COUNT(*)
FROM HR_DATA
WHERE COMMISSION_PCT IS NULL;

SELECT 
COUNT(CASE WHEN COMMISSION_PCT IS NULL THEN 1 END), 
COUNT(CASE WHEN COMMISSION_PCT IS NOT NULL THEN 1 END)
FROM HR_DATA;

SELECT COUNT_IF(COMMISSION_PCT IS NULL ) AS WITH_CMSN,
COUNT_IF(COMMISSION_PCT IS NOT NULL) AS WITHOUT_CMSN
FROM HR_DATA;

-- =====================================
-- 11. Salary Banding
-- Create salary bands like:

-- Low (< 5000)
-- Medium (5000–10000)
-- High (>10000)
-- =====================================


SELECT EMPLOYEE_ID, SALARY, CASE
WHEN SALARY > 10000 THEN 'HIGH'
WHEN SALARY BETWEEN 5000 AND 10000 THEN 'MEDIUM'
ELSE 'LOW'
END AS CATEGORY
FROM HR_DATA;

-- =====================================
-- 🔹 Advanced Snowflake Queries
-- 12. Recursive Hierarchy (Manager Tree)
-- Write a query to display employee hierarchy (manager → subordinate tree).
-- 👉 Use CONNECT BY (Oracle style) OR WITH RECURSIVE (Snowflake style).
-- =====================================

WITH RECURSIVE  EMP_TREE AS(
    SELECT EMPLOYEE_ID, FIRST_NAME, MANAGER_ID,
    1 AS LEVEL
    FROM HR_DATA
    WHERE MANAGER_ID IS NULL

    UNION ALL

    SELECT E.EMPLOYEE_ID, E.FIRST_NAME, E.MANAGER_ID, 
    ET.LEVEL + 1
    FROM HR_DATA E 
    JOIN EMP_TREE ET
    ON E.MANAGER_ID = ET.EMPLOYEE_ID
)

SELECT * 
FROM EMP_TREE
ORDER BY LEVEL, EMPLOYEE_ID;


-- SELECT 
--     EMPLOYEE_ID,
--     LPAD(FIRST_NAME, LENGTH(FIRST_NAME) + (LEVEL * 2), ' ') AS INDENTED_NAME,
--     LEVEL
-- FROM EMP_TREE
-- ORDER BY LEVEL, EMPLOYEE_ID;



-- =====================================
-- 13. Detect Cyclic Managers
-- Check if any employee is assigned as their own manager (direct/indirect loop).
-- =====================================

-- DIRECT LOOP
SELECT *
FROM HR_DATA 
WHERE EMPLOYEE_ID = MANAGER_ID;


WITH RECURSIVE EMP_TREE AS (
SELECT EMPLOYEE_ID, MANAGER_ID, EMPLOYEE_ID AS ROOT
FROM HR_DATA

UNION ALL

SELECT E.EMPLOYEE_ID, E.MANAGER_ID, ET.ROOT
FROM HR_DATA E
JOIN EMP_TREE ET 
ON E.MANAGER_ID = ET.EMPLOYEE_ID
)

SELECT * 
FROM EMP_TREE
WHERE EMPLOYEE_ID = ROOT;

WITH RECURSIVE EMP_TREE AS (
    SELECT 
        EMPLOYEE_ID,
        MANAGER_ID,
        CAST(EMPLOYEE_ID AS STRING) AS PATH
    FROM HR_DATA

    UNION ALL

    SELECT 
        E.EMPLOYEE_ID,
        E.MANAGER_ID,
        ET.PATH || '->' || E.EMPLOYEE_ID
    FROM HR_DATA E
    JOIN EMP_TREE ET
        ON E.MANAGER_ID = ET.EMPLOYEE_ID
    WHERE POSITION(E.EMPLOYEE_ID IN ET.PATH) = 0
)

SELECT *
FROM EMP_TREE;

-- =====================================
-- 14. Median Salary Per Department
-- Find median salary per department.
-- =====================================

SELECT DEPARTMENT_ID, 
MEDIAN(SALARY) 
FROM HR_DATA
GROUP BY DEPARTMENT_ID;

SELECT
    DEPARTMENT_ID,
    PERCENTILE_CONT(0.5) 
        WITHIN GROUP (ORDER BY SALARY) AS MEDIAN_SALARY
FROM HR_DATA
GROUP BY DEPARTMENT_ID;


-- -- =====================================
-- 15. Gap Between Hire Dates
-- Find difference in days between an employee's hire date and previous employee hire date.
-- =====================================

SELECT EMPLOYEE_ID, HIRE_DATE,
LAG(HIRE_DATE) OVER(ORDER BY HIRE_DATE) AS PREV_HIRE_DATE,
DATEDIFF(DAYS, LAG(HIRE_DATE) OVER(ORDER BY HIRE_DATE), HIRE_DATE) AS DAYS_DIFF
FROM HR_DATA;

-- =====================================
-- 16. Pivot Salary by Department
-- Pivot data to show average salary per department in columns.
-- =====================================
SELECT * FROM ( 

SELECT DEPARTMENT_ID, SALARY
FROM HR_DATA ) 
PIVOT (
AVG(SALARY)
FOR DEPARTMENT_ID IN (10,20,30,40,50,60) 
);


SELECT 
    AVG(CASE WHEN DEPARTMENT_ID = 10 THEN SALARY END) AS DEPT_10,
    AVG(CASE WHEN DEPARTMENT_ID = 20 THEN SALARY END) AS DEPT_20,
    AVG(CASE WHEN DEPARTMENT_ID = 30 THEN SALARY END) AS DEPT_30
FROM HR_DATA;


-- =====================================
-- 17. Latest Hired Employee Per Job
-- Find the most recently hired employee for each JOB_ID.
-- =====================================

SELECT *
FROM HR_DATA 
QUALIFY RANK() OVER(PARTITION BY JOB_ID ORDER BY HIRE_DATE DESC) = 1;


-- =====================================
-- 🔹 Hard / Real Interview-Level Questions
-- 18. Department Salary Contribution %
-- For each employee, calculate:
-- (employee salary / total department salary) * 100
-- =====================================

SELECT HD.EMPLOYEE_ID, HD.SALARY, HD.DEPARTMENT_ID, TEMP.SAL, 
ROUND((HD.SALARY/TEMP.SAL)*100,3) AS CONTRIBUTION
FROM HR_DATA HD JOIN ( 

SELECT DEPARTMENT_ID AS DID, SUM(SALARY) AS SAL
FROM HR_DATA
GROUP BY DEPARTMENT_ID ) TEMP 
ON HD.DEPARTMENT_ID = TEMP.DID;

SELECT
    EMPLOYEE_ID,
    SALARY,
    DEPARTMENT_ID,
    ROUND(
        (SALARY / SUM(SALARY) OVER (PARTITION BY DEPARTMENT_ID)) * 100, 
        3
    ) AS CONTRIBUTION
FROM HR_DATA;

-- =====================================
-- 19. Identify Managers with No Subordinates
-- Find employees who:

-- Are not listed as any employee’s manager
-- =====================================


SELECT H1.EMPLOYEE_ID, H2.MANAGER_ID
FROM HR_DATA H1 LEFT JOIN HR_DATA H2 
ON H1.EMPLOYEE_ID = H2.MANAGER_ID
WHERE H2.MANAGER_ID IS NULL;






-- =====================================
-- 20. Top N Employees by Salary Across Company
-- Find top 10 employees using efficient logic (optimize for large dataset).
-- =====================================

SELECT *
FROM HR_DATA
ORDER BY SALARY DESC, EMPLOYEE_ID
LIMIT 10;

SELECT *
FROM HR_DATA
QUALIFY RANK() OVER(ORDER BY SALARY DESC, EMPLOYEE_ID) <= 10;



-- TOP 10 SALARIES PER DEPARTMENT

SELECT * 
FROM HR_DATA
QUALIFY RANK() OVER(PARTITION BY DEPARTMENT_ID ORDER BY SALARY DESC, EMPLOYEE_ID) <= 10;



-- =====================================
-- 21. Salary Growth Trend
-- Assume employees get salary updates over time (simulate if needed):
-- Find salary change trends using window functions.
-- =====================================

SELECT EMPLOYEE_ID, SALARY,
LAG(SALARY) OVER(PARTITION BY EMPLOYEE_ID ORDER BY UPDATED_DATE DESC) AS PREV_SAL,
SALARY - LAG(SALARY) OVER(PARTITION BY EMPLOYEE_ID ORDER BY UPDATED_DATE DESC)  AS SAL_DIFF,

    CASE 
        WHEN SALARY > LAG(SALARY) OVER (PARTITION BY EMPLOYEE_ID ORDER BY UPDATE_DATE)
            THEN 'INCREASE'
        WHEN SALARY < LAG(SALARY) OVER (PARTITION BY EMPLOYEE_ID ORDER BY UPDATE_DATE)
            THEN 'DECREASE'
        ELSE 'NO CHANGE'
    END AS TREND

FROM HR_DATA ;





-- =====================================
-- 22. Find Salary Outliers
-- Detect employees whose salary is significantly higher/lower than department average
-- (e.g., 2 standard deviations).
-- =====================================

SELECT EMPLOYEE_ID, FIRST_NAME, SALARY
FROM HR_DATA
QUALIFY SALARY <
AVG(SALARY) OVER(PARTITION BY DEPARTMENT_ID)  
- 2 *  STDDEV(SALARY) OVER(PARTITION BY DEPARTMENT_ID) 
OR SALARY >
AVG(SALARY) OVER(PARTITION BY DEPARTMENT_ID)  
- 2 *  STDDEV(SALARY) OVER(PARTITION BY DEPARTMENT_ID) ;



-- =====================================
-- 23. Self-Join vs Window Optimization
-- Rewrite a self-join query using window functions (performance-focused problem).
-- =====================================

SELECT *
FROM ( 
SELECT EMPLOYEE_ID, SALARY, DEPARTMENT_ID, HIRE_DATE, 
LAG(SALARY) OVER(ORDER BY HIRE_DATE ) AS PREV_SAL
FROM HR_DATA) 
WHERE SALARY > PREV_SAL ;


SELECT * 
FROM HR_DATA
QUALIFY SALARY > AVG(SALARY) OVER(PARTITION BY DEPARTMENT_ID);


-- Find employees who earn more than the previous 2 employees

SELECT *
FROM HR_DATA 
QUALIFY SALARY > LAG(SALARY, 2) OVER(PARTITION BY DEPARTMENT_ID ORDER BY HIRE_DATE );


-- 👉 Find employees whose salary is increasing continuously (no drops at any step)

SELECT  * 
FROM ( 

SELECT 
        EMPLOYEE_ID,
        HIRE_DATE,
        SALARY,
        CASE 
            WHEN SALARY < LAG(SALARY) OVER (ORDER BY HIRE_DATE)
            THEN 1 ELSE 0
        END AS DROP_FLAG
    FROM HR_DATA
    ) 
QUALIFY SUM(DROP_FLAG) OVER(ORDER BY HIRE_DATE ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) = 0;


-- =====================================

-- 24. Dense Rank Edge Case
-- Find employees whose salary is in top 3 unique salaries per department.
-- =====================================

SELECT *
FROM ( 

SELECT EMPLOYEE_ID, FIRST_NAME, SALARY, DEPARTMENT_ID,
DENSE_RANK() OVER(PARTITION BY DEPARTMENT_ID ORDER BY SALARY DESC) AS DR
FROM HR_DATA ) TEMP 
WHERE DR <= 3;

SELECT * 
FROM HR_DATA
QUALIFY DENSE_RANK() OVER(PARTITION BY DEPARTMENT_ID ORDER BY SALARY DESC) <= 3;



-- 👉 Find employees whose salary is in top 10% of their department

SELECT * 
FROM HR_DATA
QUALIFY CUME_DIST() OVER(PARTITION BY DEPARTMENT_ID ORDER BY SALARY) <= 0.10;

--  CUME_DIST()
-- 👉 It gives a value between 0 and 1

-- Top salary → small value (close to 0)
-- Lowest salary → close to 1


-- =====================================
-- 25. Multi-Level Aggregation (CTE Practice)
-- Find:

-- Department with highest average salary
-- Then list employees from that department
-- =====================================

SELECT *
FROM HR_DATA HD JOIN ( 
SELECT DEPARTMENT_ID AS DID , AVG(SALARY) AS AVG_SAL 
FROM HR_DATA
GROUP BY DEPARTMENT_ID
ORDER BY 2 DESC
LIMIT 1 ) TEMP 
ON HD.DEPARTMENT_ID = TEMP.DID;


WITH AVG_DEPT AS (
SELECT DEPARTMENT_ID, AVG(SALARY) AS AVG_SAL
FROM HR_DATA
GROUP BY DEPARTMENT_ID
), 
TOP_DEPT AS (
SELECT DEPARTMENT_ID
FROM AVG_DEPT
QUALIFY RANK() OVER(ORDER BY AVG_SAL DESC ) = 1
)

SELECT * 
FROM HR_DATA
WHERE DEPARTMENT_ID IN (SELECT DEPARTMENT_ID FROM TOP_DEPT);

SELECT *
FROM HR_DATA
WHERE DEPARTMENT_ID IN (
SELECT DEPARTMENT_ID
FROM HR_DATA
GROUP BY DEPARTMENT_ID
QUALIFY RANK() OVER(ORDER BY AVG(SALARY) DESC) = 1
);




-- SCD 1 
UPDATE HR_DATA
SET SALARY = 26000
WHERE EMPLOYEE_ID = 100;

--SCD 2
-- Step 1: Close Old Record
UPDATE HR_DATA
SET 
END_FLAG = CURRENT_DATE(),
CURRENT_FLAG = 0
WHERE EMPLOYEE_ID = 100 AND CURRENT_FLAG = 1;


-- Step 2: Insert New Record
INSERT INTO HR_DATA (
EMPLOYEE_ID,
SALARY,
START_DATE, 
END_DATE, 
CURRENT_FLAG
) VALUES (
100, 
27000,
CURRENT_DATE(),
NULL,
1
);


-- ✅ ✅ Snowflake BEST WAY (Using MERGE 🔥)
 
MERGE INTO EMP_DIM T --1
USING EMP_DATA S 
ON T.EMPLOYEE_ID = S.EMPLOYEE_ID AND T.CURRENT_FLAG = 1

WHEN MATCHED AND T.SALARY <> S.SALARY THEN  --2
UPDATE SET 
END_DATE = CURRENT_DATE(),
CURRENT_FLAG = 0

WHEN NOT MATCHED THEN --3
INSERT (
EMPLOYEE_ID, 
SALARY, 
START_DATE,
END_DATE,
CURRENT_FLAG
)
VALUES (
S.EMPLOYEE_ID, 
S.SALARY,
CURRENT_DATE(),
NULL,
1

);

-- IN THIS 1 PART WILL MERGE + JOIN 
-- AND IN 2 PART, IT WILL ONLY CLOSE THE LAST RECORD
-- IN 3,IT WILL INSERT ONLY IF DATA IS NOT EXIST IN TARGET TABLE 

-- SO TO INSERT THE UPDATED RECORD WE WILL USE THIS 

INSERT INTO EMP_DIM (
EMPLOYEE_ID,
SALARY,
START_DATE, 
END_DATE, 
CURRENT_FLAG
)

SELECT S.EMPLOYEE_ID, S.SALARY, CURRENT_DATE(), NULL, 1
FROM EMP_STAGE S JOIN EMP_DIM T
ON S.EMPLOYEE_ID = T.EMPLOYEE_ID AND T.CURRENT_FLAG = 1
WHERE 
T.EMPLOYEE_ID IS NULL --NEW EMPLOYEE
OR S.SALARY <> T.SALARY; -- UPDATED EMPLOYEE



--SCD 3

UPDATE EMP_DIM T 
SET 
PREV_SAL = CURRENT_SAL, 
CURRENT_SAL = S.SALARY,
UDPATE_DATE = CURRENT_DATE
FROM EMP_STAGE S 
WHERE T.EMPLOYEE_ID = S.EMPLOYEE_ID 
AND T.SALARY <> S.SALARY;