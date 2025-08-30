//
//  SettingsView.swift
//  khh,b
//
//  Created by Dessen Tan on 3/6/25.
//
import SwiftUI
import _PhotosUI_SwiftUI

struct ProfilePhotoPickerView: View {
    @Binding var selectedImageData: Data?
    @Binding var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack {
            if let data = selectedImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(Circle())
                    .shadow(radius: 10)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .overlay(Text("Profile Picture"))
            }

            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()) {
                    Label("Choose Photo", systemImage: "photo")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
            }
        }
        .task(id: selectedItem) {
            if let item = selectedItem {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    selectedImageData = data
                    UserDefaults.standard.set(data.base64EncodedString(), forKey: "profileImageData")
                }
            }
        }
        .onAppear {
            if let saved = UserDefaults.standard.string(forKey: "profileImageData"),
               let data = Data(base64Encoded: saved) {
                selectedImageData = data
            }
        }
    }
}
