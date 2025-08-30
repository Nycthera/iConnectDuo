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
    // i tried finding a fix, but NO, NOTHING!
    guard NISession.isSupported else {
        print("Nearby Interaction is NOT supported")
        return
    }
    
    print("Nearby Interaction is supported")
    
    let session = NISession()
    session.delegate = NIHandler.shared
    niSession = session
    
    if let token = session.discoveryToken {
        niToken = token
        print("NI Discovery Token: \(token)")
        saveNITokenToUserDefaults(token)
    } else {
        print("Failed to get NI discovery token")
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
        if let first = nearbyObjects.first, first.distance != nil {
            if !isPaired {
                isPaired = true
                print("✅ Paired with peer!")
                sendPairingNotification(success: true)   // trigger success instantly
            }
        }
    }

    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        if reason == .timeout || reason == .peerEnded {
            if isPaired {
                isPaired = false
                print("❌ Lost connection with peer.")
                sendPairingNotification(success: false)  // trigger failure instantly
            }
        }
    }
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

func requestNotificationPermission() {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if granted {
            print("Notifications permission granted")
        } else {
            print("Notifications permission denied")
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
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

func grabApiKey() -> String {
    return getConfigValue(for: "apiKey")
}

// MARK: - Save quiz answers to Appwrite
func saveAnswersToAppwrite(selectedAnswers: [UUID: String], questions: [QuizView.Question]) async {
    let databaseId = getConfigValue(for: "appwriteDatabaseID")
    let collectionId = getConfigValue(for: "appwriteCollectionID")
    
    let userID = await UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    var answersArray: [String] = []
    answersArray.append(userID)
    
    for (index, question) in questions.enumerated() {
        let answer = selectedAnswers[question.id] ?? "NA"
        answersArray.append("q\(index + 1): \(answer)")
    }
    
    let documentData: [String: Any] = [
        "userID": userID,
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
    let deviceID = await UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    let databases = Databases(AppwriteService.shared.client)
    do {
        let documents = try await databases.listDocuments(
            databaseId: databaseId,
            collectionId: collectionId,
            queries: [
                Query.equal("userID", value: deviceID)
            ]
        )

        if documents.documents.isEmpty {
            print("No documents found for userID: \(deviceID)")
        } else {
            for doc in documents.documents {
                print("Document ID: \(doc.id)")
                print("Data: \(doc.data)")
            }
        }
    }
    catch {
        print("Error with grabbing documents: \(error)")
    }

}



struct GeminiRequest: Codable {
    let prompt: String
    let maxTokens: Int
}

struct GeminiResponse: Codable {
    let text: String
}

func callGemini(prompt: String, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: "https://gemini.googleapis.com/v1/your-endpoint") else {
        completion(nil)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer YOUR_API_KEY_HERE", forHTTPHeaderField: "Authorization")

    let body = GeminiRequest(prompt: prompt, maxTokens: 150)
    request.httpBody = try? JSONEncoder().encode(body)

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error:", error)
            completion(nil)
            return
        }

        guard let data = data else {
            completion(nil)
            return
        }

        do {
            let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
            completion(decoded.text)
        } catch {
            print("Decoding error:", error)
            completion(nil)
        }
    }.resume()
}

class MPCHandler: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, ObservableObject {
    static let shared = MPCHandler()
    
    private let serviceType = "iconnect-ni"
    private let peerID: MCPeerID
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    var isStarted = false
    
    override init() {
        peerID = MCPeerID(displayName: UIDevice.current.name + "-" + UUID().uuidString.prefix(4))
        super.init()
        
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: ["role": "sender"], serviceType: serviceType)
        advertiser.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser.delegate = self
    }
    
    func start() {
        guard !isStarted else { return }   // already started
        stop() // optional: ensure clean slate
        isStarted = true

        advertiser.startAdvertisingPeer()
        print("✅ Started advertising")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.browser.startBrowsingForPeers()
            print("🔍 Started browsing for peers")
        }
    }

    
    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        isStarted = false
        print("🛑 Stopped MPC")
    }
    
    func sendDiscoveryToken(_ token: NIDiscoveryToken) {
        guard !session.connectedPeers.isEmpty else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.sendDiscoveryToken(token)
                print("⌛ Waiting for peers before sending token...")
            }
            return
        }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            print("📤 Sent NI token to peers")
        } catch {
            print("❌ Error sending NI token:", error)
        }
    }
    
    // MARK: - Advertiser Delegate
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📩 Received invitation from \(peerID.displayName)")
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ Advertiser failed: \(error.localizedDescription) \(error)")
    }

    
    
    // MARK: - Browser Delegate
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🔎 Found peer \(peerID.displayName), info: \(info ?? [:]) – inviting...")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("⚠️ Lost peer \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ Browser failed: \(error.localizedDescription) \(error)")
    }

    
    // MARK: - Session Delegate
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected: print("✅ Connected to \(peerID.displayName)")
        case .connecting: print("⌛ Connecting to \(peerID.displayName)...")
        case .notConnected: print("❌ Not connected to \(peerID.displayName)")
        @unknown default: print("❓ Unknown state for \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            if let token = try NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) {
                print("📥 Received NI token from \(peerID.displayName)")
                niSession?.run(NINearbyPeerConfiguration(peerToken: token))
            }
        } catch {
            print("❌ Error decoding NI token:", error)
        }
    }
    
    // Unused delegate stubs
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}


// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    @Published var userRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var hasPermission = false
    
    // <<< Add this property
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
    
    // Updated request function
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


// Function to trigger a notification
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
