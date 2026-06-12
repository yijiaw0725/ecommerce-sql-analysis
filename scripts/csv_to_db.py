import pandas as pd
import sqlite3
import os

# 1. define where to put the database
db_path = 'database/ecommerce.db'
os.makedirs(os.path.dirname(db_path), exist_ok=True)  # create the folder if it doesn't exist yet
conn = sqlite3.connect(db_path)

# 2. define the table names
csv_files = {
'customers': 'olist_customers_dataset.csv',
'orders': 'olist_orders_dataset.csv',
'order_items': 'olist_order_items_dataset.csv',
'payments': 'olist_order_payments_dataset.csv',
'products': 'olist_products_dataset.csv'
}

# 3. loop to put into the database
print("transforming...")
for table_name, file_name in csv_files.items():
    if os.path.exists(file_name):
        print(f"processing: {table_name}...")
        # read csv
        df = pd.read_csv(file_name)
        # save into database, replace if it already exists
        df.to_sql(table_name, conn, if_exists='replace', index=False)
        print(f"-> {table_name} Completed!")
    else:
        print(f"Warning: Can not find file {file_name},skip")

# 4. Validate
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
print("\ntable has formed in database:")
print(cursor.fetchall())

conn.close()
print("\nAll Completed, database is ready: database/ecommerce.db")