import SwiftUI
import AVFoundation
import NearbyInteraction

struct QuizRulePartView: View {
    @State private var niToken: NIDiscoveryToken? = nil
    @State private var niSession: NISession? = nil
    
    var body: some View {
        VStack {
            Text("Chris")
                .font(.title)
                .padding()
                .navigationTitle("Nearby Interaction")
                .onAppear {
                    checkCameraPermission()
                    setupNearbyInteraction()
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
            break
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
            let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: "NI_TOKEN")
            print("NI token saved to UserDefaults")
        } catch {
            print("Failed to archive NI token:", error)
        }
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

// MARK: - Preview
#Preview {
    QuizRulePartView()
}
