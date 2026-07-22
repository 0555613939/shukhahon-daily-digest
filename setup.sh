#!/bin/bash
# שמור כ-setup.sh ותריץ: chmod +x setup.sh && ./setup.sh

# צור את התיקיות
mkdir -p shukhahon-daily-digest/{scripts,venv}
cd shukhahon-daily-digest

# סביבת ה-Environment – הדבק כאן את 4 הערכים מה-Keys and tokens
cat > .env << EOF
GITHUB_TOKEN=הדבק כאן_GITHUB_TOKEN_שלך
TWITTER_BEARER_TOKEN=הדבק כאן_TWITTER_BEARER_TOKEN_שלך
TWITTER_CLIENT_ID=הדבק כאן_TWITTER_CLIENT_ID_שלך
TWITTER_CLIENT_SECRET=הדבק כאן_TWITTER_CLIENT_SECRET_שלך
EOF

# Git ignore
cat > .gitignore << EOF
__pycache__/
.env
venv/
*.log
EOF

# requirements
cat > requirements.txt << EOF
python-dotenv
requests
EOF

# תוכנית Python ראשית (הכלי המלא)
cat > scripts/main.py << 'PYEOF'
import requests
import os
import json
from dotenv import load_dotenv
from datetime import datetime, timedelta

load_dotenv()

# 16 הערוצים שאתה עוקב אחריהם
ACCOUNTS = ["eWhispers", "RyanDetrick", "charliebilello", "KobeissiLetter", "MikeZaccardi", "LizAnnSonders", "KevRGordon", "NickTimiraos", "EricBalchunas", "DanielTNiles", "jimcramer", "StockMKTNewz", "AIStockSavvy", "DeItaone", "LiveSquawk", "wallstengine"]
BEARER = os.getenv('TWITTER_BEARER_TOKEN')
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
REPO = "ShukHahonDailyDailyDigest/shukhahon-daily-digest/YdydyhZwmr3130"שנה לשם שלך
FILE_NAME = "summary.md"

def fetch_posts():
    url = "https://api.x.com/2/tweets/search/recent"
    headers = {"Authorization": f"Bearer {BEARER}"}
    since = (datetime.now() - timedelta(days=2)).strftime("%Y-%m-%d")
    query = " OR ".join([f"from:{acc}" for acc in ACCOUNTS])
    params = {"query": query, "tweet.fields": "created_at,text", "max_results": 100, "since": since}
    
    response = requests.get(url, headers=headers, params=params)
    if response.status_code == 200:
        return response.json().get('data', [])
    return []

def summarize(posts):
    summary = f"# שוק ההון – סיכום יומי {datetime.now().strftime('%d.%m.%Y')}\n\n"
    for post in posts[:30]:  # 30 הפוסטים הכי רלוונטיים
        summary += f"**@{post.get('author', 'Unknown')}**\n"
        summary += f"{post.get('text', '')[:350]}...\n\n"
    return summary

posts = fetch_posts()
summary_text = summarize(posts)

# שמור לקובץ
with open(FILE_NAME, 'w', encoding='utf-8') as f:
    f.write(summary_text)

# פוסט אוטומטי ל-X
post_url = "https://api.x.com/2/tweets"
post_headers = {"Authorization": f"Bearer {BEARER}", "Content-Type": "application/json"}
post_data = {"text": f"סיכום יומי מלא של @ShukHahonDaily – כל 16 הערוצים! 👉 {summary_text[:200]}... {REPO}/blob/main/{FILE_NAME}"}
requests.post(post_url, headers=post_headers, json=post_data)

print("✅ סיכום מוכן + פוסט אוטומטי!")
PYEOF

# GitHub Actions (אוטומטי יומי)
cat > .github/workflows/daily-digest.yml << 'WORKEOF'
name: Daily ShukHahon Digest
on:
  schedule:
    - cron: '0 8 * * 1-5'  # 8:00 בבוקר ישראל
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Install deps
        run: pip install -r requirements.txt
      - name: Run script
        run: python scripts/main.py
      - name: Commit & push
        run: |
          git config user.name github-actions
          git config user.email github-actions@github.com
          git add .
          git commit -m "Daily digest $(date +%Y-%m-%d)" || echo "No changes"
          git push
WORKEOF

echo "✅ הכלי מלא! עכשיו:"
echo "1. הוסף את 4 הטוקנים ל-env"
echo "2. שמור את הקובץ"
echo "3. תחזור ל-GitHub ותלחץ Commit & push"
echo "4. הוסף את 4 הטוקנים ל-GitHub Secrets"
echo "5. תלחץ Run workflow"
echo "הכלי ירוץ אוטומטית כל יום 8:00 בבוקר ישראל!"
