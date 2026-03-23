import SwiftUI

@main
struct ServiHogarApp: App {
    @StateObject private var session = UserSession()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Group {
                    if session.isAuthenticated {
                        if session.role == "cliente" {
                            HomeClienteView()
                        } else {
                            HomeProfesionalView()
                        }
                    } else {
                        ContentView()
                    }
                }
            }
            .id(session.navigationId)
            .environmentObject(session)
        }
    }
}
