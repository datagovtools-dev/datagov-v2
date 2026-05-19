"""
Generate seed_dummy_data.sql for dim_customers + fact_sales_transactions.
Run:  py scripts/generate_seed_sql.py
Then paste the output SQL into Supabase SQL Editor:
  supabase.com → your project → SQL Editor → New query → paste → Run
"""
import random, uuid
from datetime import date, timedelta

random.seed(42)  # reproducible output

OUT_FILE = "scripts/seed_dummy_data.sql"

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
    "PT Gemilang Utama","PT Harapan Bangsa"]
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
DELIVERY_STATUS= ["Pending","Processing","Shipped","Delivered","Returned","Cancelled"]
PAYMENT_STATUS = ["Pending","Paid","Partial","Refunded","Failed"]
ACCOUNT_STATUS = ["Active","Inactive","Suspended","Blacklisted"]
BASE_PRICES    = [199000,299000,499000,799000,999000,1299000,1999000,
                  2499000,3499000,4999000,7999000,12999000,24999000]

STREET_NAMES   = ["Merdeka","Sudirman","Gatot Subroto","Ahmad Yani","Diponegoro",
                  "Veteran","Pahlawan","Imam Bonjol","Teuku Umar","Gajah Mada"]
NOTES_OPTIONS  = [None,None,None,
    "Sesuai permintaan customer","Fragile - handle with care",
    "Gift wrapping requested","Urgent order","Repeat customer"]

def q(s):
    """Wrap in single quotes, escaping internal single quotes."""
    if s is None:
        return "NULL"
    return "'" + str(s).replace("'", "''") + "'"

def qb(b):
    return "TRUE" if b else "FALSE"

def rand_date(start_year=2018, end_year=2025):
    start = date(start_year, 1, 1)
    end   = date(end_year, 12, 31)
    return start + timedelta(days=random.randint(0, (end - start).days))

def rand_nik():
    return "".join(str(random.randint(0,9)) for _ in range(16))

def rand_phone():
    prefixes = ["0811","0812","0813","0821","0822","0823","0851","0852","0853","0878"]
    return random.choice(prefixes) + "".join(str(random.randint(0,9)) for _ in range(8))

def rand_email(name):
    domains = ["gmail.com","yahoo.co.id","outlook.com","hotmail.com","company.co.id"]
    clean = name.lower().replace(" ",".")
    return f"{clean}{random.randint(1,999)}@{random.choice(domains)}"

def rand_postal():
    return str(random.randint(10000, 99999))

print("Generating SQL...")

lines = []

# ── Header ─────────────────────────────────────────────────────────────────
lines.append("-- ============================================================")
lines.append("--  AI Governance Tools — Dummy Data Seed")
lines.append("--  Tables: dim_customers (35 cols, 1000 rows)")
lines.append("--          fact_sales_transactions (35 cols, 1000 rows)")
lines.append("--  Generated by: py scripts/generate_seed_sql.py")
lines.append("-- ============================================================")
lines.append("")

# ── Create dim_customers ────────────────────────────────────────────────────
lines.append("""CREATE TABLE IF NOT EXISTS dim_customers (
    customer_id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
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

# ── Create fact_sales_transactions ──────────────────────────────────────────
lines.append("""CREATE TABLE IF NOT EXISTS fact_sales_transactions (
    transaction_id      UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
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

# ── Insert customers ────────────────────────────────────────────────────────
lines.append("-- Insert 1,000 customers")
customer_data = []  # list of (uuid_str, code, name) for FK use in sales

for i in range(1, 1001):
    fn    = random.choice(FIRST_NAMES)
    ln    = random.choice(LAST_NAMES)
    name  = f"{fn} {ln}"
    city  = random.choice(CITIES)
    prov  = PROVINCES[city]
    dob   = rand_date(1960, 2000)
    age   = date.today().year - dob.year
    ctype = random.choices(["Individual","Corporate"], weights=[75,25])[0]
    reg   = rand_date(2018, 2024)
    last  = reg + timedelta(days=random.randint(0, (date.today()-reg).days))
    lp    = random.randint(0, 50000)
    tier  = "Platinum" if lp>30000 else "Gold" if lp>15000 else "Silver" if lp>5000 else "Bronze"
    seg   = random.choice(SEGMENTS)
    uid   = str(uuid.uuid4())
    code  = f"CUST-{i:05d}"
    company = random.choice(COMPANIES) if ctype == "Corporate" else None

    customer_data.append((uid, code, name))

    vals = ",".join([
        q(uid), q(code), q(name), q(rand_email(name)), q(rand_phone()),
        q(random.choice(["Laki-laki","Perempuan"])),
        q(str(dob)), str(age), q("Indonesia"), q(rand_nik()),
        q(f"Jl. {random.choice(STREET_NAMES)} No.{random.randint(1,999)}"),
        q(f"RT {random.randint(1,20):02d}/RW {random.randint(1,10):02d}"),
        q(city), q(prov), q(rand_postal()), q("Indonesia"),
        q(ctype), q(company), q(random.choice(JOBS)),
        q(random.choice(INCOME_RANGES)), q(random.choice(MARITAL_STATUS)),
        q(random.choice(EDUCATION)), q(seg), q(tier), str(lp),
        str(round(random.uniform(5000000,200000000),2)),
        str(random.randint(300,850)),
        q(random.choice(REFERRALS)), q("Bahasa Indonesia"),
        q(random.choice(["WhatsApp","Email","Telepon","SMS"])),
        q(random.choice(ACCOUNT_STATUS)),
        qb(random.random() > 0.08),
        q(str(reg)), q(str(last)),
    ])
    lines.append(
        f"INSERT INTO dim_customers (customer_id,customer_code,full_name,email,phone_number,gender,"
        f"date_of_birth,age,nationality,id_number,address_line1,address_line2,city,province,"
        f"postal_code,country,customer_type,company_name,job_title,income_range,marital_status,"
        f"education_level,customer_segment,loyalty_tier,loyalty_points,credit_limit,credit_score,"
        f"referral_source,preferred_language,preferred_contact,account_status,is_active,"
        f"registration_date,last_activity_date) VALUES ({vals}) ON CONFLICT (customer_code) DO NOTHING;"
    )

lines.append("")

# ── Insert sales transactions ───────────────────────────────────────────────
lines.append("-- Insert 1,000 sales transactions")

for i in range(1, 1001):
    cust_uid, cust_code, cust_name = random.choice(customer_data)
    branch   = random.choice(BRANCHES)
    sp       = random.choice(SALESPERSONS)
    prod     = random.choice(PRODUCTS)
    prod_code, prod_name, prod_cat, prod_sub = prod
    prod_id  = prod_code

    txn_date = rand_date(2022, 2025)
    hour     = random.randint(8, 20)
    minute   = random.randint(0, 59)
    txn_time = f"{hour:02d}:{minute:02d}:00"

    qty      = random.randint(1, 20)
    bp       = random.choice(BASE_PRICES)
    disc_pct = random.choice([0,0,0,5,10,15,20,25])
    disc_amt = round(bp * disc_pct / 100, 2)
    gross    = round((bp - disc_amt) * qty, 2)
    tax_pct  = 11
    tax_amt  = round(gross * tax_pct / 100, 2)
    net      = round(gross + tax_amt, 2)

    pay_status = random.choices(PAYMENT_STATUS, weights=[5,80,5,5,5])[0]
    del_status = random.choices(DELIVERY_STATUS, weights=[5,10,15,60,5,5])[0]
    del_date   = None
    if del_status == "Delivered":
        del_date = txn_date + timedelta(days=random.randint(1,7))

    fq = f"Q{((txn_date.month - 1) // 3) + 1}"
    note = random.choice(NOTES_OPTIONS)

    vals = ",".join([
        q(str(uuid.uuid4())),
        q(f"TRX-{txn_date.year}-{i:06d}"),
        q(cust_uid), q(cust_code), q(cust_name),
        q(sp[0]), q(sp[1]),
        q(branch[0]), q(branch[1]),
        q(str(txn_date)), q(txn_time),
        str(txn_date.year), q(fq), str(txn_date.month),
        q(prod_id), q(prod_code), q(prod_name), q(prod_cat), q(prod_sub),
        str(qty), str(bp), str(disc_pct), str(disc_amt), str(gross),
        str(tax_pct), str(tax_amt), str(net),
        q(random.choice(PAYMENT_METHODS)), q(pay_status),
        q(f"INV-{txn_date.year}-{i:06d}"),
        q(random.choice(CHANNELS)),
        q(random.choice(DELIVERY_METHODS)),
        q(del_status),
        q(str(del_date)) if del_date else "NULL",
        q(note),
    ])
    lines.append(
        f"INSERT INTO fact_sales_transactions (transaction_id,transaction_code,customer_id,"
        f"customer_code,customer_name,salesperson_id,salesperson_name,branch_id,branch_name,"
        f"transaction_date,transaction_time,fiscal_year,fiscal_quarter,fiscal_month,"
        f"product_id,product_code,product_name,product_category,product_subcategory,"
        f"quantity,unit_price,discount_pct,discount_amount,gross_amount,tax_pct,tax_amount,"
        f"net_amount,payment_method,payment_status,invoice_number,order_channel,"
        f"delivery_method,delivery_status,delivery_date,notes) VALUES ({vals})"
        f" ON CONFLICT (transaction_code) DO NOTHING;"
    )

lines.append("")
lines.append("-- Verify row counts")
lines.append("SELECT 'dim_customers' AS tbl, COUNT(*) AS rows FROM dim_customers")
lines.append("UNION ALL")
lines.append("SELECT 'fact_sales_transactions', COUNT(*) FROM fact_sales_transactions;")

sql = "\n".join(lines)
with open(OUT_FILE, "w", encoding="utf-8") as f:
    f.write(sql)

size_kb = len(sql.encode("utf-8")) // 1024
print(f"Written: {OUT_FILE}  ({size_kb} KB, {len(lines)} lines)")
print()
print("Next step:")
print("  1. Open https://supabase.com  > your project > SQL Editor")
print("  2. Click 'New query'")
print("  3. Open scripts/seed_dummy_data.sql, select all, paste into the editor")
print("  4. Click 'Run'  (green button, top-right)")
print()
print("The last query will confirm row counts for both tables.")
