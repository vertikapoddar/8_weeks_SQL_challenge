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