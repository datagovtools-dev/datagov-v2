"""
Seed dummy data: customers (35 cols) + sales_transactions (32 cols), 1000 rows each.
Run from the ai-governance-tools folder:
  py scripts/seed_dummy_data.py
"""
import os, random, uuid, psycopg2
from datetime import date, datetime, timedelta

# ── Load DATABASE_URL_SYNC from .env.local ─────────────────────────────────
env_path = os.path.join(os.path.dirname(__file__), '..', '.env.local')
db_url = ""
if os.path.exists(env_path):
    for line in open(env_path, encoding="utf-8"):
        line = line.strip()
        if line.startswith("DATABASE_URL_SYNC="):
            db_url = line.split("=", 1)[1].strip().strip('"')
            break

if not db_url or "YOUR-PASSWORD" in db_url:
    print("ERROR: Fill in DATABASE_URL_SYNC in .env.local first.")
    exit(1)

print(f"Connecting to database...")
conn = psycopg2.connect(db_url)
conn.autocommit = False
cur = conn.cursor()

# ── Reference data ─────────────────────────────────────────────────────────
FIRST_NAMES = ["Budi","Siti","Andi","Dewi","Rudi","Fitri","Agus","Rina","Hendra","Maya",
    "Dika","Lestari","Fajar","Nurul","Bayu","Ayu","Rizky","Indah","Wahyu","Sari",
    "Arif","Dini","Eko","Putri","Galih","Wulan","Hadi","Ratna","Iwan","Citra",
    "Joko","Mega","Kevin","Nisa","Leo","Tari","Miko","Yuni","Nanda","Laras",
    "Ogi","Reni","Pandu","Vina","Qori","Ulfa","Rama","Tika","Surya","Zara"]
LAST_NAMES  = ["Santoso","Wijaya","Kusuma","Pratama","Hidayat","Rahayu","Setiawan",
    "Lestari","Nugroho","Handoko","Purnama","Susanto","Wibowo","Hartono","Saputra",
    "Gunawan","Utama","Firmansyah","Siregar","Situmorang","Nasution","Lubis",
    "Simanjuntak","Manurung","Sinaga","Bukit","Panjaitan","Nainggolan","Tobing",
    "Sirait","Harahap","Pardede","Tampubolon","Hutapea","Sihombing"]
CITIES      = ["Jakarta Pusat","Jakarta Selatan","Jakarta Barat","Jakarta Timur","Jakarta Utara",
    "Surabaya","Bandung","Medan","Bekasi","Depok","Tangerang","Semarang","Makassar",
    "Palembang","Bogor","Pekanbaru","Bandar Lampung","Padang","Malang","Batam"]
PROVINCES   = {"Jakarta Pusat":"DKI Jakarta","Jakarta Selatan":"DKI Jakarta",
    "Jakarta Barat":"DKI Jakarta","Jakarta Timur":"DKI Jakarta","Jakarta Utara":"DKI Jakarta",
    "Surabaya":"Jawa Timur","Bandung":"Jawa Barat","Medan":"Sumatera Utara",
    "Bekasi":"Jawa Barat","Depok":"Jawa Barat","Tangerang":"Banten","Semarang":"Jawa Tengah",
    "Makassar":"Sulawesi Selatan","Palembang":"Sumatera Selatan","Bogor":"Jawa Barat",
    "Pekanbaru":"Riau","Bandar Lampung":"Lampung","Padang":"Sumatera Barat",
    "Malang":"Jawa Timur","Batam":"Kepulauan Riau"}
JOBS        = ["Software Engineer","Data Analyst","Marketing Manager","Sales Executive",
    "Finance Manager","HR Specialist","Accountant","Product Manager","Business Analyst",
    "Operations Manager","Customer Service","Procurement Officer","Logistics Coordinator",
    "IT Support","UI/UX Designer","Data Scientist","Legal Counsel","Compliance Officer",
    "Internal Auditor","Project Manager"]
COMPANIES   = ["PT Maju Bersama","CV Karya Mandiri","PT Solusi Digital","PT Indo Teknologi",
    "CV Usaha Jaya","PT Global Nusantara","PT Cipta Kreasi","PT Artha Sejahtera",
    "PT Bumi Persada","PT Cahaya Abadi","PT Delta Prima","PT Eka Nusa","PT Fortuna Group",
    "PT Gemilang Utama","PT Harapan Bangsa","Freelance","Pemerintah","BUMN"]
PRODUCTS    = [
    ("PRD-001","Laptop Pro 14","Electronics","Computers"),
    ("PRD-002","Wireless Mouse","Electronics","Peripherals"),
    ("PRD-003","Mechanical Keyboard","Electronics","Peripherals"),
    ("PRD-004","Monitor 27 inch","Electronics","Displays"),
    ("PRD-005","USB-C Hub 7-in-1","Electronics","Accessories"),
    ("PRD-006","Noise Cancelling Headset","Electronics","Audio"),
    ("PRD-007","Webcam HD 1080p","Electronics","Peripherals"),
    ("PRD-008","SSD 1TB","Electronics","Storage"),
    ("PRD-009","RAM DDR5 16GB","Electronics","Memory"),
    ("PRD-010","Office Chair Ergonomic","Furniture","Seating"),
    ("PRD-011","Standing Desk 160cm","Furniture","Desks"),
    ("PRD-012","Filing Cabinet 4-drawer","Furniture","Storage"),
    ("PRD-013","Whiteboard 120x90","Office Supplies","Stationery"),
    ("PRD-014","Printer Laser A4","Electronics","Printers"),
    ("PRD-015","Toner Cartridge Black","Office Supplies","Consumables"),
    ("PRD-016","Paper A4 500 sheets","Office Supplies","Paper"),
    ("PRD-017","Ballpoint Pen 12pcs","Office Supplies","Stationery"),
    ("PRD-018","Stapler Heavy Duty","Office Supplies","Tools"),
    ("PRD-019","Shredder 10-sheet","Electronics","Machines"),
    ("PRD-020","Coffee Maker 12-cup","Appliances","Kitchen"),
    ("PRD-021","Water Dispenser Hot-Cold","Appliances","Kitchen"),
    ("PRD-022","Air Purifier HEPA","Appliances","Health"),
    ("PRD-023","Projector 4000 Lumens","Electronics","Presentation"),
    ("PRD-024","Presentation Clicker","Electronics","Accessories"),
    ("PRD-025","Extension Cord 5m","Electronics","Power"),
]
BRANCHES    = [("BR-JKT","Jakarta HQ"),("BR-SBY","Surabaya Branch"),
    ("BR-BDG","Bandung Branch"),("BR-MDN","Medan Branch"),("BR-SMG","Semarang Branch")]
SALESPERSONS = [("SP-001","Rizki Pratama"),("SP-002","Dewi Kusuma"),("SP-003","Bayu Santoso"),
    ("SP-004","Fitri Hidayat"),("SP-005","Agus Setiawan"),("SP-006","Nurul Rahayu"),
    ("SP-007","Hendra Wibowo"),("SP-008","Maya Lestari")]
PAYMENT_METHODS  = ["Transfer Bank","Kartu Kredit","Kartu Debit","Virtual Account",
    "QRIS","COD","Cicilan 0%","GoPay","OVO","Dana"]
DELIVERY_METHODS = ["JNE Reguler","JNE YES","J&T Express","SiCepat","Anteraja",
    "Grab Express","GoSend","Pick Up","Kurir Internal"]
CHANNELS   = ["Online - Website","Online - Mobile App","WhatsApp","Telepon","Toko Offline","Reseller"]
REFERRALS  = ["Google Search","Instagram","Facebook","Referral Teman","Email Marketing",
    "Tokopedia","Shopee","Lazada","Tiktok Shop","Walk-in"]
INCOME_RANGES  = ["< Rp 3 Juta","Rp 3-5 Juta","Rp 5-10 Juta","Rp 10-20 Juta","> Rp 20 Juta"]
EDUCATION      = ["SMA/SMK","Diploma (D3)","Sarjana (S1)","Magister (S2)","Doktor (S3)"]
MARITAL_STATUS = ["Lajang","Menikah","Cerai","Janda/Duda"]
SEGMENTS       = ["Regular","Silver","Gold","Platinum","VIP"]
LOYALTY_TIERS  = ["Bronze","Silver","Gold","Platinum"]
DELIVERY_STATUS= ["Pending","Processing","Shipped","Delivered","Returned","Cancelled"]
PAYMENT_STATUS = ["Pending","Paid","Partial","Refunded","Failed"]
ACCOUNT_STATUS = ["Active","Inactive","Suspended","Blacklisted"]

def rand_date(start_year=2018, end_year=2025):
    start = date(start_year, 1, 1)
    end   = date(end_year, 12, 31)
    return start + timedelta(days=random.randint(0, (end-start).days))

def rand_nik():
    return "".join([str(random.randint(0,9)) for _ in range(16)])

def rand_phone():
    prefixes = ["0811","0812","0813","0821","0822","0823","0851","0852","0853","0878","0896","0897"]
    return random.choice(prefixes) + "".join([str(random.randint(0,9)) for _ in range(8)])

def rand_email(name):
    domains = ["gmail.com","yahoo.co.id","outlook.com","hotmail.com","company.co.id"]
    clean = name.lower().replace(" ",".")
    return f"{clean}{random.randint(1,999)}@{random.choice(domains)}"

def rand_postal():
    return str(random.randint(10000, 99999))

# ── CREATE TABLES ──────────────────────────────────────────────────────────
print("Creating tables...")

cur.execute("""
CREATE TABLE IF NOT EXISTS dim_customers (
    customer_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_code       VARCHAR(20)  NOT NULL UNIQUE,
    full_name           VARCHAR(200) NOT NULL,
    email               VARCHAR(200) NOT NULL,
    phone_number        VARCHAR(20),
    gender              VARCHAR(10),
    date_of_birth       DATE,
    age                 INTEGER,
    nationality         VARCHAR(50)  DEFAULT 'Indonesia',
    id_number           VARCHAR(20),
    address_line1       VARCHAR(300),
    address_line2       VARCHAR(300),
    city                VARCHAR(100),
    province            VARCHAR(100),
    postal_code         VARCHAR(10),
    country             VARCHAR(50)  DEFAULT 'Indonesia',
    customer_type       VARCHAR(20),
    company_name        VARCHAR(200),
    job_title           VARCHAR(100),
    income_range        VARCHAR(30),
    marital_status      VARCHAR(20),
    education_level     VARCHAR(30),
    customer_segment    VARCHAR(20),
    loyalty_tier        VARCHAR(20),
    loyalty_points      INTEGER      DEFAULT 0,
    credit_limit        NUMERIC(15,2),
    credit_score        INTEGER,
    referral_source     VARCHAR(50),
    preferred_language  VARCHAR(20)  DEFAULT 'Bahasa Indonesia',
    preferred_contact   VARCHAR(20),
    account_status      VARCHAR(20)  DEFAULT 'Active',
    is_active           BOOLEAN      DEFAULT TRUE,
    registration_date   DATE,
    last_activity_date  DATE,
    created_at          TIMESTAMP    DEFAULT NOW()
);
""")

cur.execute("""
CREATE TABLE IF NOT EXISTS fact_sales_transactions (
    transaction_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_code    VARCHAR(30)  NOT NULL UNIQUE,
    customer_id         UUID         REFERENCES dim_customers(customer_id),
    customer_code       VARCHAR(20),
    customer_name       VARCHAR(200),
    salesperson_id      VARCHAR(10),
    salesperson_name    VARCHAR(200),
    branch_id           VARCHAR(10),
    branch_name         VARCHAR(100),
    transaction_date    DATE         NOT NULL,
    transaction_time    TIME,
    fiscal_year         INTEGER,
    fiscal_quarter      VARCHAR(5),
    fiscal_month        INTEGER,
    product_id          VARCHAR(10),
    product_code        VARCHAR(20),
    product_name        VARCHAR(200),
    product_category    VARCHAR(100),
    product_subcategory VARCHAR(100),
    quantity            INTEGER      NOT NULL DEFAULT 1,
    unit_price          NUMERIC(15,2),
    discount_pct        NUMERIC(5,2) DEFAULT 0,
    discount_amount     NUMERIC(15,2) DEFAULT 0,
    gross_amount        NUMERIC(15,2),
    tax_pct             NUMERIC(5,2) DEFAULT 11,
    tax_amount          NUMERIC(15,2),
    net_amount          NUMERIC(15,2),
    payment_method      VARCHAR(50),
    payment_status      VARCHAR(20),
    invoice_number      VARCHAR(30),
    order_channel       VARCHAR(50),
    delivery_method     VARCHAR(50),
    delivery_status     VARCHAR(20),
    delivery_date       DATE,
    notes               TEXT,
    created_at          TIMESTAMP    DEFAULT NOW()
);
""")

conn.commit()
print("Tables created.")

# ── INSERT CUSTOMERS ───────────────────────────────────────────────────────
print("Inserting 1,000 customers...")
customer_rows = []
for i in range(1, 1001):
    fn   = random.choice(FIRST_NAMES)
    ln   = random.choice(LAST_NAMES)
    name = f"{fn} {ln}"
    city = random.choice(CITIES)
    prov = PROVINCES[city]
    dob  = rand_date(1960, 2000)
    age  = date.today().year - dob.year
    ctype = random.choices(["Individual","Corporate"], weights=[75,25])[0]
    reg  = rand_date(2018, 2024)
    last = reg + timedelta(days=random.randint(0, (date.today()-reg).days))
    lp   = random.randint(0, 50000)
    tier = "Platinum" if lp>30000 else "Gold" if lp>15000 else "Silver" if lp>5000 else "Bronze"
    seg  = random.choice(SEGMENTS)
    customer_rows.append((
        str(uuid.uuid4()),
        f"CUST-{i:05d}",
        name,
        rand_email(name),
        rand_phone(),
        random.choice(["Laki-laki","Perempuan"]),
        dob,
        age,
        "Indonesia",
        rand_nik(),
        f"Jl. {random.choice(['Merdeka','Sudirman','Gatot Subroto','Ahmad Yani','Diponegoro'])} No.{random.randint(1,999)}",
        f"RT {random.randint(1,20):02d}/RW {random.randint(1,10):02d}",
        city, prov,
        rand_postal(),
        "Indonesia",
        ctype,
        random.choice(COMPANIES) if ctype=="Corporate" else None,
        random.choice(JOBS),
        random.choice(INCOME_RANGES),
        random.choice(MARITAL_STATUS),
        random.choice(EDUCATION),
        seg, tier, lp,
        round(random.uniform(5000000, 200000000), 2),
        random.randint(300, 850),
        random.choice(REFERRALS),
        "Bahasa Indonesia",
        random.choice(["WhatsApp","Email","Telepon","SMS"]),
        random.choice(ACCOUNT_STATUS),
        random.random() > 0.08,
        reg, last,
    ))

cur.executemany("""
INSERT INTO dim_customers (
    customer_id, customer_code, full_name, email, phone_number, gender,
    date_of_birth, age, nationality, id_number, address_line1, address_line2,
    city, province, postal_code, country, customer_type, company_name, job_title,
    income_range, marital_status, education_level, customer_segment, loyalty_tier,
    loyalty_points, credit_limit, credit_score, referral_source, preferred_language,
    preferred_contact, account_status, is_active, registration_date, last_activity_date
) VALUES (
    %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,
    %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s
)
ON CONFLICT (customer_code) DO NOTHING
""", customer_rows)
conn.commit()
print(f"  Inserted {len(customer_rows)} customers.")

# ── Fetch customer IDs for FK ──────────────────────────────────────────────
cur.execute("SELECT customer_id, customer_code, full_name FROM dim_customers LIMIT 1000")
customers = cur.fetchall()

# ── INSERT SALES TRANSACTIONS ──────────────────────────────────────────────
print("Inserting 1,000 sales transactions...")
sales_rows = []
for i in range(1, 1001):
    cust     = random.choice(customers)
    cust_id, cust_code, cust_name = cust
    branch   = random.choice(BRANCHES)
    sp       = random.choice(SALESPERSONS)
    product  = random.choice(PRODUCTS)
    prod_code, prod_name, prod_cat, prod_sub = product
    prod_id  = prod_code

    txn_date = rand_date(2022, 2025)
    hour     = random.randint(8, 20)
    minute   = random.randint(0, 59)
    txn_time = f"{hour:02d}:{minute:02d}:00"

    qty      = random.randint(1, 20)
    base_price = random.choice([
        199000,299000,499000,799000,999000,1299000,1999000,
        2499000,3499000,4999000,7999000,12999000,24999000
    ])
    disc_pct = random.choice([0,0,0,5,10,15,20,25])
    disc_amt = round(base_price * disc_pct / 100, 2)
    gross    = round((base_price - disc_amt) * qty, 2)
    tax_pct  = 11
    tax_amt  = round(gross * tax_pct / 100, 2)
    net      = round(gross + tax_amt, 2)

    pay_status   = random.choices(PAYMENT_STATUS, weights=[5,80,5,5,5])[0]
    del_status   = random.choices(DELIVERY_STATUS, weights=[5,10,15,60,5,5])[0]
    delivery_date = None
    if del_status == "Delivered":
        delivery_date = txn_date + timedelta(days=random.randint(1,7))

    fq = f"Q{((txn_date.month - 1) // 3) + 1}"

    sales_rows.append((
        str(uuid.uuid4()),
        f"TRX-{txn_date.year}-{i:06d}",
        cust_id, cust_code, cust_name,
        sp[0], sp[1],
        branch[0], branch[1],
        txn_date, txn_time,
        txn_date.year, fq, txn_date.month,
        prod_id, prod_code, prod_name, prod_cat, prod_sub,
        qty, base_price, disc_pct, disc_amt, gross, tax_pct, tax_amt, net,
        random.choice(PAYMENT_METHODS),
        pay_status,
        f"INV-{txn_date.year}-{i:06d}",
        random.choice(CHANNELS),
        random.choice(DELIVERY_METHODS),
        del_status,
        delivery_date,
        random.choice([None, None, None, "Sesuai permintaan customer", "Fragile - handle with care",
                       "Gift wrapping requested", "Urgent order", "Repeat customer"]),
    ))

cur.executemany("""
INSERT INTO fact_sales_transactions (
    transaction_id, transaction_code, customer_id, customer_code, customer_name,
    salesperson_id, salesperson_name, branch_id, branch_name,
    transaction_date, transaction_time, fiscal_year, fiscal_quarter, fiscal_month,
    product_id, product_code, product_name, product_category, product_subcategory,
    quantity, unit_price, discount_pct, discount_amount, gross_amount,
    tax_pct, tax_amount, net_amount, payment_method, payment_status,
    invoice_number, order_channel, delivery_method, delivery_status, delivery_date, notes
) VALUES (
    %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,
    %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s
)
ON CONFLICT (transaction_code) DO NOTHING
""", sales_rows)
conn.commit()
print(f"  Inserted {len(sales_rows)} sales transactions.")

cur.close()
conn.close()

print()
print("=" * 55)
print("  Dummy data seeded successfully!")
print("=" * 55)
print()
print("  Tables created:")
print("  - dim_customers          (35 columns, 1,000 rows)")
print("  - fact_sales_transactions (35 columns, 1,000 rows)")
print()
print("  Sample data includes:")
print("  - Indonesian customer names, cities, NIK, phone numbers")
print("  - 25 product SKUs across Electronics, Furniture, etc.")
print("  - 5 branches, 8 salespersons")
print("  - Transactions from 2022-2025 with full fiscal dims")
