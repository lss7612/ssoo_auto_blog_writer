# 네이버 블로그 HTML 템플릿

`/write-restaurant` 가 생성할 HTML 형식. 네이버 블로그 에디터의 'HTML 모드' 또는 'Ctrl+H' (소스 보기) 에 붙여넣을 수 있는 단순한 HTML.

## 설계 원칙

- **단순한 표준 HTML만 사용** — 네이버 SE class 흉내 X (붙여넣으면 에디터가 자동 변환)
- **인라인 스타일 위주** — `<style>` 태그나 외부 클래스 X
- **사진은 placeholder 주석으로** — 실제 업로드는 사용자가 에디터에서 수동
- **단락 사이 빈 줄** — 네이버 글 특유의 "여백" 느낌을 `<p>&nbsp;</p>` 로 구현
- **가운데 정렬** — 모바일 가독성 위해 `text-align: center` 기본

## 전체 골격

```html
<!-- 표지 사진 -->
<!-- PHOTO: 외관 또는 메인 음식 1장 -->

<!-- 큰 제목 -->
<p style="text-align:center;"><span style="font-size:18px;"><b>{지역} {음식종류} {가게명} | {핵심키워드}</b></span></p>

<p>&nbsp;</p>

<!-- 인트로 -->
<p style="text-align:center;">{소개 동기 1문장}</p>
<p style="text-align:center;">{가게명 + "다녀왔어요"}</p>

<!-- 마커: 협찬 여부에 따라 둘 중 하나만 -->
<!-- (A) 내돈내산일 때 -->
<p style="text-align:center;">#내돈내산</p>
<!-- (B) 협찬·체험단·제공일 때 — #내돈내산 절대 X -->
<p style="text-align:center;"><span style="color:#888;">{sponsor_disclosure 문구}</span></p>

<p>&nbsp;</p>

<!-- 가게 기본정보 박스 -->
<p style="text-align:center;"><b>{가게명}</b></p>
<p style="text-align:center;">{주소}</p>
<p style="text-align:center;">영업시간 {영업시간}</p>
<p style="text-align:center;">라스트 오더 {라스트오더시간}</p>
<p style="text-align:center;">{휴무}</p>
<p style="text-align:center;">{결제수단·주차·포장 등 한 줄로}</p>

<p>&nbsp;</p>

<!-- 위치 -->
<p style="text-align:center;"><b>위치</b></p>
<p style="text-align:center;">{지역} {음식종류} {가게명} | {핵심키워드}</p>
<!-- PHOTO: 가게 외관 또는 간판 -->
<p style="text-align:center;">{지하철역} {출구번호}번 출구</p>
<p style="text-align:center;">도보 {N}분 거리</p>
<p style="text-align:center;">{한 줄 코멘트}</p>

<p>&nbsp;</p>

<!-- 주차 -->
<p style="text-align:center;"><b>🚗 주차</b></p>
<p style="text-align:center;">{주차 가능 여부 + 위치}</p>
<p style="text-align:center;">{주차 요금 (있으면)}</p>
<p style="text-align:center;">{발렛 정보 (있으면)}</p>

<p>&nbsp;</p>

<!-- 매장 분위기 -->
<p style="text-align:center;"><b>매장 분위기</b></p>
<p style="text-align:center;">{지역} {가게명} | {핵심키워드}</p>
<!-- PHOTO: 매장 인테리어 1 -->
<p style="text-align:center;">{매장 크기 / 테이블 배치}</p>
<!-- PHOTO: 매장 인테리어 2 -->
<p style="text-align:center;">{분위기 형용사 + 누가 오기 좋은지}</p>

<p>&nbsp;</p>

<!-- 메뉴 -->
<p style="text-align:center;"><b>메뉴</b></p>
<!-- PHOTO: 메뉴판 -->
<p style="text-align:center;">{가격대 / 세트 구성 설명}</p>

<p>&nbsp;</p>

<!-- 음식 후기 (메뉴마다 한 블록 반복) -->
<p style="text-align:center;"><b>{메뉴 이름}</b></p>
<!-- PHOTO: {메뉴 이름} 클로즈업 -->
<p style="text-align:center;">{구성: 들어간 재료 나열}</p>
<!-- PHOTO: {메뉴 이름} 단면 또는 들어올리기 샷 -->
<p style="text-align:center;">{맛 표현 + 한 줄 평가}</p>

<p>&nbsp;</p>

<!-- 마무리 -->
<p style="text-align:center;">{지역} {음식종류} 맛집 찾는다면</p>
<p style="text-align:center;"><b>"{가게명}"</b> 방문해보세요</p>

<p>&nbsp;</p>

<!-- 해시태그 -->
<p style="text-align:center;">#{지역}맛집 #{가게명} #{지하철역}맛집 #{음식종류} #{데이트키워드} ...</p>
```

## 주의

- `&nbsp;` 가 포함된 빈 단락이 네이버 에디터에서 줄바꿈으로 잘 동작
- `<b>` 보다 `<strong>` 도 OK (네이버가 자동 변환)
- 이모지는 유니코드 그대로 (`🚗`, `📍`, `💳`)
- `<!-- PHOTO: ... -->` 주석은 에디터에 붙여넣어도 보이지 않음. 사용자가 그 위치를 찾아 사진 업로드 위젯으로 사진을 넣으면 됨. (생성된 HTML 파일을 사용자가 미리 브라우저로 열어 어디에 사진 들어갈지 확인하는 용도)

## 짧은 변형

음식 종류가 1개거나 단순한 글이면 메뉴별 섹션을 합칠 수도 있음. 다만 기본은 위 골격 따르기.
