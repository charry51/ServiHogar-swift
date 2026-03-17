import SwiftUI
import FirebaseCore

@main
struct ServiHogarApp: App {
    
    init() {
        FirebaseApp.configure()
        print("🚀 ServiHogar: Conectado a Firebase con éxito")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
