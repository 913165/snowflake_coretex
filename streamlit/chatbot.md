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

CREATE TABLE SKYBOOK_DB.BOOKING.PASSENGERS (
    id       NUMBER AUTOINCREMENT PRIMARY KEY,
    name     VARCHAR(100) NOT NULL,
    email    VARCHAR(100),
    phone    VARCHAR(20)
);

CREATE TABLE SKYBOOK_DB.BOOKING.AIRLINES (
    id       NUMBER AUTOINCREMENT PRIMARY KEY,
    name     VARCHAR(100) NOT NULL
);

CREATE TABLE SKYBOOK_DB.BOOKING.FLIGHTS (
    id          NUMBER AUTOINCREMENT PRIMARY KEY,
    airline_id  INT REFERENCES SKYBOOK_DB.BOOKING.AIRLINES(id),
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

INSERT INTO SKYBOOK_DB.BOOKING.AIRLINES (name)
VALUES
    ('Philippine Airlines'),
    ('Cebu Pacific'),
    ('AirAsia');

INSERT INTO SKYBOOK_DB.BOOKING.PASSENGERS (name, email, phone)
VALUES
    ('Maria Santos', 'maria@email.com', '09171234567'),
    ('Jose Reyes', 'jose@email.com', '09181234567'),
    ('Ana Gonzales', 'ana@email.com', '09191234567'),
    ('Carlos Mendoza', 'carlos@email.com', '09201234567'),
    ('Luz Villanueva', 'luz@email.com', '09211234567');

INSERT INTO SKYBOOK_DB.BOOKING.FLIGHTS (airline_id, flight_no, origin, destination, travel_date, class)
VALUES
    (1, 'PR-101', 'Metro Manila', 'Bacolod', '2026-04-12', 'Economy'),
    (2, 'SJ-471', 'Metro Manila', 'Bacolod', '2026-04-12', 'Economy'),
    (3, '22-304', 'Bacolod', 'Pampanga', '2026-04-13', 'Economy'),
    (1, 'PR-103', 'Bacolod', 'Metro Manila', '2026-04-19', 'Economy'),
    (2, '22-205', 'Pampanga', 'Bacolod', '2026-04-20', 'Economy');

INSERT INTO SKYBOOK_DB.BOOKING.FLIGHTS (airline_id, flight_no, origin, destination, travel_date, class)
VALUES
    (1, 'PR-101', 'Metro Manila', 'Bacolod', '2026-04-12', 'Economy'),
    (2, 'SJ-471', 'Metro Manila', 'Bacolod', '2026-04-12', 'Economy'),
    (3, '22-304', 'Bacolod', 'Pampanga', '2026-04-13', 'Economy'),
    (1, 'PR-103', 'Bacolod', 'Metro Manila', '2026-04-19', 'Economy'),
    (2, '22-205', 'Pampanga', 'Bacolod', '2026-04-20', 'Economy');
```

This is written for **PostgreSQL**. Want me to also generate the sample `INSERT` statements for the 5 passengers already in the demo?
