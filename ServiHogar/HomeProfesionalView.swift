import SwiftUI
import FirebaseFirestore

struct HomeProfesionalView: View {
    let azulTexto = Color(red: 0, green: 0.38, blue: 0.66)
    @Environment(\.dismiss) var dismiss
    
    @Binding var nombreUsuario: String
    var idUsuario: String // <--- String correcto
    @Binding var fotoUsuario: String
    @Binding var telefonoUsuario: String
    @Binding var domicilioUsuario: String
    var alCerrarSesion: () -> Void
    
    @State private var estaActivo = true
    @State private var pestañaSeleccionada = "Solicitudes"
    @State private var listaSolicitudes: [ModeloSolicitud] = []
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Button(action: alCerrarSesion) { Image(systemName: "rectangle.portrait.and.arrow.right").bold().foregroundColor(.white).frame(width: 40, height: 40).contentShape(Rectangle()) }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text("Bienvenido").bold().foregroundColor(azulTexto)
                    Text(nombreUsuario).font(.title2).bold().foregroundColor(azulTexto)
                    Toggle(estaActivo ? "Activo" : "Inactivo", isOn: $estaActivo).labelsHidden().tint(.green)
                }
                NavigationLink(destination: PerfilView(
                    nombre: nombreUsuario, id: idUsuario, fotoBase64: fotoUsuario, telefono: telefonoUsuario, domicilio: domicilioUsuario, esProfesional: true,
                    alCerrarSesion: { dismiss(); self.alCerrarSesion() },
                    alGuardar: { n, f, t, d, _ in self.nombreUsuario = n; self.fotoUsuario = f; self.telefonoUsuario = t; self.domicilioUsuario = d }
                )) {
                    ZStack {
                        if let data = Data(base64Encoded: fotoUsuario), let uiImage = UIImage(data: data) { Image(uiImage: uiImage).resizable().scaledToFill() }
                        else { Image(systemName: "person.crop.circle.fill").resizable().foregroundColor(.white) }
                    }.frame(width: 50, height: 50).clipShape(Circle()).background(Circle().fill(azulTexto)).padding(.leading, 10)
                }
            }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 20)
            
            HStack(spacing: 15) {
                BotonPestaña(titulo: "Solicitudes", seleccionada: $pestañaSeleccionada)
                BotonPestaña(titulo: "Historial", seleccionada: $pestañaSeleccionada)
            }.padding(.horizontal, 20).padding(.bottom, 20).onChange(of: pestañaSeleccionada) { _ in cargarDeFirestore() }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 15) {
                    if !estaActivo {
                        VStack { Spacer(); Image(systemName: "moon.zzz.fill").font(.system(size: 50)); Text("Estás inactivo").bold(); Spacer() }.foregroundColor(azulTexto).frame(height: 300)
                    } else {
                        ForEach(listaSolicitudes) { sol in
                            TarjetaSolicitud(solicitud: sol, profesionalID: idUsuario) { cargarDeFirestore() }
                        }
                    }
                }.padding(.horizontal, 20)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Image("FondoPrincipal").resizable().scaledToFill().ignoresSafeArea()).navigationBarBackButtonHidden(true).onAppear { cargarDeFirestore() }
    }
    
    func cargarDeFirestore() {
        let db = Firestore.firestore()
        let query = pestañaSeleccionada == "Solicitudes" ?
            db.collection("solicitudes").whereField("estado", isEqualTo: "pendiente") :
            db.collection("solicitudes").whereField("profesional_id", isEqualTo: idUsuario)
        
        query.addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            self.listaSolicitudes = docs.compactMap { d -> ModeloSolicitud? in
                let data = d.data()
                return ModeloSolicitud(id: d.documentID, categoria: data["categoria"] as? String, descripcion: data["descripcion"] as? String, ubicacion: data["ubicacion"] as? String, foto: data["foto"] as? String, estado: data["estado"] as? String, cliente: nil)
            }
        }
    }
}

struct TarjetaSolicitud: View {
    var solicitud: ModeloSolicitud
    var profesionalID: String
    var alAceptar: () -> Void
    let azulTexto = Color(red: 0, green: 0.38, blue: 0.66)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(solicitud.categoria ?? "Servicio").bold().foregroundColor(azulTexto)
            Divider()
            if let foto = solicitud.foto, !foto.isEmpty { ImagenBase64(base64String: foto) }
            Text(solicitud.descripcion ?? "").font(.subheadline)
            
            HStack(spacing: 15) {
                if solicitud.estado == "pendiente" || solicitud.estado == nil {
                    Button(action: { actualizarEstado("aceptado") }) { HStack { Image(systemName: "checkmark.circle.fill"); Text("Aceptar") }.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.green).foregroundColor(.white).cornerRadius(10) }.buttonStyle(BorderlessButtonStyle())
                } else if solicitud.estado == "aceptado" {
                    Button(action: { actualizarEstado("completado") }) { HStack { Image(systemName: "flag.checkered.circle.fill"); Text("Terminar") }.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.orange).foregroundColor(.white).cornerRadius(10) }.buttonStyle(BorderlessButtonStyle())
                } else {
                    HStack { Image(systemName: "checkmark.seal.fill"); Text("Terminado") }.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.gray.opacity(0.8)).foregroundColor(.white).cornerRadius(10)
                }
            }.padding(.top, 10)
        }.padding().background(Color.white).cornerRadius(15).shadow(radius: 3)
    }
    
    func actualizarEstado(_ nuevo: String) {
        let db = Firestore.firestore()
        db.collection("solicitudes").document(solicitud.id ?? "").updateData(["estado": nuevo, "profesional_id": profesionalID]) { _ in alAceptar() }
    }
}
