# 1. Find the total number of products sold by each store along with the store name.

select stores.store_name, sum(order_items.quantity) from stores
join orders using(store_id) 
join order_items using(order_id) group by stores.store_name;

# 2. Calculate the cumulative sum of quantities sold for each product over time.

select products.product_id,products.product_name,
orders.order_date, sum(order_items.quantity) from products 
join order_items using(product_id)
join orders using(order_id) 
group by products.product_id,products.product_name,orders.order_date;

# 3. Find the product with the highest total sales (quantity * price) for each category.

with A as( select products.product_id,products.product_name, 
sum(order_items.quantity * order_items.list_price) sales,
products.category_id from products join order_items using(product_id)
group by products.product_id,products.product_name,products.category_id)

select product_name from
(select *, rank() over(partition by category_id order by sales desc) rnk
from A) B
where rnk = 1;

# 4. Find the customer who spent the most money on orders.

with A as (select customers.customer_id, concat(customers.first_name, " ",customers.last_name) full_name,
sum(order_items.quantity * order_items.list_price) sales
from customers join orders
using(customer_id) join order_items using(order_id)
group by customers.customer_id, full_name)

select customer_id,full_name from A 
where sales = (select max(sales) from A);

# 5. Find the highest-priced product for each category name.

with A as( select categories.category_name, products.product_name, products.list_price, 
row_number() over ( partition by products.category_id order by products.list_price desc ) rnk
from products join categories on  products.category_id = categories.category_id)

select category_name, product_name, list_price from A where rnk = 1;

# 6. Find the total number of orders placed by each customer per store.

select customers.customer_id,concat(customers.first_name, " ",customers.last_name) full_name, stores.store_name,
count(orders.order_id) total_orders from customers 
left join orders using(customer_id) left join stores using(store_id)
group by customers.customer_id, full_name, stores.store_name;

# 7. Find the names of staff members who have not made any sales.

select * from staffs where staff_id not in (select staff_id from orders) ;

# 8. Find the top 3 most sold products in terms of quantity.

select products.product_id,products.product_name, sum(order_items.quantity) total_quantity from order_items
join products on order_items.product_id = products.product_id
group by products.product_id,products.product_name
order by total_quantity desc 
limit 3;

# 9. Find the median value of the price list.

with A as (select list_price,row_number() over (order by list_price) pos, 
count(*) over() n from order_items)

select case
	when n % 2 = 0 then (select avg(list_price) from A 
    where pos in ((n/2), (n/2)+1))
    else (select list_price from A where pos = (n+1)/2)
    end as median from A limit 1 ;

# 10. List all products that have never been ordered.(use Exists)

select products.product_id, products.product_name from products
where not exists (select product_id from order_items where products.product_id = order_items.product_id);

# 11. List the names of staff members who have made more sales than the average number of sales by all staff members.

with A as(select staffs.staff_id, concat(staffs.first_name, " " ,staffs.last_name) full_name,
sum(order_items.list_price * order_items.quantity) sales from staffs left join orders using(staff_id)
left join order_items using (order_id)
group by staffs.staff_id,full_name)

select * from A where sales > (select avg(sales) from A); 
        
# 12. Identify the customers who have ordered all types of products (i.e., from every category).

select customers.customer_id, concat(customers.first_name, " " ,customers.last_name) full_name,
count(products.category_id) from customers 
join orders using(customer_id) join order_items using (order_id) 
join products on order_items.product_id = products.product_id
group by customers.customer_id
having count(distinct products.category_id) = (select count(category_id) from categories);

