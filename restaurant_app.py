import sys
import subprocess
import pkg_resources

required = {'pyodbc', 'flask'}
installed = {pkg.key for pkg in pkg_resources.working_set}
missing = required - installed

if missing:
    subprocess.check_call([sys.executable, "-m", "pip", "install", *missing])

from flask import Flask, render_template
import pyodbc
import re

app = Flask(__name__)

def querydb(querystring, commit=False, *args):
    result = []
    conn = pyodbc.connect(driver='{SQL Server Native Client 11.0}', server=server_name, database='Restaurant', trusted_connection='yes')
    cursor = conn.cursor()
    cursor.execute(querystring, *args)
    if not commit:
        row = cursor.fetchone()
        while row:
            result.append(row)
            row = cursor.fetchone()
    else:
        cursor.commit()
    conn.close()
    return result

@app.route("/")
def home():
    return render_template('home.html')

@app.route("/finance/")
def finance():
    year_list = querydb("SELECT * FROM Annual;")
    return render_template('finance.html', years=year_list)

@app.route("/finance/query/<int:year>/<int:quarter>/<int:week>/")
def financequery(year, quarter, week):
    if quarter == 0 and week == 0:
        week_list = querydb("SELECT * FROM Week WHERE year = ?;", False, year)
    elif week == 0:
        week_list = querydb("SELECT * FROM Week WHERE quart_num = ? AND year = ?;", False, quarter, year)
    else:
        week_list = querydb("SELECT * FROM Week WHERE week_num = ? AND year = ?;", False, week, year)
    year_list = querydb("SELECT * FROM Annual;")
    return render_template('finance.html', years=year_list, records=week_list)

@app.route("/menu/")
def menu():
    return render_template("menu.html")

@app.route("/menu/query/<string:querytype>/")
def menuquery(querytype):
    if querytype == 'all':
        menu_items = querydb("SELECT * FROM MenuItem;")
    elif querytype == 'vegetarian':
        menu_items = querydb("VegetarianMenu;")
    elif querytype == 'eggfree':
        menu_items = querydb("EggFreeMenu;")
    elif querytype == 'lactosefree':
        menu_items = querydb("LactoseFreeMenu;")
    elif querytype == 'glutenfree':
        menu_items = querydb("GlutenFreeMenu;")
    elif querytype == 'seafoodfree':
        menu_items = querydb("SeafoodFreeMenu;")
    elif querytype == 'vegan':
        menu_items = querydb("VeganMenu;")
    else:
        menu_items = [None]
    return render_template('menu.html', items=menu_items)

@app.route("/menu/search/<string:param>/<string:dbsearch>/")
def menusearch(param, dbsearch):
    if not re.search("^[A-Za-z -']{1,30}$", dbsearch):
        return render_template("invalidsearch.html", message="Invalid Search")
    if param == 'ingredient':
        menu_items = querydb("SearchByIngredient ?;", False, dbsearch)
        if not menu_items:
            return render_template("invalidsearch.html", message="No Results Returned")
    if param == 'item':
        menu_items = querydb("SearchMenuByName ?;", False, dbsearch)
        if not menu_items:
            return render_template("invalidsearch.html", message="No Results Returned")
    return render_template('menu.html', searchitems=menu_items)

@app.route("/staff/")
def staff():
    return render_template("staff.html")

@app.route("/staff/query/<string:querytype>/")
def staffquery(querytype):
    if querytype == 'all':
        staff_list = querydb("SELECT * FROM Staff ORDER BY position;")
    elif querytype == 'employeeofthequarter':
        staff_list = querydb("EmployeesOfTheQuarter;")
    elif querytype == 'annualwages':
        staff_list = querydb("AverageAnnualWages;")
    elif querytype == 'positionstats':
        staff_list = querydb("PositionStatistics;")
    else:
        staff_list = [None]
    return render_template('staff.html', staff=staff_list, qtype=querytype)

@app.route("/staff/search/<string:param>/<string:dbsearch>/")
def staffsearch(param, dbsearch):
    if not re.search("^\d{5}$", dbsearch) and not re.search("^[A-Za-z -']{1,30}$", dbsearch):
        return render_template("invalidsearch.html", message="Invalid Search")
    if param == 'empid':
        staff_list = querydb("SELECT * FROM Staff WHERE employeeID = ?;", False, dbsearch)
        if not staff_list:
            return render_template("invalidsearch.html", message="No Results Returned")
    if param == 'empname':
        staff_list = querydb("SearchStaffByName ?;", False, dbsearch)
        if not staff_list:
            return render_template("invalidsearch.html", message="No Results Returned")
    if param == 'position':
        staff_list = querydb("SearchStaffByPosition ?;", False, dbsearch)
        if not staff_list:
            return render_template("invalidsearch.html", message="No Results Returned")
    return render_template('staff.html', searchstaff=staff_list, qtype='all')

@app.route("/stock/")
def stock():
    return render_template("stock.html")

@app.route("/stock/query/<string:querytype>/")
def stockquery(querytype):
    if querytype == 'all':
        stock_items = querydb("SELECT * FROM StockItem;")
    elif querytype == 'averageorders':
        stock_items = querydb("AverageWeeklyOrder;")
    elif querytype == 'numdishes':
        stock_items = querydb("NumberOfDishes;")
    elif querytype == 'supplierbreakdown':
        stock_items = querydb("SupplierBreakdown;")
    else:
        stock_items = [None]
    return render_template('stock.html', stock=stock_items, qtype=querytype)

@app.route("/stock/search/<string:param>/<string:dbsearch>/")
def stocksearch(param, dbsearch):
    if not re.search("^\d{5}$", dbsearch) and not re.search("^[A-Za-z -&']{1,30}$", dbsearch):
        return render_template("invalidsearch.html", message="Invalid Search")
    if param == 'stockid':
        stock_items = querydb("SELECT * FROM StockItem WHERE stockID = ?;", False, dbsearch)
        if not stock_items:
            return render_template("invalidsearch.html", message="No Results Returned")
    if param == 'stockname':
        stock_items = querydb("SearchStockByName ?;", False, dbsearch)
        if not stock_items:
            return render_template("invalidsearch.html", message="No Results Returned")
    if param == 'dish':
        stock_items = querydb("SearchByDish ?;", False, dbsearch)
        if not stock_items:
            return render_template("invalidsearch.html", message="No Results Returned")
    return render_template('stock.html', stockitem=stock_items, qtype='all')

@app.route("/modify/")
def modifytables():
    return render_template("modify.html")

@app.route("/modify/additem/<string:addtype>/")
def additem(addtype):
    dropdown = []
    if addtype == 'stock':
        dropdown = querydb("SupplierBreakdown;")
    return render_template('additem.html', itemtype=addtype, drop=dropdown)

@app.route("/modify/additem/dish/<string:coursetype>/<string:itemname>/<float:price>/")
def dishadd(coursetype, itemname, price):
    if not re.search("^[A-Za-z -']{1,30}$", coursetype):
        return render_template("invalidsearch.html", message = "Invalid course type")
    if not re.search("^[A-Za-z -']{1,30}$", itemname):
        return render_template("invalidsearch.html", message = "Invalid item name")
    if not price > 0:
        return render_template("invalidsearch.html", message = "Invalid price")
    try:
        querydb("INSERT INTO MenuItem VALUES (?, ?, ?);", True, coursetype, itemname, price)
    except Exception:
        return render_template("invalidsearch.html", message="Record could not be inserted")
    return render_template("additem.html", itemtype='dish', message='Successfully Inserted')

@app.route("/modify/additem/stock/<string:itemname>/<string:supplier>/<float:price>/<int:veg>/<int:lactose>/<int:egg>/<int:gluten>/<int:seafood>/")
def stockadd(itemname, supplier, price, veg, lactose, egg, gluten, seafood):
    if not re.search("^[A-Za-z -']{1,30}$", itemname):
        return render_template("invalidsearch.html", message = "Invalid item name")
    if not re.search("^[A-Za-z -&']{1,30}$", supplier):
        return render_template("invalidsearch.html", message = "Invalid supplier")
    if not price > 0:
        return render_template("invalidsearch.html", message = "Invalid price")
    if not ((veg == 0 or veg == 1) and (lactose == 0 or lactose == 1) and (egg == 0 or egg == 1) and (gluten == 0 or gluten == 1) and (seafood == 0 or seafood == 1)):
        return render_template("invalidsearch.html", message="Invalid query")
    itemid = int(querydb("SELECT max(stockID) as maxid FROM StockItem")[0].maxid) + 1
    try:
        qstring = "INSERT INTO StockItem VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);"
        querydb(qstring, True, itemid, itemname, supplier, price, veg, lactose, egg, gluten, seafood)
    except Exception:
        return render_template("invalidsearch.html", message="Record could not be inserted")
    dropdown = querydb("SupplierBreakdown;")
    return render_template("additem.html", itemtype='stock', drop=dropdown, message='Successfully Inserted')

@app.route("/modify/removeitem/<string:rmvtype>/")
def removeitem(rmvtype):
    if rmvtype == 'dish':
        items = querydb("SELECT * FROM MenuItem;")
        return render_template("removeitem.html", menu=items, course="Appetizers")
    if rmvtype == 'stock':
        items = querydb("SELECT * FROM StockItem ORDER BY stock_name;")
        return render_template("removeitem.html", stock=items)
    return render_template("invalidsearch.html", message="Invalid page")

@app.route("/modify/removeitem/dish/<string:coursetype>/")
def removedish(coursetype):
    items = querydb("SELECT * FROM MenuItem;")
    return render_template("removeitem.html", menu=items, course=coursetype)

@app.route("/modify/removeitem/dish/<string:coursetype>/<string:dish>/")
def dishremovequery(coursetype, dish):
    if not re.search("^[A-Za-z -']{1,30}$", dish):
        return render_template("invalidsearch.html", message = "Invalid item name")
    fail = False
    try:
        querydb("DELETE FROM MenuItem WHERE menu_name = ?;", True, dish)
    except Exception:
        fail = True
    if fail:
        try:
            querydb("UPDATE MenuItem SET course_type='Removed' WHERE menu_name = ?;", True, dish)
        except Exception:
            return render_template("invalidsearch.html", message="Record could not be removed")
    items = querydb("SELECT * FROM MenuItem;")
    return render_template("removeitem.html", menu=items, course=coursetype, message="Item Removed")

@app.route("/modify/removeitem/stock/<string:stockid>/")
def stockremovequery(stockid):
    if not re.search("^[0-9]{5}$", stockid):
        return render_template("invalidsearch.html", message = "Invalid query")
    try:
        querydb("DELETE FROM StockItem WHERE stockID = ?;", True, stockid)
    except Exception:
        return render_template("invalidsearch.html", message="Record could not be deleted")
    items = querydb("SELECT * FROM StockItem ORDER BY stock_name;")
    return render_template("removeitem.html", stock=items, message="Record Deleted!")

@app.route("/modify/ingredients/")
@app.route("/modify/ingredients/<string:coursetype>/")
def ingselectdish(coursetype="Appetizers"):
    menu_items = querydb("SELECT * FROM MenuItem;")
    return render_template("ingredients.html", menu=menu_items, course=coursetype)

@app.route("/modify/ingredients/<string:coursetype>/<string:dish>/")
def ingstockselect(coursetype, dish):
    ing = querydb("IngredientsByDish ?;", False, dish)
    menu_items = querydb("SELECT * FROM MenuItem;")
    return render_template("ingredients.html", menu=menu_items, course=coursetype, ingredients=ing, dish=dish)

@app.route("/modify/ingredients/<string:coursetype>/<string:dish>/<string:op>/<string:stock>/")
def ingstockop(coursetype, dish, op, stock):
    if not re.search("^[A-Za-z -']{1,30}$", dish):
        return render_template("invalidsearch.html", message = "Invalid item name")
    if not re.search("^[0-9]{5}$", stock):
        return render_template("invalidsearch.html", message = "Invalid query")
    if op == 'add':
        try:
            querydb("INSERT INTO Ingredients VALUES (?, ?);", True, stock, dish)
        except Exception:
            return render_template("invalidsearch.html", message="Record could not be inserted")
    if op == 'remove':
        try:
            querydb("DELETE FROM Ingredients WHERE menu_item_name = ? AND ingredientID = ?;", True, dish, stock)
        except Exception:
            return render_template("invalidsearch.html", message="Record could not be deleted")
    ing = querydb("IngredientsByDish ?;", False, dish)
    menu_items = querydb("SELECT * FROM MenuItem;")
    return render_template("ingredients.html", menu=menu_items, course=coursetype, ingredients=ing, dish=dish)

@app.route("/modify/menu/")
@app.route("/modify/menu/<string:coursetype>/")
def modmenu(coursetype="Appetizers"):
    items = querydb("SELECT * FROM MenuItem;")
    return render_template("modmenu.html", menu=items, course=coursetype)

@app.route("/modify/menu/<string:coursetype>/<string:dish>/<string:edittype>/<string:edit>/")
def modmenuquery(coursetype, dish, edittype, edit):
    if not re.search("^[A-Za-z -']{1,30}$", edit) or not re.search("^[A-Za-z -']{1,30}$", dish):
        return render_template("invalidsearch.html", message="Invalid Edit")
    if edittype == 'course':
        try:
            querydb("UPDATE MenuItem SET course_type= ? WHERE menu_name= ?;", True, edit, dish)
        except Exception:
            return render_template("invalidsearch.html", message="Could not edit")
    items = querydb("SELECT * FROM MenuItem;")
    return render_template("modmenu.html", menu=items, course=coursetype, message="Item Edited")


if __name__ == '__main__':
    fail = False
    server_name = input("\n\nEnter your the name of your server in Microsoft SQL\n\n\t")
    try:
        conn = pyodbc.connect(driver='{SQL Server Native Client 11.0}', server=server_name, trusted_connection='yes')
        conn.close()
    except Exception:
        fail = True
        print("\nCannot connect to server.\nEnsure that the server name is valid.\n")
    if not fail:
        try:
            conn = pyodbc.connect(driver='{SQL Server Native Client 11.0}', server=server_name, database='Restaurant', trusted_connection='yes')
            conn.close()
        except Exception:
            fail = True
            print("\nDatabase has not been created.\n")
        
    if not fail:
        app.run(debug=False)