//
//  SettingsView.swift
//  iConnect
//
//  Created by Dessen Tan on 3/6/25.
//

import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var selectedImageData: Data?

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Settings")
                    .font(.largeTitle)
                    .bold()

                ProfilePhotoPickerView(
                    selectedImageData: $selectedImageData,
                    selectedItem: $selectedItem
                )

                SaveUserDataView()

                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
}
