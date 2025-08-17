import SwiftUI

struct ContentView: View {
    @State private var username: String = ""
    @State private var selectedQ1: Int? = nil
    @State private var selectedQ2: Int? = nil
    @State private var showQuizRules = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Hi! Welcome to")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 320, height: 200)

                    (
                        Text("Your details are ").fontWeight(.bold) +
                        Text("needed").foregroundColor(.blue).fontWeight(.bold) +
                        Text(" to make this experience ").fontWeight(.bold) +
                        Text("better").foregroundColor(.blue).fontWeight(.bold)
                    )
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)

                    // TextField with adaptive color
                    TextField("Enter your real name", text: $username)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                        )
                        .foregroundColor(.primary)
                        .frame(width: 350, height: 50)

                    // Question 1
                    VStack(alignment: .leading, spacing: 10) {
                        (
                            Text("Your ").fontWeight(.bold) +
                            Text("gender").foregroundColor(.blue).fontWeight(.bold) +
                            Text("?").fontWeight(.bold)
                        )

                        HStack(spacing: 20) {
                            SelectableButton(title: "Male", isSelected: selectedQ1 == 0) { selectedQ1 = 0 }
                            SelectableButton(title: "Female", isSelected: selectedQ1 == 1) { selectedQ1 = 1 }
                        }
                    }

                    // Question 2
                    VStack(alignment: .leading, spacing: 10) {
                        (
                            Text("Gender you are").fontWeight(.bold) +
                            Text(" interested").foregroundColor(.blue).fontWeight(.bold) +
                            Text(" in?").fontWeight(.bold)
                        )

                        HStack(spacing: 20) {
                            SelectableButton(title: "Male", isSelected: selectedQ2 == 0) { selectedQ2 = 0 }
                            SelectableButton(title: "Female", isSelected: selectedQ2 == 1) { selectedQ2 = 1 }
                        }
                    }

                    // Go Button
                    Button(action: { showQuizRules = true }) {
                        HStack {
                            Spacer()
                            Text("Go!")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(.trailing, 16)
                        }
                        .frame(width: 200, height: 60)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 30)
                    .navigationDestination(isPresented: $showQuizRules) {
                        QuizRulePartView()
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
        }
    }
}

struct SelectableButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.primary)
                .padding()
                .frame(minWidth: 150, minHeight: 50)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// Preview
#Preview {
    Group {
        ContentView()
            .preferredColorScheme(.light)

        ContentView()
            .preferredColorScheme(.dark)
    }
}
