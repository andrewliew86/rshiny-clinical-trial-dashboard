# RShiny clinical trials dashboard

This project is an **R Shiny** dashboard that provides an overview of the landscape of clinical trials related to infections. The dashboard leverages real-world data from the [AACT database](https://aact.ctti-clinicaltrials.org/), which is hosted by the Clinical Trials Transformation Initiative (CTTI). It allows users to explore key information such as sponsors, trial phases, geographic distribution reported in these trials.

**Figure 1: Clinical trials dashboard built with RShiny**

<img src="https://github.com/andrewliew86/rshiny-clinical-trial-dashboard/blob/main/images/dashboard.PNG" width=100% height=100%>

## Features

- **Data Source**: Data on infection-related trials are extracted from the AACT database, restored as a PostgreSQL database in a Docker container using Python.
- **SQL Queries**: Data extraction is performed using SQL, joining key tables such as `studies`, `sponsors`, `conditions` to focus on infection-related trials.

## Data Extraction

The SQL query aggregates relevant information from multiple tables:
- **Sponsors**: Aggregated by clinical trial (`nct_id`).
- **Countries**: Grouped by trial location.
- **Reported Events**: Organ systems affected, reported during the trials.

```sql
WITH grouped_sponsors AS (
    SELECT nct_id, STRING_AGG(DISTINCT name::varchar, '|') AS sponsors
    FROM ctgov.sponsors
    GROUP BY nct_id
),
grouped_countries AS (
    SELECT nct_id, STRING_AGG(DISTINCT name::varchar, '|') AS countries
    FROM ctgov.countries
    GROUP BY nct_id
),
grouped_reported_events AS (
    SELECT nct_id, STRING_AGG(DISTINCT organ_system::varchar, '|') AS organ_systems
    FROM ctgov.reported_events
    GROUP BY nct_id
)
SELECT ctgov.studies.*, gs.sponsors, gc.countries, gre.organ_systems
FROM ctgov.conditions
JOIN ctgov.studies USING(nct_id)
JOIN grouped_sponsors gs USING(nct_id)
JOIN grouped_countries gc USING(nct_id)
JOIN grouped_reported_events gre USING(nct_id)
WHERE downcase_name LIKE '%infection%'
AND ctgov.studies.overall_status != 'TERMINATED';
```

## Usage

1. **Setup**: The database is set up in a local Docker container running PostgreSQL. The data from the AACT database is loaded into this database.
2. **Dashboard**: The R Shiny app visualizes the extracted data, providing a user-friendly interface to explore the infection-related trials.

## Prerequisites

- **Docker**: Used to run the PostgreSQL database in a container.
- **Python**: For setting up the Docker container, restoring the data dump and running the SQL queries
- **R Shiny**: For creating the interactive dashboard.
