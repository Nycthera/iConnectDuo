import AVFoundation
import NearbyInteraction
import UserNotifications
import Appwrite

// MARK: - Globals
var niSession: NISession?
var niToken: NIDiscoveryToken?

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
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        print("NI session invalidated:", error)
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        print("Nearby objects updated:", nearbyObjects)
    }
}

func getOtherDeviceToken() {
    // add functions here 
}


func testNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Hello!"
    content.body = "This is a test notification."
    content.sound = .default

    // Trigger after 5 seconds
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    

    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

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
            print("Notifications permission granted ✅")
        } else {
            print("Notifications permission denied ❌")
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
        // Show notification as banner + play sound even when app is open
        completionHandler([.banner, .sound])
    }
}

