#!/usr/bin/env python3
"""
네이버 모바일 블로그 HTML 에서 본문, 제목, 이미지 정보를 추출.
Usage: python3 extract_text.py <input.html>
표준 출력으로 다음 형식 출력:

TITLE: ...
URL: ...
---
[본문 텍스트, 단락별 줄바꿈]
[IMAGE: alt 텍스트] (이미지가 등장한 위치)
---
IMAGE_COUNT: N
"""

import sys
import re
from html.parser import HTMLParser
from html import unescape


class NaverBlogParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.in_container = 0
        self.container_depth_when_entered = None
        self.depth = 0
        self.parts = []
        self.current_block = []
        self.in_paragraph = False
        self.in_image = False
        self.image_alt = ""
        self.image_count = 0
        self.title = ""
        self.url = ""

    def handle_starttag(self, tag, attrs):
        attrs_d = dict(attrs)
        self.depth += 1

        if tag == "meta":
            prop = attrs_d.get("property", "")
            if prop == "og:title" and not self.title:
                self.title = attrs_d.get("content", "")
            elif prop == "og:url" and not self.url:
                self.url = attrs_d.get("content", "")

        cls = attrs_d.get("class", "")
        if "se-main-container" in cls and self.in_container == 0:
            self.in_container = 1
            self.container_depth_when_entered = self.depth
            return

        if self.in_container:
            # paragraph block
            if "se-text-paragraph" in cls:
                self.in_paragraph = True
                self.current_block = []
            # image block
            if tag == "img" and "se-image-resource" in cls:
                alt = attrs_d.get("alt", "").strip()
                self.image_count += 1
                self.flush_paragraph()
                self.parts.append(f"[IMAGE{f': {alt}' if alt else ''}]")

    def handle_endtag(self, tag):
        if self.in_container and self.in_paragraph and tag in ("p", "div"):
            # close paragraph when its enclosing element ends. Heuristic:
            # se-text-paragraph is usually a <p> tag.
            self.flush_paragraph()
        self.depth -= 1
        if self.in_container and self.depth < self.container_depth_when_entered:
            self.in_container = 0

    def handle_data(self, data):
        if self.in_container and self.in_paragraph:
            self.current_block.append(data)

    def flush_paragraph(self):
        if self.in_paragraph:
            text = "".join(self.current_block).strip()
            text = re.sub(r"\s+", " ", text)
            if text:
                self.parts.append(text)
            self.in_paragraph = False
            self.current_block = []


def main():
    if len(sys.argv) < 2:
        print("Usage: extract_text.py <input.html>", file=sys.stderr)
        sys.exit(1)
    with open(sys.argv[1], "r", encoding="utf-8", errors="ignore") as f:
        html = f.read()

    p = NaverBlogParser()
    p.feed(html)

    # se-text-paragraph spans aren't reliably closed by handle_endtag matching,
    # so do a fallback regex-based extraction for paragraphs if too few captured.
    if len([x for x in p.parts if not x.startswith("[IMAGE")]) < 3:
        text_paras = re.findall(
            r'<p[^>]*class="[^"]*se-text-paragraph[^"]*"[^>]*>(.*?)</p>',
            html,
            re.DOTALL,
        )
        clean = []
        for t in text_paras:
            t = re.sub(r"<[^>]+>", " ", t)
            t = unescape(t)
            t = re.sub(r"\s+", " ", t).strip()
            if t:
                clean.append(t)
        if clean:
            p.parts = clean
        # also recount images by regex
        imgs = re.findall(
            r'<img[^>]*class="[^"]*se-image-resource[^"]*"[^>]*alt="([^"]*)"',
            html,
        )
        p.image_count = len(imgs)

    print(f"TITLE: {p.title}")
    print(f"URL: {p.url}")
    print("---")
    print("\n\n".join(p.parts))
    print("---")
    print(f"IMAGE_COUNT: {p.image_count}")


if __name__ == "__main__":
    main()
