-- Premier League league table
-- Reconstructs team-level results from match-level data.

WITH team_matches AS (

    -- Home-team perspective
    SELECT
        home_team AS team,
        home_goals AS goals_for,
        away_goals AS goals_against,
        CASE
            WHEN result = 'H' THEN 'W'
            WHEN result = 'D' THEN 'D'
            WHEN result = 'A' THEN 'L'
        END AS team_result
    FROM matches

    UNION ALL

    -- Away-team perspective
    SELECT
        away_team AS team,
        away_goals AS goals_for,
        home_goals AS goals_against,
        CASE
            WHEN result = 'H' THEN 'L'
            WHEN result = 'D' THEN 'D'
            WHEN result = 'A' THEN 'W'
        END AS team_result
    FROM matches
)

SELECT
    team,
    COUNT(*) AS played,

    COUNT(*) FILTER (
        WHERE team_result = 'W'
    ) AS wins,

    COUNT(*) FILTER (
        WHERE team_result = 'D'
    ) AS draws,

    COUNT(*) FILTER (
        WHERE team_result = 'L'
    ) AS losses,

    SUM(goals_for) AS goals_for,
    SUM(goals_against) AS goals_against,

    SUM(goals_for - goals_against)
        AS goal_difference,

    SUM(
        CASE
            WHEN team_result = 'W' THEN 3
            WHEN team_result = 'D' THEN 1
            ELSE 0
        END
    ) AS points

FROM team_matches

GROUP BY team

ORDER BY
    points DESC,
    goal_difference DESC;