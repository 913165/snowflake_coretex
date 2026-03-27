Here's a clean and simple suggestion:

**Database Name**
```
skybook_db
```

**Schema Name**
```
booking
```

---

So your full table references would look like:

```
booking.passengers
booking.airlines
booking.flights
booking.bookings
```

---

**Full SQL to create it:**

```sql
CREATE DATABASE skybook_db;

CREATE SCHEMA booking;

CREATE TABLE booking.passengers (
    id       SERIAL PRIMARY KEY,
    name     VARCHAR(100) NOT NULL,
    email    VARCHAR(100),
    phone    VARCHAR(20)
);

CREATE TABLE booking.airlines (
    id       SERIAL PRIMARY KEY,
    name     VARCHAR(100) NOT NULL
);

CREATE TABLE booking.flights (
    id          SERIAL PRIMARY KEY,
    airline_id  INT REFERENCES booking.airlines(id),
    flight_no   VARCHAR(20) NOT NULL,
    origin      VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    travel_date DATE NOT NULL,
    class       VARCHAR(20)
);

CREATE TABLE booking.bookings (
    id           SERIAL PRIMARY KEY,
    ref          VARCHAR(20) UNIQUE NOT NULL,
    passenger_id INT REFERENCES booking.passengers(id),
    flight_id    INT REFERENCES booking.flights(id),
    price        NUMERIC(10,2) NOT NULL,
    status       VARCHAR(20) DEFAULT 'pending'
);
```

This is written for **PostgreSQL**. Want me to also generate the sample `INSERT` statements for the 5 passengers already in the demo?
