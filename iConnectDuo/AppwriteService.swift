//
//  AppwriteService.swift
//  iConnectDuo
//
//  Created by Chris  on 19/8/25.
//

import Appwrite
import SwiftDotenv

class AppwriteService {
    static let shared = AppwriteService()
    
    let client = Client()
    
    private init() {
        let apiKey = grabApiKey()
        client
            .setEndpoint("https://nyc.cloud.appwrite.io/v1") // Replace with your endpoint
            .setProject("68a45c19002558882211")              // Replace with your project ID
            .setKey(apiKey)
    }
}
