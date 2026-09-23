-- Team form analysis
-- Calculates cumulative and rolling 5-match points
-- from the match-level PostgreSQL data.

WITH team_matches AS (

    -- Home-team perspective
    SELECT
        match_date,
        home_team AS team,
        away_team AS opponent,
        home_goals AS goals_for,
        away_goals AS goals_against,
        CASE
            WHEN home_goals > away_goals THEN 'W'
            WHEN home_goals = away_goals THEN 'D'
            ELSE 'L'
        END AS result
    FROM matches

    UNION ALL

    -- Away-team perspective
    SELECT
        match_date,
        away_team AS team,
        home_team AS opponent,
        away_goals AS goals_for,
        home_goals AS goals_against,
        CASE
            WHEN away_goals > home_goals THEN 'W'
            WHEN away_goals = home_goals THEN 'D'
            ELSE 'L'
        END AS result
    FROM matches

),

team_points AS (

    SELECT
        match_date,
        team,
        opponent,
        goals_for,
        goals_against,
        result,
        CASE
            WHEN result = 'W' THEN 3
            WHEN result = 'D' THEN 1
            ELSE 0
        END AS points
    FROM team_matches

),

form_analysis AS (

    SELECT
        match_date,
        team,
        opponent,
        goals_for,
        goals_against,
        result,
        points,

        ROW_NUMBER() OVER (
            PARTITION BY team
            ORDER BY match_date
        ) AS match_number,

        SUM(points) OVER (
            PARTITION BY team
            ORDER BY match_date
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_points

    FROM team_points

),

form_metrics AS (

    SELECT
        match_date,
        team,
        opponent,
        goals_for,
        goals_against,
        result,
        points,
        match_number,
        cumulative_points,

        CASE
            WHEN match_number >= 5 THEN
                SUM(points) OVER (
                    PARTITION BY team
                    ORDER BY match_date
                    ROWS BETWEEN 4 PRECEDING
                    AND CURRENT ROW
                )
        END AS rolling_5_match_points,
        
        CASE
            WHEN match_number >= 5 THEN
                ROUND(
                    100.0 * SUM(
                        CASE
                            WHEN result = 'W' THEN 1
                            ELSE 0
                        END
                    ) OVER (
                        PARTITION BY team
                        ORDER BY match_date
                        ROWS BETWEEN 4 PRECEDING
                        AND CURRENT ROW
                    ) / 5,
                    1
                )
        END AS rolling_5_match_win_rate
    FROM form_analysis

)

SELECT
    match_date,
    team,
    opponent,
    goals_for,
    goals_against,
    result,
    points,
    match_number,
    cumulative_points,
    rolling_5_match_points,
    rolling_5_match_win_rate
FROM form_metrics
ORDER BY
    team,
    match_date;