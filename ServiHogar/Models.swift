import SwiftUI

struct ModeloSolicitud: Codable, Identifiable {
    let id: Int
    let categoria, descripcion, ubicacion, foto, estado: String?
    let cliente: DatosUsuario?
}

struct RespuestaLogin: Codable {
    let user: DatosUsuario?
}

struct DatosUsuario: Codable {
    let id: Int?
    let role, name, telefono, foto, domicilio: String?
    let profesiones: [String]?
}
