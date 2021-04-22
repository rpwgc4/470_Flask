/*
	CS 470 Term Project
	Initial Project Tables
	GROUP BLRST - Swetha Bhumireddy, Lily Bui, Toan Chu, Byron Nave, Ryan Williams
*/

CREATE DATABASE Restaurant;

GO
USE Restaurant;


GO


-- Creating tables MenuItem, MenuSales, Staff, Timesheet, Ingredients, StockItem, StockPurchases, Week, Annual

CREATE TABLE MenuItem (
	course_type				VARCHAR(30)			NOT NULL,
	menu_name				VARCHAR(30)			NOT NULL,
	cost					DECIMAL(9,2)		NOT NULL		DEFAULT 0,

	PRIMARY KEY (menu_name),

	CHECK (menu_name NOT LIKE '%[^A-Za-z'' -]%'),
	CHECK (course_type NOT LIKE '%[^A-Za-z'' -]%'),
	CHECK (cost >= 0)
	);

CREATE TABLE MenuSales (
	year					INT					NOT NULL,
	week_num				INT					NOT NULL,
	item_name				VARCHAR(30)			NOT NULL,
	quantity                INT					NOT NULL,
	
	PRIMARY KEY (week_num, year, item_name),

	CHECK (quantity > 0)
	);


CREATE TABLE Staff (
	employeeID				VARCHAR(5)			NOT NULL,
	l_name					VARCHAR(30),
	f_name					VARCHAR(30),
	SSN						VARCHAR(11),
	position				VARCHAR(30)							DEFAULT 'NEEDS TO BE ASSIGNED',
	hourly_wage				DECIMAL(9,2)						DEFAULT 0,

	PRIMARY KEY (employeeID),

	CHECK (f_name NOT LIKE '%[^A-Za-z'' -]%'),
	CHECK (l_name NOT LIKE '%[^A-Za-z'' -]%'),
	CHECK (SSN LIKE '[0-9][0-9][0-9][- ][0-9][0-9][- ][0-9][0-9][0-9][0-9]' 
		OR SSN LIKE REPLICATE('[0-9]', 9)),
	CHECK (employeeID LIKE REPLICATE('[0-9]', 5)),
	CHECK (position NOT LIKE '%[^A-Za-z'' -]%'),
	CHECK (hourly_wage >= 0)
	);


CREATE TABLE Timesheet (
	year					INT					NOT NULL,
	week_num				INT					NOT NULL,
	empID					VARCHAR(5)			NOT NULL,
	hours_worked			INT									DEFAULT 0,

	PRIMARY KEY (empID, week_num, year),

	CHECK (hours_worked > 0 AND hours_worked <= 50)
	);


CREATE TABLE Ingredients (
	ingredientID			VARCHAR(5)			NOT NULL,
	menu_item_name			VARCHAR(30)			NOT NULL,

	PRIMARY KEY (ingredientID, menu_item_name),
	);


CREATE TABLE StockItem (
	stockID					VARCHAR(5)			NOT NULL,
	stock_name				VARCHAR(30),
	supplier				VARCHAR(30),
	cost					DECIMAL(9,2)		NOT NULL,
	is_vegetarian			BIT					NOT NULL,
	contains_lactose		BIT					NOT NULL,
	contains_egg			BIT					NOT NULL,
	contains_gluten			BIT					NOT NULL,
	contains_seafood		BIT					NOT NULL,

	PRIMARY KEY (stockID),

	CHECK (stockID LIKE REPLICATE('[0-9]', 5)),
	CHECK (stock_name NOT LIKE '%[^A-Za-z'' -]%'),
	CHECK (supplier NOT LIKE '%[^A-Za-z'' -&]%'),
	CHECK (cost >= 0)
	);


CREATE TABLE StockPurchases (
	year					INT					NOT NULL,
	week_num				INT					NOT NULL,
	itemID					VARCHAR(5)			NOT NULL,
	inventory				INT									DEFAULT 1,
	
	PRIMARY KEY (itemID, week_num, year),

	CHECK (inventory > 0)
	);


CREATE TABLE Week (
	year					INT					NOT NULL,
	quart_num				INT					NOT NULL,
	week_num				INT					NOT NULL,
	
	PRIMARY KEY (week_num, year),

	CHECK (
			(quart_num = 1 AND week_num > 0 AND week_num < 14)
			OR
			(quart_num = 2 AND week_num > 13 AND week_num < 27)
			OR
			(quart_num = 3 AND week_num > 26 AND week_num < 40)
			OR
			(quart_num = 4 AND week_num > 39 AND week_num < 53)
		  )
	);


CREATE TABLE Annual (
	year					INT					NOT NULL,
	
	PRIMARY KEY (year),
	CHECK (year >= 1900 AND year <= 2500)
	);


GO


-- Altering tables MenuSales, Timesheet, Ingredients, StockPurchases, Week to add foreign keys

ALTER TABLE MenuSales
	ADD CONSTRAINT FK_menusales_itemname
		FOREIGN KEY (item_name) REFERENCES MenuItem(menu_name);


ALTER TABLE MenuSales
	ADD CONSTRAINT FK_menusales_weekyear
		FOREIGN KEY (week_num, year) REFERENCES Week(week_num, year);


ALTER TABLE Timesheet
	ADD CONSTRAINT FK_timesheet_empid
		FOREIGN KEY (empID) REFERENCES Staff(employeeID);


ALTER TABLE Timesheet
	ADD CONSTRAINT FK_timesheet_weekyear
		FOREIGN KEY (week_num, year) REFERENCES Week(week_num, year);


ALTER TABLE Ingredients
	ADD CONSTRAINT FK_ingredients_ingredientid
		FOREIGN KEY (ingredientID) REFERENCES StockItem(stockID);


ALTER TABLE Ingredients
	ADD CONSTRAINT FK_ingredients_menu_name
		FOREIGN KEY (menu_item_name) REFERENCES MenuItem(menu_name);


ALTER TABLE StockPurchases
	ADD CONSTRAINT FK_stockpurchases_itemid
		FOREIGN KEY (itemID) REFERENCES StockItem(stockID);


ALTER TABLE StockPurchases
	ADD CONSTRAINT FK_stockpurchases_weekyear
		FOREIGN KEY (week_num, year) REFERENCES Week(week_num, year);

ALTER TABLE Week
	ADD CONSTRAINT FK_week_year
		FOREIGN KEY (year) REFERENCES Annual(year);

GO


-- Define functions GetPrice, GetMenuTotal, GetWage, GetTotalPaycheck, GetStockPrice, GetStockTotal

CREATE FUNCTION GetPrice(@menu_item as varchar(30))
	RETURNS DECIMAL(9,2)
		AS
			BEGIN
				DECLARE @Result DECIMAL(9,2)
				SELECT @Result = cost FROM MenuItem WHERE MenuItem.menu_name = @menu_item
				RETURN @Result
			END;

GO

CREATE FUNCTION GetMenuTotal(@menu_item as varchar(30), @yr as int, @wk as int)
	RETURNS DECIMAL(9,2)
		AS
			BEGIN
				DECLARE @Price DECIMAL(9,2)
				DECLARE @Qty INT
				SELECT @Price = cost FROM MenuItem WHERE menu_name = @menu_item
				SELECT @Qty = quantity FROM MenuSales WHERE item_name = @menu_item AND year = @yr AND week_num = @wk
				RETURN (@Price * @Qty)
			END;

GO

CREATE FUNCTION GetWage(@emp_ID as varchar(5))
	RETURNS DECIMAL(9,2)
		AS
			BEGIN
				DECLARE @Result DECIMAL(9,2)
				SELECT @Result = hourly_wage FROM Staff WHERE employeeID = @emp_ID
				RETURN @Result
			END;

GO

CREATE FUNCTION GetTotalPaycheck(@emp_ID as varchar(5), @yr as int, @wk as int)
	RETURNS DECIMAL(9,2)
		AS
			BEGIN
				DECLARE @Wage DECIMAL(9,2)
				DECLARE @Hours INT
				SELECT @Wage = hourly_wage FROM Staff WHERE employeeID = @emp_ID
				SELECT @Hours = hours_worked FROM Timesheet WHERE empID = @emp_ID AND year = @yr AND week_num = @wk
			RETURN (@Wage * @Hours)
		END;

GO

CREATE FUNCTION GetStockPrice(@item_ID as varchar(5))
	RETURNS DECIMAL(9,2)
		AS
			BEGIN
				DECLARE @Result DECIMAL(9,2)
				SELECT @Result = cost FROM StockItem WHERE stockID = @item_ID
				RETURN @Result
			END;

GO

CREATE FUNCTION GetStockTotal(@item_ID as varchar(5), @yr as int, @wk as int)
	RETURNS DECIMAL(9,2)
		AS
			BEGIN
				DECLARE @Price DECIMAL(9,2)
				DECLARE @Qty INT
				SELECT @Price = cost FROM StockItem WHERE stockID = @item_ID
				SELECT @Qty = inventory FROM StockPurchases WHERE itemID = @item_ID AND year = @yr AND week_num = @wk
				RETURN (@Price * @Qty)
			END;

GO


-- Altering tables to add computed columns for MenuSales, Timesheet, StockPurchases using above defined functions

ALTER TABLE MenuSales
	ADD price AS dbo.GetPrice(item_name);

ALTER TABLE MenuSales
	ADD total_sales AS dbo.GetMenuTotal(item_name, year, week_num);

ALTER TABLE Timesheet
	ADD hourly_wage AS dbo.GetWage(empID);

ALTER TABLE Timesheet
	ADD total_paycheck AS dbo.GetTotalPaycheck(empID, year, week_num);

ALTER TABLE StockPurchases
	ADD price AS dbo.GetStockPrice(itemID);

ALTER TABLE StockPurchases
	ADD total AS dbo.GetStockTotal(itemID, year, week_num);


GO


-- Define functions GetWeekIncome and GetWeekExpense

CREATE FUNCTION GetWeekIncome(@yr as int, @wk as int)
	RETURNS DECIMAL (9,2)
		AS
			BEGIN
				DECLARE @TotalSales DECIMAL(9,2)
				SELECT @TotalSales = SUM(total_sales) FROM MenuSales WHERE year = @yr AND week_num = @wk
				RETURN @TotalSales
			END;

GO

CREATE FUNCTION GetWeekExpense(@yr as int, @wk as int)
	RETURNS DECIMAL (9,2)
		AS
			BEGIN
				DECLARE @TotalStock DECIMAL(9,2)
				DECLARE @TotalWages DECIMAL(9,2)
				SELECT @TotalStock = SUM(total) FROM StockPurchases WHERE year = @yr AND week_num = @wk
				SELECT @TotalWages = SUM(total_paycheck) FROM TimeSheet WHERE year = @yr AND week_num = @wk
			RETURN (@TotalStock + @TotalWages)
		END;

GO


-- Altering tables to add computed columns for Week using above defined functions

ALTER TABLE Week
	ADD income AS dbo.GetWeekIncome(year, week_num);

ALTER TABLE Week
	ADD expenditures AS dbo.GetWeekExpense(year, week_num);

GO


-- Define functions GetAnnualIncome and GetAnnualExpense

CREATE FUNCTION GetAnnualIncome(@yr AS INT)
	RETURNS DECIMAL(9,2)
		AS
			BEGIN
				DECLARE @Income DECIMAL(9,2)
				SELECT @Income = SUM(income) FROM Week WHERE year = @yr
				RETURN @Income
			END;

GO

CREATE FUNCTION GetAnnualExpense(@yr AS INT)
	RETURNS DECIMAL(9,2)
		AS
			BEGIN
				DECLARE @Expense DECIMAL(9,2)
				SELECT @Expense = SUM(expenditures) FROM Week WHERE year = @yr
				RETURN @Expense
			END;

GO


-- Altering tables to add computed columns for Annual using above defined functions

ALTER TABLE Annual
	ADD annual_income AS dbo.GetAnnualIncome(year);

ALTER TABLE Annual
	ADD annual_expenditures AS dbo.GetAnnualExpense(year);

GO


-- Creating View for Quarterly

CREATE VIEW vwQuarterly AS
	SELECT w.year, quart_num, SUM(income)/13 AS avg_income, SUM(expenditures)/13 AS avg_expenditures
		FROM Week as w
			LEFT JOIN Annual AS a ON w.year = a.year
		--WHERE quart_num = 1
		GROUP BY w.year, quart_num;

GO



----