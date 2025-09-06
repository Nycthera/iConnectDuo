    //
    //  Functions.swift
    //  iConnectDuo
    //
    //  Created by Chris on 19/8/25.
    //

    import AVFoundation
    import NearbyInteraction
    import UserNotifications
    import Appwrite
    import UIKit
    import MultipeerConnectivity
    import Foundation
    import MapKit
    import CoreLocation

    // MARK: - Globals
    var niSession: NISession?
    var niToken: NIDiscoveryToken?
    var devMode: Bool = true   // <-- proper declaration

    // Stable device ID stored in UserDefaults
    var deviceID: String = {
        if let saved = UserDefaults.standard.string(forKey: "simDeviceID") {
            return saved
        } else {
            let newID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            UserDefaults.standard.set(newID, forKey: "simDeviceID")
            return newID
        }
    }()

    func grabApiKey() -> String {
        return getConfigValue(for: "apiKey")
    }

    // MARK: - Notifications
    func testNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Hello!"
        content.body = "This is a test notification."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Camera Permission
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    print(granted ? "Camera access granted" : "Camera access denied")
                }
            }
        case .restricted, .denied:
            print("Camera access denied previously")
        case .authorized:
            print("Camera access already granted")
        @unknown default:
            print("Unknown camera authorization status")
        }
    }

    // MARK: - Nearby Interaction
    func setupNearbyInteraction() {
        guard NISession.isSupported else {
            print("Nearby Interaction is NOT supported")
            return
        }
        
        if niSession == nil {
            niSession = NISession()
            niSession?.delegate = NIHandler.shared
        }
        
        func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
            if let peerToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) {
                niSession?.run(NINearbyPeerConfiguration(peerToken: peerToken))
                print("NI session started with peer token")
            }
        }

    }

    func saveNITokenToUserDefaults(_ token: NIDiscoveryToken) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: token,
                                                        requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: "NI_TOKEN")
            print("NI token saved to UserDefaults")
        } catch {
            print("Failed to archive NI token:", error)
        }
    }

    // MARK: - NI Session Delegate
    class NIHandler: NSObject, NISessionDelegate {
        static let shared = NIHandler()
        var isPaired = false

        func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
            if let first = nearbyObjects.first, first.distance != nil, !isPaired {
                isPaired = true
                print("Paired with peer!")
                sendPairingNotification(success: true)
                
                // Automatically request peer UUID after pairing
                MPCHandler.shared.requestPeerUUIDs()
            }
        }
        
        func session(_ session: NISession, didInvalidateWith error: Error) {
            print("NI Session invalidated: \(error.localizedDescription)")
            if let token = niToken {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    session.run(NINearbyPeerConfiguration(peerToken: token))
                    print("NI session restarted after invalidation")
                }
            }
        }

        func sessionWasSuspended(_ session: NISession) {
            print("NI Session was suspended")
            if let token = niToken {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    session.run(NINearbyPeerConfiguration(peerToken: token))
                    print("NI session resumed after suspension")
                }
            }
        }

        func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
            if reason == .timeout || reason == .peerEnded {
                if isPaired {
                    isPaired = false
                    print("Lost connection with peer.")
                    sendPairingNotification(success: false)
                }
            }
        }
    }

    // MARK: - Notifications
    func sendPairingNotification(success: Bool) {
        let content = UNMutableNotificationContent()
        content.title = success ? "Pairing Successful 🎉" : "Pairing Failed ❌"
        content.body = success ? "You’re now connected with the other user." : "Could not establish a connection. Try again."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error)")
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print(granted ? "Notifications permission granted" : "Notifications permission denied")
            if let error = error { print("Error: \(error.localizedDescription)") }
        }
    }

    class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
        static let shared = NotificationHandler()
        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    willPresent notification: UNNotification,
                                    withCompletionHandler completionHandler:
                                        @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.banner, .sound])
        }
    }

    // MARK: - Config helpers
    func getConfigValue(for key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            fatalError("Missing config value for key: \(key)")
        }
        return value
    }

    // MARK: - Appwrite quiz saving
    func saveAnswersToAppwrite(selectedAnswers: [UUID: String], questions: [QuizView.Question]) async {
        let databaseId = getConfigValue(for: "appwriteDatabaseID")
        let collectionId = getConfigValue(for: "appwriteCollectionID")
        
        var answersArray: [String] = []
        answersArray.append(deviceID)
        
        for (index, question) in questions.enumerated() {
            let answer = selectedAnswers[question.id] ?? "NA"
            answersArray.append("q\(index + 1): \(answer)")
        }
        
        let documentData: [String: Any] = [
            "userID": deviceID,
            "userAnswers": answersArray
        ]
        
        let databases = Databases(AppwriteService.shared.client)
        
        if devMode {
            print("func not run, disable dev mode")
        } else {
            do {
                let document = try await databases.createDocument(
                    databaseId: databaseId,
                    collectionId: collectionId,
                    documentId: "unique()",
                    data: documentData
                )
                print("Document saved successfully:", document)
            } catch {
                print("Error saving document:", error)
            }
        }
    }

    func fetchAnswersFromAppwrite() async {
        let databaseId = getConfigValue(for: "appwriteDatabaseID")
        let collectionId = getConfigValue(for: "appwriteCollectionID")
        
        let databases = Databases(AppwriteService.shared.client)
        do {
            let documents = try await databases.listDocuments(
                databaseId: databaseId,
                collectionId: collectionId,
                queries: [Query.equal("userID", value: deviceID)]
            )
            
            if documents.documents.isEmpty {
                print("No documents found for userID: \(deviceID)")
            } else {
                for doc in documents.documents {
                    print("Document ID: \(doc.id)")
                    print("Data: \(doc.data)")
                }
            }
        } catch {
            print("Error fetching documents: \(error)")
        }
    }

    // MARK: - MPCHandler & UUID exchange
    enum MessageType: String, Codable {
        case requestUUID
        case responseUUID
        case requestLocation
        case responseLocation
        case notifyRequestSuccess
    }

    struct Message: Codable {
        let type: MessageType
        let payload: String?
    }

    func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error.localizedDescription)")
            }
        }
    }


    class MPCHandler: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, ObservableObject {
        static let shared = MPCHandler()
        
        private let serviceType = "iconnect-ni"
        private let peerID: MCPeerID
        private var session: MCSession!
        private var advertiser: MCNearbyServiceAdvertiser!
        private var browser: MCNearbyServiceBrowser!
        var isStarted = false
        
        @Published var peerDeviceIDs: [String] = []
        @Published var peerLocations: [String: CLLocationCoordinate2D] = [:]
        
        override init() {
            peerID = MCPeerID(displayName: deviceID.prefix(8).description)
            super.init()
            
            session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
            session.delegate = self
            
            advertiser = MCNearbyServiceAdvertiser(peer: peerID,
                                                   discoveryInfo: ["role": "sender", "deviceID": deviceID],
                                                   serviceType: serviceType)
            advertiser.delegate = self
            
            browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
            browser.delegate = self
        }
        
        func start() {
            guard !isStarted else { return }
            stop()
            isStarted = true
            
            advertiser.startAdvertisingPeer()
            print("Started advertising")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.browser.startBrowsingForPeers()
                print("Started browsing for peers")
            }
        }
        
        func stop() {
            advertiser.stopAdvertisingPeer()
            browser.stopBrowsingForPeers()
            isStarted = false
            print("Stopped MPC")
        }
        
        func sendDiscoveryToken(_ token: NIDiscoveryToken) {
            guard !session.connectedPeers.isEmpty else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.sendDiscoveryToken(token)
                }
                return
            }
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
                print("Sent NI token to peers")
            } catch {
                print("Error sending NI token:", error)
            }
        }
        
        func requestPeerUUIDs() {
            guard !session.connectedPeers.isEmpty else {
                print("No connected peers yet, retrying UUID request...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.requestPeerUUIDs() // retry until a peer connects
                }
                return
            }

            let message = Message(type: .requestUUID, payload: nil)
            sendToAllPeers(message)
            sendToAllPeers(Message(type: .notifyRequestSuccess, payload: "UUID request received"))
        }

        
        func requestPeerLocations() {
            guard !session.connectedPeers.isEmpty else {
                print("No connected peers yet, retrying location request...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.requestPeerLocations() // retry until a peer connects
                }
                return
            }

            let message = Message(type: .requestLocation, payload: nil)
            sendToAllPeers(Message(type: .notifyRequestSuccess, payload: "loc request received"))
            print("Sent location request to peers")
        }

        
        func debugPrintPeers() {
                print("==== Connected Peers ====")
                for uuid in peerDeviceIDs {
                    if let loc = peerLocations[uuid] {
                        print("UUID: \(uuid) — Location: \(loc.latitude), \(loc.longitude)")
                    } else {
                        print("UUID: \(uuid) — Location: unknown")
                    }
                }
                print("========================")
            }

        
        
        // MARK: - MCSessionDelegate
        func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
            switch state {
            case .connected: print("Connected to \(peerID.displayName)")
            case .connecting: print("Connecting to \(peerID.displayName)...")
            case .notConnected: print("Not connected to \(peerID.displayName)")
            @unknown default: print("Unknown state for \(peerID.displayName)")
            }
        }
        
        private func sendToAllPeers(_ message: Message) {
            guard !session.connectedPeers.isEmpty else {
                print("No connected peers, cannot send message")
                return
            }
            do {
                let data = try JSONEncoder().encode(message)
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            } catch {
                print("Failed to send message to all peers:", error)
            }
        }

        
        func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
            if let message = try? JSONDecoder().decode(Message.self, from: data) {
                switch message.type {
                case .requestUUID:
                    sendMessage(.responseUUID, payload: deviceID, to: [peerID])
                case .responseUUID:
                    if let uuid = message.payload, !peerDeviceIDs.contains(uuid) {
                        peerDeviceIDs.append(uuid)
                        print("Received peer UUID: \(uuid)")
                        requestPeerLocations()
                    }
                case .requestLocation:
                    if let location = LocationManager.shared.userLocation {
                        let payload = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                        sendMessage(.responseLocation, payload: payload, to: [peerID])
                    }
                case .responseLocation:
                    if let payload = message.payload,
                       let uuid = peerDeviceIDs.first { // assume single peer
                        let parts = payload.split(separator: ",").compactMap { Double($0) }
                        if parts.count == 2 {
                            let lat = parts[0]
                            let lon = parts[1]
                            peerLocations[uuid] = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            print("Updated location for peer \(uuid): \(lat), \(lon)")
                        }
                    }
                case .notifyRequestSuccess:
                    if let info = message.payload {
                        sendLocalNotification(title: "Request Success", body: info)
                        print("success")
                    }
                }
                return
            }

            // 2️⃣ If JSON decoding failed, try decoding as NIDiscoveryToken
            if let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) {
                if niSession == nil { setupNearbyInteraction() }
                niSession?.run(NINearbyPeerConfiguration(peerToken: token))
                print("Received NI token from peer \(peerID.displayName)")
                return
            }

            // 3️⃣ If neither worked, log
            print("Received unknown data from peer \(peerID.displayName): \(data)")
        }


            // Helper to send message to specific peers
            private func sendMessage(_ type: MessageType, payload: String?, to peers: [MCPeerID]) {
                let message = Message(type: type, payload: payload)
                do {
                    let data = try JSONEncoder().encode(message)
                    try session.send(data, toPeers: peers, with: .reliable)
                } catch {
                    print("Failed to send message:", error)
                }
            }
        
        // MARK: - Unused delegate stubs
        func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
        func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
        func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
        
        // MARK: - Advertiser Delegate
        func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                        withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
            invitationHandler(true, session)
        }
        
        func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
            print("Advertiser failed: \(error.localizedDescription)")
        }
        
        // MARK: - Browser Delegate
        func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        }
        
        func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
        func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {}
    }

    // MARK: - Location Manager
    class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
        private let manager = CLLocationManager()
        static let shared = LocationManager()
        
        @Published var userLocation: CLLocation?
        @Published var userRegion: MKCoordinateRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        @Published var hasPermission = false
        private var permissionCompletion: ((Bool) -> Void)?
        
        override init() {
            super.init()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            checkPermission()
        }
        
        func checkPermission() {
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                hasPermission = true
                manager.startUpdatingLocation()
            case .denied, .restricted:
                hasPermission = false
            case .notDetermined:
                hasPermission = false
            @unknown default:
                hasPermission = false
            }
        }
        
        func requestLocationPermission(completion: ((Bool) -> Void)? = nil) {
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                hasPermission = true
                manager.startUpdatingLocation()
                completion?(true)
            case .notDetermined:
                permissionCompletion = completion
                manager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                hasPermission = false
                completion?(false)
            @unknown default:
                hasPermission = false
                completion?(false)
            }
        }
        
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.checkPermission()
                self.permissionCompletion?(self.hasPermission)
                self.permissionCompletion = nil
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            DispatchQueue.main.async { [weak self] in
                self?.userLocation = location
                self?.userRegion.center = location.coordinate
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("Failed to get user location:", error)
        }
    }

    func GeminiMatch() {
        // 1. Get API key from Info.plist
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_API_KEY") as? String else {
            print("API Key not found!")
            return
        }

        // 2. Set up the URL
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent") else {
            fatalError("Invalid URL")
        }

        // 3. Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-goog-api-key")

        // 4. Request body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "Explain how AI works in a few words"]
                    ]
                ]
            ]
        ]

        // 5. Convert body to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            print("Error encoding JSON: \(error)")
            return
        }

        // 6. Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request error: \(error)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Response: \(json)")
                } else {
                    print("Cannot parse JSON")
                }
            } catch {
                print("JSON parse error: \(error)")
            }
        }

        // 7. Start the task
        task.resume()
    }
