CREATE PROCEDURE VegetarianMenu
AS
SELECT course_type, menu_name, cost FROM (SELECT MIN(is_vegetarian+0) as veg, course_type, menu_name, mi.cost 
	FROM MenuItem as mi INNER JOIN Ingredients as ing ON mi.menu_name = ing.menu_item_name 
	INNER JOIN StockItem as si ON ing.ingredientID = si.stockID 
	GROUP BY course_type, menu_name, mi.cost) as whole WHERE veg = 1;

GO
CREATE PROCEDURE EggFreeMenu
AS
SELECT course_type, menu_name, cost FROM (SELECT MAX(contains_egg+0) as egg, course_type, menu_name, mi.cost 
	FROM MenuItem as mi INNER JOIN Ingredients as ing ON mi.menu_name = ing.menu_item_name 
	INNER JOIN StockItem as si ON ing.ingredientID = si.stockID 
	GROUP BY course_type, menu_name, mi.cost) as whole WHERE egg = 0;

GO
CREATE PROCEDURE GlutenFreeMenu
AS
SELECT course_type, menu_name, cost FROM (SELECT MAX(contains_gluten+0) as gluten, course_type, menu_name, mi.cost 
	FROM MenuItem as mi INNER JOIN Ingredients as ing ON mi.menu_name = ing.menu_item_name 
	INNER JOIN StockItem as si ON ing.ingredientID = si.stockID 
	GROUP BY course_type, menu_name, mi.cost) as whole WHERE gluten = 0;

GO
CREATE PROCEDURE LactoseFreeMenu
AS
SELECT course_type, menu_name, cost FROM (SELECT MAX(contains_lactose+0) as dairy, course_type, menu_name, mi.cost 
	FROM MenuItem as mi INNER JOIN Ingredients as ing ON mi.menu_name = ing.menu_item_name 
	INNER JOIN StockItem as si ON ing.ingredientID = si.stockID 
	GROUP BY course_type, menu_name, mi.cost) as whole WHERE dairy = 0;

GO
CREATE PROCEDURE SeafoodFreeMenu
AS
SELECT course_type, menu_name, cost FROM (SELECT MAX(contains_seafood+0) as fish, course_type, menu_name, mi.cost 
	FROM MenuItem as mi INNER JOIN Ingredients as ing ON mi.menu_name = ing.menu_item_name 
	INNER JOIN StockItem as si ON ing.ingredientID = si.stockID 
	GROUP BY course_type, menu_name, mi.cost) as whole WHERE fish = 0;

GO
CREATE PROCEDURE VeganMenu
AS
(SELECT course_type, menu_name, cost FROM (SELECT MIN(is_vegetarian+0) as veg, course_type, menu_name, mi.cost 
	FROM MenuItem as mi INNER JOIN Ingredients as ing ON mi.menu_name = ing.menu_item_name 
	INNER JOIN StockItem as si ON ing.ingredientID = si.stockID 
	GROUP BY course_type, menu_name, mi.cost) as whole WHERE veg = 1
INTERSECT
SELECT course_type, menu_name, cost FROM (SELECT MAX(contains_lactose+0) as dairy, course_type, menu_name, mi.cost 
	FROM MenuItem as mi INNER JOIN Ingredients as ing ON mi.menu_name = ing.menu_item_name 
	INNER JOIN StockItem as si ON ing.ingredientID = si.stockID 
	GROUP BY course_type, menu_name, mi.cost) as whole WHERE dairy = 0)
INTERSECT
SELECT course_type, menu_name, cost FROM (SELECT MAX(contains_egg+0) as egg, course_type, menu_name, mi.cost 
	FROM MenuItem as mi INNER JOIN Ingredients as ing ON mi.menu_name = ing.menu_item_name 
	INNER JOIN StockItem as si ON ing.ingredientID = si.stockID 
	GROUP BY course_type, menu_name, mi.cost) as whole WHERE egg = 0;

GO
--Hardest working employee of each quarter
CREATE PROCEDURE EmployeesOfTheQuarter
AS
SELECT maxhours.year, maxhours.quart_num, f_name, l_name, hours_in_quarter
FROM (SELECT year, quart_num, MAX(hours) as hours_in_quarter
	FROM (SELECT wk.year, quart_num, empID, SUM(hours_worked) as hours
		FROM Staff as stf INNER JOIN Timesheet as ts ON empID = employeeID
		INNER JOIN Week as wk ON wk.year = ts.year AND wk.week_num = ts.week_num
		GROUP BY wk.year, wk.quart_num, empID) as sumhours
		GROUP BY year, quart_num) as maxhours
		INNER JOIN (SELECT wk.year, quart_num, f_name, l_name, empID, SUM(hours_worked) as hours
		FROM Staff as stf INNER JOIN Timesheet as ts ON empID = employeeID
		INNER JOIN Week as wk ON wk.year = ts.year AND wk.week_num = ts.week_num
		GROUP BY wk.year, wk.quart_num, f_name, l_name, empID) as empsum 
		ON empsum.year = maxhours.year AND empsum.quart_num = maxhours.quart_num AND empsum.hours = maxhours.hours_in_quarter
		ORDER BY year DESC, quart_num DESC;
GO
--Employees by average yearly earnings
CREATE PROCEDURE AverageAnnualWages
AS
SELECT f_name, l_name, empID, position, AVG(year_income) as annual_salary
	FROM (SELECT wk.year, f_name, l_name, empID, position, SUM(total_paycheck) as year_income
		FROM Week as wk INNER JOIN Timesheet as ts ON wk.year = ts.year AND wk.week_num = ts.week_num
		INNER JOIN Staff as stf ON empID = employeeID
		GROUP BY wk.year, f_name, l_name, empID, position) as annual_salaries
	GROUP BY f_name, l_name, empID, position
	ORDER BY annual_salary DESC;
	
GO

CREATE PROCEDURE PositionStatistics
AS
SELECT wk.year, position, SUM(total_paycheck) as annual_salary, AVG(hours_worked) as weekly_hours
	FROM Week as wk INNER JOIN Timesheet as ts ON wk.year= ts.year AND wk.week_num = ts.week_num
	INNER JOIN Staff as stf ON empID = employeeID
	GROUP BY wk.year, position
	ORDER BY year DESC, annual_salary DESC;

GO
CREATE PROCEDURE AverageWeeklyOrder
AS
SELECT stock_name, stockID, AVG(inventory) as qty, AVG(total) as total
	FROM StockItem as si INNER JOIN StockPurchases as sp ON stockID = itemID
	INNER JOIN Week as wk ON wk.year = sp.year AND wk.week_num = sp.week_num
	GROUP BY stock_name, stockID
	ORDER BY total DESC;

GO

CREATE PROCEDURE NumberOfDishes
AS
SELECT stock_name, stockID, supplier, COUNT(menu_item_name) as num_items
	FROM StockItem as si INNER JOIN Ingredients as ing ON stockID = ingredientID
	GROUP BY stock_name, stockID, supplier
	ORDER BY num_items DESC;

GO

CREATE PROCEDURE SupplierBreakdown
AS
SELECT si.supplier, num_items, SUM(total) as total
	FROM StockItem as si INNER JOIN StockPurchases as sp ON stockID = itemID
	INNER JOIN Week as wk ON wk.year = sp.year AND wk.week_num = sp.week_num
	INNER JOIN (SELECT supplier, COUNT(stockID) as num_items FROM StockItem GROUP BY supplier) as supp_info
	ON supp_info.supplier = si.supplier GROUP BY si.supplier, num_items
	ORDER BY total DESC;

GO

CREATE PROCEDURE SearchByIngredient @ing VARCHAR(30)
AS
SELECT course_type, menu_name, mi.cost, stock_name
FROM MenuItem as mi INNER JOIN Ingredients as ing ON menu_name = menu_item_name
INNER JOIN StockItem as si ON ingredientID = stockID
WHERE stock_name LIKE '%' + @ing + '%'
ORDER BY menu_name, stock_name;

GO

CREATE PROCEDURE SearchByDish @dish VARCHAR(30)
AS
SELECT stock_name, supplier, cost, menu_item_name
FROM StockItem as si INNER JOIN Ingredients as ing ON ingredientID = stockID
WHERE menu_item_name LIKE '%' + @dish + '%'
ORDER BY menu_item_name, stock_name;

GO

CREATE PROCEDURE IngredientsByDish @dish VARCHAR(30)
AS
SELECT menu_item_name, stock_name, stockID FROM Ingredients RIGHT OUTER JOIN StockItem
ON ingredientID=stockID AND menu_item_name = @dish ORDER BY stock_name;

GO

CREATE PROCEDURE SearchMenuByName @name VARCHAR(30)
AS
SELECT * FROM MenuItem WHERE menu_name LIKE '%'+ @name +'%';

GO

CREATE PROCEDURE SearchStockByName @name VARCHAR(30)
AS
SELECT * FROM StockItem WHERE stock_name LIKE '%'+ @name +'%';

GO

CREATE PROCEDURE SearchStaffByName @name VARCHAR(30)
AS
SELECT * FROM Staff WHERE l_name LIKE '%' + @name + '%' OR f_name LIKE '%' + @name + '%';

GO

CREATE PROCEDURE SearchStaffByPosition @position VARCHAR(30)
AS
SELECT * FROM Staff WHERE position LIKE '%' + @position + '%';

GO