import os
import random
from datetime import datetime, timedelta

import numpy as np
import pandas as pd
from faker import Faker

fake = Faker()
Faker.seed(42)
random.seed(42)
np.random.seed(42)

OUTPUT_FOLDER = "generated_data"
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# -----------------------------
# CONFIGURATION
# -----------------------------

NUM_PRODUCTS = 500
NUM_CUSTOMERS = 100_000
NUM_STORES = 200
NUM_EMPLOYEES = 2_000

# -----------------------------
# PRODUCT DATA
# -----------------------------

PRODUCTS = {
    "Shoes": {
        "Running": [
            "Nike Pegasus 41",
            "Nike Air Zoom",
            "Nike Revolution 7",
            "Nike Infinity Run",
            "Nike Structure"
        ],
        "Basketball": [
            "Nike LeBron",
            "Nike KD",
            "Nike Giannis",
            "Nike Sabrina"
        ],
        "Lifestyle": [
            "Nike Air Force 1",
            "Nike Dunk Low",
            "Nike Air Max 270",
            "Nike Blazer Mid"
        ]
    },
    "Apparel": {
        "Hoodies": [
            "Nike Club Hoodie",
            "Nike Tech Fleece"
        ],
        "T-Shirts": [
            "Nike Sportswear Tee",
            "Nike Dri-FIT Tee"
        ],
        "Shorts": [
            "Nike Pro Shorts",
            "Nike Running Shorts"
        ],
        "Jackets": [
            "Nike Windrunner",
            "Nike Rain Jacket"
        ]
    },
    "Accessories": {
        "Bags": [
            "Nike Backpack",
            "Nike Gym Sack"
        ],
        "Socks": [
            "Nike Everyday Socks"
        ],
        "Caps": [
            "Nike Heritage Cap"
        ],
        "Bottles": [
            "Nike Water Bottle"
        ]
    }
}

COLORS = [
    "Black",
    "White",
    "Blue",
    "Red",
    "Green",
    "Grey",
    "Pink"
]

SIZES = [
    "XS","S","M","L","XL",
    "38","39","40","41","42","43","44","45"
]

COUNTRIES = {
    "USA": ["New York","Chicago","Los Angeles","Dallas"],
    "Germany": ["Berlin","Munich","Hamburg"],
    "France": ["Paris","Lyon"],
    "United Kingdom": ["London","Manchester"],
    "Italy": ["Rome","Milan"],
    "Spain": ["Madrid","Barcelona"],
    "Poland": ["Warsaw","Krakow"],
    "Georgia": ["Tbilisi","Batumi","Kutaisi"]
}

PAYMENT_METHODS = [
    "Visa",
    "Mastercard",
    "PayPal",
    "Apple Pay",
    "Google Pay"
]

SHIPPING_TYPES = [
    "Standard",
    "Express"
]

SHIFTS = [
    "Morning",
    "Afternoon",
    "Evening"
]

# 2
def create_products():

    rows = []

    product_id = 1

    while len(rows) < NUM_PRODUCTS:

        category = random.choice(list(PRODUCTS.keys()))

        subcategory = random.choice(
            list(PRODUCTS[category].keys())
        )

        product_name = random.choice(
            PRODUCTS[category][subcategory]
        )

        color = random.choice(COLORS)

        size = random.choice(SIZES)

        if category == "Shoes":
            price = random.randint(90,220)

        elif category == "Apparel":
            price = random.randint(30,120)

        else:
            price = random.randint(15,70)

        cost = round(price * random.uniform(0.55,0.70),2)
        product_id_value = f"P{product_id:05}"
        product_code_value = f"NK-{product_id:05}"

        rows.append({
            "ProductID": product_id_value,
            "ProductCode": product_code_value,
            "ProductName": product_name,
            "Brand": "Nike",
            "Category": category,
            "Subcategory": subcategory,
            "Color": color,
            "Size": size,
            "Cost": cost,
            "Price": price
        })

        product_id += 1

    df = pd.DataFrame(rows)

    print("Products:",len(df))

    return df

#3 customer generator
def create_customers():

    rows=[]

    for i in range(1,NUM_CUSTOMERS+1):

        gender=random.choice(["Male","Female"])

        birth=fake.date_of_birth(
            minimum_age=18,
            maximum_age=70
        )

        country=random.choice(list(COUNTRIES.keys()))

        city=random.choice(COUNTRIES[country])

        rows.append({

            "CustomerID":f"C{i:06}",

            "FirstName":fake.first_name_male() if gender=="Male" else fake.first_name_female(),

            "LastName":fake.last_name(),

            "Gender":gender,

            "BirthDate":birth,

            "Email":fake.email(),

            "Country":country,

            "City":city

        })

    df=pd.DataFrame(rows)

    print("Customers:",len(df))

    return df
#4 store generator
def create_stores():

    rows=[]

    for i in range(1,NUM_STORES+1):

        country=random.choice(list(COUNTRIES.keys()))

        city=random.choice(COUNTRIES[country])

        rows.append({

            "StoreID":f"ST{i:03}",

            "StoreName":f"Nike {city}",

            "Country":country,

            "City":city,

            "Address":fake.street_address()

        })

    df=pd.DataFrame(rows)

    print("Stores:",len(df))

    return df
#5 employee generator
def create_employees(stores):

    rows=[]

    for i in range(1,NUM_EMPLOYEES+1):

        store=stores.sample(1).iloc[0]

        rows.append({

            "EmployeeID":f"EMP{i:05}",

            "EmployeeName":fake.name(),

            "StoreID":store["StoreID"],

            "Position":random.choice([
                "Cashier",
                "Sales Associate",
                "Supervisor",
                "Manager"
            ])

        })

    df=pd.DataFrame(rows)

    print("Employees:",len(df))

    return df


def random_date(start_date, end_date):
    delta = end_date - start_date
    random_days = random.randint(0, delta.days)
    return start_date + timedelta(days=random_days)

# sales

def generate_online_sales(products, customers, rows=500000):

    customers_list = customers.to_dict("records")
    products_list = products.to_dict("records")

    sales = []

    start_date = datetime(2024, 1, 1)
    end_date = datetime(2025, 12, 31)

    for i in range(1, rows + 1):

        customer = random.choice(customers_list)
        product = random.choice(products_list)

        quantity = random.randint(1, 5)

        order_date = random_date(start_date, end_date)

        unit_price = product["Price"]
        unit_cost = product["Cost"]

        sales_amount = round(quantity * unit_price, 2)
        cost_amount = round(quantity * unit_cost, 2)

        discount = round(
            sales_amount * random.uniform(0, 0.30),
            2
        )

        sales.append({

            # =========================
            # Order Information
            # =========================
            "OnlineOrderID": f"ON{i:07}",

            # =========================
            # Date Entity
            # =========================
            "OrderDate": order_date.date(),
            "Year": order_date.year,
            "Quarter": (order_date.month - 1) // 3 + 1,
            "Month": order_date.month,
            "Day": order_date.day,

            # =========================
            # Customer Entity
            # =========================
            "CustomerID": customer["CustomerID"],
            "FirstName": customer["FirstName"],
            "LastName": customer["LastName"],
            "Gender": customer["Gender"],
            "BirthDate": customer["BirthDate"],
            "Email": customer["Email"],
            "CustomerCountry": customer["Country"],
            "CustomerCity": customer["City"],

            # =========================
            # Product Entity
            # =========================
            "ProductID": product["ProductID"],
            "ProductCode": product["ProductCode"],
            "ProductName": product["ProductName"],
            "Brand": product["Brand"],
            "Category": product["Category"],
            "Subcategory": product["Subcategory"],
            "Color": product["Color"],
            "Size": product["Size"],

            # =========================
            # Measures
            # =========================
            "Quantity": quantity,
            "UnitPrice": unit_price,
            "UnitCost": unit_cost,
            "SalesAmount": sales_amount,
            "CostAmount": cost_amount,
            "DiscountAmount": discount,

            # =========================
            # Additional Attributes
            # =========================
            "PaymentMethod": random.choice(PAYMENT_METHODS),
            "ShippingType": random.choice(SHIPPING_TYPES),
            "CouponCode": random.choice([
                "",
                "SAVE10",
                "WELCOME15",
                "SPRING20"
            ]),
            "SalesChannel": "Online"

        })

        if i % 10000 == 0:
            print(f"Generated {i:,} online sales...")

    df = pd.DataFrame(sales)

    df.to_csv(
        os.path.join(OUTPUT_FOLDER, "nike_online_sales.csv"),
        index=False
    )

    print("Online Sales:", len(df))

    return df

def generate_store_sales(products, customers, stores, employees, rows=500000):

    products_list = products.to_dict("records")
    customers_list = customers.to_dict("records")
    stores_list = stores.to_dict("records")
    employees_list = employees.to_dict("records")

    # Employees grouped by store
    employees_by_store = {}

    for employee in employees_list:

        store_id = employee["StoreID"]

        if store_id not in employees_by_store:
            employees_by_store[store_id] = []

        employees_by_store[store_id].append(employee)

    sales = []

    start_date = datetime(2024, 1, 1)
    end_date = datetime(2025, 12, 31)

    for i in range(1, rows + 1):

        customer = random.choice(customers_list)
        store = random.choice(stores_list)
        product = random.choice(products_list)
        employee = random.choice(
            employees_by_store[store["StoreID"]]
        )

        quantity = random.randint(1, 5)

        sale_date = random_date(start_date, end_date)

        unit_price = product["Price"]
        unit_cost = product["Cost"]

        sales_amount = round(quantity * unit_price, 2)
        cost_amount = round(quantity * unit_cost, 2)

        discount = round(
            sales_amount * random.uniform(0, 0.25),
            2
        )

        sales.append({

            # ===================================
            # Transaction
            # ===================================

            "ReceiptID": f"POS{i:07}",

            # ===================================
            # Date Entity
            # ===================================

            "SaleDate": sale_date.date(),
            "Year": sale_date.year,
            "Quarter": (sale_date.month - 1) // 3 + 1,
            "Month": sale_date.month,
            "Day": sale_date.day,

            # ===================================
            # Customer Entity
            # ===================================

            "CustomerID": customer["CustomerID"],
            "FirstName": customer["FirstName"],
            "LastName": customer["LastName"],
            "Gender": customer["Gender"],
            "BirthDate": customer["BirthDate"],
            "Email": customer["Email"],
            "CustomerCountry": customer["Country"],
            "CustomerCity": customer["City"],

            # ===================================
            # Store Entity
            # ===================================

            "StoreID": store["StoreID"],
            "StoreName": store["StoreName"],
            "StoreAddress": store["Address"],
            "StoreCountry": store["Country"],
            "StoreCity": store["City"],

            # ===================================
            # Employee Entity
            # ===================================

            "EmployeeID": employee["EmployeeID"],
            "EmployeeName": employee["EmployeeName"],
            "Position": employee["Position"],

            # ===================================
            # Product Entity
            # ===================================

            "ProductID": product["ProductID"],
            "ProductCode": product["ProductCode"],
            "ProductName": product["ProductName"],
            "Brand": product["Brand"],
            "Category": product["Category"],
            "Subcategory": product["Subcategory"],
            "Color": product["Color"],
            "Size": product["Size"],

            # ===================================
            # Measures
            # ===================================

            "Quantity": quantity,
            "UnitPrice": unit_price,
            "UnitCost": unit_cost,
            "SalesAmount": sales_amount,
            "CostAmount": cost_amount,
            "DiscountAmount": discount,

            # ===================================
            # Additional Attributes
            # ===================================

            "RegisterNumber": random.randint(1, 10),
            "Shift": random.choice(SHIFTS),
            "PaymentMethod": random.choice(PAYMENT_METHODS),
            "SalesChannel": "Store"

        })

        if i % 10000 == 0:
            print(f"Generated {i:,} store sales...")

    df = pd.DataFrame(sales)

    df.to_csv(
        os.path.join(OUTPUT_FOLDER, "nike_store_sales.csv"),
        index=False
    )

    print("Store Sales:", len(df))

    return df

if __name__ == "__main__":

    # Generate master data (kept in memory only)
    products = create_products()

    customers = create_customers()

    stores = create_stores()

    employees = create_employees(stores)

    # Generate Online source system
    online_sales = generate_online_sales(
        products,
        customers,
        rows=500000
    )

    # Generate Store (POS) source system
    store_sales = generate_store_sales(
        products,
        customers,
        stores,
        employees,
        rows=500000
    )

    print("\nAll files generated successfully.")