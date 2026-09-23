import os
from pathlib import Path

import numpy as np
import pandas as pd
from sqlalchemy import create_engine, text


# Project paths

PROJECT_ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = PROJECT_ROOT / "data" / "raw" / "E0.csv"


# Database connection

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg2://christianormsby@localhost:5432/premier_league"
)

TABLE_NAME = "matches"


# Columns needed from the CSV

REQUIRED_COLUMNS = [
    "Date",
    "HomeTeam",
    "AwayTeam",
    "FTHG",
    "FTAG",
    "FTR",
    "HS",
    "AS",
    "HST",
    "AST",
    "HF",
    "AF",
    "HC",
    "AC",
    "HY",
    "AY",
    "HR",
    "AR",
]


# Names to use in PostgreSQL

DATABASE_COLUMNS = [
    "match_date",
    "home_team",
    "away_team",
    "home_goals",
    "away_goals",
    "result",
    "home_shots",
    "away_shots",
    "home_shots_on_target",
    "away_shots_on_target",
    "home_fouls",
    "away_fouls",
    "home_corners",
    "away_corners",
    "home_yellow_cards",
    "away_yellow_cards",
    "home_red_cards",
    "away_red_cards",
]


def main():

    print("Starting Premier League match data load...")
    print()

    # Connect to PostgreSQL

    engine = create_engine(DATABASE_URL)

    print("Database engine created.")

    # Load the CSV

    if not CSV_PATH.exists():
        raise FileNotFoundError(
            f"CSV file not found: {CSV_PATH}"
        )

    df = pd.read_csv(CSV_PATH)

    print(
        f"CSV loaded successfully: "
        f"{len(df)} rows, {len(df.columns)} columns."
    )

    # Check the CSV has the columns we need

    missing_columns = [
        column
        for column in REQUIRED_COLUMNS
        if column not in df.columns
    ]

    if missing_columns:
        raise ValueError(
            f"Missing required source columns: {missing_columns}"
        )

    print("Source column validation passed.")

    # Select the columns for PostgreSQL

    matches = df[REQUIRED_COLUMNS].copy()

    print(
        f"Selected {len(matches.columns)} columns "
        "for the matches table."
    )

    # Rename the columns

    matches.columns = DATABASE_COLUMNS

    print("Column names transformed.")

    # Convert dates

    matches["match_date"] = pd.to_datetime(
        matches["match_date"],
        dayfirst=True,
        errors="coerce",
    )

    if matches["match_date"].isna().any():
        invalid_dates = matches.loc[
            matches["match_date"].isna()
        ]

        raise ValueError(
            f"Invalid match dates found:\n{invalid_dates}"
        )

    print("Date validation passed.")

    # Check for missing values

    missing_values = matches.isna().sum()

    missing_values = missing_values[
        missing_values > 0
    ]

    if not missing_values.empty:
        raise ValueError(
            f"Missing values found:\n{missing_values}"
        )

    print("Missing-value validation passed.")

    # Check the result values

    valid_results = {"H", "D", "A"}

    if not matches["result"].isin(valid_results).all():
        invalid_results = matches.loc[
            ~matches["result"].isin(valid_results),
            "result",
        ].unique()

        raise ValueError(
            f"Unexpected result values found: "
            f"{invalid_results}"
        )

    print("Result-value validation passed.")

    # Check results match the final scores

    expected_results = np.select(
        [
            matches["home_goals"] > matches["away_goals"],
            matches["home_goals"] < matches["away_goals"],
        ],
        [
            "H",
            "A",
        ],
        default="D",
    )

    result_mismatches = (
        matches["result"] != expected_results
    )

    if result_mismatches.any():
        mismatches = matches.loc[
            result_mismatches,
            [
                "match_date",
                "home_team",
                "away_team",
                "home_goals",
                "away_goals",
                "result",
            ],
        ]

        raise ValueError(
            "Result values do not match final scores:\n"
            f"{mismatches}"
        )

    print("Result and score validation passed.")

    # Check for duplicate matches

    duplicate_columns = [
        "match_date",
        "home_team",
        "away_team",
    ]

    duplicate_matches = matches[
        matches.duplicated(
            subset=duplicate_columns,
            keep=False,
        )
    ]

    if not duplicate_matches.empty:
        raise ValueError(
            "Duplicate matches found:\n"
            f"{duplicate_matches}"
        )

    print("Duplicate-match validation passed.")

    # Make sure we have some data

    if matches.empty:
        raise ValueError(
            "No match records found after transformation."
        )

    print(
        f"Data validation passed: "
        f"{len(matches)} matches ready to load."
    )

    # Refresh the matches table

    with engine.begin() as connection:

        connection.execute(
            text(f"DELETE FROM {TABLE_NAME}")
        )

        matches.to_sql(
            TABLE_NAME,
            connection,
            if_exists="append",
            index=False,
        )

    print()
    print(
        f"Successfully loaded {len(matches)} "
        f"matches into PostgreSQL."
    )


if __name__ == "__main__":
    main()