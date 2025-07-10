create database Hotel_Booking;
use hotel_booking;
select * FROM HOTEL_BOOKING;


-- What is the average number of special requests per reserved room type?

SELECT 
  room_category,
  AVG(total_of_special_requests) AS avg_special_requests
FROM HOTEL_BOOKING
GROUP BY room_category;

-- For each meal code, what is the cancellation rate?

SELECT 
  meal_name,
  COUNT(*) AS total_bookings,
  SUM(CASE WHEN reservation_status = 'Canceled' THEN 1 ELSE 0 END) AS total_cancellations,
  ROUND(
    100.0 * SUM(CASE WHEN reservation_status = 'Canceled' THEN 1 ELSE 0 END) / COUNT(*), 2
  ) AS cancellation_rate_percentage
FROM HOTEL_BOOKING
GROUP BY meal_name;

-- Which reserved room types had the most mismatch with assigned room types?

SELECT 
  room_category AS reserved_room_type,
  assigned_room_type_code,
  COUNT(*) AS mismatch_count
FROM HOTEL_BOOKING
WHERE room_category != assigned_room_type_code
GROUP BY room_category, assigned_room_type_code
ORDER BY mismatch_count DESC;

-- Show the cumulative number of bookings per reservation status over time.

SELECT 
  reservation_status,
  reservation_status_date,
  COUNT(*) AS daily_bookings,
  SUM(COUNT(*)) OVER (
    PARTITION BY reservation_status
    ORDER BY reservation_status_date
  ) AS cumulative_bookings
FROM HOTEL_BOOKING
GROUP BY reservation_status, reservation_status_date
ORDER BY reservation_status, reservation_status_date;


-- For each reservation status, show the average number of days on the waiting list.

SELECT 
  reservation_status,
  AVG(days_in_waiting_list) AS avg_wait_days
FROM HOTEL_BOOKING
GROUP BY reservation_status;


-- What is the rank of each week's average ADR compared to other weeks?
WITH week_avg_adr AS (
  SELECT 
    arrival_date_week_number, 
    AVG(adr) AS avg_adr
  FROM HOTEL_BOOKING
  GROUP BY arrival_date_week_number
)
SELECT 
  arrival_date_week_number, 
  avg_adr,
  RANK() OVER (ORDER BY avg_adr DESC) AS adr_rank
FROM week_avg_adr;


-- What is the average ADR of each reservation status, and how does each booking compare to it?

SELECT 
  reservation_status,
  adr,
  AVG(adr) OVER (PARTITION BY reservation_status) AS avg_status_adr,
  adr - AVG(adr) OVER (PARTITION BY reservation_status) AS deviation_from_avg
FROM HOTEL_BOOKING;

-- List bookings with more special requests than the average for that week.

WITH weekly_avg_requests AS (
  SELECT *,
         AVG(total_of_special_requests) OVER (PARTITION BY arrival_date_week_number) AS weekly_avg_requests
  FROM HOTEL_BOOKING
)
SELECT *
FROM weekly_avg_requests
WHERE total_of_special_requests > weekly_avg_requests;


-- Identify peak ADR weeks along with a moving average of ADR (3-week window).

WITH adr_by_week AS (
  SELECT arrival_date_week_number, AVG(adr) AS avg_adr
  FROM HOTEL_BOOKING
  GROUP BY arrival_date_week_number
)
SELECT 
  *,
  ROUND(AVG(avg_adr) OVER (
    ORDER BY arrival_date_week_number 
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
  ), 2) AS moving_avg_adr
FROM adr_by_week;

-- Find guests (grouped by country & repeat status) who have the most cumulative special requests.

WITH guest_requests AS (
  SELECT 
    country,
    is_repeated_guest,
    SUM(total_of_special_requests) AS total_requests
  FROM HOTEL_BOOKING
  GROUP BY country, is_repeated_guest
)
SELECT *,
  RANK() OVER (ORDER BY total_requests DESC) AS request_rank
FROM guest_requests;




   




