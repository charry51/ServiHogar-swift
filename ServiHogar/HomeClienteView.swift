import SwiftUI
import PhotosUI
import FirebaseFirestore

struct HomeClienteView: View {
    let azulTexto = Color(red: 0, green: 0.38, blue: 0.66)
    @Environment(\.dismiss) var dismiss
    
    @Binding var nombreUsuario: String
    var idUsuario: String // <--- String correcto
    @Binding var fotoUsuario: String
    @Binding var telefonoUsuario: String
    @Binding var domicilioUsuario: String
    var alCerrarSesion: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: alCerrarSesion) { Image(systemName: "rectangle.portrait.and.arrow.right").bold().foregroundColor(.white).frame(width: 40, height: 40).contentShape(Rectangle()) }
                Spacer()
                NavigationLink(destination: PerfilView(
                    nombre: nombreUsuario, id: idUsuario, fotoBase64: fotoUsuario, telefono: telefonoUsuario, domicilio: domicilioUsuario, esProfesional: false,
                    alCerrarSesion: { dismiss(); self.alCerrarSesion() },
                    alGuardar: { n, f, t, d, _ in self.nombreUsuario = n; self.fotoUsuario = f; self.telefonoUsuario = t; self.domicilioUsuario = d }
                )) {
                    ZStack {
                        if let data = Data(base64Encoded: fotoUsuario), let uiImage = UIImage(data: data) { Image(uiImage: uiImage).resizable().scaledToFill() }
                        else { Image(systemName: "person.crop.circle.fill").font(.title).foregroundColor(.white) }
                    }.frame(width: 40, height: 40).clipShape(Circle())
                }
            }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    TarjetaServicio(tituloUI: "Fontanería", categoriaDB: "Fontanero", imagen: "FotoFontaneria", idUsuario: idUsuario)
                    TarjetaServicio(tituloUI: "Limpieza", categoriaDB: "Limpieza", imagen: "FotoLimpieza", idUsuario: idUsuario)
                    TarjetaServicio(tituloUI: "Electricidad", categoriaDB: "Electricista", imagen: "FotoElectricidad", idUsuario: idUsuario)
                    TarjetaServicio(tituloUI: "Carpintería", categoriaDB: "Carpintero", imagen: "FotoCarpinteria", idUsuario: idUsuario)
                }.padding(.horizontal, 20)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Image("FondoPrincipal").resizable().scaledToFill().ignoresSafeArea()).navigationBarBackButtonHidden(true)
    }
}

struct TarjetaServicio: View {
    var tituloUI, categoriaDB, imagen: String
    var idUsuario: String
    var body: some View {
        NavigationLink(destination: CrearSolicitudView(categoriaUI: tituloUI, categoriaDB: categoriaDB, idUsuario: idUsuario)) {
            VStack(spacing: 0) {
                Image(imagen).resizable().scaledToFill().frame(height: 110).clipped()
                Text(tituloUI).bold().foregroundColor(Color(red: 0, green: 0.38, blue: 0.66)).padding(.vertical, 12).frame(maxWidth: .infinity).background(Color.white)
            }.cornerRadius(15).shadow(radius: 5)
        }.buttonStyle(PlainButtonStyle())
    }
}

struct CrearSolicitudView: View {
    var categoriaUI, categoriaDB: String
    var idUsuario: String
    @Environment(\.dismiss) var dismiss
    
    @State private var descripcion = ""
    @State private var ubicacion = ""
    @State private var fotoBase64 = ""
    @State private var imagenConvertida: Image? = nil
    @State private var fotoSeleccionada: PhotosPickerItem? = nil
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) { Image(systemName: "chevron.left").bold().foregroundColor(.white).frame(width: 40, height: 40) }
                Spacer(); Text("Pedir \(categoriaUI)").bold().foregroundColor(.white); Spacer()
                Color.clear.frame(width: 40, height: 40)
            }.padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    TextField("Ubicación", text: $ubicacion).padding().background(Color.white).cornerRadius(10)
                    TextEditor(text: $descripcion).frame(height: 100).padding(5).background(Color.white).cornerRadius(10)
                    PhotosPicker(selection: $fotoSeleccionada, matching: .images) {
                        if let imagenConvertida { imagenConvertida.resizable().scaledToFill().frame(height: 150).cornerRadius(10) }
                        else { Label("Subir Foto", systemImage: "camera").frame(maxWidth: .infinity).frame(height: 100).background(Color.white).cornerRadius(10) }
                    }.onChange(of: fotoSeleccionada) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                                imagenConvertida = Image(uiImage: uiImage); fotoBase64 = uiImage.jpegData(compressionQuality: 0.2)?.base64EncodedString() ?? ""
                            }
                        }
                    }
                }.padding()
            }
            Button("Enviar Solicitud") { enviarAFirebase() }.buttonStyle(.borderedProminent).padding()
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Image("FondoPrincipal").resizable().scaledToFill().ignoresSafeArea()).navigationBarBackButtonHidden(true)
    }
    
    func enviarAFirebase() {
        let db = Firestore.firestore()
        let datos: [String: Any] = ["cliente_id": idUsuario, "categoria": categoriaDB, "descripcion": descripcion, "ubicacion": ubicacion, "foto": fotoBase64, "estado": "pendiente", "fecha": Timestamp()]
        db.collection("solicitudes").addDocument(data: datos) { _ in dismiss() }
    }
}
