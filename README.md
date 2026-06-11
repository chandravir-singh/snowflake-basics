# 📊 Snowflake HR Data Pipeline + SQL Practice (End-to-End Basics) 🚀

---

## 📌 Project Overview

This project combines:

✅ **Fundamental Data Pipeline Concepts in Snowflake**  
✅ **Real-Time Processing (Streams + Tasks + Merge)**  
✅ **SQL Interview Preparation (Beginner → Advanced)**  

It is designed to demonstrate both:
- Data Engineering fundamentals
- Advanced SQL problem-solving skills

---

## 🏗 Architecture (Pipeline)

```

```
         ┌───────────────┐
         │   HR_DATA     │  (Source Table)
         └──────┬────────┘
                ↓
         ┌───────────────┐
         │   STREAM      │ (hr_stream)
         └──────┬────────┘
                ↓
         ┌───────────────┐
         │   TASK        │ (hr_task)
         └──────┬────────┘
                ↓
         ┌───────────────┐
         │ HR_SUMMARY    │ (Aggregated Data)
         └───────────────┘
```

```

---

## 📂 Project Structure

```

snowflake-hr-pipeline/
│
├── HR\_PIPELINE.SQL ✅ (Pipeline + SQL Queries)
└── README.md       ✅ Documentation

````

---

## 🛠 Technologies Used

- Snowflake SQL
- Streams (CDC)
- Tasks (Automation)
- MERGE (Upsert Logic)
- Window Functions
- Advanced SQL Analytics

---

# ✅ ✅ PIPELINE IMPLEMENTATION

---

## 🔹 STEP 1: Create Summary Table

```sql
CREATE OR REPLACE TABLE HR_SUMMARY
````

👉 Stores aggregated data:

* JOB\_ID
* TOTAL\_EMP

***

## 🔹 STEP 2: Create Stream

```sql
CREATE STREAM hr_stream ON TABLE HR_DATA;
```

✅ Tracks:

* Inserts
* Updates
* Deletes

***

## 🔹 STEP 3: Create Task (Automation)

```sql
CREATE TASK hr_task
WAREHOUSE = COMPUTE_WH
SCHEDULE = '1 MINUTE'
```

👉 Runs automatically every minute

***

## 🔥 STEP 4: MERGE LOGIC (CORE)

```sql
MERGE INTO HR_SUMMARY tgt
USING (...)
```

### ✅ WHEN MATCHED

* Updates existing department counts

### ✅ WHEN NOT MATCHED

* Inserts new JOB\_ID

***

## ✅ STEP 5: Start Task

```sql
ALTER TASK hr_task RESUME;
```

***

## ✅ DATA FLOW

| Step                 | Action              |
| -------------------- | ------------------- |
| New data in HR\_DATA | Stream captures it  |
| Task runs            | Reads stream        |
| Merge executes       | Updates HR\_SUMMARY |

***

# 🧠 SQL INTERVIEW QUESTIONS COVERED

***

## ✅ Basic → Intermediate

### 🔹 Top Salary Per Department

* `RANK()`, `QUALIFY`

### 🔹 Second Highest Salary

* `DENSE_RANK()`

### 🔹 Above Department Average

* Subquery + Window function

***

## ✅ Window Functions Mastery

* `RANK()`, `DENSE_RANK()`
* `LAG()`
* `SUM() OVER`
* `AVG() OVER`

***

## ✅ Analytical Queries

* Running total salary
* Department ranking
* Salary contribution %
* Median salary

***

## ✅ Advanced Concepts 🔥

***

### 🔹 Recursive CTE (Hierarchy)

```sql
WITH RECURSIVE EMP_TREE
```

👉 Builds employee-manager hierarchy

***

### 🔹 Cycle Detection

👉 Detect invalid manager loops

***

### 🔹 Salary Outliers

```sql
AVG + STDDEV
```

👉 Identifies anomaly data

***

### 🔹 Pivoting Data

* Convert rows → columns

***

### 🔹 Salary Trends

```sql
LAG() + CASE
```

👉 Detect increase/decrease

***

### 🔹 Top N Optimization

```sql
LIMIT + QUALIFY
```

***

## ✅ Real Interview Scenarios Covered

* Top N problems
* Window optimization
* Aggregation + filtering
* Self join vs window
* Recursive queries
* CDC pipelines

***

# ✅ SCD (Slowly Changing Dimension)

***

## 🔹 SCD Type 1

👉 Overwrite data

```sql
UPDATE HR_DATA
SET SALARY = ...
```

***

## 🔹 SCD Type 2 (History Tracking)

### Step 1: Close Old Record

```sql
UPDATE
SET CURRENT_FLAG = 0
```

### Step 2: Insert New Record

```sql
INSERT INTO HR_DATA
```

***

## 🔥 Best Practice (MERGE)

```sql
MERGE INTO EMP_DIM
```

✅ Handles:

* Updates
* Inserts
* History tracking

***

## 🔹 SCD Type 3

👉 Stores previous value in same row

***

# 🧠 Key Learning Outcomes

This project demonstrates:

✅ Data pipeline design  
✅ Incremental processing (Streams)  
✅ Automation (Tasks)  
✅ Merge-based upsert logic  
✅ SQL problem-solving (interview level)  
✅ Advanced analytics queries

***

# 🚀 Real-World Use Cases

* HR Analytics dashboards
* Employee reporting systems
* Data warehouse pipelines
* Real-time analytics

***

# ⚠ Important Notes

✅ Task must be active:

```sql
ALTER TASK hr_task RESUME;
```

✅ Warehouse must be running:

```sql
ALTER WAREHOUSE COMPUTE_WH RESUME;
```

✅ Streams are consumed once after task run

***

# 🚀 Future Enhancements

* Convert to production MERGE pipelines
* Integrate Snowpipe (real-time ingestion)
* Connect Power BI / Tableau
* Add dashboards

***

## 👨‍💻 Author

**Chandravir Singh**  
Software Engineer | Data Engineer Enthusiast

***

## ⭐ If you found this useful

Give it a ⭐ on GitHub 🚀

```

---

# ✅ ✅ ✅ GitHub Description (Use this)

👉 **Best description for this repo:**

```

Snowflake data pipeline + SQL interview preparation project covering Streams, Tasks, MERGE, SCD types, and advanced analytical queries.

```

---



