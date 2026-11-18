import SwiftUI

@main
struct MyApp: App {
    // Single ViewModel instance shared across the whole app
    @StateObject private var vm = LearningViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)  // Inject into all views
                .tint(.learnOrange)     // Default color for all buttons
        }
    }
}
