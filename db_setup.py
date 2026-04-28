import psycopg2
import os
import pandas as pd
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    database=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    port=os.getenv("DB_PORT")
)

currencyexchange = pd.read_sql("SELECT * FROM currencyexchange", conn)
customer = pd.read_sql("SELECT * FROM customer", conn)
date = pd.read_sql("SELECT * FROM date", conn)
product = pd.read_sql("SELECT * FROM product", conn)
sales = pd.read_sql("SELECT * FROM sales", conn)
store = pd.read_sql("SELECT * FROM store", conn)