SELECT
  DATE(timestamp)          AS "Date",
  TIME(timestamp)          AS "Time",
  type                     AS "Type",
  CASE WHEN type == "commit" AND boolean_key = "is_conflict" AND boolean_value
    THEN "conflict" END AS "Properties"
FROM activities
WHERE
  project_id = 4
  AND type IN ("commit", "comment", "pull_request")
  AND timestamp BETWEEN "2015-12-07" AND "2015-12-19"
ORDER BY timestamp;
