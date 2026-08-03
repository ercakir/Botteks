import sqlite3
import datetime
import random

def create_sqlite_demo_db():
    conn = sqlite3.connect("tekstil_demo.db")
    cursor = conn.cursor()

    # 1. musteriler
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS musteriler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        musteri_adi TEXT NOT NULL,
        ulke TEXT NOT NULL
    );
    """)

    # 2. kumaslar
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS kumaslar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kumas_adi TEXT NOT NULL
    );
    """)

    # 3. urun_turleri
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS urun_turleri (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        urun_turu_adi TEXT NOT NULL
    );
    """)

    # 4. urunler
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS urunler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        urun_kodu TEXT NOT NULL UNIQUE,
        urun_turu_id INTEGER,
        kumas_id INTEGER,
        cinsiyet_id INTEGER
    );
    """)

    # 5. musteri_alt_markalari
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS musteri_alt_markalari (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        musteri_id INTEGER,
        alt_marka_no TEXT,
        alt_marka_kodu TEXT,
        alt_marka_adi TEXT NOT NULL,
        kategori TEXT NOT NULL,
        merkez_ulke TEXT NOT NULL,
        aktif BOOLEAN DEFAULT 1
    );
    """)

    # 6. siparisler
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS siparisler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarih TEXT NOT NULL,
        musteri_id INTEGER,
        musteri_alt_marka_id INTEGER,
        urun_kodu TEXT NOT NULL,
        urun_durumu TEXT NOT NULL,
        miktar INTEGER NOT NULL,
        birim_fiyat REAL NOT NULL
    );
    """)

    # 7. odemeler
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS odemeler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        odeme_tarihi TEXT NOT NULL,
        miktar REAL NOT NULL,
        musteri_id INTEGER,
        musteri_alt_marka_id INTEGER
    );
    """)

    # Check if data already populated
    cursor.execute("SELECT COUNT(*) FROM musteriler")
    if cursor.fetchone()[0] == 0:
        print("Populating SQLite demo dataset...")

        # Insert Musteriler
        musteriler_data = [
            (1, "H&M Hennes & Mauritz AB", "İsveç"),
            (2, "Inditex S.A.", "İspanya"),
            (3, "Primark Limited", "İrlanda"),
            (4, "C&A Mode GmbH", "Almanya"),
            (5, "LPP S.A.", "Polonya")
        ]
        cursor.executemany("INSERT INTO musteriler (id, musteri_adi, ulke) VALUES (?, ?, ?)", musteriler_data)

        # Insert Kumaslar
        kumaslar_data = [
            (1, "Pamuklu Süprem"),
            (2, "Keten Karışım"),
            (3, "Kot / Denim"),
            (4, "Ribana Örme"),
            (5, "Pike Kumaş")
        ]
        cursor.executemany("INSERT INTO kumaslar (id, kumas_adi) VALUES (?, ?)", kumaslar_data)

        # Insert Urun Turleri
        urun_turleri_data = [
            (1, "Tshirt"),
            (2, "Sweatshirt"),
            (3, "Gömlek"),
            (4, "Pantolon"),
            (5, "Elbise")
        ]
        cursor.executemany("INSERT INTO urun_turleri (id, urun_turu_adi) VALUES (?, ?)", urun_turleri_data)

        # Insert Musteri Alt Markalari
        alt_markalar_data = [
            (1, 1, "ALT-001", "HM-MAIN", "H&M", "Uygun Fiyatlı Moda", "İsveç", 1),
            (2, 1, "ALT-002", "COS-MODA", "COS", "Premium Moda", "İsveç", 1),
            (3, 2, "ALT-003", "IND-ZARA", "Zara", "Premium Moda", "İspanya", 1),
            (4, 2, "ALT-004", "IND-MASS", "Massimo Dutti", "Premium Moda", "İspanya", 1),
            (5, 2, "ALT-005", "IND-BERS", "Bershka", "Genç Moda", "İspanya", 1),
            (6, 2, "ALT-006", "IND-PULL", "Pull&Bear", "Genç Moda", "İspanya", 1),
            (7, 2, "ALT-007", "IND-OYSH", "Oysho", "Spor ve Yaşam", "İspanya", 1),
            (8, 2, "ALT-008", "IND-STRA", "Stradivarius", "Genç Moda", "İspanya", 1),
            (9, 3, "ALT-009", "PRI-MAIN", "Primark", "Uygun Fiyatlı Moda", "İrlanda", 1),
            (10, 3, "ALT-010", "PRI-KIDS", "Primark Kids", "Çocuk Moda", "İrlanda", 1),
            (11, 4, "ALT-011", "CNA-MODE", "C&A Mode", "Uygun Fiyatlı Moda", "Almanya", 1),
            (12, 5, "ALT-012", "LPP-SINS", "Sinsay", "Uygun Fiyatlı Moda", "Polonya", 1)
        ]
        cursor.executemany("INSERT INTO musteri_alt_markalari VALUES (?, ?, ?, ?, ?, ?, ?, ?)", alt_markalar_data)

        # Insert Urunler
        urunler_data = [
            (1, "BASKILI-TSHIRT-01", 1, 1, 1),
            (2, "BASKILI-SWEATSHIRT-02", 2, 1, 1),
            (3, "KADIN-GÖMLEK-03", 3, 2, 1),
            (4, "KOT-PANTOLON-04", 4, 3, 2),
            (5, "PİKE-TSHIRT-05", 1, 5, 2)
        ]
        cursor.executemany("INSERT INTO urunler VALUES (?, ?, ?, ?, ?)", urunler_data)

        # Generate Siparisler (Orders) over past 3 years
        durumlar = ["teslim edildi", "kargolandi", "üretimde", "beklemede", "iptal"]
        siparisler_data = []
        odemeler_data = []

        start_date = datetime.date(2023, 1, 1)
        s_id = 1
        o_id = 1

        for i in range(250):
            days_offset = random.randint(0, 1250)
            tarih = (start_date + datetime.timedelta(days=days_offset)).strftime("%Y-%m-%d")
            musteri_id = random.randint(1, 5)
            # Find alt_marka for this musteri
            m_alt_ids = [am[0] for am in alt_markalar_data if am[1] == musteri_id]
            alt_id = random.choice(m_alt_ids) if m_alt_ids else 1
            urun = random.choice(urunler_data)
            durum = random.choice(durumlar)
            miktar = random.randint(100, 2500)
            birim_fiyat = round(random.uniform(15.0, 95.0), 2)

            siparisler_data.append((s_id, tarih, musteri_id, alt_id, urun[1], durum, miktar, birim_fiyat))

            # Add payment if delivered or shipped
            if durum in ["teslim edildi", "kargolandi"]:
                odeme_miktar = round(miktar * birim_fiyat * random.uniform(0.9, 1.0), 2)
                odemeler_data.append((o_id, tarih, odeme_miktar, musteri_id, alt_id))
                o_id += 1

            s_id += 1

        cursor.executemany("INSERT INTO siparisler VALUES (?, ?, ?, ?, ?, ?, ?, ?)", siparisler_data)
        cursor.executemany("INSERT INTO odemeler VALUES (?, ?, ?, ?, ?)", odemeler_data)

    conn.commit()
    conn.close()
    print("SQLite demo database created successfully at tekstil_demo.db!")

if __name__ == "__main__":
    create_sqlite_demo_db()
