//
//  AppwriteService.swift
//  iConnectDuo
//
//  Created by Chris  on 19/8/25.
//

import Appwrite

class AppwriteService {
    static let shared = AppwriteService()
    
    let client = Client()
    
    private init() {
        client
            .setEndpoint("https://nyc.cloud.appwrite.io/v1") // Your Appwrite endpoint
            .setProject("68a45c19002558882211") // Your Appwrite project ID
            .setKey("")
    }
    
    // Ping function
    func sendPing() async -> (Bool, String) {
        let health = Health(client)
        do {
            let response = try await health.get()
            return (true, "Ping successful: \(response)")
        } catch {
            return (false, "Ping failed: \(error.localizedDescription)")
        }
    }
}
