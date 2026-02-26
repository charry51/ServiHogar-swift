import SwiftUI
import PhotosUI

// ==========================================
// PANTALLA PRINCIPAL DEL CLIENTE
// ==========================================
struct HomeClienteView: View {
    let azulTexto = Color(red: 0, green: 0.38, blue: 0.66)
    @Environment(\.dismiss) var dismiss
    
    @Binding var nombreUsuario: String
    var idUsuario: Int
    @Binding var fotoUsuario: String
    @Binding var telefonoUsuario: String
    @Binding var domicilioUsuario: String
    var alCerrarSesion: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // CABECERA
            HStack {
                Button(action: alCerrarSesion) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .bold()
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle()) // Área táctil mejorada
                }
                Spacer()
                
                NavigationLink(destination: PerfilView(
                    nombre: nombreUsuario, id: idUsuario, fotoBase64: fotoUsuario, telefono: telefonoUsuario, domicilio: domicilioUsuario, esProfesional: false,
                    alCerrarSesion: { dismiss(); self.alCerrarSesion() },
                    alGuardar: { n, f, t, d, _ in self.nombreUsuario = n; self.fotoUsuario = f; self.telefonoUsuario = t; self.domicilioUsuario = d }
                )) {
                    ZStack {
                        if let data = Data(base64Encoded: fotoUsuario), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage).resizable().scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill").font(.title).foregroundColor(.white)
                        }
                    }.frame(width: 40, height: 40).clipShape(Circle())
                }
            }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 20)
            
            // LISTA DE SERVICIOS
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    TarjetaServicio(tituloUI: "Fontanería", categoriaDB: "Fontanero", imagen: "FotoFontaneria", idUsuario: idUsuario)
                    TarjetaServicio(tituloUI: "Limpieza", categoriaDB: "Limpieza", imagen: "FotoLimpieza", idUsuario: idUsuario)
                    TarjetaServicio(tituloUI: "Electricidad", categoriaDB: "Electricista", imagen: "FotoElectricidad", idUsuario: idUsuario)
                    TarjetaServicio(tituloUI: "Carpintería", categoriaDB: "Carpintero", imagen: "FotoCarpinteria", idUsuario: idUsuario)
                }.padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Image("FondoPrincipal").resizable().scaledToFill().ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

// ==========================================
// TARJETA DE SERVICIO (Para el Cliente)
// ==========================================
struct TarjetaServicio: View {
    var tituloUI, categoriaDB, imagen: String
    var idUsuario: Int
    
    var body: some View {
        NavigationLink(destination: CrearSolicitudView(categoriaUI: tituloUI, categoriaDB: categoriaDB, idUsuario: idUsuario)) {
            VStack(spacing: 0) {
                Image(imagen)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 110)
                    .clipped()
                
                Text(tituloUI)
                    .bold()
                    .foregroundColor(Color(red: 0, green: 0.38, blue: 0.66))
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
            }
            .cornerRadius(15)
            .shadow(radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// ==========================================
// CREAR SOLICITUD (Solo lo usa el Cliente)
// ==========================================
struct CrearSolicitudView: View {
    var categoriaUI, categoriaDB: String
    var idUsuario: Int
    @Environment(\.dismiss) var dismiss
    
    @State private var descripcion = ""
    @State private var ubicacion = ""
    @State private var fotoBase64 = ""
    @State private var imagenConvertida: Image? = nil
    @State private var fotoSeleccionada: PhotosPickerItem? = nil
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left").bold().foregroundColor(.white).frame(width: 40, height: 40).contentShape(Rectangle())
                }
                Spacer()
                Text("Pedir \(categoriaUI)").bold().foregroundColor(.white)
                Spacer()
                // Espacio vacío para equilibrar la cabecera
                Color.clear.frame(width: 40, height: 40)
            }.padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    TextField("Ubicación", text: $ubicacion)
                        .padding().background(Color.white).cornerRadius(10)
                    
                    TextEditor(text: $descripcion)
                        .frame(height: 100).padding(5).background(Color.white).cornerRadius(10)
                    
                    PhotosPicker(selection: $fotoSeleccionada, matching: .images) {
                        if let imagenConvertida {
                            imagenConvertida.resizable().scaledToFill().frame(height: 150).cornerRadius(10)
                        } else {
                            Label("Subir Foto", systemImage: "camera")
                                .frame(maxWidth: .infinity).frame(height: 100).background(Color.white).cornerRadius(10)
                        }
                    }
                    .onChange(of: fotoSeleccionada) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                                imagenConvertida = Image(uiImage: uiImage)
                                fotoBase64 = uiImage.jpegData(compressionQuality: 0.2)?.base64EncodedString() ?? ""
                            }
                        }
                    }
                }.padding()
            }
            Button("Enviar Solicitud") { enviar() }.buttonStyle(.borderedProminent).padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Image("FondoPrincipal").resizable().scaledToFill().ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
    
    func enviar() {
        guard let url = URL(string: "http://127.0.0.1:8000/api/solicitudes") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["cliente_id": idUsuario, "categoria": categoriaDB, "descripcion": descripcion, "ubicacion": ubicacion, "foto": fotoBase64]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, resp, _ in
            if let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                DispatchQueue.main.async { dismiss() }
            }
        }.resume()
    }
}
