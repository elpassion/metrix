SELECT
  DATE(timestamp) AS "Date",
  TIME(timestamp) AS "Time",
  number          AS "Build #",
  state           AS "State",
  gpa             AS "GPA",
  coverage        AS "Coverage", -- coverage2 for project 1 and 2
  lines_of_code   AS "LOC",
  lines_tested    AS "LOC Tested",
  quality_issues  AS "Quality Issues",
  style_issues    AS "Style Issues",
  security_issues AS "Security Issues"
FROM builds
WHERE state NOT IN ("canceled")
      AND project_id = 3
      AND NOT pull_request
ORDER BY number;

SELECT DATE(timestamp), type, count(*) FROM (
  SELECT project_id, timestamp, "comment" AS type FROM comments
  UNION SELECT project_id, timestamp, "release" AS type FROM releases
  UNION SELECT project_id, timestamp, "pull" AS type FROM pull_requests
  UNION SELECT project_id, timestamp, "commit" AS type FROM commits
) WHERE project_id = 4 GROUP BY DATE(timestamp), type ORDER BY type, timestamp;
