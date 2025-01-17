// import Models
import SwiftUI
// import Utils
import WebKit

final class WebAppViewCoordinator: NSObject {
  var webViewActionHandler: (WKScriptMessage) -> Void = { _ in }
  var linkHandler: (URL) -> Void = { _ in }
  var needsReload = true
  var lastSavedAnnotationID: UUID?

  override init() {
    super.init()
  }
}

extension WebAppViewCoordinator: WKScriptMessageHandler {
  func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
    webViewActionHandler(message)
  }
}

extension WebAppViewCoordinator: WKNavigationDelegate {
  // swiftlint:disable:next line_length
  func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if navigationAction.navigationType == .linkActivated {
      if let linkURL = navigationAction.request.url {
        linkHandler(linkURL)
      }
      decisionHandler(.cancel)
    } else {
      decisionHandler(.allow)
    }
  }
}

struct WebViewConfig {
  let url: URL
  let themeId: String
  let margin: Int
  let fontSize: Int
  let fontFamily: String
  let rawAuthCookie: String?
}

extension WKWebView {
  func configureForOmnivoreAppEmbed(config: WebViewConfig) {
    // Set cookies to pass article preferences to web view
    injectCookie(cookieString: "theme=\(config.themeId); Max-Age=31536000;", url: config.url)
    injectCookie(cookieString: "margin=\(config.margin); Max-Age=31536000;", url: config.url)
    injectCookie(cookieString: "fontSize=\(config.fontSize); Max-Age=31536000;", url: config.url)
    injectCookie(cookieString: "fontFamily=\(config.fontFamily); Max-Age=31536000;", url: config.url)

    let authToken = extractAuthToken(rawAuthCookie: config.rawAuthCookie, url: config.url)

    if let authToken = authToken {
      injectCookie(cookieString: "authToken=\(authToken); Max-Age=31536000;", url: config.url)
    } else {
      injectCookie(cookieString: config.rawAuthCookie, url: config.url)
    }
  }

  private func injectCookie(cookieString: String?, url: URL) {
    if let cookieString = cookieString {
      for cookie in HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": cookieString], for: url) {
        configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {}
      }
    }
  }
}

// Temp utility until we swap out the web build used in prod.
// Once we do that we can just pass in the authToken directly
// and remove the rawAuthCookie param.
// This util just makes it easier to feature flag the web build used
private func extractAuthToken(rawAuthCookie: String?, url: URL) -> String? {
  guard let rawAuthCookie = rawAuthCookie else { return nil }
  let cookies = HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": rawAuthCookie], for: url)
  return cookies.first?.value
}
