--1.users--
create table users(
	id integer primary key,
	name varchar(100) not null,
	email varchar(150),
	created_at timestamp default current_timestamp 
	--дата и время--
); 

-- char(n) - строка фиксированной длины --
/*varchar(n)/character varying(n) - строка переменной длины,n-max
text-строка неогранниченной длины, для больших текстов*/


--2.categories--
create table categories(
	id integer primary key,
	name varchar(100) not null
	
);


--3.products--
create table products (
	id integer  primary key,
	name varchar(100) not null,
	price numeric (10,2) not null check (price>=0),
	-- numeric == demical 10 цифр в числе 2 после запятой--
	category_id integer not null,
	foreign key (category_id) references categories (id)
);


--4.orders--

create table orders (
	id integer primary key,
	user_id integer not null,
	foreign key (user_id) references users(id),
	status varchar(150) default 'Ожидает оплаты',
	created_at timestamp default CURRENT_TIMESTAMP
);



--5.order_id--
create table order_items (
	id integer primary key,
	order_id integer not null,
	foreign key (order_id) references orders(id),
	product_id integer not null,
	foreign key (product_id) references products(id),
	quantity integer default 0 check (quantity>=0)
);


--6.payments--
create table payments (
	id integer primary key,
	order_id integer not null,
	foreign key (order_id) references orders (id),
	amount numeric(10,2) default 0 check (amount>=0),
	--! хорошо бы связать оплату и статус заказа--
	payment_date timestamp default CURRENT_TIMESTAMP
);


---Задача 1. Средняя стоимость заказа по категориям товаров--- , 

select name, AVG(summ)
from 
(select categories.name as name, SUM(products.price*order_items.quantity) as summ
from order_items 
join orders on order_items.order_id=orders.id 
join products on order_items.product_id =products.id
join categories on categories.id=products.category_id
where orders.created_at>='2023-03-01' and orders.created_at<'2023-04-01'
group by categories.name, order_items.order_id)
group by name;

--задача 2---
select name,total_spent, rank() over (order by total_spent DESC) as user_rank
from 
(select users.name as name, sum (payments.amount) as total_spent
from orders 
join users on orders.user_id=users.id 
join payments on payments.order_id=orders.id 
where orders.status = 'Оплачен'
group by name)
limit 3;

--задача 3--
select to_char (orders.created_at,'YYYY-MM') as month, count(orders.id) as total_orders, sum(payments.amount) total_payments 
from 
orders join payments on orders.id=payments.order_id 
group by to_char (orders.created_at,'YYYY-MM') 
order by month;

--задача 4 --
select product_name,total_sold, ROUND (total_sold / (sum(total_sold) over())* 100,2) as sales_percantage
from 
(select products.name product_name, sum(order_items.quantity) total_sold
from order_items join products on order_items.product_id=products.id
group by products.name
order by total_sold desc)
limit 5;

--Задача 5 --
select user_name, total_spent
from 
(select user_name, total_spent, AVG(total_spent) over() avg 
from 
(select users.name user_name, sum(payments.amount) total_spent
from orders join payments on orders.id=payments.order_id 
join users on orders.user_id=users.id 
where orders.status = 'Оплачен'
group by users.name))
where total_spent>avg
;

--Задача 6 --
select category_name,product_name,total_sold
from 
(select category_name,product_name,total_sold, rank() over(partition by category_name order by total_sold desc)
from 
(select categories.name category_name, products.name product_name,sum(order_items.quantity) total_sold
from order_items join products on order_items.product_id =products.id
join categories on products.category_id=categories.id
group by products.name,categories.name
))
order by category_name;

--Задача 7--

--заказ создан в месяце---
select month,category_name,sum
from
(select month,category_name,sum,rank() over(partition by month order by sum desc) as rank
from
(select month, category_name,sum(price) as sum
from 
(select to_char(orders.created_at,'YYYY-MM') as month, categories.name category_name, order_items.quantity*products.price as price
from order_items join products on order_items.product_id=products.id 
join categories on categories.id=products.category_id 
join orders on order_items.order_id=orders.id 
join payments on payments.order_id=orders.id 
where orders.created_at>='2023-01-01' and orders.created_at<'2023-07-01')
group by  month, category_name))
where rank=1
;

--заказ оплачен в месяце---
select month,category_name,sum
from
(select month,category_name,sum,rank() over(partition by month order by sum desc) as rank
from
(select month, category_name,sum(price) as sum
from 
(select to_char(orders.created_at,'YYYY-MM') as month, categories.name category_name, order_items.quantity*products.price as price
from order_items join products on order_items.product_id=products.id 
join categories on categories.id=products.category_id 
join orders on order_items.order_id=orders.id 
join payments on payments.order_id=orders.id 
where payments.payment_date>='2023-01-01' and payments.payment_date<'2023-07-01')
group by  month, category_name))
where rank=1
;

--8--
select month,monthly_payments, 
sum (monthly_payments) over( rows BETWEEN UNBOUNDED PRECEDING AND CURRENT row) as cumulative_payments
from  
(select to_char(p.payment_date, 'YYYY-MM') as month,sum(p.amount) monthly_payments
from payments p
where p.payment_date is not null
group by month
order by month);

