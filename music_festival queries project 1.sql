-- 1: Who is the most senior employee base on the job tittle?
SELECT*
FROM employee
ORDER BY levels DESC
LIMIT 1;
 -- 2: Which country is the most invoices?
  SELECT billing_country,COUNT(*) AS C FROM
  invoice
  GROUP BY billing_country
  ORDER BY C DESC
  LIMIT 1;
  -- 3: What are the three values of total invoices?
  
 SELECT ROUND(total) FROM
 invoice
 ORDER BY total DESC
 LIMIT 3
 --Q5 who is the best customer? The customer who has spent the most money will be declared the best customer.
 --Write a query that returns the person who has spent the most money.
 SELECT 
  c.first_name, 
  c.last_name, 
  SUM(i.total) as total 
FROM 
  customer c 
  INNER JOIN invoice i ON c.customer_id = i.customer_id 
GROUP BY 
  c.customer_id 
ORDER BY 
  total DESC 
LIMIT 
  1;

-- Questions Moderate level part 2
-- Q1: Write a query that return the email.first name, last name,&Genre of all Rock Music listners.
-- Returns your list ordered alphabitcally 

SELECT 
  email, 
  first_name, 
  last_name 
FROM 
  customer c 
  JOIN invoice i ON c.customer_id = i.customer_id 
  JOIN invoice_line inl ON i.invoice_id = inl.invoice_id 
WHERE 
  track_id IN(
    SELECT 
      track_id 
    FROM 
      track t 
      JOIN genre g ON t.genre_id = g.genre_id 
    WHERE 
      g.name LIKE 'Rock'
  ) 
ORDER BY 
  email;

Q2; -- let's invite the artists who have written the most rock music in our data set
-- write a query that returns the artist name and track count of the top 10 rock music.

SELECT 
  ar.name, 
  COUNT(ar.artist_id) AS number_of_songs 
FROM 
  track t 
  JOIN album a ON t.album_id = a.album_id 
  JOIN artist ar ON ar.artist_id = a.artist_id 
  JOIN genre g ON t.genre_id = g.genre_id 
WHERE 
  g.name LIKE 'Rock' 
GROUP BY 
  ar.artist_id 
ORDER BY 
  number_of_songs DESC 
LIMIT 
  10;


 -- Q 3 Return all the tracks names that have a song lenth longer than the average song lenth.
 -- Return the Names and Miliseconds for each track. Order by the song lenth with the longest songs
 -- listed first.
     SELECT 
  name, 
  milliseconds 
FROM 
  track 
WHERE 
  milliseconds > (
    SELECT 
      AVG(milliseconds) as Avg_track_length 
    from 
      track
  ) 
ORDER BY 
  milliseconds DESC;


	-- Advanced Questions
-- Q 1;  Find how much amount spent by each customer on artists? Write a query return customer name,artist name 
--- and total spent

WITH best_selling_artist AS (
  SELECT 
    artist.artist_id AS artist_id, 
    artist.name AS artist_name, 
    SUM(
      invoice_line.unit_price * invoice_line.quantity
    ) AS total_spent 
  FROM 
    invoice_line 
    JOIN track ON track.track_id = invoice_line.track_id 
    JOIN album ON track.album_id = album.album_id 
    JOIN artist ON artist.artist_id = album.artist_id 
  GROUP BY 
    1 
  ORDER BY 
    3 DESC 
  LIMIT 
    1
) 
SELECT 
  c.customer_id, 
  c.first_name, 
  c.last_name, 
  bsa.artist_name, 
  SUM(il.unit_price * il.quantity) AS total_spent 
FROM 
  invoice i 
  JOIN customer c ON c.customer_id = i.customer_id 
  JOIN invoice_line il ON i.invoice_id = il.invoice_id 
  JOIN track t ON t.track_id = il.track_id 
  JOIN album alb ON t.album_id = alb.album_id 
  JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id 
GROUP BY 
  1, 
  2, 
  3, 
  4 
ORDER BY 
  5 DESC;

-- Q2;    We want to find out the most popular music Genre for each country. We determine the
-- most popular genre as the genre with the highest amount of purchases. Write a query
-- that returns each country along with the top Genre. For countries where the maximum
-- number of purchases is shared return all Genres
-- METHOD ONE
WITH popular_genre AS (
  SELECT 
    COUNT(quantity), 
    country, 
    g.name, 
    g.genre_id, 
    ROW_NUMBER() OVER(
      PARTITION BY country 
      ORDER BY 
        COUNT(quantity) DESC
    ) AS RowNo 
  FROM 
    customer c 
    JOIN invoice i ON c.customer_id = i.customer_id 
    JOIN invoice_line il ON il.invoice_id = i.invoice_id 
    JOIN track t ON t.track_id = il.track_id 
    JOIN genre g ON t.genre_id = g.genre_id 
  GROUP BY 
    2, 
    3, 
    4 
  ORDER BY 
    2 ASC, 
    1 DESC
) 
SELECT 
  * 
FROM 
  popular_genre 
WHERE 
  ROWNo <= 1;

  -- SECOND METHOD

WITH RECURSIVE sale_per_country AS (
  SELECT 
    COUNT(*) AS purchases_per_genre, 
    c.country, 
    g.name, 
    g.genre_id 
  FROM 
    customer c 
    JOIN invoice i ON c.customer_id = i.customer_id 
    JOIN invoice_line il ON i.invoice_id = il.invoice_id 
    JOIN track t ON t.track_id = il.track_id 
    JOIN genre g ON g.genre_id = t.genre_id 
  GROUP BY 
    2, 
    3, 
    4 
  ORDER BY 
    2
), 
max_genre_per_country AS (
  SELECT 
    MAX(purchases_per_genre) AS max_genre_number, 
    country 
  FROM 
    sale_per_country 
  GROUP BY 
    2 
  ORDER BY 
    2
) 
SELECT 
  sale_per_country.* 
FROM 
  sale_per_country 
  JOIN max_genre_per_country ON max_genre_per_country.country = sale_per_country.country 
WHERE 
  sale_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

--    Q3: Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount. 
-- METHOD ONE
WITH RECURSIVE customer_with_country AS(
  SELECT 
    c.customer_id, 
    first_name, 
    last_name, 
    i.billing_country, 
    SUM(i.total) AS total_spending 
  FROM 
    customer c 
    JOIN invoice i ON c.customer_id = i.customer_id 
  GROUP BY 
    1, 
    2, 
    3, 
    4 
  ORDER BY 
    1, 
    5 DESC
), 
country_max_spending AS (
  SELECT 
    billing_country, 
    MAX(total_spending) AS max_spending 
  FROM 
    customer_with_country 
  GROUP BY 
    billing_country
) 
SELECT 
  cc.billing_country, 
  cc.total_spending, 
  cc.first_name, 
  cc.last_name, 
  cc.customer_id 
FROM 
  customer_with_country cc 
  JOIN country_max_spending ms ON cc.billing_country = ms.billing_country 
WHERE 
  cc.total_spending = ms.max_spending 
ORDER BY 
  1;

  -- METHOD SECOND
WITH customer_with_country AS (
  SELECT 
    c.customer_id, 
    first_name, 
    last_name, 
    billing_country, 
    SUM(total) AS total_spending, 
    ROW_number() OVER(
      PARTITION BY billing_country 
      ORDER BY 
        SUM(total) DESC
    ) AS RowNo 
  FROM 
    customer c 
    JOIN invoice i ON c.customer_id = i.customer_id 
  GROUP BY 
    1, 
    2, 
    3, 
    4 
  ORDER BY 
    4 ASC, 
    5 DESC
) 
SELECT 
  * 
FROM 
  customer_with_country 
WHERE 
  RowNo <= 1;

  

  

  
  
















