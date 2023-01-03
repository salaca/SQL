-- 1. What is the total amount each customer spent at the restaurant?

SELECT
  	s.customer_id, sum(price) AS total_amount
FROM sales s
INNER JOIN menu m ON m.product_id=s.product_id
GROUP BY customer_id

-- 2. How many days has each customer visited the restaurant?

USE week1
SELECT customer_id,
    COUNT (DISTINCT order_date) as visited_days
FROM sales 
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH first_order_cte AS 
(SELECT s.customer_id, s.order_date, m.product_name,  DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rank_
FROM sales s
JOIN menu m  ON s.product_id=m.product_id)

SELECT customer_id, product_name
FROM first_order_cte
WHERE rank_=1
GROUP BY customer_id,product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 m.product_name AS most_purchased_item,
       count(s.product_id) AS order_count
FROM menu m
INNER JOIN sales s ON m.product_id = s.product_id
GROUP BY product_name
ORDER BY order_count DESC;

--5. Which item was the most popular for each customer?

WITH most_popular_cte AS 
(SELECT  s.customer_id, m.product_name, COUNT(s.product_id) AS order_time, 
rank() over(PARTITION BY customer_id ORDER BY count(product_name) DESC) AS rank_num
FROM sales s
JOIN menu m  ON s.product_id=m.product_id
GROUP BY s.customer_id,  m.product_name )
SELECT customer_id, product_name, order_time
FROM most_popular_cte
where rank_num=1

--6. Which item was purchased first by the customer after they became a member?

WITH first_order_cte AS 
(SELECT s.customer_id, s.order_date, m.product_name, join_date, DENSE_RANK () OVER(PARTITION BY (s.customer_id) order by order_Date) as rank_ 
FROM sales s
JOIN menu m  ON s.product_id=m.product_id
JOIN members mb ON mb.customer_id=s.customer_id
WHERE order_date > = join_date)
SELECT customer_id,product_name FROM first_order_cte
WHERE rank_=1

-- 7. Which item was purchased just before the customer became a member?
USE week1;
WITH last_order_cte AS 
( SELECT s.customer_id, s.order_date, m.product_name, join_date, DENSE_RANK () OVER(PARTITION BY (s.customer_id) order by order_Date desc) as rank_ 
FROM sales s
JOIN menu m  ON s.product_id=m.product_id
JOIN members mb ON mb.customer_id=s.customer_id
WHERE join_date >  order_date)
SELECT customer_id,  product_name  FROM last_order_cte
WHERE rank_=1
GROUP BY customer_id, product_name ;

-- 8. What is the total items and amount spent for each member before they became a member?

USE week1;

SELECT s.customer_id, count(m.product_name) as number_items,  sum(price) AS spent
FROM sales s
JOIN menu m  ON s.product_id=m.product_id
JOIN members mb ON mb.customer_id=s.customer_id
WHERE join_date >  order_date
GROUP BY s.customer_id


--9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
USE week1;
SELECT s.customer_id,
SUM(CASE WHEN m.product_name='Sushi' THEN price*20 ELSE price*10 END) AS cust_point
FROM menu m
INNER JOIN sales s  ON s.product_id=m.product_id
group by s.customer_id

-- 10. In the first week after a customer joins the program (including their join date) 
--they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January
USE week1;

WITH program_date AS(SELECT join_date, DATEADD(day, 6,join_date) AS campaign_date, customer_id FROM members)

SELECT s.customer_id,
SUM(CASE WHEN order_date BETWEEN join_date AND campaign_date THEN price*20
         WHEN order_date NOT BETWEEN join_date AND campaign_date AND product_name = 'sushi' THEN price*20
         WHEN order_date NOT BETWEEN join_date AND campaign_date AND product_name != 'sushi' THEN price*10
         END) AS customer_points
FROM menu m
INNER JOIN sales s ON m.product_id = s.product_id
INNER JOIN program_date mem ON mem.customer_id = s.customer_id
AND order_date <='2021-01-31'
AND order_date >=join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;