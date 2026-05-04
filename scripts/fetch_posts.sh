#!/usr/bin/env bash
# 네이버 블로그 RSS 에서 카테고리 필터링 후 모바일 페이지 본문을 수집.
# Usage: bash scripts/fetch_posts.sh <blogId> <categoryName> [maxCount]
# 예:    bash scripts/fetch_posts.sh 6519636 "먹깨비 냠냠:)" 30
#
# 출력:
#   samples/{logNo}.html  (raw 모바일 페이지)
#   samples/{logNo}.txt   (추출된 본문)
#   samples/_index.json   (전체 인덱스)

set -euo pipefail

BLOG_ID="${1:?blogId required}"
CATEGORY="${2:?categoryName required}"
MAX_COUNT="${3:-30}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SAMPLES_DIR="$ROOT_DIR/samples"
EXTRACT_PY="$ROOT_DIR/scripts/extract_text.py"

mkdir -p "$SAMPLES_DIR"

UA="Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
RSS_URL="https://rss.blog.naver.com/${BLOG_ID}.xml"
RSS_FILE="$SAMPLES_DIR/.rss.xml"

echo "▶ RSS 수집: $RSS_URL"
HTTP_CODE=$(curl -sS -A "$UA" -o "$RSS_FILE" -w "%{http_code}" "$RSS_URL" || echo "000")
if [[ "$HTTP_CODE" != "200" ]]; then
  echo "✗ RSS 가져오기 실패 (HTTP $HTTP_CODE)" >&2
  exit 1
fi
echo "  ✓ RSS 받음 ($(wc -c < "$RSS_FILE" | tr -d ' ') bytes)"

# RSS 파싱하여 (logNo, title, category) 목록 만들기 → category 일치만 필터
ITEMS_FILE="$SAMPLES_DIR/.items.tsv"
python3 - "$RSS_FILE" "$CATEGORY" > "$ITEMS_FILE" <<'PYEOF'
import sys, re, html
from xml.etree import ElementTree as ET

rss_path, target_category = sys.argv[1], sys.argv[2]
def norm(s):
    # 네이버 RSS 카테고리는 NBSP(\xa0)를 포함하는 경우가 있음 → 일반 공백으로 정규화
    return (s or "").replace("\xa0", " ").strip()

tree = ET.parse(rss_path)
root = tree.getroot()
channel = root.find("channel")
if channel is None:
    sys.exit("channel not found")

target_norm = norm(target_category)
for item in channel.findall("item"):
    title = norm(item.findtext("title"))
    link = (item.findtext("link") or "").strip()
    cat = norm(item.findtext("category"))
    pub = (item.findtext("pubDate") or "").strip()
    if cat != target_norm:
        continue
    m = re.search(r"/(\d+)\?", link)
    if not m:
        continue
    log_no = m.group(1)
    # tab-separated; titles might contain tabs, replace
    safe_title = title.replace("\t", " ")
    print(f"{log_no}\t{safe_title}\t{cat}\t{pub}")
PYEOF

TOTAL_FOUND=$(wc -l < "$ITEMS_FILE" | tr -d ' ')
echo "  ✓ 카테고리 \"$CATEGORY\" 일치: $TOTAL_FOUND 개"

if [[ "$TOTAL_FOUND" == "0" ]]; then
  echo "✗ 일치하는 글 없음. 카테고리명을 확인하세요." >&2
  exit 1
fi

# 본문 수집
INDEX_FILE="$SAMPLES_DIR/_index.json"
echo "[" > "$INDEX_FILE"

COUNT=0
FIRST=1
while IFS=$'\t' read -r LOG_NO TITLE CATEGORY_FROM PUB_DATE; do
  if [[ "$COUNT" -ge "$MAX_COUNT" ]]; then break; fi
  COUNT=$((COUNT + 1))

  HTML_FILE="$SAMPLES_DIR/${LOG_NO}.html"
  TXT_FILE="$SAMPLES_DIR/${LOG_NO}.txt"

  if [[ -f "$TXT_FILE" ]]; then
    echo "[$COUNT/$MAX_COUNT] $LOG_NO  (이미 있음, 스킵)"
  else
    URL="https://m.blog.naver.com/${BLOG_ID}/${LOG_NO}"
    echo "[$COUNT/$MAX_COUNT] $LOG_NO  fetch $URL"
    HTTP_CODE=$(curl -sS -A "$UA" -o "$HTML_FILE" -w "%{http_code}" "$URL" || echo "000")
    if [[ "$HTTP_CODE" != "200" ]]; then
      echo "  ✗ HTTP $HTTP_CODE — 스킵" >&2
      rm -f "$HTML_FILE"
      continue
    fi
    python3 "$EXTRACT_PY" "$HTML_FILE" > "$TXT_FILE"
    sleep 1
  fi

  # JSON 인덱스 추가 (제목/날짜는 jq 없이 파이썬으로 안전 인용)
  ENTRY=$(python3 -c "
import json, sys
d = {
  'logNo': '$LOG_NO',
  'title': sys.argv[1],
  'category': sys.argv[2],
  'pubDate': sys.argv[3],
  'url': 'https://blog.naver.com/${BLOG_ID}/$LOG_NO',
  'mobileUrl': 'https://m.blog.naver.com/${BLOG_ID}/$LOG_NO',
  'htmlFile': 'samples/${LOG_NO}.html',
  'txtFile': 'samples/${LOG_NO}.txt',
}
print(json.dumps(d, ensure_ascii=False, indent=2))
" "$TITLE" "$CATEGORY_FROM" "$PUB_DATE")

  if [[ "$FIRST" == "1" ]]; then FIRST=0; else echo "," >> "$INDEX_FILE"; fi
  echo -n "$ENTRY" >> "$INDEX_FILE"
done < "$ITEMS_FILE"

echo "" >> "$INDEX_FILE"
echo "]" >> "$INDEX_FILE"

# 정리
rm -f "$RSS_FILE" "$ITEMS_FILE"

echo ""
echo "✓ 완료: samples/_index.json 에 $COUNT 개 항목 기록"
echo "  본문 파일: $(ls "$SAMPLES_DIR"/*.txt 2>/dev/null | wc -l | tr -d ' ') 개"
