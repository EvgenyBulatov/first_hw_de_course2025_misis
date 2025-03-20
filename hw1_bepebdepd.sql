
-- №1: Вывести среднюю стоимость заказов для каждой категории товаров, учитывая только заказы, созданные в марте 2023 года. --
SELECT categories.name AS category_name, AVG(order_items.quantity * products.price)
FROM 
	categories
	INNER JOIN products ON categories.id=products.category_id
	INNER JOIN order_items ON products.id=order_items.product_id
	INNER JOIN orders ON orders.id = order_items.order_id AND EXTRACT(MONTH FROM orders.created_at) = 3 AND EXTRACT(YEAR FROM orders.created_at) = 2023
GROUP BY category_name;


-- №2: Вывести топ-3 пользователей, которые потратили больше всего денег на оплаченные заказы. Учитывать только заказы со статусом "Оплачен". В отдельном столбце указать, какое место пользователь занимает --
SELECT users.name AS user_name, SUM(payments.amount) AS total_spent, ROW_NUMBER() OVER (ORDER BY SUM(payments.amount) DESC) AS user_rank
FROM 
	users
	INNER JOIN orders ON users.id = orders.user_id
	INNER JOIN payments ON orders.id = payments.order_id AND orders.status='Оплачен'
GROUP BY users.name
ORDER BY total_spent DESC
LIMIT 3;


-- №3: Вывести количество заказов и общую сумму платежей по каждому месяцу в 2023 году. --
SELECT TO_CHAR(orders.created_at, 'YYYY-MM') AS p_month, COUNT(payments.order_id) AS total_orders, SUM(payments.amount) AS total_payments
FROM
	orders
	INNER JOIN payments ON orders.id = payments.order_id
GROUP BY p_month
ORDER BY p_month;


-- №4: Вывести топ-5 товаров по количеству продаж, а также их долю в общем количестве продаж. Долю округлить до двух знаков после запятой --
WITH q_total_sales AS 
(
SELECT SUM(quantity) AS total_sales
FROM order_items
)

SELECT products.name AS product_name, SUM(order_items.quantity) AS total_sold, ROUND(SUM(order_items.quantity)::numeric/(SELECT total_sales FROM q_total_sales)*100, 2) AS sales_percentage
FROM 
	order_items
	INNER JOIN products ON order_items.product_id = products.id
GROUP BY products.name
ORDER BY total_sold DESC
LIMIT 5;


-- №5: Вывести пользователей, общая сумма оплаченных заказов которых превышает среднюю сумму оплаченных заказов по всем пользователям. --
WITH q_total_paid_orders AS
(
SELECT users.name AS username, SUM(payments.amount) AS user_paid
FROM 
	users 
	INNER JOIN orders ON users.id=orders.user_id
	INNER JOIN payments ON orders.id=payments.order_id AND orders.status='Оплачен'
GROUP BY username
)

SELECT users.name AS user_name, SUM(payments.amount) AS total_spent
FROM 
	users
	INNER JOIN orders ON users.id = orders.user_id
	INNER JOIN payments ON orders.id = payments.order_id AND orders.status='Оплачен'
GROUP BY user_name
HAVING SUM(payments.amount) > (SELECT AVG(user_paid) FROM q_total_paid_orders);


-- №6: Для каждой категории товаров вывести топ-3 товара по количеству проданных единиц. Используйте оконную функцию для ранжирования товаров внутри каждой категории. --
SELECT categories.name AS category_name, products.name AS product_name, SUM(order_items.quantity) AS total_sold, RANK() OVER (PARTITION BY categories.name ORDER BY SUM(order_items.quantity) DESC) AS rank_
FROM
	categories
	INNER JOIN products ON categories.id=products.category_id
	INNER JOIN order_items ON products.id=order_items.product_id
GROUP BY category_name, product_name;


-- №7: Вывести категории товаров, которые принесли максимальную выручку в каждом месяце первого полугодия 2023 года. --
WITH q AS (
    SELECT 
        TO_CHAR(orders.created_at, 'YYYY-MM') AS month,
        categories.name AS category_name,
        SUM(products.price*order_items.quantity) AS total_revenue,
        RANK() OVER (PARTITION BY TO_CHAR(orders.created_at, 'YYYY-MM') ORDER BY SUM(products.price*order_items.quantity) DESC) AS revenue_rank
    FROM 
        orders
	    INNER JOIN order_items ON orders.id = order_items.order_id
	    INNER JOIN products ON order_items.product_id = products.id  
	    INNER JOIN categories ON products.category_id = categories.id      
		INNER JOIN payments ON payments.order_id=orders.id	
	    WHERE orders.created_at >= '2023-01-01' AND orders.created_at < '2023-07-01'     
    GROUP BY month, categories.name
)
SELECT month, category_name, total_revenue
FROM q
WHERE revenue_rank = 1
ORDER BY month;


-- №8: Накопительная сумма платежей по месяцам --
SELECT month, monthly_payments,
	SUM(monthly_payments) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_payments
FROM (
	SELECT to_char(payment_date, 'YYYY-MM') AS month, SUM(amount) AS monthly_payments
	FROM payments
	WHERE payment_date IS NOT NULL
	GROUP BY month
) AS q
ORDER BY month