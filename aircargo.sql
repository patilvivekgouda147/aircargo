
create database Air_Cargo_Analysis;
-- 1. Create an ER diagram --

-- 2. 
show databases;

use air_cargo_analysis;

create table if not exists customer(
	customer_id int not null auto_increment primary key,
    first_name varchar(20) not null,
    last_name varchar(20) not null,
    date_of_birth date not null,
    gender char(1) not null
);


describe customer;
-- 
load data local infile "C:\Users\patil\OneDrive\Documents\Data Analyst\Simplilearn\SQL\Dataset\SQL_Datasets\OSL Datasets\Airlines_Datasets\airlines_datasets\customer.csv"
into table customer
fields terminated by ',' enclosed by ' " ' lines terminated by '\n' ignore 1 rows;

select * from customer;

-- creating routes table
create table if not exists routes(
	route_id int not null unique primary key,
    flight_num int constraint chk_1 check (flight_num is not null),
    origin_airport char(3) not null,
    aircraft_id varchar(10) not null,
    distance_miles int not null constraint check_2 check (distance_miles > 0)
);

alter table routes
ADD destination_airport char(3) not null;

describe routes;
select * from routes;

ALTER TABLE routes
MODIFY COLUMN destination_airport char(3) not null AFTER origin_airport;

describe routes;


select * from routes;

create table If not exists pof(
	pof_id int auto_increment primary key,
    customer_id int not null,
    aircraft_id varchar(10) not null,
    route_id int not null,
    depart char(3) not null,
    arrival char(3) not null,
    seat_num char(4) not null,
    class_id varchar(15) not null,
    travel_date date not null,
    flight_num int not null,
    constraint fk_pof foreign key (customer_id) references customer(customer_id)
);

describe pof;

select * from pof;

Create table if not exists ticket_details(
	tkt_id int auto_increment primary key,
    p_date date not null,
    customer_id int not null,
    aircraft_id varchar(10) not null,
    class_id varchar(15) not null,
    no_of_tkts int not null,
    a_code char(3) not null,
    price_per_tkt decimal(5,2) not null,
    brand varchar(30) not null,
    constraint fk_tkt_dts foreign key (customer_id) references customer(customer_id)
);

describe ticket_details;
select * from ticket_details;

-- 3. display all the passengers (customers) who have travelled in routes 01 to 25
select * from customer;

use air_cargo_analysis;
select * 
from customer 
WHERE customer_id IN 
	(	SELECT DISTINCT customer_id 
		FROM pof 
        WHERE route_id BETWEEN 1 AND 25
        )
ORDER BY customer_id;

-- 4. Write a query to identify the number of passengers and total revenue in business class from the ticket_details table.
select * from customer;

select count(distinct customer_id) AS num_passengers, sum(no_of_tkts*price_per_tkt) AS total_revenue 
from ticket_details
where class_id = 'Bussiness';

-- 5. Write a query to display the full name of the customer by extracting the first name and last name from the customer table.
select concat(first_name, " ", last_name) AS full_name
from customer;

-- 6. Write a query to extract the customers who have registered and booked a ticket. Use data from the customer and ticket_details tables.

select first_name, last_name 
from customer
where customer_id IN 
(
	select distinct customer_id
    from  ticket_details 
);

-- 7.Write a query to identify the customer’s first name and last name based on their customer ID and brand (Emirates) from the ticket_details table. 
select first_name, last_name
from customer
where customer_id IN
(
	SELECT DISTINCT customer_id 
    FROM ticket_details
    WHERE brand = 'Emirates'
);

--  8. Write a query to identify the customers who have travelled by Economy Plus class using Group By and Having clause on the passengers_on_flights table.
SELECT class_id, COUNT(DISTINCT customer_id) AS num_passengers
FROM pof
GROUP BY class_id 
HAVING class_id = 'Economy Plus';

SELECT *
FROM customer a
INNER JOIN 
(
	SELECT DISTINCT customer_id
    FROM pof
    WHERE class_id = 'Economy Plus') b
ON a.customer_id = b.customer_id;

-- 9.Write a query to identify whether the revenue has crossed 10000 using the IF clause on the ticket_details table.

SELECT 
IF (
( SELECT SUM(no_of_tkts * price_per_tkt) AS total_revenue 
FROM ticket_details) > 10000, 'Crossed 10k','Not Crossed 10k') AS revenue_check; 


-- 10. Write a query to create and grant access to a new user to perform operations on a database
Create user if not exists 'gayuram'@'127.0.0.1'identified by 'password123';
grant all PRIVILEGES on air_cargo_analysis to gayuram@127.0.0.1;

-- 11. Write a query to find the maximum ticket price for each class using window functions on the ticket_details table.
 select class_id , max(price_per_tkt) 
 from ticket_details
 group by class_id;

select distinct class_id, max(price_per_tkt) over (partition by class_id) as max_price
from ticket_details
order by max_price;

-- 12. For the route ID 4, write a query to view the execution plan of the passengers_on_flights table.
explain select *
from pof 
where route_id = 4;

-- 13. Write a query to extract the passengers whose route ID is 4 by improving the speed and performance of the passengers_on_flights table.
create index idx_rid on pof (route_id);

explain select *
from pof 
where route_id = 4;

-- 14. Write a query to calculate the total price of all tickets booked by a customer across different aircraft IDs using rollup function
select customer_id, aircraft_id, sum(price_per_tkt * no_of_tkts) as total_price
from ticket_details
group by customer_id, aircraft_id
order by customer_id, aircraft_id;

select customer_id, aircraft_id, sum(price_per_tkt * no_of_tkts) as total_price
from ticket_details
group by customer_id, aircraft_id with rollup 
order by customer_id, aircraft_id;

-- 15. Write a query to create a view with only business class customers along with the brand of airlines.
create view buss_class_customers as 
select a.*, b.brand 
from customer a
INNER JOIN
(select distinct customer_id, brand
from ticket_details
where class_id = 'Business' 
order by customer_id) b
ON a.customer_id = b.customer_id;

select * from buss_class_customers;

-- 16. Write a query to create a stored procedure to get the details of all passengers flying between a range of routes defined in run time. Also, return an error message if the table doesn't exist.
select * 
from customer
where customer_id IN
(select distinct customer_id
from pof
where route_id IN (1,5)
);


delimiter //
create procedure check_route(in rid varchar(255))
begin
	declare TableNotFound condition for 1146;
    declare exit handler for TableNotFound
		select'Please check if table customer/route id are created - one/both are missing' Message;
	set @query = concat('select * from customer where customer_id in (select distinct customer_id from pof where route_id in (',rid,')); ');
    prepare sql_query from @query;
    execute sql_query;
end//
delimiter ;

call check_route("1,8");

-- 17. Write a query to create a stored procedure that extracts all the details from the routes table where the travelled distance is more than 2000 miles.
delimiter //
create procedure check_dist()
begin
	select*from routes where distance_miles > 2000;
end //
delimiter ;

call check_dist;

-- 18. Write a query to create a stored procedure that groups the distance travelled by each flight into three categories. The categories are, short distance travel (SDT) for >=0 AND <= 2000 miles, intermediate distance travel (IDT) for >2000 AND <=6500, and long-distance travel (LDT) for >6500
select flight_num, distance_miles, CASE
										when distance_miles between 0 and 2000 then "SDT"
                                        when distance_miles between 2001 and 6500 then "IDT"
                                        else "LDT"
									END distance_category 
from routes;

delimiter //
create function group_dist(dist int)
returns varchar(10)
deterministic
begin
	declare dist_cat char(3);
    if dist between 0 and 2000 then
		set dist_cat = 'SDT';
	elseif dist between 2001 and 6500 then 
		set dist_cat = 'IDT';
	elseif dist > 6500 then
		set dist_cat = 'LDT';
	end if;
    return(dist_cat);
end //

create procedure group_dist_proc()
begin
	select	flight_num, distance_miles, group_dist(distance_miles) as distance_category 
    from routes;
end //
delimiter ;

call group_dist_proc();

-- 19. Write a query to extract ticket purchase date, customer ID, class ID and specify if the complimentary services are provided for the specific class using a stored function in stored procedure on the ticket_details table. Condition: If the class is Business and Economy Plus, then complimentary services are given as Yes, else it is No

select p_date, customer_id, class_id, CASE
											when class_id in ('Business','Economy Plus') then "Yes"
                                            else "No"
										END as complimentary_service 
from ticket_details;

delimiter //
create function check_comp_serv(cls varchar(15))
returns char(3)
deterministic
begin
	declare comp_ser char(3);
    if cls in ('Business','Economy Plus') then
		set comp_ser = 'Yes';
	else 
		set comp_ser = 'No';
	end if ;
    return(comp_ser);
end //

create procedure check_comp_serv_proc()
begin
	select p_date, customer_id, class_id, check_comp_serv(class_id) as complimentary_service 
    from ticket_details;
end //
delimiter ;

call check_comp_serv_proc();

-- 20. Write a query to extract the first record of the customer whose last name ends with Scott using a cursor from the customer table.

select *
from customer 
where last_name = 'Scott' limit 1;

delimiter //
create procedure cust_lname_scott()
begin
	declare c_id int;
    declare f_name varchar(20);
    declare l_name varchar(20);
    declare dob date;
    declare gen char(1);
    
    declare cust_rec cursor 
    for
    select * from customer where last_name = 'Scott';
    
    create table if not exists cursor_table(
											c_id int,
                                            f_name varchar(20),
                                            l_name varchar(20),
                                            dob date,
                                            gen char(1)
                                            );
	open cust_rec;
    fetch cust_rec into c_id, f_name, l_name, dob, gen;
    insert into cursor_table(c_id, f_name , l_name, dob, gen) 
    values (c_id, f_name, l_name, dob, gen);
    close cust_rec;
    
    select * from cursor_table;
    end//
    delimiter ;
    
    call cust_lname_scott();
