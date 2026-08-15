-- 1 Employee Retention Analysis
  -- 1.1 Who are the top 5 highest serving employees?
                      --      On inspection of the data, I have noticed that there are some employees who have left the company but they still appear in the employee table. 
                      --      To ensure that we are only considering current employees for this analysis, I will filter out those who have left the company by checking against the turnover table. 
                      --      This way, we can accurately identify the top 5 highest serving employees based on their tenure with the company. 
                      --      I also used this in some other queries to ensure that we are only analyzing current employees.
SELECT     first_name || ' ' || last_name AS employee_full_name, 
                        job_title, 
                        hire_date, 
                        age(current_date, hire_date) AS tenure from employee e
      WHERE NOT EXISTS (
      SELECT 2
      FROM turnover t
      WHERE t.employee_id = e.employee_id 
      )
ORDER BY tenure DESC
LIMIT 5;

  -- 1.2 What is the turnover rate for each department?
    SELECT
        d.department_name,
        COUNT(DISTINCT e.employee_id) AS employee_count,
        COUNT(DISTINCT t.employee_id) AS ex_employee,
          ROUND(
            COUNT(DISTINCT t.employee_id)::numeric 
            / NULLIF(COUNT(DISTINCT e.employee_id), 0)*100, 
            2
            ) AS "turnover_rate(%)"
    FROM    department d
    LEFT JOIN employee e ON d.department_id = e.department_id
    LEFT JOIN turnover t ON e.employee_id = t.employee_id
    GROUP BY d.department_name;

  -- 1.3 Which employees are at risk of leaving based on their performance?
  -- Calclulate the average performance score for each employee and identify those with low scores (e.g., below 3.5) as potentially at risk of leaving.
    SELECT  e.first_name || ' ' || e.last_name AS full_name,
        ROUND(AVG(p.performance_score), 2) AS avg_performance_score
    FROM performance p
    LEFT JOIN employee e ON p.employee_id = e.employee_id
    GROUP BY e.employee_id, full_name
    ORDER BY avg_performance_score ASC
    LIMIT 6;

  -- 1.4 What are the main reasons employees are leaving the company?
    SELECT reason_for_leaving, COUNT(reason_for_leaving) AS count
      FROM turnover
    GROUP BY reason_for_leaving
    ORDER BY count DESC;

-- 2 Performance Ananlysis
          -- Ratio of workforce
                  SELECT 
                          COUNT(CASE WHEN t.employee_id IS NULL THEN 1 END) AS number_of_current_employees,
                          COUNT(CASE WHEN t.employee_id IS NOT NULL THEN 1 END) AS number_of_ex_employees
                  FROM employee e
                  LEFT JOIN turnover t ON e.employee_id = t.employee_id;
  -- 2.1 How many employees has left the company?
    SELECT COUNT(DISTINCT employee_id) AS Number_of_Ex_Employees FROM turnover;
  
  -- 2.2 How many employees have a performance score of 5.0 / below 3.5?
WITH filtered_employees AS (
    SELECT employee_id
    FROM performance p
    WHERE NOT EXISTS (
        SELECT 1
        FROM turnover t
        WHERE t.employee_id = p.employee_id 
    )
    GROUP BY employee_id,performance_score
    HAVING performance_score < 3.5 OR performance_score = 5.0
)
SELECT COUNT(DISTINCT employee_id) AS total_matching_employees 
FROM filtered_employees;

  -- 2.3 Which department has the most employees with a performance of 5.0 / below 3.5?
WITH filtered_employees AS (
      SELECT employee_id, department_id
      FROM performance p
          WHERE NOT EXISTS (
              SELECT 1
              FROM turnover t
              WHERE t.employee_id = p.employee_id 
            )
    GROUP BY employee_id,performance_score,department_id
    HAVING performance_score < 3.5 OR performance_score = 5.0
  )
SELECT  d.department_name, 
                    COUNT(DISTINCT employee_id) AS total_matching_employees FROM filtered_employees
                    JOIN department d ON filtered_employees.department_id = d.department_id
    GROUP BY d.department_name
    ORDER BY total_matching_employees DESC;
 

  -- 2.4 What is the average performance score by department?
 WITH filtered_employees AS (
    SELECT employee_id, department_id, performance_score
    FROM performance p
    WHERE NOT EXISTS (
        SELECT 1
        FROM turnover t
        WHERE t.employee_id = p.employee_id 
    )
    GROUP BY employee_id,performance_score,department_id
    -- HAVING performance_score < 3.5 OR performance_score = 5.0
)
SELECT  d.department_name, 
                    ROUND(AVG(performance_score), 2) AS average_performance_score, 
                    COUNT(DISTINCT employee_id) AS total_matching_employees FROM filtered_employees
                    
    JOIN department d ON filtered_employees.department_id = d.department_id
    GROUP BY d.department_name
    ORDER BY average_performance_score DESC;

-- 3 Salary Analysis
  -- 3.1 What is the total salary expense for the company?
    SELECT '£' || TO_CHAR(SUM(salary_amount), '999,999,999.00') AS total_salary FROM salary;

  -- 3.2 What is the average salary by job title?
     SELECT '£' || TO_CHAR(AVG(salary_amount), '999,999,999.00') AS average_salary, 
            e.job_title
    FROM salary s
    JOIN employee e ON s.employee_id = e.employee_id
    GROUP BY e.job_title
    ORDER BY average_salary DESC;

  -- 3.3 How many employees earn above 80,000?
    SELECT COUNT(distinct employee_id) AS high_earners
    FROM salary
    WHERE salary_amount > 80000;

  -- 3.4 How does performance correlate with salary across departments?
   -- Correlation at departmental level

WITH active_employees AS (
    SELECT e.employee_id, e.department_id
    FROM employee e
    WHERE NOT EXISTS (
        SELECT 1
        FROM turnover t
        WHERE t.employee_id = e.employee_id 
    )
)
SELECT 
    d.department_name,
    COUNT(DISTINCT ae.employee_id) AS total_active_employees,
    ROUND(corr(p.performance_score, s.salary_amount)::numeric, 3) AS departmental_correlation_coefficient
FROM active_employees ae
JOIN performance p ON ae.employee_id = p.employee_id
JOIN salary s ON ae.employee_id = s.employee_id
JOIN department d ON ae.department_id = d.department_id
GROUP BY d.department_name
-- HAVING COUNT(DISTINCT ae.employee_id) > 5
ORDER BY departmental_correlation_coefficient DESC;

-- Correlation at organisational level
 WITH active_employees AS (
    SELECT e.employee_id
    FROM employee e
    WHERE NOT EXISTS (
        SELECT 1
        FROM turnover t
        WHERE t.employee_id = e.employee_id 
    )
)
SELECT 
    ROUND(corr(p.performance_score, s.salary_amount)::numeric, 3) AS company_wide_correlation
FROM active_employees ae
JOIN performance p ON ae.employee_id = p.employee_id
JOIN salary s ON ae.employee_id = s.employee_id;



        SELECT employee_id, count(attendance_status) AS absent_count FROM attendance a
    WHERE NOT EXISTS (
        SELECT 1
        FROM turnover t
        WHERE t.employee_id = a.employee_id 
    )
    AND attendance_status = 'Absent'
    GROUP BY employee_id
    ORDER BY absent_count DESC;
