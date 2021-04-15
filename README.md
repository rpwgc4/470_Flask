# 470_Flask
Database and Flask web application repository

Take the following steps to run this Flask application.
1) If you haven't already, construct the database from the DDL and csv files in the database folder
2) Make sure to pip install flask and pyodbc on your command prompt.
3) Make sure flask and pyodbc are installed correctly: 
        Type `python` into the command prompt to open the python shell. 
        Enter `import pyodbc` and `import flask`. These should run without any error displayed.
        Enter `exit()` to exit the shell
        If you run into any issues on Windows I recommend trying `python -m pip install` instead of just `pip install`
4) Change the connection settings for your setup:
        Open up flask_app.py in your editor of choice. Find the querydb() function.
        In the call pyodbc.connect() edit the arguments for server and database to match your setup and save.
5) Run the app by: 
        Navigating to the project directory in the command prompt and entering `python -m flask_app`
        The command prompt will print out the address that the website is hosted at
        Note that 127.0.0.1 can also be written as localhost
        So you will enter something like 'localhost:5000' into your browser to reach the home page
