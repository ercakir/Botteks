import ai_agent
import psycopg2

try:
    # Veritabanı bağlantı bilgileri
    connection = psycopg2.connect(
        host="127.0.0.1",
        port="5432",
        database="tekstil_demo_2",
        user="chatbot_user",
        password="sifreniz" # Eğer docker kurarken başka bir şifre verdiysen onu yazmalısın
    )

    cursor = connection.cursor()
    
    # Basit bir test sorgusu: Kumaş türlerini çekelim
    cursor.execute("SELECT id, kumas_adi FROM kumaslar LIMIT 5;")
    kumaslar = cursor.fetchall()

    print("\n🎉 BAĞLANTI BAŞARILI! Veritabanından gelen kumaşlar:")
    print("-" * 50)
    for kumas in kumaslar:
        print(f"ID: {kumas[0]} - Kumaş Adı: {kumas[1]}")
    print("-" * 50)

    cursor.close()
    connection.close()

except Exception as error:
    print("\n❌ Bağlantı hatası oluştu:")
    print(error)