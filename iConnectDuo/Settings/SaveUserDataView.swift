//
//  SaveUserDataView.swift
//  iConnect
//
//  Created by Dessen Tan on 3/6/25.
//

import SwiftUI

struct SaveUserDataView: View {
    @AppStorage("userName") private var name = ""
    @AppStorage("userAge") private var age = 0
    @AppStorage("userLocation") private var location = ""
    @AppStorage("userSpecialty") private var specialty = "None"
    @AppStorage("userInterest") private var interest = "None"
    
    @State private var sheet1 = false
    @State private var sheet2 = false
    
    var body: some View {
        Form {
            Section(header: Text("Name")) {
                TextField("Name", text: $name)
            }
            Section(header: Text("Age")) {
                TextField("Age", value: $age, format: .number)
                    .keyboardType(.numberPad)
            }
            Section(header: Text("Location")) {
                TextField("Location", text:$location)
            }
            
            Section(header:
                        HStack {
                Text("Specialty")
                Spacer()
                Button(action: {
                    sheet1 = true
                }) {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
            }
            ) {
                Specialty(specalty: specialty)
            }
            
            Section(header:
                        HStack {
                Text("Interest")
                Spacer()
                Button(action: {
                    sheet2 = true
                }) {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
            }
            ) {
                Interest(interest: interest)
            }
        }
        .sheet(isPresented: $sheet1) {
            SpecialtyEditorView(specialty: $specialty)
        }
        .sheet(isPresented: $sheet2) {
            InterestEditorView(interest: $interest)
        }
    }
}

struct SpecialtyEditorView: View {
    @Binding var specialty: String
    @Environment(\.dismiss) var dismiss
    
    @State private var newSpecialty: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Enter new specialty", text: $newSpecialty)
            }
            .navigationTitle("Edit Specialty")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !newSpecialty.isEmpty {
                            specialty = newSpecialty
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                newSpecialty = specialty
            }
        }
    }
}

struct InterestEditorView: View {
    @Binding var interest: String
    @Environment(\.dismiss) var dismiss
    
    @State private var newInterest: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Enter new interest", text: $newInterest)
            }
            .navigationTitle("Edit Interest")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !newInterest.isEmpty {
                            interest = newInterest
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                newInterest = interest
            }
        }
    }
}
#Preview{
    SettingsView(selectedItem: .constant(nil), selectedImageData: .constant(nil))
}
