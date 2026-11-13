//
//  ContentView.swift
//  apps
//
//  Created by USER on 2023/01/23.
//

import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        UIWebView(url: URL(string: "https://apps.hyunsub.kim")!)
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct UIWebView: UIViewRepresentable {
    let url: URL
    let webview = WebView()

    func makeUIView(context: Context) -> WKWebView {
        let request = URLRequest(url: self.url, cachePolicy: .returnCacheDataElseLoad)
        webview.load(request)
        return webview
    }

    func updateUIView(_ webview: WKWebView, context: Context) {
        let request = URLRequest(url: self.url, cachePolicy: .returnCacheDataElseLoad)
        webview.load(request)
    }
}

class WebView: WKWebView, WKNavigationDelegate {
    private let pullToRefreshControl = UIRefreshControl()

    init() {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(DeviceKeyMessageHandler(), name: DeviceKeyMessageHandler.name)
        let pullToRefreshHandler = PullToRefreshMessageHandler()
        configuration.userContentController.add(pullToRefreshHandler, name: PullToRefreshMessageHandler.name)
        super.init(frame: CGRect.zero, configuration: configuration)
        pullToRefreshHandler.webView = self
        super.navigationDelegate = self

        pullToRefreshControl.addTarget(self, action: #selector(reloadWebView(_:)), for: .valueChanged)
        setPullToRefresh(true)

        super.allowsBackForwardNavigationGestures = true
        
        super.evaluateJavaScript("navigator.userAgent") { [weak self] (result, error) in
            if let webView = self, let userAgent = result as? String {
                webView.customUserAgent = userAgent + " Hyunsub/1.0.0"
            }
        }

        if #available(iOS 16.4, *) {
            super.isInspectable = true
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc func reloadWebView(_ sender: UIRefreshControl) {
        super.reload()
        sender.endRefreshing()
    }

    /// 당겨서 새로고침을 켜고 끈다. 끌 때는 당기는 동작 자체(바운스)도 막아 화면이 끌려 내려오지 않게 한다.
    func setPullToRefresh(_ enabled: Bool) {
        super.scrollView.refreshControl = enabled ? pullToRefreshControl : nil
        super.scrollView.bounces = enabled
    }

    /// 새 문서가 열리면 기본값(켜짐)으로 되돌린다. 끈 화면을 벗어난 뒤에도 꺼진 채 남지 않게 한다.
    /// 끄고 싶은 화면은 문서가 열린 뒤 웹이 다시 `false`를 보낸다.
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        setPullToRefresh(true)
    }
}

/// 웹이 `webkit.messageHandlers.hyunsubPullToRefresh.postMessage(bool)`로 당겨서 새로고침을 켜고 끈다.
/// 전체 화면에 고정된 페이지(chat 등)는 끌어내리면 화면이 어색하게 밀려 내려와서 끈다.
/// hyunsub.kim 서비스의 메인 프레임에서 온 메시지만 받는다.
class PullToRefreshMessageHandler: NSObject, WKScriptMessageHandler {
    static let name = "hyunsubPullToRefresh"
    private static let allowedDomain = "hyunsub.kim"

    /// WKUserContentController가 핸들러를 강하게 잡으므로 순환 참조가 생기지 않게 약하게 둔다.
    weak var webView: WebView?

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let origin = message.frameInfo.securityOrigin
        let host = origin.host
        guard message.frameInfo.isMainFrame, origin.protocol == "https",
              host == Self.allowedDomain || host.hasSuffix("." + Self.allowedDomain) else {
            Logger.log("Pull-to-refresh message ignored: origin=\(origin.protocol)://\(host)")
            return
        }
        guard let enabled = message.body as? Bool else {
            Logger.log("Pull-to-refresh message ignored: body is not a bool")
            return
        }

        webView?.setPullToRefresh(enabled)
    }
}

/// timeline 웹이 발급받은 위치 업로드 기기 키를 `webkit.messageHandlers.hyunsubDeviceKey.postMessage(key)`로 넘기면 Keychain에 저장한다.
/// 다른 사이트·iframe이 키를 덮어쓰지 못하도록 timeline 메인 프레임에서 온 메시지만 받는다.
class DeviceKeyMessageHandler: NSObject, WKScriptMessageHandler {
    static let name = "hyunsubDeviceKey"
    private static let allowedHost = "timeline.hyunsub.kim"

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let origin = message.frameInfo.securityOrigin
        guard message.frameInfo.isMainFrame, origin.protocol == "https", origin.host == Self.allowedHost else {
            Logger.log("Device key message ignored: origin=\(origin.protocol)://\(origin.host)")
            return
        }
        guard let key = message.body as? String else {
            Logger.log("Device key message ignored: body is not a string")
            return
        }

        let saved = DeviceKeyStore.shared.save(key)
        Logger.log("Device key \(saved ? "saved" : "save failed")")
    }
}
