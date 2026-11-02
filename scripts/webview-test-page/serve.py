#!/usr/bin/env python3
# 시뮬레이터에서 WebView 동작을 재현하는 테스트 페이지를 Mac에서 띄우는 로컬 서버입니다.
# 정적 파일 외에 기본 http.server로 만들 수 없는 응답 네 개를 추가합니다.
#   GET  /attachment       Content-Disposition: attachment 다운로드
#   GET  /status/500       서버 오류 페이지
#   GET  /redirect?to=URL  302 redirect (외부 스킴 포함)
#   POST /echo             받은 method와 body를 그대로 보여 주는 페이지
# 같은 Mac에서만 접속하도록 127.0.0.1에만 bind합니다.

import argparse
import html
import os
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit

ROOT = os.path.dirname(os.path.abspath(__file__))


class TestPageHandler(SimpleHTTPRequestHandler):
    # 기본 매핑은 HTML·텍스트에 charset을 붙이지 않으므로 UTF-8을 명시합니다.
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".html": "text/html; charset=utf-8",
        ".txt": "text/plain; charset=utf-8",
    }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        # 페이지를 고친 뒤 앱에서 바로 새 버전을 보도록 캐시를 끕니다.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_GET(self):
        if not self.send_route(include_body=True):
            super().do_GET()

    def do_HEAD(self):
        if not self.send_route(include_body=False):
            super().do_HEAD()

    def do_POST(self):
        if urlsplit(self.path).path != "/echo":
            self.send_error(HTTPStatus.NOT_FOUND)
            return
        try:
            length = int(self.headers.get("Content-Length") or 0)
        except ValueError:
            length = -1
        if length < 0:
            self.send_error(HTTPStatus.BAD_REQUEST, "invalid Content-Length")
            return
        body = self.rfile.read(length).decode("utf-8", errors="replace")
        content_type = self.headers.get("Content-Type", "")
        self.send_html(
            HTTPStatus.OK,
            "POST echo",
            f"<p>method: <code>{html.escape(self.command)}</code></p>"
            f"<p>content-type: <code>{html.escape(content_type)}</code></p>"
            f"<p>body:</p><pre>{html.escape(body)}</pre>",
        )

    def send_route(self, include_body):
        url = urlsplit(self.path)
        if url.path == "/attachment":
            payload = b"Clipy WebView test attachment\n"
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Disposition", 'attachment; filename="clipy-attachment.txt"')
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            if include_body:
                self.wfile.write(payload)
            return True
        if url.path == "/status/500":
            self.send_html(
                HTTPStatus.INTERNAL_SERVER_ERROR,
                "500",
                "<p>The server answered 500. This page should show instead of the app error screen.</p>",
                include_body,
            )
            return True
        if url.path == "/redirect":
            target = parse_qs(url.query).get("to", [""])[0]
            if not target:
                self.send_error(HTTPStatus.BAD_REQUEST, "to parameter is required")
                return True
            self.send_response(HTTPStatus.FOUND)
            self.send_header("Location", target)
            self.send_header("Content-Length", "0")
            self.end_headers()
            return True
        return False

    def send_html(self, status, title, body_html, include_body=True):
        payload = (
            "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">"
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
            f"<title>{html.escape(title)}</title></head>"
            f"<body style=\"font-family: -apple-system, sans-serif; padding: 16px\">"
            f"<h1>{html.escape(title)}</h1>{body_html}"
            "<p><a href=\"/\">Back to the test page</a></p></body></html>"
        ).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        if include_body:
            self.wfile.write(payload)


def main():
    parser = argparse.ArgumentParser(description="Clipy WebView test page server")
    parser.add_argument("--port", type=int, default=8780)
    args = parser.parse_args()
    server = ThreadingHTTPServer(("127.0.0.1", args.port), TestPageHandler)
    print(f"Serving {ROOT} at http://127.0.0.1:{args.port}/")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
