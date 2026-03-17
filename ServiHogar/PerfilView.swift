import SwiftUI
import PhotosUI
import FirebaseFirestore

struct PerfilView: View {
    @Environment(\.dismiss) var dismiss
    let azulTexto = Color(red: 0, green: 0.38, blue: 0.66)
    
    @State var nombre: String
    var id: String // <--- String correcto
    @State var fotoBase64: String
    @State var telefono: String
    @State var domicilio: String
    var esProfesional: Bool
    
    var alCerrarSesion: () -> Void
    var alGuardar: (String, String, String, String, String) -> Void
    
    @State private var password = ""
    @State private var fotoSeleccionada: PhotosPickerItem? = nil
    @State private var mostrandoAlerta = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) { Image(systemName: "chevron.left").font(.title2).bold().foregroundColor(azulTexto).frame(width: 40, height: 40) }
                Spacer(); Text("Mi Perfil").font(.title2).bold().foregroundColor(azulTexto); Spacer(); Color.clear.frame(width: 40, height: 40)
            }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ZStack(alignment: .bottomTrailing) {
                        if let data = Data(base64Encoded: fotoBase64), let uiImage = UIImage(data: data) { Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 120, height: 120).clipShape(Circle()).shadow(radius: 5) }
                        else { Image(systemName: "person.crop.circle.fill").resizable().foregroundColor(azulTexto.opacity(0.8)).frame(width: 120, height: 120).background(Circle().fill(Color.white)).shadow(radius: 5) }
                        
                        PhotosPicker(selection: $fotoSeleccionada, matching: .images) { Image(systemName: "camera.fill").font(.system(size: 20)).foregroundColor(.white).padding(10).background(azulTexto).clipShape(Circle()).shadow(radius: 3) }
                        .onChange(of: fotoSeleccionada) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) { fotoBase64 = uiImage.jpegData(compressionQuality: 0.2)?.base64EncodedString() ?? "" }
                            }
                        }
                    }.padding(.top, 20).padding(.bottom, 10)
                    
                    VStack(spacing: 15) {
                        CampoFormularioPerfil(titulo: "Nombre", texto: $nombre, colorTexto: azulTexto)
                        CampoFormularioPerfil(titulo: "Teléfono", texto: $telefono, colorTexto: azulTexto)
                        CampoFormularioPerfil(titulo: "Domicilio", texto: $domicilio, colorTexto: azulTexto)
                    }.padding(.horizontal, 20)
                }
            }
            
            Button(action: guardarEnFirebase) { Text("Guardar Cambios").font(.system(size: 18, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 50).background(azulTexto).cornerRadius(25).shadow(radius: 5) }
            .padding(.horizontal, 40).padding(.bottom, 30).padding(.top, 10)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Image("FondoPrincipal").resizable().scaledToFill().ignoresSafeArea()).navigationBarBackButtonHidden(true)
        .alert("Perfil Actualizado", isPresented: $mostrandoAlerta) { Button("OK") { dismiss() } }
    }
    
    func guardarEnFirebase() {
        let db = Firestore.firestore()
        db.collection("usuarios").document(id).updateData(["name": nombre, "telefono": telefono, "domicilio": domicilio, "foto": fotoBase64]) { _ in
            alGuardar(nombre, fotoBase64, telefono, domicilio, "")
            mostrandoAlerta = true
        }
    }
}

struct CampoFormularioPerfil: View {
    var titulo: String; @Binding var texto: String; var colorTexto: Color
    var body: some View { VStack(alignment: .leading, spacing: 5) { Text(titulo).bold().foregroundColor(colorTexto); TextField("", text: $texto).padding(12).background(Color.white).cornerRadius(10).shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2) } }
}
