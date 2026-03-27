# Movie Ratings - Semantic View Demo (YAML Approach)

This guide walks through creating a Snowflake database with movie ratings data and building a **Semantic View** from a YAML-based semantic model using `SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML`.

---

## 1. Create Database and Schema

```sql
CREATE DATABASE MOVIE_RATINGS;

CREATE SCHEMA MOVIE_RATINGS.APP;
```

---

## 2. Create Tables

### MOVIES - Stores movie metadata including title, genre, director, and budget.

```sql
CREATE TABLE MOVIE_RATINGS.APP.MOVIES (
    MOVIE_ID         INT            PRIMARY KEY,
    TITLE            VARCHAR(100)   NOT NULL,
    GENRE            VARCHAR(30),
    RELEASE_YEAR     INT,
    DIRECTOR         VARCHAR(60),
    BUDGET_MILLIONS  DECIMAL(6,1)
);
```

### USERS - Stores user profiles who write reviews.

```sql
CREATE TABLE MOVIE_RATINGS.APP.USERS (
    USER_ID      INT          PRIMARY KEY,
    USERNAME     VARCHAR(30)  NOT NULL,
    AGE          INT,
    COUNTRY      VARCHAR(30),
    JOINED_DATE  DATE
);
```

### REVIEWS - Stores user reviews with ratings (1-10 scale) for movies.

```sql
CREATE TABLE MOVIE_RATINGS.APP.REVIEWS (
    REVIEW_ID    INT           PRIMARY KEY,
    USER_ID      INT           NOT NULL REFERENCES MOVIE_RATINGS.APP.USERS(USER_ID),
    MOVIE_ID     INT           NOT NULL REFERENCES MOVIE_RATINGS.APP.MOVIES(MOVIE_ID),
    RATING       INT,
    REVIEW_TEXT  VARCHAR(300),
    REVIEW_DATE  DATE
);
```

> **Note:** Snowflake does not support `CHECK` constraints, so rating validation (1-10) should be enforced at the application layer.

---

## 3. Insert Sample Data

### Movies - 10 popular films across genres and decades.

```sql
INSERT INTO MOVIE_RATINGS.APP.MOVIES VALUES
(1,  'Inception',                           'Sci-Fi',  2010, 'Christopher Nolan',     160.0),
(2,  'The Dark Knight',                     'Action',  2008, 'Christopher Nolan',     185.0),
(3,  'Parasite',                            'Thriller',2019, 'Bong Joon-ho',           11.4),
(4,  'Interstellar',                        'Sci-Fi',  2014, 'Christopher Nolan',     165.0),
(5,  'Spider-Man: No Way Home',             'Action',  2021, 'Jon Watts',             200.0),
(6,  'Everything Everywhere All at Once',   'Comedy',  2022, 'Daniel Kwan',            25.0),
(7,  'Oppenheimer',                         'Drama',   2023, 'Christopher Nolan',     100.0),
(8,  'Barbie',                              'Comedy',  2023, 'Greta Gerwig',          145.0),
(9,  'Dune: Part Two',                      'Sci-Fi',  2024, 'Denis Villeneuve',      190.0),
(10, 'The Godfather',                       'Drama',   1972, 'Francis Ford Coppola',    6.0);
```

### Users - 8 reviewers from different countries.

```sql
INSERT INTO MOVIE_RATINGS.APP.USERS VALUES
(1, 'movie_buff_22',    22, 'USA',       '2023-01-15'),
(2, 'cinephile_uk',     28, 'UK',        '2022-06-10'),
(3, 'nolan_fan',        19, 'India',     '2023-08-20'),
(4, 'film_critic_99',   35, 'USA',       '2021-03-01'),
(5, 'popcorn_lover',    24, 'Canada',    '2023-11-05'),
(6, 'sci_fi_geek',      31, 'Australia', '2022-09-12'),
(7, 'drama_queen',      27, 'UK',        '2024-01-20'),
(8, 'weekend_watcher',  20, 'India',     '2024-03-10');
```

### Reviews - 20 reviews with ratings and comments.

```sql
INSERT INTO MOVIE_RATINGS.APP.REVIEWS VALUES
(1,  1, 1,  9,  'Mind-bending! Watched it 3 times.',        '2024-01-10'),
(2,  1, 7,  10, 'Cillian Murphy was phenomenal.',           '2024-02-15'),
(3,  2, 3,  10, 'Absolute masterpiece. Deserved every Oscar.','2023-05-20'),
(4,  2, 10, 9,  'A timeless classic.',                      '2023-07-01'),
(5,  3, 1,  10, 'Nolan is a genius!',                       '2024-03-05'),
(6,  3, 4,  9,  'Made me cry. Hans Zimmer killed it.',      '2024-03-06'),
(7,  3, 2,  10, 'Best superhero movie ever made.',          '2024-03-07'),
(8,  4, 6,  8,  'Creative and weird. Loved it.',            '2024-01-25'),
(9,  4, 8,  7,  'Fun but overhyped.',                       '2024-02-01'),
(10, 4, 3,  9,  'Brilliant social commentary.',             '2024-02-10'),
(11, 5, 5,  8,  'Nostalgia overload! All 3 Spider-Men!',   '2024-04-01'),
(12, 5, 9,  9,  'Better than Part One.',                    '2024-04-15'),
(13, 6, 1,  8,  'Great concept, slightly confusing.',       '2024-05-01'),
(14, 6, 4,  10, 'Best space movie ever.',                   '2024-05-02'),
(15, 6, 9,  10, 'Visually stunning. Chalamet nailed it.',   '2024-05-10'),
(16, 7, 7,  9,  'Heavy but important film.',                '2024-06-01'),
(17, 7, 10, 10, 'Nothing beats The Godfather.',             '2024-06-05'),
(18, 7, 8,  6,  'Entertaining but shallow.',                '2024-06-10'),
(19, 8, 2,  9,  'Heath Ledger was iconic.',                 '2024-07-01'),
(20, 8, 5,  7,  'Good fan service but messy plot.',         '2024-07-10');
```

---

## 4. Semantic Model YAML

The YAML file defines the semantic layer: tables, dimensions, facts, metrics, relationships, and verified queries. Save this as `movie_ratings_semantic.yaml`.

```yaml
name: SV_MOVIE_ANALYTICS
description: "Semantic view for movie ratings analytics - covers movies, users, and reviews"

tables:
  - name: movies
    description: "Movies table with title, genre, director, and budget"
    base_table:
      database: MOVIE_RATINGS
      schema: APP
      table: MOVIES
    primary_key:
      columns:
        - MOVIE_ID
    dimensions:
      - name: title
        synonyms:
          - "movie name"
          - "film"
        description: "Title of the movie"
        expr: TITLE
        data_type: VARCHAR(100)
      - name: genre
        synonyms:
          - "category"
          - "type"
        description: "Movie genre"
        expr: GENRE
        data_type: VARCHAR(30)
        is_enum: true
        sample_values:
          - "Sci-Fi"
          - "Action"
          - "Drama"
          - "Comedy"
          - "Thriller"
      - name: director
        synonyms:
          - "filmmaker"
          - "directed by"
        description: "Director of the movie"
        expr: DIRECTOR
        data_type: VARCHAR(60)
      - name: release_year
        synonyms:
          - "year"
          - "released"
        description: "Year the movie was released"
        expr: RELEASE_YEAR
        data_type: NUMBER
    facts:
      - name: budget
        description: "Production budget in millions USD"
        expr: BUDGET_MILLIONS
        data_type: "NUMBER(6,1)"
    metrics:
      - name: avg_budget
        description: "Average production budget in millions"
        expr: AVG(movies.budget)

  - name: users
    description: "Users who write reviews"
    base_table:
      database: MOVIE_RATINGS
      schema: APP
      table: USERS
    primary_key:
      columns:
        - USER_ID
    dimensions:
      - name: username
        synonyms:
          - "user"
          - "reviewer"
        description: "Reviewer username"
        expr: USERNAME
        data_type: VARCHAR(30)
      - name: country
        synonyms:
          - "location"
          - "region"
        description: "User country"
        expr: COUNTRY
        data_type: VARCHAR(30)
        is_enum: true
        sample_values:
          - "USA"
          - "UK"
          - "India"
          - "Canada"
          - "Australia"
      - name: age
        description: "User age"
        expr: AGE
        data_type: NUMBER
    time_dimensions:
      - name: joined_date
        synonyms:
          - "signup date"
          - "registration date"
        description: "Date the user joined the platform"
        expr: JOINED_DATE
        data_type: DATE
    metrics:
      - name: total_users
        description: "Total number of users"
        expr: COUNT(USER_ID)

  - name: reviews
    description: "User reviews and ratings for movies"
    base_table:
      database: MOVIE_RATINGS
      schema: APP
      table: REVIEWS
    primary_key:
      columns:
        - REVIEW_ID
    dimensions:
      - name: review_text
        synonyms:
          - "comment"
          - "feedback"
        description: "Review content written by the user"
        expr: REVIEW_TEXT
        data_type: VARCHAR(300)
    time_dimensions:
      - name: review_date
        synonyms:
          - "date"
          - "when reviewed"
        description: "Date the review was submitted"
        expr: REVIEW_DATE
        data_type: DATE
    facts:
      - name: rating_value
        description: "Rating given by user on a 1-10 scale"
        expr: RATING
        data_type: NUMBER
    metrics:
      - name: avg_rating
        synonyms:
          - "average score"
          - "mean rating"
        description: "Average rating across reviews"
        expr: AVG(reviews.rating_value)
      - name: total_reviews
        synonyms:
          - "review count"
          - "number of reviews"
        description: "Total number of reviews"
        expr: COUNT(REVIEW_ID)
      - name: highest_rating
        description: "Highest rating received"
        expr: MAX(reviews.rating_value)
      - name: lowest_rating
        description: "Lowest rating received"
        expr: MIN(reviews.rating_value)

relationships:
  - name: reviews_to_movies
    left_table: reviews
    right_table: movies
    relationship_columns:
      - left_column: MOVIE_ID
        right_column: MOVIE_ID
  - name: reviews_to_users
    left_table: reviews
    right_table: users
    relationship_columns:
      - left_column: USER_ID
        right_column: USER_ID

verified_queries:
  - name: top_rated_movies
    question: "What are the top rated movies?"
    sql: |
      SELECT movies.title, AVG(reviews.rating_value) AS avg_rating
      FROM reviews JOIN movies ON reviews.MOVIE_ID = movies.MOVIE_ID
      GROUP BY movies.title
      ORDER BY avg_rating DESC
      LIMIT 10
    use_as_onboarding_question: true

  - name: reviews_by_country
    question: "How many reviews were written by users from each country?"
    sql: |
      SELECT users.country, COUNT(reviews.REVIEW_ID) AS total_reviews
      FROM reviews JOIN users ON reviews.USER_ID = users.USER_ID
      GROUP BY users.country
      ORDER BY total_reviews DESC
    use_as_onboarding_question: true

  - name: nolan_movies_avg_rating
    question: "What is the average rating for Christopher Nolan movies?"
    sql: |
      SELECT movies.title, AVG(reviews.rating_value) AS avg_rating
      FROM reviews JOIN movies ON reviews.MOVIE_ID = movies.MOVIE_ID
      WHERE movies.DIRECTOR = 'Christopher Nolan'
      GROUP BY movies.title
      ORDER BY avg_rating DESC
    use_as_onboarding_question: true
```

---

## 5. Upload YAML to Stage

Create an internal stage and copy the YAML file from the workspace.

```sql
CREATE OR REPLACE STAGE MOVIE_RATINGS.APP.SEMANTIC_MODELS
  DIRECTORY = (ENABLE = TRUE);

COPY FILES INTO @MOVIE_RATINGS.APP.SEMANTIC_MODELS
FROM 'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live'
FILES=('movie_ratings_semantic.yaml');
```

---

## 6. Validate YAML (Dry Run)

Before creating the semantic view, validate the YAML with `dry_run = TRUE`. This checks for syntax and schema errors without creating any object.

```sql
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'MOVIE_RATINGS.APP',
  $$ <paste full YAML content here> $$,
  TRUE   -- dry_run: validate only, do not create
);
-- Expected output: "YAML file is valid for creating a semantic view. No object has been created yet."
```

---

## 7. Create Semantic View from YAML

Once validated, create the semantic view by calling without the dry_run flag.

```sql
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'MOVIE_RATINGS.APP',
  $$ <paste full YAML content here> $$
);
-- Expected output: "Semantic view was successfully created."
```

> **Tip:** The first argument is the target schema (`DATABASE.SCHEMA`). The semantic view name comes from the `name` field in the YAML (`SV_MOVIE_ANALYTICS`).

---

## 8. Verify the Semantic View

### List semantic views in the schema

```sql
SHOW SEMANTIC VIEWS IN SCHEMA MOVIE_RATINGS.APP;
```

### Inspect metrics defined in the semantic view

```sql
SHOW SEMANTIC METRICS IN MOVIE_RATINGS.APP.SV_MOVIE_ANALYTICS;
```

### Inspect dimensions

```sql
SHOW SEMANTIC DIMENSIONS IN MOVIE_RATINGS.APP.SV_MOVIE_ANALYTICS;
```

---

## 9. Sample Queries Using the Semantic View

### Top rated movies - Returns movies ranked by average rating.

```sql
SELECT *
FROM SEMANTIC_VIEW(
    MOVIE_RATINGS.APP.SV_MOVIE_ANALYTICS
    METRICS reviews.avg_rating
    DIMENSIONS movies.title
)
ORDER BY avg_rating DESC
LIMIT 10;
```

### Reviews per genre - Shows how many reviews each genre received and their average rating.

```sql
SELECT *
FROM SEMANTIC_VIEW(
    MOVIE_RATINGS.APP.SV_MOVIE_ANALYTICS
    METRICS reviews.avg_rating, reviews.total_reviews
    DIMENSIONS movies.genre
)
ORDER BY total_reviews DESC;
```

### Reviews by country - Breaks down review activity by user country.

```sql
SELECT *
FROM SEMANTIC_VIEW(
    MOVIE_RATINGS.APP.SV_MOVIE_ANALYTICS
    METRICS reviews.total_reviews, reviews.avg_rating
    DIMENSIONS users.country
)
ORDER BY total_reviews DESC;
```

### Director leaderboard - Ranks directors by average rating across all their reviewed films.

```sql
SELECT *
FROM SEMANTIC_VIEW(
    MOVIE_RATINGS.APP.SV_MOVIE_ANALYTICS
    METRICS reviews.avg_rating, reviews.total_reviews
    DIMENSIONS movies.director
)
ORDER BY avg_rating DESC;
```

### Monthly review trend - Shows review volume and average ratings over time.

```sql
SELECT *
FROM SEMANTIC_VIEW(
    MOVIE_RATINGS.APP.SV_MOVIE_ANALYTICS
    METRICS reviews.total_reviews, reviews.avg_rating
    DIMENSIONS reviews.review_date
)
ORDER BY review_date;
```

### Rating extremes per movie - Shows the highest and lowest rating each movie received.

```sql
SELECT *
FROM SEMANTIC_VIEW(
    MOVIE_RATINGS.APP.SV_MOVIE_ANALYTICS
    METRICS reviews.highest_rating, reviews.lowest_rating, reviews.avg_rating
    DIMENSIONS movies.title
)
ORDER BY avg_rating DESC;
```

### Average budget by genre - Compares production budgets across genres.

```sql
SELECT *
FROM SEMANTIC_VIEW(
    MOVIE_RATINGS.APP.SV_MOVIE_ANALYTICS
    METRICS movies.avg_budget
    DIMENSIONS movies.genre
)
ORDER BY avg_budget DESC;
```

---

## YAML Key Concepts

| Section | Purpose |
|---|---|
| **tables** | Maps logical table names to physical Snowflake tables |
| **dimensions** | Categorical/descriptive columns used for grouping and filtering |
| **time_dimensions** | Date/time columns for time-series analysis |
| **facts** | Numeric columns used in aggregations |
| **metrics** | Pre-defined aggregate expressions (AVG, COUNT, MAX, MIN, etc.) |
| **relationships** | Join paths between tables (foreign key references) |
| **verified_queries** | Example Q&A pairs that improve Cortex Analyst accuracy |
| **synonyms** | Alternative names so natural language queries can match columns |
| **is_enum / sample_values** | Helps Cortex Analyst understand valid categorical values |
