-- Home vs away performance analysis
-- Compares team performance at home and away
-- using points, goals scored and goals conceded.

WITH team_matches AS (

    -- Home-team perspective
    SELECT
        match_date,
        home_team AS team,
        'Home' AS venue,
        home_goals AS goals_for,
        away_goals AS goals_against,
        CASE
            WHEN home_goals > away_goals THEN 'W'
            WHEN home_goals = away_goals THEN 'D'
            ELSE 'L'
        END AS result,
        CASE
            WHEN home_goals > away_goals THEN 3
            WHEN home_goals = away_goals THEN 1
            ELSE 0
        END AS points
    FROM matches

    UNION ALL

    -- Away-team perspective
    SELECT
        match_date,
        away_team AS team,
        'Away' AS venue,
        away_goals AS goals_for,
        home_goals AS goals_against,
        CASE
            WHEN away_goals > home_goals THEN 'W'
            WHEN away_goals = home_goals THEN 'D'
            ELSE 'L'
        END AS result,
        CASE
            WHEN away_goals > home_goals THEN 3
            WHEN away_goals = home_goals THEN 1
            ELSE 0
        END AS points
    FROM matches

)

,

team_performance AS (

    SELECT
        team,

        COUNT(*) AS matches,

        SUM(
            CASE
                WHEN venue = 'Home' THEN 1
                ELSE 0
            END
        ) AS home_matches,

        SUM(
            CASE
                WHEN venue = 'Away' THEN 1
                ELSE 0
            END
        ) AS away_matches,

        ROUND(
            AVG(
                CASE
                    WHEN venue = 'Home' THEN points
                END
            ),
            2
        ) AS home_points_per_match,

        ROUND(
            AVG(
                CASE
                    WHEN venue = 'Away' THEN points
                END
            ),
            2
        ) AS away_points_per_match,

        ROUND(
            AVG(
                CASE
                    WHEN venue = 'Home' THEN goals_for
                END
            ),
            2
        ) AS home_goals_per_match,

        ROUND(
            AVG(
                CASE
                    WHEN venue = 'Away' THEN goals_for
                END
            ),
            2
        ) AS away_goals_per_match,

        ROUND(
            AVG(
                CASE
                    WHEN venue = 'Home' THEN goals_against
                END
            ),
            2
        ) AS home_goals_conceded_per_match,

        ROUND(
            AVG(
                CASE
                    WHEN venue = 'Away' THEN goals_against
                END
            ),
            2
        ) AS away_goals_conceded_per_match

    FROM team_matches

    GROUP BY team

)

,

home_away_comparison AS (

    SELECT
        team,
        matches,
        home_matches,
        away_matches,
        home_points_per_match,
        away_points_per_match,
        home_goals_per_match,
        away_goals_per_match,
        home_goals_conceded_per_match,
        away_goals_conceded_per_match,

        ROUND(
            home_points_per_match - away_points_per_match,
            2
        ) AS home_points_advantage,

        ROUND(
            home_goals_per_match - away_goals_per_match,
            2
        ) AS home_goal_advantage,

        ROUND(
            away_goals_conceded_per_match
            - home_goals_conceded_per_match,
            2
        ) AS home_defensive_advantage

    FROM team_performance

)

SELECT
    team,
    matches,
    home_matches,
    away_matches,
    home_points_per_match,
    away_points_per_match,
    home_goals_per_match,
    away_goals_per_match,
    home_goals_conceded_per_match,
    away_goals_conceded_per_match,
    home_points_advantage,
    home_goal_advantage,
    home_defensive_advantage
FROM home_away_comparison
ORDER BY home_points_advantage DESC;