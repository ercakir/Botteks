import psycopg2
import sys
import io
from openai import OpenAI

# Windows terminallerinde Türkçe karakter hatalarını önleyelim
if sys.platform.startswith("win"):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8")

# 1. Qwen 3.5 Model Bağlantı Ayarları
client = OpenAI(
    base_url="http://43.229.92.27:8081/v1",
    api_key="not-needed"
)
MODEL_NAME = "qwen3.5-35b"

# 2. PostgreSQL Veritabanı Bağlantı Fonksiyonu
def execute_sql(sql_query):
    try:
        connection = psycopg2.connect(
            host="localhost",
            port="5432",
            database="tekstil_demo_2",
            user="chatbot_user",
            password="sifreniz" # Veritabanı şifreni buraya girmeyi unutma
        )
        connection.set_client_encoding('UTF8') 
        cursor = connection.cursor()
        cursor.execute(sql_query)
        
        if sql_query.strip().upper().startswith("SELECT"):
            columns = [desc[0] for desc in cursor.description]
            results = cursor.fetchall()
            cursor.close()
            connection.close()
            return {"status": "success", "columns": columns, "data": results}
        
        connection.commit()
        cursor.close()
        connection.close()
        return {"status": "success", "message": "Sorgu başarıyla çalıştırıldı."}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# 3. Model için Veritabanı Şeması
DB_SCHEMA = """
Tablo: musteriler (id, musteri_adi, ulke)
Tablo: kumaslar (id, kumas_adi)
Tablo: urun_turleri (id, urun_turu_adi)
Tablo: urunler (id, urun_kodu, urun_turu_id, kumas_id, cinsiyet_id)
Tablo: musteri_alt_markalari (id, musteri_id, alt_marka_no, alt_marka_kodu, alt_marka_adi, kategori, merkez_ulke, aktif)
Tablo: siparisler (id, tarih, musteri_id, musteri_alt_marka_id, urun_kodu, urun_durumu, miktar, birim_fiyat)
Tablo: odemeler (id, odeme_tarihi, miktar, musteri_id, musteri_alt_marka_id)
"""

# AI çevrimdışı olduğunda kullanılacak devasa simülasyon sözlüğü
# AI çevrimdışı olduğunda kullanılacak devasa ve HATAYA DAYANIKLI simülasyon sözlüğü
OFFLINE_SQL_MAP = {
    # Hata yapmaya müsait kelimeler için hem Türkçe hem İngilizce kökler kullanıyoruz
    "müşteri sayı": "SELECT COUNT(*) AS toplam_musteri FROM musteriler;",
    "musteri sayi": "SELECT COUNT(*) AS toplam_musteri FROM musteriler;",
    "müşterileri listele": "SELECT id, musteri_adi, ulke FROM musteriler ORDER BY id;",
    "musterileri listele": "SELECT id, musteri_adi, ulke FROM musteriler ORDER BY id;",
    "kaç marka": "SELECT musteri_id, COUNT(*) AS marka_sayisi FROM musteri_alt_markalari GROUP BY musteri_id;",
    
    # ÜLKELER (Veritabanındaki bozuklukları aşmak için metin yerine musteri_id kullanıyoruz)
    "sveç": "SELECT alt_marka_kodu, alt_marka_adi, kategori FROM musteri_alt_markalari WHERE musteri_id = 1;",
    "svec": "SELECT alt_marka_kodu, alt_marka_adi, kategori FROM musteri_alt_markalari WHERE musteri_id = 1;",
    "spanya": "SELECT alt_marka_kodu, alt_marka_adi, kategori FROM musteri_alt_markalari WHERE musteri_id = 2;",
    "rlanda": "SELECT alt_marka_kodu, alt_marka_adi, kategori FROM musteri_alt_markalari WHERE musteri_id = 3;",
    "almanya": "SELECT alt_marka_kodu, alt_marka_adi, kategori FROM musteri_alt_markalari WHERE musteri_id = 4;",
    "polonya": "SELECT alt_marka_kodu, alt_marka_adi, kategori FROM musteri_alt_markalari WHERE musteri_id = 5;",
    "zara": "SELECT alt_marka_kodu, alt_marka_adi, kategori FROM musteri_alt_markalari WHERE alt_marka_adi = 'Zara';",
    "aktif marka": "SELECT alt_marka_kodu, alt_marka_adi, kategori FROM musteri_alt_markalari WHERE aktif = TRUE;",

    # KUMAŞLAR VE ÜRÜNLER
    "kumaş": "SELECT id, kumas_adi FROM kumaslar ORDER BY id;",
    "kumas": "SELECT id, kumas_adi FROM kumaslar ORDER BY id;",
    "süprem": "SELECT u.urun_kodu, ut.urun_turu_adi FROM urunler u JOIN urun_turleri ut ON u.urun_turu_id = ut.id WHERE u.kumas_id = 1 LIMIT 10;",
    "suprem": "SELECT u.urun_kodu, ut.urun_turu_adi FROM urunler u JOIN urun_turleri ut ON u.urun_turu_id = ut.id WHERE u.kumas_id = 1 LIMIT 10;",
    "kadın": "SELECT u.urun_kodu, ut.urun_turu_adi, k.kumas_adi FROM urunler u JOIN urun_turleri ut ON u.urun_turu_id = ut.id JOIN kumaslar k ON u.kumas_id = k.id WHERE u.cinsiyet_id = 1 LIMIT 10;",
    "kadin": "SELECT u.urun_kodu, ut.urun_turu_adi, k.kumas_adi FROM urunler u JOIN urun_turleri ut ON u.urun_turu_id = ut.id JOIN kumaslar k ON u.kumas_id = k.id WHERE u.cinsiyet_id = 1 LIMIT 10;",
    "erkek": "SELECT u.urun_kodu, ut.urun_turu_adi, k.kumas_adi FROM urunler u JOIN urun_turleri ut ON u.urun_turu_id = ut.id JOIN kumaslar k ON u.kumas_id = k.id WHERE u.cinsiyet_id = 2 LIMIT 10;",

    # SİPARİŞ DURUMLARI
    "beklemede": "SELECT id, tarih, urun_kodu, miktar, birim_fiyat FROM siparisler WHERE urun_durumu = 'beklemede' ORDER BY tarih DESC LIMIT 10;",
    "üretimde": "SELECT id, tarih, urun_kodu, miktar, birim_fiyat FROM siparisler WHERE urun_durumu = 'üretimde' ORDER BY tarih DESC LIMIT 10;",
    "uretimde": "SELECT id, tarih, urun_kodu, miktar, birim_fiyat FROM siparisler WHERE urun_durumu = 'üretimde' ORDER BY tarih DESC LIMIT 10;",
    "kargoland": "SELECT id, tarih, urun_kodu, miktar, birim_fiyat FROM siparisler WHERE urun_durumu = 'kargolandi' ORDER BY tarih DESC LIMIT 10;",
    "teslim": "SELECT id, tarih, urun_kodu, miktar, birim_fiyat FROM siparisler WHERE urun_durumu = 'teslim edildi' ORDER BY tarih DESC LIMIT 10;",
    "iptal edilen": "SELECT id, tarih, urun_kodu, miktar, birim_fiyat FROM siparisler WHERE urun_durumu = 'iptal' ORDER BY tarih DESC LIMIT 10;",
    "son sipariş": "SELECT s.id, s.tarih, m.musteri_adi, s.urun_kodu, s.miktar, s.birim_fiyat, s.urun_durumu FROM siparisler s JOIN musteriler m ON s.musteri_id = m.id ORDER BY s.tarih DESC LIMIT 5;",
    "son siparis": "SELECT s.id, s.tarih, m.musteri_adi, s.urun_kodu, s.miktar, s.birim_fiyat, s.urun_durumu FROM siparisler s JOIN musteriler m ON s.musteri_id = m.id ORDER BY s.tarih DESC LIMIT 5;",

    # FİNANS
    "toplam ciro": "SELECT SUM(miktar * birim_fiyat) AS net_ciro_eur FROM siparisler WHERE urun_durumu != 'iptal';",
    "tahsilat": "SELECT SUM(miktar) AS toplam_tahsilat_eur FROM odemeler;",
    "bakiye": "SELECT (SELECT SUM(miktar * birim_fiyat) FROM siparisler WHERE urun_durumu != 'iptal') - (SELECT SUM(miktar) FROM odemeler) AS kalan_net_alacak_eur;",
    "kayı": "SELECT SUM(miktar * birim_fiyat) AS iptal_kayip_eur FROM siparisler WHERE urun_durumu = 'iptal';",
    "kayi": "SELECT SUM(miktar * birim_fiyat) AS iptal_kayip_eur FROM siparisler WHERE urun_durumu = 'iptal';",
    "fiyat": "SELECT ROUND(AVG(birim_fiyat), 2) AS ort_fiyat_eur FROM siparisler WHERE urun_durumu != 'iptal';"
}

# 4. Doğal Dili SQL'e Çeviren Fonksiyon
def ask_ai_for_sql(user_prompt):
    system_instruction = f"""
Sen bir PostgreSQL veritabanı uzmanısın. Kullanıcının Türkçe sorduğu soruları veritabanı şemasına göre sadece ve sadece geçerli bir SQL SELECT sorgusuna dönüştürmelisin.
Geriye SQL sorgusu dışında hiçbir açıklama, markdown işareti (```sql gibi) veya metin yazma. Sadece çalıştırılabilir saf SQL sorgusunu dön.

Veritabanı Şeması:
{DB_SCHEMA}
"""
    try:
        response = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {"role": "system", "content": system_instruction},
                {"role": "user", "content": f"Soru: {user_prompt}\nSQL:"}
            ],
            temperature=0.1,
            timeout=5.0
        )
        message_content = response.choices[0].message.content
        if message_content is None:
            raise ValueError("Yapay zeka boş yanıt döndürdü.")
        raw_sql = message_content.strip()
        return raw_sql.replace("```sql", "").replace("```", "").strip()
        
    except Exception as e:
        print("\n⚠️  AI Sunucusuna ulaşılamadı. 'Çevrimdışı Simülasyon Modu' ile cevap aranıyor...")
        
        # Basitçe tamamen küçük harfe çevirip en güvenli kökleri arıyoruz
        prompt_lower = user_prompt.lower()
        
        for key, sql in OFFLINE_SQL_MAP.items():
            if key in prompt_lower:
                return sql
                
        # Eşleşmezse hata vermemesi için güvenli sorgu
        return "SELECT id, musteri_adi, ulke FROM musteriler LIMIT 3;"
# 5. Ana Çalıştırma Döngüsü
if __name__ == "__main__":
    print("\n==================================================")
    print("🤖 AI Müşteri Framework — Akıllı Raporlama Paneli")
    print("==================================================")
    print("Sormak istediğiniz soruları serbestçe yazabilirsiniz (Örn: 'Almanya şirketlerini getir')")
    print("Çıkmak için 'exit' yazabilirsiniz.\n")
    
    while True:
        prompt = input("Sorunuzu yazın: ").strip()
        
        if prompt.lower() == 'exit':
            print("👋 Görüşmek üzere!")
            break
            
        if not prompt:
            continue
            
        print("🧠 Sorgu hazırlanıyor...")
        generated_sql = ask_ai_for_sql(prompt)
        
        if generated_sql:
            print(f"\n📝 Oluşturulan SQL:\n{generated_sql}\n")
            db_result = execute_sql(generated_sql)
            
            if db_result["status"] == "success":
                print("📊 Veritabanı Sonuçları:")
                print(f"Sütunlar: {db_result.get('columns')}")
                print("-" * 50)
                for row in db_result.get('data', []):
                    # Finansal veriler varsa okunaklı formatlayalım
                    formatted_row = tuple(
                        f"{val:,.2f} EUR" if isinstance(val, (int, float)) and any(x in prompt.lower() for x in ["ciro", "bakiye", "tahsilat", "fiyat", "kayıp"])
                        else val for val in row
                    )
                    print(formatted_row)
                print("-" * 50)
            else:
                print(f"❌ SQL Çalıştırma Hatası: {db_result['message']}")
        else:
            print("❌ SQL sorgusu oluşturulamadı.")