//
//  B2BAPIClient.swift
//  B2BAPIClientProject
//
//  Created by Yousef Alselawe on 22/09/2024.
//

import Foundation

public class B2BAPIClient {

    private let baseURL = "https://cms.3abee.com/api/v1/"
    private var token: String? {
        get {
            return UserDefaults.standard.string(forKey: "_token")
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "_token")
        }
    }

    public init() {}

    // MARK: - Helper Method to Make Request

    private func makeRequest(urlString: String, method: String, body: Data? = nil, requiresAuth: Bool = true, headers: [String: String] = [:], completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: baseURL + urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = method
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        // Add Authorization header if required
        if requiresAuth, let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body
        
        let curl = generateCURL(request: request)
        print("cURL Command: \(curl)")

        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server responded with code \(httpResponse.statusCode)"])))
                return
            }

            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data in response"])))
            }
        }.resume()
    }

    // MARK: - API Methods

    // Generate Token (Login)

    public func generateToken(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
         let endpoint = "login"
         
         // Request body
         let body: [String: Any] = [
             "email": email,
             "password": password
         ]
         
         // Headers
         let headers = [
             "client-id": "44582823",
             "client-secret": "ZwbCSACSu2bNegwH90xmFd1CSAFkm0lnsQo6ORjTf1FoAMvjUT4SfWajHUup1YqJ",
             "Content-Type": "application/json"
         ]

         // Convert the body to JSON data
         guard let bodyData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
             completion(.failure(NSError(domain: "SerializationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize body data"])))
             return
         }

         // Make the request
         makeRequest(urlString: endpoint, method: "POST", body: bodyData, requiresAuth: false, headers: headers) { result in
             switch result {
             case .success(let data):
                 // Log the raw response data for debugging
                 if let responseString = String(data: data, encoding: .utf8) {
                     print("Response JSON: \(responseString)")
                 }

                 // Parse the response
                 if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                     
                     // Check if status is false and return the error message
                     if let status = json["status"] as? Bool, !status {
                         let errorMessage = json["message"] as? String ?? "Unknown error"
                         completion(.failure(NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                         return
                     }
                     
                     // Handle status true and parse the token
                     if let status = json["status"] as? Bool, status == true,
                        let dataDict = json["data"] as? [String: Any],
                        let token = dataDict["token"] as? String {
                         // Store the token for future requests
                         self.token = token
                         print("Token: \(token)")

                         // Optional: Handle other parts of the response (e.g., user info, expires_in)
                         if let user = dataDict["user"] as? [String: Any],
                            let userName = user["name"] as? String,
                            let userEmail = user["email"] as? String {
                             print("User Name: \(userName), User Email: \(userEmail)")
                         }

                         completion(.success(()))
                     } else {
                         completion(.failure(NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid token response"])))
                     }
                 } else {
                     completion(.failure(NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid token response"])))
                 }
             case .failure(let error):
                 completion(.failure(error))
             }
         }
     }
    

    // MARK: - Token Management

    // Method to manually set token, if needed
    public func setToken(_ token: String) {
        self.token = token
    }

    // Method to clear token (e.g., on logout)
    public func clearToken() {
        self.token = nil
    }
}


func generateCURL(request: URLRequest) -> String {
    var curlCommand = "curl"

    // Add the method
    if let method = request.httpMethod {
        curlCommand += " -X \(method)"
    }

    // Add the URL
    if let url = request.url {
        curlCommand += " '\(url.absoluteString)'"
    }

    // Add headers
    if let headers = request.allHTTPHeaderFields {
        for (key, value) in headers {
            curlCommand += " -H '\(key): \(value)'"
        }
    }

    // Add the body if it exists
    if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
        // Escape any quotes within the body string
        let escapedBody = bodyString.replacingOccurrences(of: "'", with: "\\'")
        curlCommand += " --data '\(escapedBody)'"
    }

    return curlCommand
}



//    // MARK: - API Methods
//
//    // Generate Token
//    public func generateToken(email: String, password: String, clientId: String, clientSecret: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        let endpoint = "login"
//        let body: [String: Any] = ["email": email, "password": password]
//        let headers = [
//            "lang": "en",
//            "client-id": clientId,
//            "client-secret": clientSecret,
//            "Content-Type": "application/json"
//        ]
//
//        guard let bodyData = try? JSONSerialization.data(withJSONObject: body, options: []) else { return }
//
//        makeRequest(urlString: endpoint, method: "POST", body: bodyData, requiresAuth: false, headers: headers) { result in
//            switch result {
//            case .success(let data):
//                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                   let tokenData = json["data"] as? [String: Any],
//                   let accessToken = tokenData["token"] as? String {
//                    self.token = accessToken
//                    completion(.success(()))
//                } else {
//                    completion(.failure(NSError(domain: "TokenError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid token response"])))
//                }
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//
//    // to Fetch Currency
//    public func getCurrencies(completion: @escaping (Result<[String: Any], Error>) -> Void) {
//        let endpoint = "currency"
//        makeRequest(urlString: endpoint, method: "GET", headers: [:]) { result in
//            switch result {
//            case .success(let data):
//                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                    completion(.success(json))
//                } else {
//                    completion(.failure(NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"])))
//                }
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//
//    // Example to Fetch Account Balance
//    public func getAccountBalance(completion: @escaping (Result<[String: Any], Error>) -> Void) {
//        let endpoint = "check/account/balance"
//        makeRequest(urlString: endpoint, method: "GET", headers: [:]) { result in
//            switch result {
//            case .success(let data):
//                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                    completion(.success(json))
//                } else {
//                    completion(.failure(NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"])))
//                }
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//
//    // MARK: - Token Management
//
//    // Method to manually set token, if needed
//    public func setToken(_ token: String) {
//        self.token = token
//    }
//
//    // Method to clear token (e.g., on logout)
//    public func clearToken() {
//        self.token = nil
//    }
//}
