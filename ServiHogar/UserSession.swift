import SwiftUI
import Foundation
import Combine

class UserSession: ObservableObject {
    @Published var currentUser: DatosUsuario?
    @Published var isAuthenticated: Bool = false
    @Published var navigationId = UUID()
    
    // Propiedades rápidas para acceder a los datos del usuario
    var nombre: String { currentUser?.name ?? "Usuario" }
    var id: Int { currentUser?.id ?? 0 }
    var foto: String { currentUser?.foto ?? "" }
    var telefono: String { currentUser?.telefono ?? "" }
    var domicilio: String { currentUser?.domicilio ?? "" }
    var role: String { currentUser?.role ?? "cliente" }
    var profesiones: [String] { currentUser?.profesiones ?? [] }
    
    func login(user: DatosUsuario) {
        self.currentUser = user
        self.isAuthenticated = true
    }
    
    func logout() {
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    func updateProfile(name: String, foto: String, telefono: String, domicilio: String, profesiones: [String]? = nil) {
        guard let current = currentUser else { return }
        self.currentUser = DatosUsuario(
            id: current.id,
            role: current.role,
            name: name,
            telefono: telefono,
            foto: foto,
            domicilio: domicilio,
            profesiones: profesiones ?? current.profesiones
        )
    }
    
    func popToRoot() {
        self.navigationId = UUID()
    }
}
