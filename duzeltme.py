import psycopg2

try:
    # Veritabanına bağlan
    connection = psycopg2.connect(
        host="localhost",
        port="5432",
        database="tekstil_demo_2",
        user="chatbot_user",
        password="sifreniz" 
    )
    
    # Türkçe karakterleri doğru iletmek için UTF8 ayarı
    connection.set_client_encoding('UTF8')
    cursor = connection.cursor()

    # Hatalı ülkeleri düzeltecek SQL komutları
    sql_guncelleme = """
    UPDATE musteriler SET ulke = 'İsveç' WHERE musteri_adi = 'H&M';
    UPDATE musteriler SET ulke = 'İspanya' WHERE musteri_adi = 'Inditex';
    UPDATE musteriler SET ulke = 'İrlanda' WHERE musteri_adi = 'Primark';
    """
    
    # Komutları çalıştır ve kalıcı olarak kaydet (commit)
    cursor.execute(sql_guncelleme)
    connection.commit()
    
    print("✅ Ülke isimleri veritabanında başarıyla düzeltildi!")
    
except Exception as e:
    print(f"❌ Bir hata oluştu: {e}")

finally:
    if connection:
        cursor.close()
        connection.close()