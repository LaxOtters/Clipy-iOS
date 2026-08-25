//
//  SessionWebViewNewWindowNavigationTestSupport.swift
//  Clipy
//
//  Created by 박민서 on 8/25/26.
//

import Network
import UIKit
import WebKit

@testable import FeatureSession

enum NewWindowNavigationTestError: Error {
    case missingMainWebView
    case timedOut
}

final class SessionWebViewNewWindowHarness {
    let sessionWebView = SessionWebView(frame: CGRect(x: 0, y: 0, width: 390, height: 760))

    var mainWebView: WKWebView {
        get throws {
            guard let webView = sessionWebView.subviews.compactMap({ $0 as? WKWebView }).first else {
                throw NewWindowNavigationTestError.missingMainWebView
            }
            return webView
        }
    }

    private let window: UIWindow
    private var isTornDown = false

    init() {
        window = UIWindow(frame: sessionWebView.bounds)
        let viewController = UIViewController()
        viewController.view.addSubview(sessionWebView)
        window.rootViewController = viewController
        window.isHidden = false
    }

    deinit {
        tearDown()
    }

    func tearDown() {
        guard !isTornDown else { return }
        isTornDown = true
        sessionWebView.removeFromSuperview()
        window.rootViewController = nil
        window.isHidden = true
    }
}

struct LocalHTTPRequest: Equatable, Sendable {
    let method: String
    let path: String
    let body: Data
}

final class LocalHTTPServer: @unchecked Sendable {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "clipy.session-web-new-window-http-server")
    private let receiptLock = NSLock()
    private var storedReceipts: [LocalHTTPRequest] = []
    private(set) var port: UInt16 = 0

    var receipts: [LocalHTTPRequest] {
        receiptLock.withLock { storedReceipts }
    }

    init() throws {
        listener = try NWListener(using: .tcp, on: .any)

        let startup = LocalHTTPServerStartup()
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                startup.finish()
            case let .failed(error):
                startup.finish(error: error)
            default:
                break
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection)
        }
        listener.start(queue: queue)

        guard startup.wait(timeout: 5) else {
            throw LocalHTTPServerError.startTimedOut
        }
        if let startupError = startup.error {
            throw startupError
        }
        guard let listenerPort = listener.port else {
            throw LocalHTTPServerError.missingPort
        }
        port = listenerPort.rawValue
    }

    func url(path: String) -> URL {
        URL(string: "http://127.0.0.1:\(port)\(path)")!
    }

    func stop() {
        listener.cancel()
    }

    private func accept(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveRequest(on: connection, accumulatedData: Data())
    }

    private func receiveRequest(on connection: NWConnection, accumulatedData: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            guard let self else {
                connection.cancel()
                return
            }

            var requestData = accumulatedData
            if let data {
                requestData.append(data)
            }

            if let request = Self.parseRequest(from: requestData) {
                receiptLock.withLock {
                    self.storedReceipts.append(request)
                }
                sendResponse(for: request, on: connection)
                return
            }

            if isComplete || error != nil {
                connection.cancel()
                return
            }

            receiveRequest(on: connection, accumulatedData: requestData)
        }
    }

    private func sendResponse(for request: LocalHTTPRequest, on connection: NWConnection) {
        let body = Data(responseHTML(for: request).utf8)
        let header = Data((
            "HTTP/1.1 200 OK\r\n"
                + "Content-Type: text/html; charset=utf-8\r\n"
                + "Content-Length: \(body.count)\r\n"
                + "Connection: close\r\n"
                + "\r\n"
        ).utf8)
        connection.send(
            content: header + body,
            contentContext: .finalMessage,
            isComplete: true,
            completion: .contentProcessed { _ in
                connection.cancel()
            }
        )
    }

    private func responseHTML(for request: LocalHTTPRequest) -> String {
        switch request.path {
        case "/get-start":
            return """
            <html><body>
                <a id="get-link" href="\(url(path: "/get-destination"))" target="_blank">open</a>
            </body></html>
            """
        case "/post-start":
            return """
            <html><body>
                <form id="post-form" action="\(url(path: "/post-destination"))" method="post" target="_blank">
                    <input name="item" value="clipy">
                    <input name="count" value="1">
                </form>
            </body></html>
            """
        default:
            return "<html><body>destination</body></html>"
        }
    }

    private static func parseRequest(from data: Data) -> LocalHTTPRequest? {
        let separator = Data("\r\n\r\n".utf8)
        guard
            let headerRange = data.range(of: separator),
            let headerText = String(data: data[..<headerRange.lowerBound], encoding: .utf8)
        else {
            return nil
        }

        let lines = headerText.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            return nil
        }
        let requestParts = requestLine.split(separator: " ", maxSplits: 2).map(String.init)
        guard requestParts.count >= 2 else {
            return nil
        }

        let contentLength = lines.dropFirst().first { line in
            line.lowercased().hasPrefix("content-length:")
        }
        .flatMap { Int($0.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces)) }
        ?? 0

        let bodyStart = headerRange.upperBound
        guard data.count >= bodyStart + contentLength else {
            return nil
        }

        return LocalHTTPRequest(
            method: requestParts[0],
            path: requestParts[1],
            body: data.subdata(in: bodyStart..<(bodyStart + contentLength))
        )
    }
}

final class LocalHTTPServerStartup: @unchecked Sendable {
    private let semaphore = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var storedError: Error?
    private var isFinished = false

    var error: Error? {
        lock.withLock { storedError }
    }

    func finish(error: Error? = nil) {
        let shouldSignal = lock.withLock {
            guard !isFinished else {
                return false
            }

            isFinished = true
            storedError = error
            return true
        }
        if shouldSignal {
            semaphore.signal()
        }
    }

    func wait(timeout: TimeInterval) -> Bool {
        semaphore.wait(timeout: .now() + timeout) == .success
    }
}

enum LocalHTTPServerError: Error {
    case startTimedOut
    case missingPort
}
