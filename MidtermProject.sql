#GET THE DIM DATE TABLE
USE sakila_db;

DROP TABLE IF EXISTS dim_date;
CREATE TABLE dim_date(
 date_key int NOT NULL,
 full_date date NULL,
 date_name char(11) NOT NULL,
 date_name_us char(11) NOT NULL,
 date_name_eu char(11) NOT NULL,
 day_of_week tinyint NOT NULL,
 day_name_of_week char(10) NOT NULL,
 day_of_month tinyint NOT NULL,
 day_of_year smallint NOT NULL,
 weekday_weekend char(10) NOT NULL,
 week_of_year tinyint NOT NULL,
 month_name char(10) NOT NULL,
 month_of_year tinyint NOT NULL,
 is_last_day_of_month char(1) NOT NULL,
 calendar_quarter tinyint NOT NULL,
 calendar_year smallint NOT NULL,
 calendar_year_month char(10) NOT NULL,
 calendar_year_qtr char(10) NOT NULL,
 fiscal_month_of_year tinyint NOT NULL,
 fiscal_quarter tinyint NOT NULL,
 fiscal_year int NOT NULL,
 fiscal_year_month char(10) NOT NULL,
 fiscal_year_qtr char(10) NOT NULL,
  PRIMARY KEY (`date_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

# Here is the PopulateDateDimension Stored Procedure: 
delimiter //

DROP PROCEDURE IF EXISTS PopulateDateDimension//
CREATE PROCEDURE PopulateDateDimension(BeginDate DATETIME, EndDate DATETIME)
BEGIN

	# =============================================
	# Description: http://arcanecode.com/2009/11/18/populating-a-kimball-date-dimension/
	# =============================================

	# A few notes, this code does nothing to the existing table, no deletes are triggered before hand.
    # Because the DateKey is uniquely indexed, it will simply produce errors if you attempt to insert duplicates.
	# You can however adjust the Begin/End dates and rerun to safely add new dates to the table every year.
	# If the begin date is after the end date, no errors occur but nothing happens as the while loop never executes.

	# Holds a flag so we can determine if the date is the last day of month
	DECLARE LastDayOfMon CHAR(1);

	# Number of months to add to the date to get the current Fiscal date
	DECLARE FiscalYearMonthsOffset INT;

	# These two counters are used in our loop.
	DECLARE DateCounter DATETIME;    #Current date in loop
	DECLARE FiscalCounter DATETIME;  #Fiscal Year Date in loop

	# Set this to the number of months to add to the current date to get the beginning of the Fiscal year.
    # For example, if the Fiscal year begins July 1, put a 6 there.
	# Negative values are also allowed, thus if your 2010 Fiscal year begins in July of 2009, put a -6.
	SET FiscalYearMonthsOffset = 6;

	# Start the counter at the begin date
	SET DateCounter = BeginDate;

	WHILE DateCounter <= EndDate DO
		# Calculate the current Fiscal date as an offset of the current date in the loop
		SET FiscalCounter = DATE_ADD(DateCounter, INTERVAL FiscalYearMonthsOffset MONTH);

		# Set value for IsLastDayOfMonth
		IF MONTH(DateCounter) = MONTH(DATE_ADD(DateCounter, INTERVAL 1 DAY)) THEN
			SET LastDayOfMon = 'N';
		ELSE
			SET LastDayOfMon = 'Y';
		END IF;

		# add a record into the date dimension table for this date
		INSERT INTO dim_date
			(date_key
			, full_date
			, date_name
			, date_name_us
			, date_name_eu
			, day_of_week
			, day_name_of_week
			, day_of_month
			, day_of_year
			, weekday_weekend
			, week_of_year
			, month_name
			, month_of_year
			, is_last_day_of_month
			, calendar_quarter
			, calendar_year
			, calendar_year_month
			, calendar_year_qtr
			, fiscal_month_of_year
			, fiscal_quarter
			, fiscal_year
			, fiscal_year_month
			, fiscal_year_qtr)
		VALUES  (
			( YEAR(DateCounter) * 10000 ) + ( MONTH(DateCounter) * 100 ) + DAY(DateCounter)  #DateKey
			, DateCounter #FullDate
			, CONCAT(CAST(YEAR(DateCounter) AS CHAR(4)),'/', DATE_FORMAT(DateCounter,'%m'),'/', DATE_FORMAT(DateCounter,'%d')) #DateName
			, CONCAT(DATE_FORMAT(DateCounter,'%m'),'/', DATE_FORMAT(DateCounter,'%d'),'/', CAST(YEAR(DateCounter) AS CHAR(4)))#DateNameUS
			, CONCAT(DATE_FORMAT(DateCounter,'%d'),'/', DATE_FORMAT(DateCounter,'%m'),'/', CAST(YEAR(DateCounter) AS CHAR(4)))#DateNameEU
			, DAYOFWEEK(DateCounter) #DayOfWeek
			, DAYNAME(DateCounter) #DayNameOfWeek
			, DAYOFMONTH(DateCounter) #DayOfMonth
			, DAYOFYEAR(DateCounter) #DayOfYear
			, CASE DAYNAME(DateCounter)
				WHEN 'Saturday' THEN 'Weekend'
				WHEN 'Sunday' THEN 'Weekend'
				ELSE 'Weekday'
			END #WeekdayWeekend
			, WEEKOFYEAR(DateCounter) #WeekOfYear
			, MONTHNAME(DateCounter) #MonthName
			, MONTH(DateCounter) #MonthOfYear
			, LastDayOfMon #IsLastDayOfMonth
			, QUARTER(DateCounter) #CalendarQuarter
			, YEAR(DateCounter) #CalendarYear
			, CONCAT(CAST(YEAR(DateCounter) AS CHAR(4)),'-',DATE_FORMAT(DateCounter,'%m')) #CalendarYearMonth
			, CONCAT(CAST(YEAR(DateCounter) AS CHAR(4)),'Q',QUARTER(DateCounter)) #CalendarYearQtr
			, MONTH(FiscalCounter) #[FiscalMonthOfYear]
			, QUARTER(FiscalCounter) #[FiscalQuarter]
			, YEAR(FiscalCounter) #[FiscalYear]
			, CONCAT(CAST(YEAR(FiscalCounter) AS CHAR(4)),'-',DATE_FORMAT(FiscalCounter,'%m')) #[FiscalYearMonth]
			, CONCAT(CAST(YEAR(FiscalCounter) AS CHAR(4)),'Q',QUARTER(FiscalCounter)) #[FiscalYearQtr]
		);
		# Increment the date counter for next pass thru the loop
		SET DateCounter = DATE_ADD(DateCounter, INTERVAL 1 DAY);
	END WHILE;
END//

CALL PopulateDateDimension('2000-01-01', '2010-12-31');

SELECT MIN(full_date) AS BeginDate
	, MAX(full_date) AS EndDate
FROM dim_date;

#Export Data from One Entity into a JSON File
SELECT * from sakila.film;

#Export Data from One Entity into a CSV file
SELECT * from sakila.rental;

#ADD CUSTOMER AND FACT_ORDERS TABLES 
#modified customer table by dropping "active" column
#----------------------------------------------------
USE sakila_db;

CREATE TABLE `customer` (
  `customer_id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `store_id` tinyint unsigned NOT NULL,
  `first_name` varchar(45) NOT NULL,
  `last_name` varchar(45) NOT NULL,
  `email` varchar(50) DEFAULT NULL,
  `address_id` smallint unsigned NOT NULL,
  `create_date` datetime NOT NULL,
  `last_update` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`customer_id`),
  KEY `idx_fk_store_id` (`store_id`),
  KEY `idx_fk_address_id` (`address_id`),
  KEY `idx_last_name` (`last_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
INSERT INTO `sakila_db`.`customer`
(`customer_id`,
`store_id`,
`first_name`,
`last_name`,
`email`,
`address_id`,
`create_date`,
`last_update`)
SELECT `customer`.`customer_id`,
    `customer`.`store_id`,
    `customer`.`first_name`,
    `customer`.`last_name`,
    `customer`.`email`,
    `customer`.`address_id`,
    `customer`.`create_date`,
    `customer`.`last_update`
FROM `sakila`.`customer`;


SELECT * FROM sakila_db.customer;
#----------------------------------------------------
#CREATES THE INVENtORY TABLE: 

USE sakila_db;
CREATE TABLE `inventory` (
  `inventory_id` mediumint unsigned NOT NULL AUTO_INCREMENT,
  `film_id` smallint unsigned NOT NULL,
  `store_id` tinyint unsigned NOT NULL,
  `last_update` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`inventory_id`),
  KEY `idx_fk_film_id` (`film_id`),
  KEY `idx_store_id_film_id` (`store_id`,`film_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4582 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
INSERT INTO `sakila_db`.`inventory`
(`inventory_id`,
`film_id`,
`store_id`,
`last_update`)
SELECT `inventory`.`inventory_id`,
    `inventory`.`film_id`,
    `inventory`.`store_id`,
    `inventory`.`last_update`
FROM `sakila`.`inventory`;

SELECT * FROM sakila_db.inventory;

#----------------------------------------------------
#CREATES THE PAYMENT TABLE:
USE sakila_db;
CREATE TABLE `payment` (
  `payment_id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `customer_id` smallint unsigned NOT NULL,
  `staff_id` tinyint unsigned NOT NULL,
  `rental_id` int DEFAULT NULL,
  `amount` decimal(5,2) NOT NULL,
  `payment_date` datetime NOT NULL,
  `last_update` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`payment_id`),
  KEY `idx_fk_staff_id` (`staff_id`),
  KEY `idx_fk_customer_id` (`customer_id`),
  KEY `fk_payment_rental` (`rental_id`)
) ENGINE=InnoDB AUTO_INCREMENT=16050 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
INSERT INTO `sakila_db`.`payment`
(`payment_id`,
`customer_id`,
`staff_id`,
`rental_id`,
`amount`,
`payment_date`,
`last_update`)
SELECT `payment`.`payment_id`,
    `payment`.`customer_id`,
    `payment`.`staff_id`,
    `payment`.`rental_id`,
    `payment`.`amount`,
    `payment`.`payment_date`,
    `payment`.`last_update`
FROM `sakila`.`payment`;

SELECT * FROM sakila_db.payment;

#------------------------------------------------------------
#QUERIES BELOW

#The below query calculates the total number of rentals for each customer using the fact orders table and the customer table 
SELECT 
    c.first_name, 
    c.last_name, 
    COUNT(f.rental_key) AS total_number_rentals
FROM 
    fact_orders f
JOIN 
    customer c ON f.customer_id = c.customer_id
GROUP BY 
    c.first_name, c.last_name
ORDER BY 
    total_number_rentals DESC;


#The below query joins the fact orders table with the inventory and film tables to calculate the total number of rentals for each film 
SELECT 
    fi.title, 
    COUNT(f.rental_key) AS total_number_rentals
FROM 
    fact_orders f
JOIN 
    inventory i ON f.inventory_id = i.inventory_id
JOIN 
    film fi ON i.film_id = fi.film_id
GROUP BY 
    fi.title
ORDER BY 
    total_number_rentals DESC;
    
#The below query gives us the information (total rentals and revenue) on films that are longer than a given duration (in this case 115 minutes)
SELECT 
    fi.title, 
    COUNT(f.rental_key) AS total_rentals,
    SUM(p.amount) AS total_revenue
FROM 
    film fi
JOIN 
    inventory i ON fi.film_id = i.film_id
JOIN 
    fact_orders f ON i.inventory_id = f.inventory_id
JOIN 
    payment p ON f.rental_key = p.rental_id
WHERE 
    fi.length > 120 
GROUP BY 
    fi.title
ORDER BY 
    total_revenue DESC;
    
#The below lists the business's 5 best customers by how much they have paid total
SELECT 
    c.first_name, 
    c.last_name, 
    SUM(p.amount) AS total_paid
FROM 
    payment p
JOIN 
    customer c ON p.customer_id = c.customer_id
GROUP BY 
    c.first_name, c.last_name
ORDER BY 
    total_paid DESC
LIMIT 5;

#The below query shows us customers who have rented films more than 3 times (and how many times each of them rented)
SELECT 
    c.first_name, 
    c.last_name, 
    COUNT(f.rental_key) AS total_rental_number
FROM 
    fact_orders f
JOIN 
    customer c ON f.customer_id = c.customer_id
GROUP BY 
    c.first_name, c.last_name
HAVING 
    total_rental_number > 3
ORDER BY 
    total_rental_number DESC;






