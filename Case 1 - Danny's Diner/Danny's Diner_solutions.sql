use case1_dannys_diner;

/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS "Total amount spent"
FROM sales s JOIN menu m ON s.product_id = m.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS "days visted"
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT customer_id, product_name
FROM (
SELECT customer_id, product_name,
DENSE_RANK () OVER (PARTITION BY customer_id ORDER BY order_date) AS ranking
FROM sales s JOIN menu m ON s.product_id = m.product_id) T1
WHERE ranking = 1
GROUP BY customer_id, product_name;

/* with CTE */

WITH ranking AS
(SELECT customer_id, product_name, 
DENSE_RANK () OVER (PARTITION BY customer_id ORDER BY order_date) as ranks
FROM sales s JOIN menu m ON s.product_id = m.product_id)
SELECT customer_id, product_name
FROM ranking
WHERE ranks = 1
GROUP BY customer_id, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, COUNT(order_date) AS order_count
FROM sales s JOIN menu m ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY order_count DESC
LIMIT 1;	

-- 5. Which item was the most popular for each customer?
SELECT customer_id, product_name, order_count
FROM (
SELECT customer_id, product_name, COUNT(order_date) AS order_count, 
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(order_date) desc) AS ranking
FROM sales s JOIN menu m ON s.product_id = m.product_id
GROUP BY customer_id, product_name
ORDER BY customer_id) t1
WHERE ranking = 1;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT customer_id, product_name
FROM (
SELECT s.customer_id, product_name, 
DENSE_RANK () OVER (PARTITION BY customer_id ORDER BY order_date) AS ranking
FROM sales s, menu m, members m1 WHERE s.product_id = m.product_id AND s.customer_id = m1.customer_id AND order_date >= join_date) T1
WHERE ranking = 1
GROUP BY customer_id, product_name;

-- 7. Which item was purchased just before the customer became a member?
SELECT customer_id, product_name
FROM (
SELECT s.customer_id, product_name, 
DENSE_RANK () OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS ranking
FROM sales s, menu m, members m1 WHERE s.product_id = m.product_id AND s.customer_id = m1.customer_id AND order_date < join_date) T1
WHERE ranking = 1
GROUP BY customer_id, product_name;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(s.product_id) as total_items, SUM(price) AS amount_spent
FROM sales s, menu m, members m1 WHERE s.product_id = m.product_id AND s.customer_id = m1.customer_id AND order_date < join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, SUM(points) AS Total_points
FROM (
SELECT customer_id,  
CASE
WHEN s.product_id = 1 THEN price*2*10
ELSE price*10
END AS points
FROM sales s, menu m WHERE s.product_id = m.product_id) T1
GROUP BY customer_id; 

SELECT customer_id, SUM( 
CASE
WHEN s.product_id = 1 THEN price*2*10
ELSE price*10
END) AS points
FROM sales s, menu m WHERE s.product_id = m.product_id
GROUP BY customer_id; 

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id, SUM( 
CASE
WHEN s.product_id = 1 THEN price*2*10
WHEN order_date - join_date < 7 AND order_date - join_date >= 0 THEN price*2*10
ELSE price*10
END) AS points
FROM sales s, menu m, members m1 WHERE s.product_id = m.product_id and s.customer_id = m1.customer_id
AND MONTH(order_date) = 1
GROUP BY customer_id
ORDER BY customer_id; 

-- BONUS QUESTIONS
-- B1. Recreating a desired table
SELECT s.customer_id, order_date, product_name, price,
CASE
WHEN order_date >= join_date THEN "Y"
ELSE "N"
END AS member
FROM sales s 
INNER JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members m1 ON s.customer_id = m1.customer_id;

-- B1. Ranking of customer products
WITH member_table AS
(SELECT s.customer_id, order_date, product_name, price,
CASE
WHEN order_date >= join_date THEN "Y"
ELSE "N"
END AS member
FROM sales s 
INNER JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members m1 ON s.customer_id = m1.customer_id)
SELECT *, 
CASE
WHEN member = "N" THEN null
ELSE 
RANK () OVER (PARTITION BY customer_id, member ORDER BY order_date)
END AS ranking
FROM member_table;