# Movie Ratings Demo — Views & Semantic Views

## Overview

A simple, student-friendly Snowflake demo with **3 tables**, **3 views**, and **1 semantic view** — designed to teach the difference between regular views and semantic views using popular movies everyone knows.

**Database:** `MOVIE_RATINGS.APP`

---

## Tables (3)

### MOVIES

| Column | Type | Description |
|--------|------|-------------|
| MOVIE_ID | INT (PK) | Unique movie identifier |
| TITLE | VARCHAR(100) | Movie title |
| GENRE | VARCHAR(30) | Genre (Sci-Fi, Action, Comedy, Drama, Thriller) |
| RELEASE_YEAR | INT | Year released |
| DIRECTOR | VARCHAR(60) | Director name |
| BUDGET_MILLIONS | DECIMAL(6,1) | Production budget in millions USD |

**Sample data:** Inception, The Dark Knight, Parasite, Interstellar, Spider-Man: No Way Home, Everything Everywhere All at Once, Oppenheimer, Barbie, Dune: Part Two, The Godfather

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

---

### USERS

| Column | Type | Description |
|--------|------|-------------|
| USER_ID | INT (PK) | Unique user identifier |
| USERNAME | VARCHAR(30) | Display name |
| AGE | INT | User age |
| COUNTRY | VARCHAR(30) | Country (USA, UK, India, Canada, Australia) |
| JOINED_DATE | DATE | Registration date |

**8 users** with fun usernames: movie_buff_22, cinephile_uk, nolan_fan, film_critic_99, popcorn_lover, sci_fi_geek, drama_queen, weekend_watcher

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

---

### REVIEWS

| Column | Type | Description |
|--------|------|-------------|
| REVIEW_ID | INT (PK) | Unique review identifier |
| USER_ID | INT (FK) | References USERS |
| MOVIE_ID | INT (FK) | References MOVIES |
| RATING | INT | Rating on 1-10 scale |
| REVIEW_TEXT | VARCHAR(300) | Written review |
| REVIEW_DATE | DATE | Date of review |

**20 reviews** with realistic comments like "Mind-bending! Watched it 3 times." and "Heath Ledger was iconic."

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

## Entity Relationships

```
USERS ──── REVIEWS ──── MOVIES
 (1:N)       (N:1)
```

---

## Regular Views (3) — Teaching JOINs & Aggregations

### V_MOVIE_LEADERBOARD
Movies ranked by average rating with review counts.

```sql
SELECT * FROM MOVIE_RATINGS.APP.V_MOVIE_LEADERBOARD ORDER BY AVG_RATING DESC;
```

| Column | Description |
|--------|-------------|
| TITLE | Movie title |
| GENRE | Genre |
| DIRECTOR | Director |
| RELEASE_YEAR | Year released |
| TOTAL_REVIEWS | Number of reviews |
| AVG_RATING | Average rating (1-10) |
| HIGHEST_RATING | Max rating received |
| LOWEST_RATING | Min rating received |

### V_USER_ACTIVITY
Per-user review summary showing engagement.

```sql
SELECT * FROM MOVIE_RATINGS.APP.V_USER_ACTIVITY ORDER BY REVIEWS_WRITTEN DESC;
```

| Column | Description |
|--------|-------------|
| USERNAME | User display name |
| AGE | User age |
| COUNTRY | User country |
| REVIEWS_WRITTEN | Total reviews by user |
| AVG_RATING_GIVEN | How generous/strict the user rates |
| FIRST_REVIEW | Date of first review |
| LAST_REVIEW | Date of most recent review |

### V_REVIEW_DETAILS
Enriched view joining all 3 tables — every review with movie + user info.

```sql
SELECT * FROM MOVIE_RATINGS.APP.V_REVIEW_DETAILS ORDER BY REVIEW_DATE DESC;
```

| Column | Description |
|--------|-------------|
| REVIEW_ID | Review identifier |
| USERNAME | Who wrote it |
| COUNTRY | Reviewer's country |
| MOVIE_TITLE | Which movie |
| GENRE | Movie genre |
| DIRECTOR | Movie director |
| RATING | Score given |
| REVIEW_TEXT | Written feedback |
| REVIEW_DATE | When reviewed |

---

## Semantic View (1) — The Star of the Demo

### SV_MOVIE_ANALYTICS

A **semantic view** adds business meaning on top of raw tables. It defines:
- **Facts** — measurable values (rating, budget)
- **Dimensions** — attributes to slice/filter by (title, genre, country)
- **Metrics** — pre-defined calculations (avg_rating, total_reviews)
- **Relationships** — how tables join together
- **Synonyms** — alternative names so natural language queries work

#### Defined Facts

| Fact | Source Column | Description |
|------|-------------|-------------|
| rating_value | REVIEWS.RATING | Rating given by user (1-10 scale) |
| budget | MOVIES.BUDGET_MILLIONS | Production budget in millions USD |

#### Defined Dimensions

| Dimension | Synonyms | Description |
|-----------|----------|-------------|
| movies.title | movie name, film | Title of the movie |
| movies.genre | category, type | Movie genre |
| movies.director | filmmaker, directed by | Director |
| movies.release_year | year, released | Release year |
| users.username | user, reviewer | Reviewer name |
| users.country | location, region | User country |
| users.age | — | User age |
| reviews.review_date | date, when reviewed | Review submission date |
| reviews.review_text | comment, feedback | Review content |

#### Defined Metrics

| Metric | Expression | Synonyms |
|--------|-----------|----------|
| avg_rating | AVG(rating) | average score, mean rating |
| total_reviews | COUNT(review_id) | review count, number of reviews |
| highest_rating | MAX(rating) | — |
| lowest_rating | MIN(rating) | — |
| avg_budget | AVG(budget) | — |

#### Relationships

```
REVIEWS.MOVIE_ID → MOVIES.MOVIE_ID
REVIEWS.USER_ID  → USERS.USER_ID
```

---

## Demo Queries

### Regular View Queries

```sql
-- Top rated movies
SELECT * FROM MOVIE_RATINGS.APP.V_MOVIE_LEADERBOARD ORDER BY AVG_RATING DESC;

-- Most active users
SELECT * FROM MOVIE_RATINGS.APP.V_USER_ACTIVITY ORDER BY REVIEWS_WRITTEN DESC;

-- All reviews enriched
SELECT * FROM MOVIE_RATINGS.APP.V_REVIEW_DETAILS ORDER BY REVIEW_DATE DESC;
```

### Semantic View Queries

```sql
-- Top movies by average rating and review count
SELECT * FROM SEMANTIC_VIEW(
  MOVIE_RATINGS.APP.SV_MOVIE_ANALYTICS
  METRICS reviews.avg_rating, reviews.total_reviews
  DIMENSIONS movies.title, movies.genre
) ORDER BY AVG_RATING DESC;

-- Ratings by country
SELECT * FROM SEMANTIC_VIEW(
  MOVIE_RATINGS.APP.SV_MOVIE_ANALYTICS
  METRICS reviews.avg_rating, reviews.total_reviews
  DIMENSIONS users.country
) ORDER BY TOTAL_REVIEWS DESC;

-- Director comparison
SELECT * FROM SEMANTIC_VIEW(
  MOVIE_RATINGS.APP.SV_MOVIE_ANALYTICS
  METRICS reviews.avg_rating, reviews.total_reviews, movies.avg_budget
  DIMENSIONS movies.director
) ORDER BY AVG_RATING DESC;

-- Genre breakdown
SELECT * FROM SEMANTIC_VIEW(
  MOVIE_RATINGS.APP.SV_MOVIE_ANALYTICS
  METRICS reviews.avg_rating, reviews.total_reviews
  DIMENSIONS movies.genre
) ORDER BY AVG_RATING DESC;
```

### Cortex Analyst (Natural Language)

With the semantic view, **Cortex Analyst** can answer plain English questions:
- "What are the top rated movies?"
- "Which country gives the highest ratings?"
- "How many reviews does each genre have?"
- "Show me Christopher Nolan movies by rating"

---

## View vs Semantic View — Key Differences for Students

| Feature | Regular View | Semantic View |
|---------|-------------|---------------|
| **What it is** | Saved SQL query | Business meaning layer over tables |
| **Queried with** | `SELECT * FROM view_name` | `SELECT * FROM SEMANTIC_VIEW(...)` |
| **Defines** | SQL logic (JOINs, WHERE, GROUP BY) | Facts, Dimensions, Metrics, Relationships |
| **Synonyms** | No | Yes — enables natural language |
| **Cortex Analyst** | Cannot use | Can use for text-to-SQL |
| **Pre-built metrics** | No (you write the AGG yourself) | Yes (AVG, COUNT, etc. defined once) |
| **Use case** | Simplify complex queries | Enable self-service analytics + AI |
