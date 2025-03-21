-- 1. Создание таблиц 

create table users (
id          integer primary key,             
name        character varying(100) not null, 
email       character varying(150) unique not null,
created_at  timestamp        
); 

 
create table categories (
id         integer primary key,            
name   character varying(100) not null 
);


create table products (
id           integer primary key,             
 name         character varying(100),
 price        numeric(10,2) not null check (price > 0),       
 category_id  integer,   
 foreign key (category_id) references categories(id)
); 


create table orders (
id          integer primary key,              
user_id     integer not null,              
status      character varying(50), 
created_at  timestamp,  
foreign key(user_id) references users(id)
);


create table order_items (
 id         integer primary key,              
 order_id   integer not null,              
 product_id integer not null,              
 quantity   integer not null check (quantity >= 0),      
foreign key(order_id) references orders(id), 
foreign key(product_id) references products(id) 
 );


create table payments (
id           integer primary key,             
order_id     integer not null,              
amount       numeric(10,2) check (amount >= 0),      
payment_date timestamp,
foreign key(order_id) references orders(id)
);


--Задача 1. Средняя стоимость заказа по категориям товаров.
-- Вывести среднюю cуммарную стоимость товаров в заказе для каждой категории товаров, учитывая только заказы, созданные в марте 2023 года. 


SELECT 
category_name, 
ROUND(AVG(order_total), 2) AS avg_order_amount
FROM 
(SELECT c.name AS category_name, SUM(p.price) AS order_total
FROM 
orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN  products p ON oi.product_id = p.id
JOIN categories c ON p.category_id = c.id
WHERE EXTRACT(MONTH FROM o.created_at) = 3
GROUP BY c.name, o.id) AS category_orders
GROUP BY category_name;


-- Задача 2. Вывести топ-3 пользователей, которые потратили больше всего денег на оплаченные заказы. Учитывать только заказы со статусом "Оплачен". 
--В отдельном столбце указать, какое место пользователь занимает 


select 
name, 
total_spent, 
rank() over (order by total_spent desc) as user_rank 
from  
	( 
Select u.name, sum(p.amount) as total_spent
From users u
Join orders o on o.user_id = u.id 
Join payments p on o.id = p.order_id 
Where o.status = 'Оплачен'
Group by u.name 
     ) 
limit 3;



--Задача 3. Количество заказов и сумма платежей по месяцам.
--Вывести количество заказов и общую сумму платежей по каждому месяцу в 2023 году.

select 
 to_char(DATE_TRUNC('month', created_at), 'YYYY-MM') AS month, 
count(o.id) as total_orders, 
SUM(p.amount) AS total_payments 
from 
payments p 
join orders o on p.order_id = o.id
group by month 
order by month; 


--Задача 4. Рейтинг товаров по количеству продаж.
--Вывести топ-5 товаров по количеству продаж, а также их долю в общем количестве продаж.  Долю округлить до двух знаков после запятой

select 
pr.name as product_name, 
sum(oi.quantity) as total_sold, 
round((sum(oi.quantity) * 100.0 / (select sum(quantity) from order_items)), 2)  as sales_percantage
from 
products pr  
join order_items oi on oi.product_id = pr.id 
join orders o on oi.order_id = o.id
group by product_name 
order by total_sold desc
limit 5;


--Задача 5. Пользователи, которые сделали заказы на сумму выше среднего.
--Вывести пользователей, общая сумма оплаченных заказов которых превышает  среднюю сумму оплаченных заказов по всем пользователям.

select
u.name as user_name, 
sum(p.amount) as total_spent 
from 
users u 
join orders o on u.id = o.user_id 
join payments p on o.id = p.order_id
where o.status = 'Оплачен'
group by user_name
having sum(p.amount) > ( select avg(total)  from   (select sum(p2.amount) as total 
from users u2 
join orders o2 on u2.id = o2.user_id 
join payments p2 on o2.id = p2.order_id 
where o2.status = 'Оплачен' 
group by u2.name) 
);

--Задача 6 
--Для каждой категории товаров вывести топ-3 товара по количеству проданных единиц. 

select 
category_name, 
product_name, 
total_sold 
from 
(
select 
c.name as category_name, 
pr.name as product_name, 
sum(oi.quantity) as total_sold, 
row_number() over (partition by c.name order by sum(oi.quantity) desc) as rank
from 
categories c
join products pr on pr.category_id = c.id
join order_items oi on oi.product_id = pr.id
group by c.name, pr.name
) 
where rank <= 3; 

--Задача 7. Категории товаров с максимальной выручкой в каждом месяце.
--Вывести категории товаров, которые принесли максимальную выручку в каждом месяце первого полугодия 2023 года.

select 
month, 
category_name, 
total_revenue 
from
(
select 
month, 
category_name,  
total_revenue, 
row_number() over (partition by month order by total_revenue desc) as rw from   
(select 
to_char(DATE_TRUNC('month', created_at), 'YYYY-MM') AS month, 
c.name as category_name, 
sum(pr.price * oi.quantity) as  total_revenue
from 
categories c 
join products pr on c.id = pr.category_id 
join order_items oi on oi.product_id = pr.id 
join orders o on o.id = oi.order_id 
where  EXTRACT(MONTH FROM o.created_at) <= 6
group by month, category_name )
) 
where rw = 1;


--Задача 8. Накопительная сумма платежей по месяцам.
--Вывести накопительную сумму платежей по каждому месяцу в 2023 году. Накопительная сумма должна рассчитываться нарастающим итогом. 

select 
month, 
monthly_payments, 
sum(monthly_payments) over (order by month) as cumulative_payments 
from 
(
select 
to_char(DATE_TRUNC('month', payment_date), 'YYYY-MM') AS month, 
sum(amount) as monthly_payments 
from 
payments p 
group by month 
having to_char(DATE_TRUNC('month', payment_date), 'YYYY-MM')  is not null
order by month
);




























