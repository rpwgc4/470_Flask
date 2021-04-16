from flask import Flask, render_template
import pyodbc
import re

app = Flask(__name__)

def querydb(querystring):
    result = []
    conn = pyodbc.connect(driver='{SQL Server Native Client 11.0}', server='LAPTOP-A7VIMRGT', database='chktest', trusted_connection='yes')
    cursor = conn.cursor()
    cursor.execute(querystring)
    row = cursor.fetchone()
    while row:
        result.append(row)
        row = cursor.fetchone()
    return result

@app.route("/")
def home():
    return render_template('home.html')

@app.route("/finance")
def finance():
    return render_template('finance.html')

@app.route("/menu")
def menu():
    return render_template("menu.html")

@app.route("/menu/query/<string:querytype>")
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

@app.route("/menu/search/<string:param>/<string:dbsearch>")
def menusearch(param, dbsearch):
    if not re.search("^[A-Za-z ]{1,30}$", dbsearch):
        return render_template("invalidsearch.html", message="Invalid Search")
    if param == 'ingredient':
        menu_items = querydb("SearchByIngredient '" + dbsearch + "';")
        if not menu_items:
            return render_template("invalidsearch.html", message="No Results Returned")
    if param == 'item':
        menu_items = querydb("SELECT * FROM MenuItem WHERE menu_name LIKE '%" + dbsearch + "%';")
        if not menu_items:
            return render_template("invalidsearch.html", message="No Results Returned")
    return render_template('menu.html', items=menu_items)

@app.route("/staff")
def staff():
    return render_template("staff.html")

@app.route("/staff/query/<string:querytype>")
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

@app.route("/stock")
def stock():
    return render_template("stock.html")

@app.route("/stock/query/<string:querytype>")
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

if __name__ == '__main__':
    app.run(debug=True)