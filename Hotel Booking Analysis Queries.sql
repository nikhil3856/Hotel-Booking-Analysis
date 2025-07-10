use hotelbooking;
select * FROM HOTELBOOKING;

SELECT DISTINCT ARRIVAL_DATE_WEEK_NUMBER FROM HOTELBOOKING;
SELECT DISTINCT stays_in_weekend_nights FROM HOTELBOOKING;
SELECT DISTINCT stays_in_week_nights FROM HOTELBOOKING;
SELECT DISTINCT number_of_adults FROM HOTELBOOKING;
SELECT DISTINCT number_of_children FROM HOTELBOOKING;
SELECT DISTINCT number_of_babies FROM HOTELBOOKING;
SELECT DISTINCT meal_code FROM HOTELBOOKING;
SELECT DISTINCT country_code FROM HOTELBOOKING;
SELECT DISTINCT is_repeated_guest FROM HOTELBOOKING;
SELECT DISTINCT previous_cancellations FROM HOTELBOOKING;
SELECT DISTINCT previous_bookings_not_canceled FROM HOTELBOOKING;
SELECT DISTINCT reserved_room_type_code FROM HOTELBOOKING;
SELECT DISTINCT assigned_room_type_code FROM HOTELBOOKING;
SELECT DISTINCT booking_changes FROM HOTELBOOKING;
SELECT DISTINCT days_in_waiting_list FROM HOTELBOOKING;
SELECT DISTINCT adr FROM HOTELBOOKING;
SELECT DISTINCT required_car_parking_spaces FROM HOTELBOOKING;
SELECT DISTINCT total_of_special_requests FROM HOTELBOOKING;
SELECT DISTINCT reservation_status FROM HOTELBOOKING;
SELECT DISTINCT reservation_status_date FROM HOTELBOOKING;

select * from room_type;
select * from mealtype;
select * from country;
select * from hotelbooking;

SET SQL_SAFE_UPDATES = 0;


-- Tables Connections

Alter table hotelbooking add column room_category varchar(20); 

update hotelbooking as h
join room_type as r
on h.reserved_room_type_code = r.room_code
set   
   h.reserved_room_type_code = r.room_name,
   h.room_category = r.room_category
   where h.reserved_room_type_code is not null;

update hotelbooking as h
join room_type as r
on h.assigned_room_type_code = r.room_code
set   
   h.assigned_room_type_code = r.room_name;


alter table hotelbooking add column meal_description varchar(50);
alter table hotelbooking modify column meal_description varchar(255);

update hotelbooking as h
join mealtype as m 
on h.meal_code = m.meal_code
set 
   h.meal_code = m.meal_name,
   h.meal_description = m.meal_description
   where m.meal_code is not null;

update hotelbooking as h
join country as c
on h.country_code = c.country_code
set
    h.country_code = c.country_name;
    
    
    
-- What is the average number of special requests per reserved room type?

SELECT 
  reserved_room_type_code,
  AVG(total_of_special_requests) AS avg_special_requests
FROM HOTELBOOKING
GROUP BY reserved_room_type_code;

-- For each meal code, what is the cancellation rate?

SELECT 
  meal_code,
  COUNT(*) AS total_bookings,
  SUM(CASE WHEN reservation_status = 'Canceled' THEN 1 ELSE 0 END) AS total_cancellations,
  ROUND(
    100.0 * SUM(CASE WHEN reservation_status = 'Canceled' THEN 1 ELSE 0 END) / COUNT(*), 2
  ) AS cancellation_rate_percentage
FROM HOTELBOOKING
GROUP BY meal_code;

-- Which reserved room types had the most mismatch with assigned room types?

SELECT 
  reserved_room_type_code,
  assigned_room_type_code,
  COUNT(*) AS mismatch_count
FROM HOTELBOOKING
WHERE reserved_room_type_code != assigned_room_type_code
GROUP BY reserved_room_type_code, assigned_room_type_code
ORDER BY mismatch_count DESC;

-- Show the cumulative number of bookings per reservation status over time.

SELECT 
  reservation_status,
  reservation_status_date,
  COUNT(*) AS daily_bookings,
  SUM(COUNT(*)) OVER (PARTITION BY reservation_status ORDER BY reservation_status_date) AS cumulative_bookings
FROM HOTELBOOKING
GROUP BY reservation_status, reservation_status_date
ORDER BY reservation_status, reservation_status_date;


-- For each reservation status, show the average number of days on the waiting list.

SELECT 
  reservation_status,
  AVG(days_in_waiting_list) AS avg_wait_days
FROM HOTELBOOKING
GROUP BY reservation_status;


-- What is the rank of each week's average ADR compared to other weeks?
WITH week_avg_adr AS (
  SELECT 
    ARRIVAL_DATE_WEEK_NUMBER, 
    AVG(adr) AS avg_adr
  FROM HOTELBOOKING
  GROUP BY ARRIVAL_DATE_WEEK_NUMBER
)
SELECT 
  ARRIVAL_DATE_WEEK_NUMBER, 
  avg_adr,
  RANK() OVER (ORDER BY avg_adr DESC) AS adr_rank
FROM week_avg_adr;


-- What is the average ADR of each reservation status, and how does each booking compare to it?

SELECT 
  reservation_status,
  adr,
  AVG(adr) OVER (PARTITION BY reservation_status) AS avg_status_adr,
  adr - AVG(adr) OVER (PARTITION BY reservation_status) AS deviation_from_avg
FROM HOTELBOOKING;

-- List bookings with more special requests than the average for that week.

WITH weekly_avg_requests AS (
  SELECT *,
         AVG(total_of_special_requests) OVER (PARTITION BY ARRIVAL_DATE_WEEK_NUMBER) AS weekly_avg_requests
  FROM HOTELBOOKING
)
SELECT *
FROM weekly_avg_requests
WHERE total_of_special_requests > weekly_avg_requests;


-- Identify peak ADR weeks along with a moving average of ADR (3-week window).

WITH adr_by_week AS (
  SELECT ARRIVAL_DATE_WEEK_NUMBER, AVG(adr) AS avg_adr
  FROM HOTELBOOKING
  GROUP BY ARRIVAL_DATE_WEEK_NUMBER
)
SELECT 
  *,
  ROUND(AVG(avg_adr) OVER (
    ORDER BY ARRIVAL_DATE_WEEK_NUMBER 
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 2) AS moving_avg_adr
FROM adr_by_week;

-- Find guests (grouped by country & repeat status) who have the most cumulative special requests.

WITH guest_requests AS (
  SELECT 
    country_code,
    is_repeated_guest,
    SUM(total_of_special_requests) AS total_requests
  FROM HOTELBOOKING
  GROUP BY country_code, is_repeated_guest
)
SELECT *,
  RANK() OVER (ORDER BY total_requests DESC) AS request_rank
FROM guest_requests;




   




