SELECT
  DATE(timestamp) AS "Date",
  TIME(timestamp) AS "Time",
  number          AS "ID",
  state           AS "State",
  gpa             AS "GPA",
  coverage2       AS "Coverage", -- coverage for project 4
  lines_of_code   AS "LOC",
  lines_tested    AS "LOC Tested",
  quality_issues  AS "Quality Issues",
  style_issues    AS "Style Issues",
  security_issues AS "Security Issues"
FROM builds
WHERE state NOT IN ("canceled")
      AND project_id = 3
      AND NOT pull_request
      AND timestamp BETWEEN "2015-12-07" AND "2015-12-19"
ORDER BY number;
