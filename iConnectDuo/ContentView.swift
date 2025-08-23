//
//  ContentView.swift
//  iConnectDuo
//
//  Created by Chris  on 19/8/25.
//

import SwiftUI
import AVFoundation
import NearbyInteraction
import SwiftDotenv
struct ContentView: View {
    @State private var username: String = ""
    @State private var selectedQ1: Int? = nil
    @State private var selectedQ2: Int? = nil
    @State private var showQuizRules = false
    @State private var deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    var body: some View {
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Hi! Welcome to")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .offset(x: -60, y: 10)
                    
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 250)
                        .offset(y: -30)
                    
                    (
                        Text("Your details are ") .fontWeight(.bold) +
                        Text("needed").foregroundColor(.blue).fontWeight(.bold) +
                        Text(" to make this experience ") .fontWeight(.bold) +
                        Text("better").foregroundColor(.blue).fontWeight(.bold)
                    )
                    .offset(y: -50)
                    .padding(.horizontal)
                    
                    TextField("Enter your real name", text: $username)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.3)))
                        .foregroundColor(.black)
                        .frame(width: 350, height: 50)
                        .offset(y: -60)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your ") .fontWeight(.bold) +
                        Text("gender").foregroundColor(.blue).fontWeight(.bold) +
                        Text("? ") .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            SelectableButton(title: "Male", isSelected: selectedQ1 == 0) { selectedQ1 = 0 }
                            SelectableButton(title: "Female", isSelected: selectedQ1 == 1) { selectedQ1 = 1 }
                        }
                    }
                    .offset(y: -40)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Gender you are") .fontWeight(.bold) +
                        Text(" interested").foregroundColor(.blue).fontWeight(.bold) +
                        Text(" in? ") .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            SelectableButton(title: "Male", isSelected: selectedQ2 == 0) { selectedQ2 = 0 }
                            SelectableButton(title: "Female", isSelected: selectedQ2 == 1) { selectedQ2 = 1 }
                        }
                    }
                    .offset(y: -30)
                    
                    Button(action: { showQuizRules = true }) {
                        HStack {
                            Spacer()
                            Text("Go!")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(.trailing, 16)
                        }
                        .frame(width: 200, height: 60)
                        .background(Color.gray)
                        .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 30)
                    .navigationDestination(isPresented: $showQuizRules) {
                        QuizRulesPart()
                    }
                    .padding()
                    .onAppear {
                        requestNotificationPermission()
                        testNotification()
                        setupNearbyInteraction()
                        let key = grabApiKey()
                        print("API key grabbed: \(key)")
                        
                        
                    }
                }
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
                .foregroundColor(.black)
                .padding()
                .frame(minWidth: 150, minHeight: 50)
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.3)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2))
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct QuizRulesPart: View {
    @State private var rise1 = false
    @State private var rise2 = false
    @State private var goToQuizQ1 = false
    @State private var showButton = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 20) {
                    (
                        Text("To enhance your experience better,") +
                        Text(" a quiz would be taken ").foregroundColor(.blue).fontWeight(.bold) +
                        Text("to find your ") +
                        Text("best match").foregroundColor(.blue).fontWeight(.bold)
                    )
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .font(.title2)
                    .bold()
                    .offset(y: rise1 ? geo.safeAreaInsets.top - 60 : geo.size.height + 100)
                    .padding(20)
                    
                    (
                        Text("This quiz consists of a total of ") +
                        Text("7 questions").foregroundColor(.blue).fontWeight(.bold) +
                        Text(", estimated a completion time of ") +
                        Text("10-15 Minutes").foregroundColor(.blue).fontWeight(.bold)
                    )
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .font(.title2)
                    .bold()
                    .offset(y: rise2 ? geo.safeAreaInsets.top - 60 : geo.size.height + 100)
                    .padding(20)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { goToQuizQ1 = true }) {
                            Text("Ready!")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 200, height: 60)
                                .background(Color.gray)
                                .cornerRadius(12)
                        }
                        .opacity(showButton ? 1 : 0)
                        .padding(.trailing, 30)
                        .padding(.bottom, 30)
                        .navigationDestination(isPresented: $goToQuizQ1) {
                            QuizView()
                        }
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 2.0)) { rise1 = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation(.easeOut(duration: 2.0)) { rise2 = true } }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { withAnimation(.easeIn(duration: 1.0)) { showButton = true } }
            }
        }
    }
}

struct QuizView: View {
    struct Question: Identifiable {
        let id = UUID()
        let text: String
        let options: [String]
    }
    
    let allQuestions: [Question] = [
        Question(text: "How do you usually spend your free time?", options: ["Reading or studying","Hanging out with friends","Playing video games","Exercising or sports"]),
        Question(text: "How do you handle conflict?", options: ["Stay calm and analyze","Express feelings openly","Avoid it","Confront directly"]),
        Question(text: "Which environment makes you most productive?", options: ["Quiet and alone","Background noise or music","Team environment","Outdoors or moving around"]),
        Question(text: "Are you more:", options: ["Introverted","Extroverted","Ambiverted","Depends on the situation"]),
        Question(text: "How do you make decisions?", options: ["Logically and rationally","Based on intuition","Ask friends/family for advice","Go with the flow"]),
        Question(text: "What kind of humor do you enjoy most?", options: ["Witty and clever","Slapstick or silly","Dark or sarcastic","Light and friendly"]),
        Question(text: "What motivates you the most?", options: ["Achievement and success","Helping others","Learning and curiosity","Fun and excitement"]),
        Question(text: "Do you prefer to plan or be spontaneous?", options: ["Plan everything in advance","Mostly plan but leave room for fun","Go with the flow","Completely spontaneous"]),
        Question(text: "How do you usually react to stress?", options: ["Stay calm and focus","Talk it out with friends","Withdraw and reflect","Get anxious easily"]),
        Question(text: "Which describes your social style best?", options: ["Enjoy small groups","Love big gatherings","Mix of both","Prefer online interactions"]),
        Question(text: "How do you approach new challenges?", options: ["Carefully analyze","Jump right in","Ask for advice","Avoid if possible"]),
        Question(text: "Which kind of activities do you enjoy most?", options: ["Creative/artistic","Physical/sports","Intellectual/puzzle","Relaxing/social"]),
        Question(text: "Do you prefer working:", options: ["Independently","In a team","Depends on the task","I avoid work!"]),
        Question(text: "How do you express your emotions?", options: ["Openly and clearly","Mostly internally","Depends on the person","Through humor or jokes"]),
        Question(text: "Are you more:", options: ["Optimistic","Realistic","Pessimistic","Depends on the situation"]),
        Question(text: "How often do you try new things?", options: ["All the time","Sometimes","Rarely","Never"]),
        Question(text: "What’s your approach to conflict in relationships?", options: ["Direct and honest","Diplomatic and careful","Avoid confrontation","Depends on the situation"]),
        Question(text: "Which do you value most in friends?", options: ["Loyalty","Fun","Honesty","Support"]),
        Question(text: "Do you consider yourself more:", options: ["Logical","Emotional","Creative","Balanced"]),
        Question(text: "How do you usually spend weekends?", options: ["Relaxing at home","Going out with friends","Trying new experiences","Catching up on work/study"])
    ]
    
    @State private var quizQuestions: [Question] = []
    @State private var currentIndex: Int = 0
    @State private var selectedAnswers: [UUID: String] = [:]
    @State private var quizCompleted = false
    @State private var isSaving = false
    @State private var showFinishedView = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if showFinishedView {
                    FinishedView()
                } else if !quizQuestions.isEmpty {
                    let currentQuestion = quizQuestions[currentIndex]
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Question \(currentIndex + 1) of \(quizQuestions.count)")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(currentQuestion.text)
                            .font(.title2)
                            .bold()
                        
                        ForEach(currentQuestion.options, id: \.self) { option in
                            Button(action: {
                                selectedAnswers[currentQuestion.id] = option
                            }) {
                                HStack {
                                    Text(option)
                                        .foregroundColor(.black)
                                    Spacer()
                                    if selectedAnswers[currentQuestion.id] == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2)))
                            }
                        }
                        
                        Spacer()
                        
                        HStack {
                            if currentIndex > 0 {
                                Button("Back") { currentIndex -= 1 }
                                    .frame(width: 100, height: 50)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(10)
                            }
                            Spacer()
                            Button(currentIndex == quizQuestions.count - 1 ? "Finish" : "Next") {
                                if currentIndex < quizQuestions.count - 1 {
                                    currentIndex += 1
                                } else {
                                    finishQuiz()
                                }
                            }
                            .frame(width: 120, height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                quizQuestions = Array(allQuestions.shuffled().prefix(7))
            }
        }
    }
    
    func finishQuiz() {
        isSaving = true
        
        Task {
            await saveAnswersToAppwrite(selectedAnswers: selectedAnswers, questions: quizQuestions)
            isSaving = false
            showFinishedView = true
        }
    }
    
}

// MARK: - Finished View
struct FinishedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            Text("🎉 Quiz Completed!")
                .font(.largeTitle)
                .bold()
            Text("Your answers have been saved successfully.")
                .font(.title2)
                .foregroundColor(.gray)
            Spacer()
        }
        .padding()
    }
}



#Preview {
    ContentView()
}
