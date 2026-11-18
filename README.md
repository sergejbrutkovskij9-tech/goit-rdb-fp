# goit-rdb-fp

Фінальний проєкт з курсу реляційних баз даних. Датасет `infectious_cases.csv` - статистика інфекційних захворювань по країнах і роках.

## Файли

- `goit_rdb_fp.ipynb` - notebook з усіма запитами і результатами (PostgreSQL 16 у Colab через pgserver)
- `fp_queries.sql` - ті самі SQL-запити одним файлом
- `infectious_cases.csv` - вихідні дані
- `screenshots/` - скриншоти запитів і результатів

## Що зроблено

1. Завантаження даних. Створено схему `pandemic` (`CREATE SCHEMA`), вона встановлена за замовчуванням (`SET search_path TO pandemic`). CSV імпортовано через pandas `to_sql` у таблицю `infectious_cases` (10521 рядок, 12 колонок, усі як текст, як у файлі).
2. Нормалізація до 3НФ.
   - `entities` - унікальні комбінації `entity` + `code` (245 рядків, `id` - PK);
   - `infectious_cases_norm` - показники по роках з `entity_id` (FK на `entities`) замість назви і коду. Порожні значення перетворені на `NULL`, числа - на `NUMERIC`.
3. Аналіз `Number_rabies`. AVG, MIN, MAX, SUM для кожної комбінації `entity` + `code`, сортування за середнім за спаданням, 10 рядків.
4. Різниця в роках. `MAKE_DATE(year, 1, 1)`, `CURRENT_DATE` і `DATE_PART('year', AGE(...))`.
5. Власні функції.
   - `year_diff(y)` - різниця в роках між 1 січня року `y` і поточною датою;
   - `avg_cases(cases, divider)` - середня кількість захворювань за період (12 - місяць, 4 - квартал, 2 - півріччя), використана тільки для рядків з числовим значенням.

## Запуск

1. Відкрити `goit_rdb_fp.ipynb` у Google Colab.
2. Runtime → Run all.

CSV читається напряму з цього репозиторію:
`https://raw.githubusercontent.com/sergejbrutkovskij9-tech/goit-rdb-fp/main/infectious_cases.csv`
