import Foundation
import SwiftSoup

enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case parsingFailed(String)
    case loginFailed(String)

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .requestFailed(let error):
            return "请求失败: \(error.localizedDescription)"
        case .invalidResponse:
            return "服务器响应无效"
        case .parsingFailed(let detail):
            return "解析失败: \(detail)"
        case .loginFailed(let detail):
            return "登录失败: \(detail)"
        }
    }
}

class NetworkManager {
    static let shared = NetworkManager()

    let session: URLSession
    private let baseURL = URL(string: "https://www.4d4y.com/forum/")!

    // Chinese encodings for Discuz forums
    private let gb18030: String.Encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(0x80000631)))
    private let gb2312: String.Encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(0x80000630)))

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = false
        // Use shared cookie storage to sync cookies with WKWebView
        config.httpCookieStorage = HTTPCookieStorage.shared
        session = URLSession(configuration: config)
    }

    // Helper to decode HTML data with proper encoding
    private func decodeHTMLData(_ data: Data) throws -> String {
        let encodings: [String.Encoding] = [.utf8, gb18030, gb2312, .windowsCP1252]

        for encoding in encodings {
            if let html = String(data: data, encoding: encoding) {
                return html
            }
        }

        throw NetworkError.parsingFailed("Failed to decode HTML with any encoding")
    }

    // MARK: - Login

    func fetchLoginPage() async throws -> LoginFormData {
        let url = baseURL.appendingPathComponent("logging.php?action=login")

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("https://www.4d4y.com/forum/", forHTTPHeaderField: "Referer")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        let html = try decodeHTMLData(data)
        print("[LoginPage] HTML length: \(html.count)")
        print("[LoginPage] HTML sample (first 300 chars): \(String(html.prefix(300)))")

        return try ForumHTMLParser.parseLoginPage(html)
    }

    func login(username: String, password: String, questionId: Int, answer: String) async throws -> Bool {
        let formData = try await fetchLoginPage()

        print("[Login] formhash: \(formData.formhash)")
        print("[Login] username: \(username)")
        print("[Login] password: \(password.md5)")

        // Build the login URL with required parameters matching the actual forum login
        var urlComponents = URLComponents(string: "https://www.4d4y.com/forum/logging.php")!
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "login"),
            URLQueryItem(name: "loginsubmit", value: "yes"),
            URLQueryItem(name: "inajax", value: "1")
        ]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("https://www.4d4y.com/forum/logging.php?action=login", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("https://www.4d4y.com", forHTTPHeaderField: "Origin")

        // Build POST body matching curl format
        let bodyItems: [String: String] = [
            "formhash": formData.formhash,
            "referer": "https%3A%2F%2Fwww.4d4y.com%2Fforum%2F",
            "loginfield": "username",
            "username": username,
            "password": password.md5,
            "questionid": String(questionId),
            "answer": answer,
            "cookietime": "2592000"
        ]

        let bodyString = bodyItems.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        print("[Login] body: \(bodyString)")
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("[Login] Invalid HTTP response")
            throw NetworkError.invalidResponse
        }

        print("[Login] Response URL: \(httpResponse.url?.absoluteString ?? "nil")")
        print("[Login] Status code: \(httpResponse.statusCode)")

        // Print response headers for cookies
        if let cookies = httpResponse.allHeaderFields["Set-Cookie"] as? String {
            print("[Login] Set-Cookie: \(cookies)")
        }

        // Print response body for debugging
        if let responseBody = String(data: data, encoding: .utf8) {
            print("[Login] Response body (first 500 chars): \(String(responseBody.prefix(500)))")
        }

        // Check for login failure by examining response
        if httpResponse.url?.path.contains("logging.php") == true {
            // Try to parse error message from response
            if let html = String(data: data, encoding: .utf8) {
                print("[Login] Response contains logging.php - login likely failed")
                if html.contains("密码错误") || html.contains("password") || html.contains("密码") {
                    print("[Login] Password error detected")
                    throw NetworkError.loginFailed("密码错误")
                } else if html.contains("用户不存在") || html.contains("user") {
                    print("[Login] User not found detected")
                    throw NetworkError.loginFailed("用户不存在")
                }
            }
            throw NetworkError.loginFailed("登录失败")
        }

        // Check if we got a redirect to main page (successful login)
        if httpResponse.statusCode == 302 || httpResponse.statusCode == 301 {
            print("[Login] Got redirect - login might be successful")
            // Check cookies
            if let cookies = HTTPCookieStorage.shared.cookies {
                print("[Login] Cookies after login: \(cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; "))")
            }
        }

        return httpResponse.statusCode == 200 || httpResponse.statusCode == 302
    }

    // MARK: - Forum List

    func fetchForumList(useCache: Bool = true) async throws -> [Forum] {
        let cacheKey = CacheManager.CacheKeys.forumList()

        // Try cache first
        if useCache, let cachedForums: [Forum] = CacheManager.shared.load([Forum].self, forKey: cacheKey) {
            print("[ForumList] Using cache, age: \(CacheManager.shared.getCacheAge(forKey: cacheKey) ?? "unknown")")
            // Refresh in background
            Task {
                if let freshForums = try? await self.fetchForumListWithoutCache() {
                    CacheManager.shared.save(freshForums, forKey: cacheKey)
                }
            }
            return cachedForums
        }

        // Fetch from network
        let forums = try await fetchForumListWithoutCache()
        CacheManager.shared.save(forums, forKey: cacheKey)
        return forums
    }

    func fetchForumListWithoutCache() async throws -> [Forum] {
        let urlString = "https://www.4d4y.com/forum/index.php"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        // Debug: Print cookies before request
        if let cookies = HTTPCookieStorage.shared.cookies {
            let cookieStr = cookies.map { "\($0.name)=\($0.value.prefix(10))..." }.joined(separator: "; ")
            print("[Network] ForumList cookies BEFORE request: \(cookieStr)")
        } else {
            print("[Network] ForumList: No cookies in HTTPCookieStorage.shared")
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("https://www.4d4y.com/forum/", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)

        // Debug: Print raw response
        if let httpResponse = response as? HTTPURLResponse {
            print("[Network] ForumList HTTP status: \(httpResponse.statusCode)")
            print("[Network] ForumList response headers: \(httpResponse.allHeaderFields)")
        }

        // Try multiple encodings
        let encodings: [String.Encoding] = [.utf8, gb18030, gb2312, .windowsCP1252]
        var decoded成功 = false
        for encoding in encodings {
            if let html = String(data: data, encoding: encoding) {
                print("[Network] ForumList response (\(encoding), first 2000 chars): \(String(html.prefix(2000)))")
                decoded成功 = true
                break
            }
        }
        if !decoded成功 {
            // Print raw bytes as hex for debugging
            let bytes = [UInt8](data.prefix(100))
            let hexStr = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
            print("[Network] ForumList response: (could not decode, first 100 bytes hex): \(hexStr)")
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        return try ForumHTMLParser.parseForumList(data)
    }

    // MARK: - Thread List

    func fetchThreadList(fid: Int, page: Int = 1, filter: String? = nil, orderby: String? = nil) async throws -> [ForumThread] {
        var urlString = "https://www.4d4y.com/forum/forumdisplay.php?fid=\(fid)&page=\(page)"

        if let filter = filter, !filter.isEmpty {
            urlString += "&filter=\(filter)"
        }
        if let orderby = orderby, !orderby.isEmpty {
            urlString += "&orderby=\(orderby)"
        }

        print("[Network] fetchThreadList URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        // Debug: Print cookies before request
        if let cookies = HTTPCookieStorage.shared.cookies {
            let cookieStr = cookies.map { "\($0.name)=\($0.value.prefix(10))..." }.joined(separator: "; ")
            print("[Network] Cookies BEFORE request: \(cookieStr)")
        } else {
            print("[Network] No cookies in HTTPCookieStorage.shared")
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("https://www.4d4y.com/forum/", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }

            // Debug: Print raw response for fid=2 (hot threads)
            if fid == 2 {
                if let httpResponse = response as? HTTPURLResponse {
                    print("[Network] ThreadList fid=\(fid) HTTP status: \(httpResponse.statusCode)")
                }

                let encodings: [String.Encoding] = [.utf8, gb18030, gb2312, .windowsCP1252]
                var decoded成功 = false
                for encoding in encodings {
                    if let html = String(data: data, encoding: encoding) {
                        print("[Network] ThreadList fid=\(fid) response (\(encoding), first 3000 chars): \(String(html.prefix(3000)))")
                        decoded成功 = true
                        break
                    }
                }
                if !decoded成功 {
                    let bytes = [UInt8](data.prefix(100))
                    let hexStr = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                    print("[Network] ThreadList fid=\(fid) response: (could not decode, first 100 bytes hex): \(hexStr)")
                }
            }

            // Parser handles encoding internally
            return try ForumHTMLParser.parseThreadList(data)
        } catch {
            throw error
        }
    }

    // MARK: - Thread Detail

    func fetchThreadDetail(tid: Int, page: Int = 1, useCache: Bool = true) async throws -> ThreadDetail {
        let cacheKey = CacheManager.CacheKeys.threadDetail(tid: tid, page: page)

        // Try cache first for page 1 (main content)
        if useCache, page == 1, let cachedDetail: ThreadDetail = CacheManager.shared.load(ThreadDetail.self, forKey: cacheKey) {
            print("[ThreadDetail] Using cache for tid=\(tid), age: \(CacheManager.shared.getCacheAge(forKey: cacheKey) ?? "unknown")")
            // Refresh in background
            Task {
                if let freshDetail = try? await self.fetchThreadDetailWithoutCache(tid: tid, page: page) {
                    CacheManager.shared.save(freshDetail, forKey: cacheKey)
                }
            }
            return cachedDetail
        }

        let detail = try await fetchThreadDetailWithoutCache(tid: tid, page: page)
        CacheManager.shared.save(detail, forKey: cacheKey)
        return detail
    }

    private func fetchThreadDetailWithoutCache(tid: Int, page: Int = 1) async throws -> ThreadDetail {
        let pageString = page > 1 ? "&page=\(page)" : ""
        let urlString = "https://www.4d4y.com/forum/viewthread.php?tid=\(tid)&highlight=\(pageString)"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("https://www.4d4y.com/forum/", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }

            return try ForumHTMLParser.parseThreadDetail(data)
        } catch {
            throw error
        }
    }

    // MARK: - Reply

    func replyThread(tid: Int, message: String, formhash: String) async throws -> Bool {
        var components = URLComponents(url: baseURL.appendingPathComponent("post.php"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "action", value: "reply"),
            URLQueryItem(name: "tid", value: String(tid)),
            URLQueryItem(name: "formhash", value: formhash),
            URLQueryItem(name: "posttime", value: String(Int(Date().timeIntervalSince1970)))
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyItems: [URLQueryItem] = [
            URLQueryItem(name: "message", value: message),
            URLQueryItem(name: "formhash", value: formhash)
        ]
        let bodyString = bodyItems.map { "\($0.name)=\($0.value?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        return httpResponse.statusCode == 200 || httpResponse.statusCode == 302
    }

    // MARK: - Create Thread

    func createThread(fid: Int, title: String, message: String, formhash: String) async throws -> Bool {
        var components = URLComponents(url: baseURL.appendingPathComponent("post.php"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "action", value: "newthread"),
            URLQueryItem(name: "fid", value: String(fid)),
            URLQueryItem(name: "formhash", value: formhash)
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyItems: [URLQueryItem] = [
            URLQueryItem(name: "subject", value: title),
            URLQueryItem(name: "message", value: message),
            URLQueryItem(name: "formhash", value: formhash)
        ]
        let bodyString = bodyItems.map { "\($0.name)=\($0.value?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        return httpResponse.statusCode == 200 || httpResponse.statusCode == 302
    }

    // MARK: - Logout

    func logout(formhash: String) async throws {
        let url = baseURL.appendingPathComponent("logging.php?action=logout&formhash=\(formhash)")
        let (_, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 302 else {
            throw NetworkError.invalidResponse
        }
    }

    // MARK: - Private Messages

    func fetchPrivateMessages(page: Int = 1) async throws -> [PrivateMessage] {
        let urlString = "https://www.4d4y.com/forum/pm.php?page=\(page)"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("https://www.4d4y.com/forum/", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }

            return try ForumHTMLParser.parsePrivateMessages(data)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }

    // MARK: - PM Detail

    func fetchPMDetail(uid: Int, page: Int = 1) async throws -> PMDetail {
        let urlString = "https://www.4d4y.com/forum/pm.php?uid=\(uid)&filter=privatepm&daterange=5&page=\(page)"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("https://www.4d4y.com/forum/", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }

            return try ForumHTMLParser.parsePMDetail(data)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }

    // MARK: - User Profile

    func fetchUserProfile(uid: Int) async throws -> ForumUser {
        let urlString = "https://www.4d4y.com/forum/space.php?uid=\(uid)"

        print("[UserProfile] Request URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("https://www.4d4y.com/forum/", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await session.data(for: request)

            // Debug: Print response info
            if let httpResponse = response as? HTTPURLResponse {
                print("[UserProfile] Response Status: \(httpResponse.statusCode)")
                print("[UserProfile] Response URL: \(httpResponse.url?.absoluteString ?? "nil")")
                print("[UserProfile] All Header Fields: \(httpResponse.allHeaderFields)")
            }

            // Debug: Print raw data info
            print("[UserProfile] Data length: \(data.count) bytes")
            if let firstBytes = String(data: data.prefix(100), encoding: .utf8) {
                print("[UserProfile] First 100 bytes (UTF8): \(firstBytes)")
            } else {
                print("[UserProfile] First 100 bytes (hex): \(data.prefix(100).map { String(format: "%02x", $0) }.joined(separator: " "))")
            }

            // Debug: Print response body (first 2000 chars) - try multiple encodings
            let gb18030 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(0x80000631)))
            let gb2312 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(0x80000630)))
            var decodedHtml: String?
            for encoding in [gb18030, gb2312, .utf8] {
                if let html = String(data: data, encoding: encoding) {
                    decodedHtml = html
                    print("[UserProfile] Decoded with: \(encoding)")
                    break
                }
            }
            if let html = decodedHtml {
                print("[UserProfile] Response Body (first 2000 chars):")
                print(String(html.prefix(2000)))
            } else {
                print("[UserProfile] Response Body: (unable to decode)")
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }

            return try ForumHTMLParser.parseUserProfile(data)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }

    // MARK: - Search

    func search(keyword: String, page: Int = 1) async throws -> SearchDetail {
        let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
        let urlString = "https://www.4d4y.com/forum/search.php?srchtype=title&srchtxt=\(encodedKeyword)&searchsubmit=true&st=on&srchuname=&srchfilter=all&srchfrom=0&before=&orderby=lastpost&ascdesc=desc&page=\(page)"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("https://www.4d4y.com/forum/search.php", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }

            return try ForumHTMLParser.parseSearchResults(data)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
}

// MARK: - String MD5 Extension

extension String {
    var md5: String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: 16)

        _ = data.withUnsafeBytes { buffer in
            CC_MD5(buffer.baseAddress, CC_LONG(data.count), &digest)
        }

        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

import CommonCrypto
