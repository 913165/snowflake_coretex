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

### USERS

| Column | Type | Description |
|--------|------|-------------|
| USER_ID | INT (PK) | Unique user identifier |
| USERNAME | VARCHAR(30) | Display name |
| AGE | INT | User age |
| COUNTRY | VARCHAR(30) | Country (USA, UK, India, Canada, Australia) |
| JOINED_DATE | DATE | Registration date |

**8 users** with fun usernames: movie_buff_22, cinephile_uk, nolan_fan, film_critic_99, popcorn_lover, sci_fi_geek, drama_queen, weekend_watcher

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
