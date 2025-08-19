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
            .setKey("standard_b8be234d01f61ff702d04a62f66b9d5853e62d402374be24bea419cb73318aa6a0460cdd11202e065f92402a4cecc65cdd3a4325682bb331e041870823d938ffadd8f187d305da7b0376639049817b0befcb82592f7be1b562b803794a8d5da42da89b814201d992cb68c6427c844334f03d49e7a7e446950da3b649c0928ab5")
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
