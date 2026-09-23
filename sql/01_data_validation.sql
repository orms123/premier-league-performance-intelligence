-- Basic validation of the matches table.

-- Check total number of matches.
SELECT COUNT(*) AS total_matches
FROM matches;


-- Check the date range.
SELECT
    MIN(match_date) AS first_match,
    MAX(match_date) AS last_match
FROM matches;


-- Check number of unique teams.
SELECT COUNT(DISTINCT home_team) AS home_teams
FROM matches;


-- Check result distribution.
SELECT
    result,
    COUNT(*) AS matches
FROM matches
GROUP BY result
ORDER BY result;


-- Check that every team has played exactly 38 matches.
WITH team_matches AS (

    SELECT home_team AS team
    FROM matches

    UNION ALL

    SELECT away_team AS team
    FROM matches
)

SELECT
    team,
    COUNT(*) AS played
FROM team_matches
GROUP BY team
ORDER BY team;