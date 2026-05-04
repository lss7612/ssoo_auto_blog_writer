# 블로그 자동 작성 하네스

내 네이버 블로그 ("쑤기로운 일상생활") 의 맛집 글들을 학습해서, 새 맛집 방문 후 사진과 정보만 던지면 같은 톤의 네이버 블로그용 HTML을 생성하는 Claude Code 도구.

## 폴더 구조

```
.claude/commands/    # /write-restaurant 슬래시 커맨드
scripts/             # 수집·추출 스크립트
samples/             # 수집된 원본 글 (학습용 원자료, 1회만)
rules/               # 학습 결과 (글 구조·말투·HTML 템플릿)
photos/              # 슬래시 커맨드 호출 시 사진 임시 저장
output/              # 생성된 HTML
```

## 1회성 셋업 (학습)

내 블로그 글들을 가져와서 글 구조·말투를 학습하는 단계. 한 번만 하면 됨.

```bash
# 1. 맛집 카테고리 글 30개 수집 (~1분 소요)
bash scripts/fetch_posts.sh 6519636 "먹깨비 냠냠:)" 30

# 2. Claude에게 학습 요청
#    → Claude Code에서 "samples/ 분석해서 rules/ 만들어줘" 라고 말하면
#      Claude가 rules/structure.md, tone.md, html_template.md, examples.md 4개 파일 생성
```

> **차단 시 fallback**: curl이 막히면 사용자가 직접 글을 열어 페이지 소스를 복사해 `samples/{logNo}.html` 로 저장하면 됨. 이후 Claude에게 분석 요청하면 동일하게 동작.

## 매번 사용 (글쓰기)

```
1. Claude Code에서 /write-restaurant 입력
2. 사진을 채팅에 끌어다 놓기 (5~15장 권장)
3. Claude의 질문에 답 (가게 이름, 주소, 메뉴, 총평 등)
4. output/{날짜}_{가게명}.html 생성됨
5. 네이버 블로그 에디터를 'HTML 모드'로 열고 파일 내용 붙여넣기
6. 사진 자리(<!-- PHOTO: ... -->)에 사진 업로드
```

## 룰 재학습

말투를 바꾸고 싶거나 최근 글 스타일을 반영하고 싶을 때:

```bash
bash scripts/fetch_posts.sh 6519636 "먹깨비 냠냠:)" 30
# 그 후 Claude에게 "rules 다시 만들어줘"
```
