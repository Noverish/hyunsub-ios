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

class WebView: WKWebView {
    init() {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(DeviceKeyMessageHandler(), name: DeviceKeyMessageHandler.name)
        super.init(frame: CGRect.zero, configuration: configuration)
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadWebView(_:)), for: .valueChanged)
        super.scrollView.addSubview(refreshControl)

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
