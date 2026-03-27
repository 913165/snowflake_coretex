# 🏋️ Gym Fitness Tracker — MySQL Database Script

## Schema Overview

```
MEMBERS ──── WORKOUTS ──── TRAINERS
                │
            EXERCISES
```

---

## Step 1 — Create Database

```sql
CREATE DATABASE IF NOT EXISTS GYM_TRACKER;
USE GYM_TRACKER;
```

---

## Step 2 — Create Tables

### TRAINERS

```sql
CREATE TABLE TRAINERS (
    trainer_id       INT           PRIMARY KEY AUTO_INCREMENT,
    trainer_name     VARCHAR(60)   NOT NULL,
    specialization   VARCHAR(50),
    experience_years INT,
    hourly_rate      DECIMAL(6,2)
);
```

### MEMBERS

```sql
CREATE TABLE MEMBERS (
    member_id       INT          PRIMARY KEY AUTO_INCREMENT,
    full_name       VARCHAR(60)  NOT NULL,
    age             INT,
    gender          VARCHAR(10),
    city            VARCHAR(40),
    join_date       DATE,
    membership_type VARCHAR(20)  -- Basic, Premium, Elite
);
```

### WORKOUTS

```sql
CREATE TABLE WORKOUTS (
    workout_id       INT  PRIMARY KEY AUTO_INCREMENT,
    member_id        INT  NOT NULL,
    trainer_id       INT,
    workout_date     DATE NOT NULL,
    duration_minutes INT,
    workout_type     VARCHAR(30),  -- Strength, Cardio, Yoga, CrossFit, HIIT
    calories_burned  INT,
    FOREIGN KEY (member_id)  REFERENCES MEMBERS(member_id),
    FOREIGN KEY (trainer_id) REFERENCES TRAINERS(trainer_id)
);
```

### EXERCISES

```sql
CREATE TABLE EXERCISES (
    exercise_id   INT          PRIMARY KEY AUTO_INCREMENT,
    workout_id    INT          NOT NULL,
    exercise_name VARCHAR(50)  NOT NULL,
    sets          INT,
    reps          INT,
    weight_kg     DECIMAL(5,1),
    FOREIGN KEY (workout_id) REFERENCES WORKOUTS(workout_id)
);
```

---

## Step 3 — Insert Data

### TRAINERS (6 rows)

```sql
INSERT INTO TRAINERS (trainer_name, specialization, experience_years, hourly_rate) VALUES
('Raj Mehta',       'Strength & Conditioning', 8,  1200.00),
('Priya Sharma',    'Yoga & Flexibility',       5,   900.00),
('Arjun Nair',      'CrossFit & HIIT',          6,  1100.00),
('Sneha Kulkarni',  'Cardio & Weight Loss',      4,   850.00),
('Vikram Desai',    'Bodybuilding',              10, 1500.00),
('Anjali Menon',    'Functional Training',        3,   800.00);
```

---

### MEMBERS (10 rows)

```sql
INSERT INTO MEMBERS (full_name, age, gender, city, join_date, membership_type) VALUES
('Aarav Singh',     28, 'Male',   'Mumbai',    '2023-01-10', 'Premium'),
('Divya Patel',     24, 'Female', 'Pune',      '2023-03-15', 'Basic'),
('Rahul Joshi',     32, 'Male',   'Bangalore', '2022-11-05', 'Elite'),
('Pooja Reddy',     26, 'Female', 'Hyderabad', '2023-06-20', 'Premium'),
('Karan Malhotra',  30, 'Male',   'Delhi',     '2023-02-28', 'Elite'),
('Neha Gupta',      22, 'Female', 'Mumbai',    '2024-01-08', 'Basic'),
('Siddharth Rao',   35, 'Male',   'Chennai',   '2022-08-14', 'Elite'),
('Meera Iyer',      29, 'Female', 'Bangalore', '2023-09-01', 'Premium'),
('Aditya Kumar',    27, 'Male',   'Pune',      '2023-07-17', 'Basic'),
('Shreya Bose',     31, 'Female', 'Kolkata',   '2023-04-22', 'Premium');
```

---

### WORKOUTS (25 rows)

```sql
INSERT INTO WORKOUTS (member_id, trainer_id, workout_date, duration_minutes, workout_type, calories_burned) VALUES
(1,  1, '2024-01-05', 60,  'Strength',  450),
(1,  1, '2024-01-12', 75,  'Strength',  520),
(2,  2, '2024-01-07', 45,  'Yoga',      200),
(2,  4, '2024-01-21', 50,  'Cardio',    380),
(3,  5, '2024-01-08', 90,  'Strength',  700),
(3,  3, '2024-01-22', 60,  'CrossFit',  600),
(4,  2, '2024-01-10', 50,  'Yoga',      210),
(4,  4, '2024-02-03', 55,  'Cardio',    400),
(5,  1, '2024-01-15', 80,  'Strength',  620),
(5,  3, '2024-01-29', 60,  'HIIT',      580),
(6,  4, '2024-02-01', 40,  'Cardio',    320),
(6,  2, '2024-02-14', 45,  'Yoga',      190),
(7,  5, '2024-01-18', 100, 'Strength',  780),
(7,  3, '2024-02-05', 70,  'CrossFit',  650),
(8,  6, '2024-01-20', 55,  'Functional',370),
(8,  2, '2024-02-10', 50,  'Yoga',      220),
(9,  4, '2024-02-02', 45,  'Cardio',    340),
(9,  3, '2024-02-18', 60,  'HIIT',      510),
(10, 1, '2024-01-25', 70,  'Strength',  530),
(10, 6, '2024-02-08', 60,  'Functional',390),
(3,  5, '2024-02-15', 85,  'Strength',  720),
(5,  1, '2024-02-20', 75,  'Strength',  590),
(1,  3, '2024-02-22', 55,  'HIIT',      500),
(7,  5, '2024-02-25', 95,  'Strength',  800),
(4,  4, '2024-03-01', 50,  'Cardio',    360);
```

---

### EXERCISES (30 rows)

```sql
INSERT INTO EXERCISES (workout_id, exercise_name, sets, reps, weight_kg) VALUES
-- Workout 1 (Aarav · Strength)
(1,  'Bench Press',       4, 10, 70.0),
(1,  'Deadlift',          3, 8,  100.0),
(1,  'Shoulder Press',    3, 12, 40.0),
-- Workout 3 (Divya · Yoga)
(3,  'Sun Salutation',    5, 1,  NULL),
(3,  'Warrior Pose',      3, 1,  NULL),
-- Workout 5 (Rahul · Strength)
(5,  'Squat',             5, 6,  120.0),
(5,  'Bench Press',       4, 8,  90.0),
(5,  'Pull-ups',          4, 10, NULL),
-- Workout 6 (Rahul · CrossFit)
(6,  'Box Jumps',         4, 15, NULL),
(6,  'Kettlebell Swings', 4, 20, 24.0),
(6,  'Burpees',           3, 15, NULL),
-- Workout 9 (Karan · Strength)
(9,  'Deadlift',          5, 5,  140.0),
(9,  'Barbell Row',       4, 10, 80.0),
(9,  'Incline Press',     3, 12, 60.0),
-- Workout 10 (Karan · HIIT)
(10, 'Sprint Intervals',  6, 1,  NULL),
(10, 'Jump Rope',         4, 1,  NULL),
-- Workout 13 (Siddharth · Strength)
(13, 'Squat',             6, 5,  150.0),
(13, 'Deadlift',          5, 4,  160.0),
(13, 'Bench Press',       5, 6,  100.0),
-- Workout 14 (Siddharth · CrossFit)
(14, 'Muscle-ups',        4, 8,  NULL),
(14, 'Kettlebell Swings', 5, 20, 32.0),
-- Workout 18 (Aditya · HIIT)
(18, 'Burpees',           4, 20, NULL),
(18, 'Mountain Climbers', 3, 30, NULL),
(18, 'Jump Squats',       4, 15, NULL),
-- Workout 19 (Shreya · Strength)
(19, 'Hip Thrust',        4, 12, 80.0),
(19, 'Romanian Deadlift', 3, 10, 60.0),
(19, 'Lat Pulldown',      3, 12, 50.0),
-- Workout 24 (Siddharth · Strength)
(24, 'Squat',             6, 4,  160.0),
(24, 'Deadlift',          5, 3,  170.0),
(24, 'Bench Press',       5, 5,  105.0);
```

---

## Entity Relationships

| Relationship | Type | Join Key |
|---|---|---|
| MEMBERS → WORKOUTS | 1 : N | `member_id` |
| TRAINERS → WORKOUTS | 1 : N | `trainer_id` |
| WORKOUTS → EXERCISES | 1 : N | `workout_id` |

---

## Sample Analytics Queries

```sql
-- Total calories burned per member
SELECT m.full_name, SUM(w.calories_burned) AS total_calories
FROM MEMBERS m
JOIN WORKOUTS w ON m.member_id = w.member_id
GROUP BY m.full_name
ORDER BY total_calories DESC;

-- Most popular workout type
SELECT workout_type, COUNT(*) AS session_count, ROUND(AVG(calories_burned), 0) AS avg_calories
FROM WORKOUTS
GROUP BY workout_type
ORDER BY session_count DESC;

-- Trainer workload & avg session duration
SELECT t.trainer_name, t.specialization,
       COUNT(w.workout_id)          AS total_sessions,
       ROUND(AVG(w.duration_minutes), 1) AS avg_duration_mins
FROM TRAINERS t
JOIN WORKOUTS w ON t.trainer_id = w.trainer_id
GROUP BY t.trainer_name, t.specialization
ORDER BY total_sessions DESC;

-- Members with most exercises logged
SELECT m.full_name, COUNT(e.exercise_id) AS exercises_logged
FROM MEMBERS m
JOIN WORKOUTS w  ON m.member_id  = w.member_id
JOIN EXERCISES e ON w.workout_id = e.workout_id
GROUP BY m.full_name
ORDER BY exercises_logged DESC;

-- Average calories burned by membership type
SELECT m.membership_type, ROUND(AVG(w.calories_burned), 0) AS avg_calories
FROM MEMBERS m
JOIN WORKOUTS w ON m.member_id = w.member_id
GROUP BY m.membership_type;
```
