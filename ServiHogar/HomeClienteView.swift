import SwiftUI
import PhotosUI

// ==========================================
// PANTALLA PRINCIPAL DEL CLIENTE
// ==========================================
struct HomeClienteView: View {
    @EnvironmentObject var session: UserSession
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // CABECERA
            HStack {
                Button(action: { session.logout() }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .bold()
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                Spacer()
                
                // NAVEGACIÓN AL PERFIL
                NavigationLink(destination: PerfilView()) {
                    ImagenPerfil(foto: session.foto)
                }
            }.padding(.horizontal, Theme.paddingHorizontal).padding(.top, 10).padding(.bottom, 20)
            
            // LISTA DE SERVICIOS
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    TarjetaServicio(tituloUI: "Fontanería", categoriaDB: "Fontanero", imagen: "FotoFontaneria")
                    TarjetaServicio(tituloUI: "Limpieza", categoriaDB: "Limpieza", imagen: "FotoLimpieza")
                    TarjetaServicio(tituloUI: "Electricidad", categoriaDB: "Electricista", imagen: "FotoElectricidad")
                    TarjetaServicio(tituloUI: "Carpintería", categoriaDB: "Carpintero", imagen: "FotoCarpinteria")
                }.padding(.horizontal, Theme.paddingHorizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Image(Theme.fondoPrincipal).resizable().scaledToFill().ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

// ==========================================
// TARJETA DE SERVICIO (Para el Cliente)
// ==========================================
struct TarjetaServicio: View {
    var tituloUI, categoriaDB, imagen: String
    
    var body: some View {
        NavigationLink(destination: CrearSolicitudView(categoriaUI: tituloUI, categoriaDB: categoriaDB)) {
            VStack(spacing: 0) {
                Image(imagen)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 110)
                    .clipped()
                
                Text(tituloUI)
                    .bold()
                    .foregroundColor(Theme.azulTexto)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
            }
            .cornerRadius(Theme.cornerRadiusTarjeta)
            .shadow(radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// ==========================================
// CREAR SOLICITUD (Solo lo usa el Cliente)
// ==========================================
struct CrearSolicitudView: View {
    @EnvironmentObject var session: UserSession
    var categoriaUI, categoriaDB: String
    @Environment(\.dismiss) var dismiss
    
    @State private var descripcion = ""
    @State private var ubicacion = ""
    @State private var fotoBase64 = ""
    @State private var imagenConvertida: Image? = nil
    @State private var fotoSeleccionada: PhotosPickerItem? = nil
    @State private var enviando = false
    
    @State private var mostrarAlerta = false
    @State private var mensajeAlerta = ""
    
    var body: some View {
        VStack {
            // ... (HStack and ScrollView unchanged)
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left").bold().foregroundColor(.white).frame(width: 40, height: 40).contentShape(Rectangle())
                }
                Spacer()
                Text("Pedir \(categoriaUI)").bold().foregroundColor(.white)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }.padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingElementos) {
                    TextField("Ubicación", text: $ubicacion)
                        .padding().background(Color.white).cornerRadius(Theme.cornerRadiusCampo)
                    
                    TextEditor(text: $descripcion)
                        .frame(height: 100).padding(5).background(Color.white).cornerRadius(Theme.cornerRadiusCampo)
                    
                    PhotosPicker(selection: $fotoSeleccionada, matching: .images) {
                        if let imagenConvertida {
                            imagenConvertida.resizable().scaledToFill().frame(height: 150).cornerRadius(Theme.cornerRadiusCampo)
                        } else {
                            Label("Subir Foto", systemImage: "camera")
                                .frame(maxWidth: .infinity).frame(height: 100).background(Color.white).cornerRadius(Theme.cornerRadiusCampo)
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
            
            Button(action: { Task { await enviar() } }) {
                if enviando {
                    ProgressView().tint(.white)
                } else {
                    Text("Enviar Solicitud").bold()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.azulBoton)
            .padding()
            .disabled(enviando)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Image(Theme.fondoPrincipal).resizable().scaledToFill().ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .alert(mensajeAlerta, isPresented: $mostrarAlerta) { Button("OK", role: .cancel) { } }
    }
    
    func enviar() async {
        enviando = true
        let body: [String: Any] = [
            "cliente_id": session.id,
            "categoria": categoriaDB,
            "descripcion": descripcion,
            "ubicacion": ubicacion,
            "foto": fotoBase64
        ]
        
        do {
            let exito = try await NetworkService.shared.performSimpleRequest(route: "/solicitudes", method: "POST", body: body)
            if exito {
                dismiss()
            } else {
                mensajeAlerta = "Error: El servidor rechazó la solicitud."
                mostrarAlerta = true
            }
        } catch {
            mensajeAlerta = "Error de conexión: \(error.localizedDescription)"
            mostrarAlerta = true
        }
        enviando = false
    }
}
