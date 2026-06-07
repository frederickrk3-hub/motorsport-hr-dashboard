-- Motorsport HR Management System
-- Dashboard queries (SQLite). Run on Motorsport_HR_Database_SQLite.db


-- A. Cost per race event
SELECT r.race_name,
       rs.series_name,
       r.location,
       SUM(a.calculated_cost) AS cost
FROM Assignment a
JOIN Race        r  ON a.race_id   = r.race_id
JOIN RaceSeries  rs ON r.series_id = rs.series_id
GROUP BY r.race_id
ORDER BY cost DESC;


-- A. Cost per race series
SELECT rs.series_name,
       SUM(a.calculated_cost) AS cost
FROM Assignment a
JOIN Race        r  ON a.race_id   = r.race_id
JOIN RaceSeries  rs ON r.series_id = rs.series_id
GROUP BY rs.series_id
ORDER BY cost DESC;


-- B. Tire expertise by brand (distinct engineers per brand)
SELECT t.brand,
       COUNT(DISTINCT ewt.personnel_id) AS engineers
FROM ExperienceWithTire ewt
JOIN Tire t ON t.tire_id = ewt.tire_id
GROUP BY t.brand
ORDER BY engineers DESC;


-- C. Travel days per engineer
SELECT e.name,
       SUM(r.required_travel_days) AS total_travel_days
FROM Engineer e
JOIN Assignment a ON a.personnel_id = e.personnel_id
JOIN Race       r ON r.race_id      = a.race_id
GROUP BY e.personnel_id
ORDER BY total_travel_days DESC;


-- D. Total cost per engineer
SELECT e.name,
       SUM(a.calculated_cost) AS total_cost
FROM Engineer e
JOIN Assignment a ON a.personnel_id = e.personnel_id
GROUP BY e.personnel_id
ORDER BY total_cost DESC;


-- E. Available engineers for a race (no assignment overlapping the race dates)
-- Replace :race_start and :race_end with the chosen race's start_date and end_date.
SELECT e.personnel_id,
       e.name,
       e.specialization,
       e.contract_type
FROM Engineer e
WHERE e.personnel_id NOT IN (
        SELECT a.personnel_id
        FROM Assignment a
        JOIN Race r ON r.race_id = a.race_id
        WHERE r.start_date <= :race_end
          AND r.end_date   >= :race_start
      );


-- H. Salary per engineer
SELECT name,
       salary_rate
FROM Engineer
ORDER BY salary_rate DESC;


-- Engineer ledger (combines C, D and H into one row per engineer)
SELECT e.name,
       e.specialization,
       e.contract_type,
       e.salary_rate                AS daily_rate,
       COUNT(a.assignment_id)       AS assignments,
       SUM(r.required_travel_days)  AS travel_days,
       SUM(a.calculated_cost)       AS total_cost
FROM Engineer e
LEFT JOIN Assignment a ON a.personnel_id = e.personnel_id
LEFT JOIN Race       r ON r.race_id      = a.race_id
GROUP BY e.personnel_id
ORDER BY total_cost DESC;


-- Expert coverage per tire compound (fewest experts first = hiring priority)
SELECT t.compound_name,
       t.brand,
       COUNT(ewt.personnel_id)               AS experts,
       ROUND(AVG(ewt.experience_in_years),1) AS avg_years,
       MAX(ewt.experience_in_years)          AS max_years
FROM Tire t
LEFT JOIN ExperienceWithTire ewt ON ewt.tire_id = t.tire_id
GROUP BY t.tire_id
ORDER BY experts ASC, avg_years ASC;


-- Specialization vs tire brand (expert count and average experience)
SELECT e.specialization,
       t.brand,
       COUNT(*)                              AS experts,
       ROUND(AVG(ewt.experience_in_years),1) AS avg_years
FROM ExperienceWithTire ewt
JOIN Engineer e ON e.personnel_id = ewt.personnel_id
JOIN Tire     t ON t.tire_id      = ewt.tire_id
GROUP BY e.specialization, t.brand;
