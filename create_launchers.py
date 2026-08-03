import os

desktop = "C:/Users/Lenovo/Desktop"
proj = "c:/Users/Lenovo/.gemini/antigravity-ide/scratch/tekstil-demo"

bat_content = """@echo off
echo Botteks BI ve Sunumu Aciliyor...
start "" "http://localhost:8501"
start "" "C:\\Users\\Lenovo\\Desktop\\Botteks_Sunumu.html"
exit
"""

url_sunum = """[InternetShortcut]
URL=file:///C:/Users/Lenovo/Desktop/Botteks_Sunumu.html
"""

url_app = """[InternetShortcut]
URL=http://localhost:8501
"""

for p in [desktop, proj]:
    with open(os.path.join(p, "Sunumu_Ac.bat"), "w", encoding="utf-8") as f:
        f.write(bat_content)
    with open(os.path.join(p, "Botteks_Sunumu_Web.url"), "w", encoding="utf-8") as f:
        f.write(url_sunum)
    with open(os.path.join(p, "Botteks_Canli_Uygulama.url"), "w", encoding="utf-8") as f:
        f.write(url_app)

print("Successfully created 1-click web launcher files!")
