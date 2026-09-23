-- Team performance analysis
-- Calculates attacking and defensive performance
-- from the match-level PostgreSQL data.

WITH team_matches AS (

    -- Home-team perspective
    SELECT
        home_team AS team,
        home_goals AS goals_for,
        away_goals AS goals_against,
        home_shots AS shots,
        home_shots_on_target AS shots_on_target
    FROM matches

    UNION ALL

    -- Away-team perspective
    SELECT
        away_team AS team,
        away_goals AS goals_for,
        home_goals AS goals_against,
        away_shots AS shots,
        away_shots_on_target AS shots_on_target
    FROM matches
),

team_performance AS (

    SELECT
        team,
        COUNT(*) AS played,

        ROUND(
            AVG(goals_for),
            2
        ) AS goals_per_match,

        ROUND(
            AVG(goals_against),
            2
        ) AS goals_conceded_per_match,

        ROUND(
            AVG(shots),
            2
        ) AS shots_per_match,

        ROUND(
            AVG(shots_on_target),
            2
        ) AS shots_on_target_per_match,

        ROUND(
            AVG(shots_on_target) / NULLIF(AVG(shots), 0),
            3
        ) AS shot_accuracy,

        ROUND(
            AVG(goals_for) / NULLIF(AVG(shots), 0),
            3
        ) AS goal_conversion

    FROM team_matches

    GROUP BY team
)

SELECT
    team,
    played,
    goals_per_match,
    goals_conceded_per_match,
    shots_per_match,
    shots_on_target_per_match,
    shot_accuracy,
    goal_conversion,

    RANK() OVER (
        ORDER BY goals_per_match DESC
    ) AS attacking_rank,

    RANK() OVER (
        ORDER BY goals_conceded_per_match ASC
    ) AS defensive_rank,

    RANK() OVER (
        ORDER BY goal_conversion DESC
    ) AS conversion_rank


FROM team_performance

ORDER BY attacking_rank;