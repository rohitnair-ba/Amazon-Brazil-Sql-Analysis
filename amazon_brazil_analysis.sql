/*
Amazon Brazil SQL Analysis Project
Repository: amazon-brazil-sql-analysis

Collected from the available project screenshots and question context.
The supplied query logic is preserved as shown in the available source material.
*/

-- Q1. Find the total number of orders fulfilled by each seller state.
SELECT
    sellers.seller_state,
    COUNT(DISTINCT order_items.order_id) count_of_order
FROM sellers
JOIN order_items USING (seller_id)
GROUP BY sellers.seller_state
ORDER BY count_of_order DESC;


-- Q2. Calculate cumulative revenue by product category over time.
WITH cte AS (
    SELECT
        products.product_category_name,
        DATE(orders.order_purchase_timestamp) AS order_date,
        SUM(order_items.price) AS revenue
    FROM products
    JOIN order_items USING (product_id)
    JOIN orders USING (order_id)
    GROUP BY products.product_category_name, order_date
)
SELECT
    product_category_name,
    order_date,
    revenue,
    SUM(revenue) OVER (
        PARTITION BY product_category_name
        ORDER BY order_date
    ) AS running_total
FROM cte
ORDER BY order_date;


-- Q3. Find the most-used payment method and average order value by payment type.
WITH cte1 AS (
    SELECT
        order_id,
        payment_type,
        SUM(payment_value) total_order_value
    FROM order_payments
    GROUP BY order_id, payment_type
),
cte2 AS (
    SELECT
        payment_type,
        COUNT(order_id) payment_count,
        ROUND(AVG(total_order_value), 2) avg_order_value
    FROM cte1
    GROUP BY payment_type
)
SELECT * FROM cte2
ORDER BY payment_count DESC;


-- Q4. Find the customer who has spent the most money.
SELECT
    customer_id, SUM(payment_value) AS total_spent
FROM
    orders
        JOIN
    order_payments USING (order_id)
GROUP BY customer_id
ORDER BY total_spent DESC
LIMIT 1;


-- Q5. Find the average review score for each product category.
SELECT
    product_category_name,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM
    products
        JOIN
    order_items USING (product_id)
        JOIN
    order_reviews USING (order_id)
GROUP BY product_category_name;


-- Q6. Find the total number of orders placed by each customer,
-- broken down by the state they live in.
SELECT
    customer_id, customer_state, COUNT(order_id)
FROM
    customers
        JOIN
    orders USING (customer_id)
GROUP BY customer_id , customer_state;


-- Q7. Identify sellers who registered but have never fulfilled a single order.
SELECT sellers.seller_id,
count(case
when orders.order_status = 'delivered' then 0
end) delivered_orders_count
from sellers
left join order_items using (seller_id)
left join orders using (order_id)
group by sellers.seller_id
having delivered_orders_count = 0;


-- Q8. Find the top 5 product categories by total revenue.
SELECT
    product_category_name, SUM(price) AS total_revenue
FROM
    products
        JOIN
    order_items USING (product_id)
GROUP BY product_category_name
ORDER BY total_revenue DESC
LIMIT 5;


-- Q9. Find the median delivery time (in days) between order placement and delivery.
WITH cte1 AS (SELECT
    DATEDIFF(order_delivered_customer_date,
             order_purchase_timestamp) delivery_days
FROM
    orders
WHERE DATEDIFF(order_delivered_customer_date,
               order_purchase_timestamp) IS NOT NULL),

cte2 AS (SELECT cte1.*, ROW_NUMBER() OVER(ORDER BY delivery_days) pos,
         COUNT(delivery_days) OVER() n FROM cte1)
SELECT AVG(delivery_days) median_delivery_time
FROM cte2
WHERE pos IN (CEIL(n/2), CEIL((n+1)/2));


-- Q10. Find all products that have never been ordered.
SELECT
    p.product_id, p.product_category_name
FROM
    products p
WHERE
    NOT EXISTS ( SELECT
        1
    FROM
        order_items oi
    WHERE
        oi.product_id = p.product_id);


-- Q11. Find sellers who have fulfilled more orders than the average seller.
WITH cte1 AS (SELECT seller_id, COUNT(DISTINCT order_id) count
FROM sellers LEFT JOIN order_items USING(seller_id)
GROUP BY seller_id),
cte2 AS (SELECT seller_id, count,
AVG(count) OVER() average_seller FROM cte1)
SELECT * FROM cte2
WHERE count > average_seller;


-- Q12. Find which Brazilian states have the highest average customer review
-- score for orders delivered there.
SELECT
    customer_state, AVG(review_score) AS avg_customer_review
FROM
    customers
        JOIN
    orders USING (customer_id)
        JOIN
    order_reviews USING (order_id)
WHERE
    order_status = 'delivered'
GROUP BY customer_state
ORDER BY avg_customer_review DESC;


-- Q13. Identify customers who placed orders but never left a review.
SELECT
    o.customer_id, r.review_id
FROM
    orders o
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE
    r.review_id IS NULL;


-- Q14. Find the month with the highest number of orders placed.
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%M') AS months,
    COUNT(order_id) AS order_placed
FROM
    orders
GROUP BY months
ORDER BY order_placed DESC
LIMIT 1;
