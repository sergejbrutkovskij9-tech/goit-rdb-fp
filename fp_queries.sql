-- Фінальний проєкт goit-rdb-fp
-- PostgreSQL 16

-- 1. Завантаження даних

CREATE SCHEMA IF NOT EXISTS pandemic;
SET search_path TO pandemic;

SHOW search_path;

-- імпорт CSV зроблено в notebook через pandas:
-- url = 'https://raw.githubusercontent.com/sergejbrutkovskij9-tech/goit-rdb-fp/main/infectious_cases.csv'
-- df = pd.read_csv(url, dtype=str, keep_default_na=False)
-- df.to_sql('infectious_cases', engine, schema='pandemic', if_exists='replace', index=False)

SELECT COUNT(*) AS n_rows
FROM infectious_cases;

SELECT *
FROM infectious_cases
LIMIT 10;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'pandemic'
  AND table_name = 'infectious_cases'
ORDER BY ordinal_position;

SELECT
    COUNT(*) FILTER (WHERE code = '')          AS empty_code,
    COUNT(*) FILTER (WHERE number_rabies = '') AS empty_rabies,
    COUNT(*) FILTER (WHERE number_malaria = '') AS empty_malaria,
    COUNT(*) FILTER (WHERE polio_cases = '')   AS empty_polio,
    COUNT(DISTINCT entity)                     AS n_entities,
    MIN(year)                                  AS min_year,
    MAX(year)                                  AS max_year
FROM infectious_cases;

DROP TABLE IF EXISTS infectious_cases_norm;
DROP TABLE IF EXISTS entities;

CREATE TABLE entities (
    id     SERIAL PRIMARY KEY,
    entity TEXT NOT NULL,
    code   TEXT,
    UNIQUE (entity, code)
);

INSERT INTO entities (entity, code)
SELECT DISTINCT entity, NULLIF(code, '')
FROM infectious_cases
ORDER BY entity;

CREATE TABLE infectious_cases_norm (
    id                   SERIAL PRIMARY KEY,
    entity_id            INTEGER NOT NULL REFERENCES entities(id),
    year                 INTEGER NOT NULL,
    number_yaws          NUMERIC,
    polio_cases          NUMERIC,
    cases_guinea_worm    NUMERIC,
    number_rabies        NUMERIC,
    number_malaria       NUMERIC,
    number_hiv           NUMERIC,
    number_tuberculosis  NUMERIC,
    number_smallpox      NUMERIC,
    number_cholera_cases NUMERIC,
    UNIQUE (entity_id, year)
);

INSERT INTO infectious_cases_norm (
    entity_id, year, number_yaws, polio_cases, cases_guinea_worm, number_rabies,
    number_malaria, number_hiv, number_tuberculosis, number_smallpox, number_cholera_cases
)
SELECT
    e.id,
    ic.year::INTEGER,
    NULLIF(ic.number_yaws, '')::NUMERIC,
    NULLIF(ic.polio_cases, '')::NUMERIC,
    NULLIF(ic.cases_guinea_worm, '')::NUMERIC,
    NULLIF(ic.number_rabies, '')::NUMERIC,
    NULLIF(ic.number_malaria, '')::NUMERIC,
    NULLIF(ic.number_hiv, '')::NUMERIC,
    NULLIF(ic.number_tuberculosis, '')::NUMERIC,
    NULLIF(ic.number_smallpox, '')::NUMERIC,
    NULLIF(ic.number_cholera_cases, '')::NUMERIC
FROM infectious_cases ic
JOIN entities e
    ON e.entity = ic.entity
   AND e.code IS NOT DISTINCT FROM NULLIF(ic.code, '')
ORDER BY e.id, ic.year::INTEGER;

SELECT
    (SELECT COUNT(*) FROM infectious_cases)      AS raw_rows,
    (SELECT COUNT(*) FROM infectious_cases_norm) AS norm_rows,
    (SELECT COUNT(*) FROM entities)              AS n_entities;

SELECT *
FROM entities
ORDER BY id
LIMIT 10;

SELECT *
FROM infectious_cases_norm
ORDER BY id
LIMIT 10;

-- 3. Аналіз Number_rabies

SELECT
    e.id,
    e.entity,
    e.code,
    ROUND(AVG(n.number_rabies), 2) AS avg_rabies,
    ROUND(MIN(n.number_rabies), 2) AS min_rabies,
    ROUND(MAX(n.number_rabies), 2) AS max_rabies,
    ROUND(SUM(n.number_rabies), 2) AS sum_rabies
FROM infectious_cases_norm n
JOIN entities e ON e.id = n.entity_id
WHERE n.number_rabies IS NOT NULL
GROUP BY e.id, e.entity, e.code
ORDER BY avg_rabies DESC
LIMIT 10;

SELECT
    e.entity,
    n.year,
    MAKE_DATE(n.year, 1, 1) AS start_date,
    CURRENT_DATE AS cur_date,
    DATE_PART('year', AGE(CURRENT_DATE, MAKE_DATE(n.year, 1, 1)))::INTEGER AS year_diff
FROM infectious_cases_norm n
JOIN entities e ON e.id = n.entity_id
ORDER BY n.id
LIMIT 10;

-- 5. Власні функції

DROP FUNCTION IF EXISTS year_diff(INTEGER);

CREATE FUNCTION year_diff(y INTEGER)
RETURNS INTEGER
LANGUAGE sql
AS $$
    SELECT DATE_PART('year', AGE(CURRENT_DATE, MAKE_DATE(y, 1, 1)))::INTEGER;
$$;

SELECT year_diff(1996) AS diff_1996, year_diff(2000) AS diff_2000;

SELECT
    e.entity,
    n.year,
    MAKE_DATE(n.year, 1, 1) AS start_date,
    year_diff(n.year) AS year_diff_func,
    DATE_PART('year', AGE(CURRENT_DATE, MAKE_DATE(n.year, 1, 1)))::INTEGER AS year_diff_builtin
FROM infectious_cases_norm n
JOIN entities e ON e.id = n.entity_id
ORDER BY n.id
LIMIT 10;

SELECT COUNT(*) AS n_mismatch
FROM infectious_cases_norm
WHERE year_diff(year) <> DATE_PART('year', AGE(CURRENT_DATE, MAKE_DATE(year, 1, 1)))::INTEGER;

DROP FUNCTION IF EXISTS avg_cases(NUMERIC, NUMERIC);

CREATE FUNCTION avg_cases(cases NUMERIC, divider NUMERIC)
RETURNS NUMERIC
LANGUAGE sql
AS $$
    SELECT ROUND(cases / NULLIF(divider, 0), 2);
$$;

SELECT avg_cases(120, 12) AS per_month, avg_cases(120, 4) AS per_quarter, avg_cases(120, 2) AS per_half, avg_cases(120, 0) AS div_zero;

SELECT
    e.entity,
    n.year,
    n.number_rabies,
    avg_cases(n.number_rabies, 12) AS rabies_per_month,
    avg_cases(n.number_rabies, 4)  AS rabies_per_quarter,
    avg_cases(n.number_rabies, 2)  AS rabies_per_half_year
FROM infectious_cases_norm n
JOIN entities e ON e.id = n.entity_id
WHERE n.number_rabies IS NOT NULL
ORDER BY n.id
LIMIT 10;

SELECT
    entity,
    year,
    number_rabies,
    avg_cases(number_rabies::NUMERIC, 12) AS rabies_per_month,
    avg_cases(number_rabies::NUMERIC, 4)  AS rabies_per_quarter,
    avg_cases(number_rabies::NUMERIC, 2)  AS rabies_per_half_year
FROM infectious_cases
WHERE number_rabies ~ '^[0-9]+(\.[0-9]+)?$'
ORDER BY entity, year::INTEGER
LIMIT 10;

-- Висновки
