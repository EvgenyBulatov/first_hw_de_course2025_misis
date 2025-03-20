-- 1. 
SELECT 
    c.name AS category_name,
    ROUND(AVG(oi_total.total_amount), 2) AS avg_order_amount
FROM (
    SELECT 
        o.id AS order_id,
        p.category_id,
        SUM(p.price * oi.quantity) AS total_amount
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE DATE_TRUNC('month', o.created_at) = '2023-03-01'
    GROUP BY o.id, p.category_id
) oi_total
JOIN categories c ON oi_total.category_id = c.id
GROUP BY c.name
ORDER BY avg_order_amount DESC;






-- 2.
WITH user_spending AS (
    SELECT 
        u.name AS user_name,
        SUM(p.amount) AS total_spent
    FROM orders o
    JOIN payments p ON o.id = p.order_id
    JOIN users u ON o.user_id = u.id
    WHERE o.status = 'Оплачен'
    GROUP BY u.id, u.name
)
SELECT 
    user_name,
    total_spent,
    RANK() OVER (ORDER BY total_spent DESC) AS user_rank
FROM user_spending
LIMIT 3;







--3.
SELECT 
    TO_CHAR(o.created_at, 'YYYY-MM') AS month,
    COUNT(o.id) AS total_orders,
    COALESCE(SUM(p.amount), 0) AS total_payments
FROM orders o
LEFT JOIN payments p ON o.id = p.order_id
WHERE EXTRACT(YEAR FROM o.created_at) = 2023
GROUP BY month
ORDER BY month;






--4.
WITH total_sales AS (
    SELECT SUM(quantity) AS total_quantity FROM order_items
)
SELECT 
    p.name AS product_name,
    SUM(oi.quantity) AS total_sold,
    ROUND((SUM(oi.quantity) * 100.0 / (SELECT total_quantity FROM total_sales)), 2) AS sales_percentage
FROM order_items oi
JOIN products p ON oi.product_id = p.id
GROUP BY p.name
ORDER BY total_sold DESC
LIMIT 5;






--5.
WITH user_spending AS (
    SELECT 
        u.name AS user_name,
        COALESCE(SUM(p.amount), 0) AS total_spent
    FROM users u
    JOIN orders o ON u.id = o.user_id
    JOIN payments p ON o.id = p.order_id
    WHERE o.status = 'Оплачен'
    GROUP BY u.id, u.name
),
avg_spent AS (
    SELECT AVG(total_spent) AS avg_spending FROM user_spending
)
SELECT 
    us.user_name,
    us.total_spent
FROM user_spending us
JOIN avg_spent a ON us.total_spent > a.avg_spending
ORDER BY us.total_spent DESC;






--6.
WITH product_sales AS (
    SELECT 
        c.name AS category_name,
        p.name AS product_name,
        SUM(oi.quantity) AS total_sold,
        RANK() OVER (PARTITION BY c.id ORDER BY SUM(oi.quantity) DESC) AS rank
    FROM products p
    JOIN categories c ON p.category_id = c.id
    JOIN order_items oi ON p.id = oi.product_id
    GROUP BY c.id, c.name, p.id, p.name
)
SELECT category_name, product_name, total_sold
FROM product_sales
WHERE rank <= 3
ORDER BY category_name, rank;





--7.
WITH category_revenue AS (
    SELECT
        TO_CHAR(o.created_at, 'YYYY-MM') AS month,
        c.name AS category_name,
        SUM(oi.quantity * p.price) AS total_revenue
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    JOIN categories c ON p.category_id = c.id
    WHERE o.created_at >= '2023-01-01' AND o.created_at < '2023-07-01'
    GROUP BY TO_CHAR(o.created_at, 'YYYY-MM'), c.name
),
ranked_revenue AS (
    SELECT
        month,
        category_name,
        total_revenue,
        RANK() OVER (PARTITION BY month ORDER BY total_revenue DESC) AS rank
    FROM category_revenue
)
SELECT
    month,
    category_name,
    total_revenue
FROM ranked_revenue
WHERE rank = 1
ORDER BY month;






--8. 
WITH monthly_payments AS (
    SELECT
        TO_CHAR(p.payment_date, 'YYYY-MM') AS month,
        SUM(p.amount) AS monthly_payments
    FROM payments p
    WHERE p.payment_date >= '2023-01-01' AND p.payment_date < '2023-07-01'
    GROUP BY TO_CHAR(p.payment_date, 'YYYY-MM')
)
SELECT 
    mp.month,
    mp.monthly_payments,
    SUM(mp.monthly_payments) OVER (ORDER BY mp.month) AS cumulative_payments
FROM monthly_payments mp
ORDER BY mp.month;

