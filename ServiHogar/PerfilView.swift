import SwiftUI
import PhotosUI

// ==========================================
// PANTALLA DE PERFIL (Cliente y Profesional)
// ==========================================
struct PerfilView: View {
    @EnvironmentObject var session: UserSession
    @Environment(\.dismiss) var dismiss
    
    @State private var nombre: String = ""
    @State private var fotoBase64: String = ""
    @State private var telefono: String = ""
    @State private var domicilio: String = ""
    @State private var password = ""
    @State private var fotoSeleccionada: PhotosPickerItem? = nil
    @State private var guardando = false
    @State private var profesiones: Set<String> = []
    @State private var mostrarAlerta = false
    @State private var mensajeAlerta = ""
    let listaOficios = ["Fontanero", "Electricista", "Carpintero", "Limpieza", "Pintor"]
    
    var body: some View {
        VStack(spacing: 0) {
            // ... (Cabecera unchanged)
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .bold()
                        .foregroundColor(Theme.azulTexto)
                        .frame(width: 40, height: 40)
                }
                Spacer()
                
                Text("Mi Perfil")
                    .font(.title2)
                    .bold()
                    .foregroundColor(Theme.azulTexto)
                
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, Theme.paddingHorizontal)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // --- FOTO DE PERFIL ---
                    ZStack(alignment: .bottomTrailing) {
                        ImagenPerfil(foto: fotoBase64, size: 120)
                            .shadow(radius: 5)
                        
                        PhotosPicker(selection: $fotoSeleccionada, matching: .images) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Theme.azulBoton)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .onChange(of: fotoSeleccionada) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                                    fotoBase64 = uiImage.jpegData(compressionQuality: 0.2)?.base64EncodedString() ?? ""
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // --- CAMPOS DE TEXTO ---
                    VStack(spacing: Theme.spacingElementos) {
                        CampoFormularioPerfil(titulo: "Nombre", texto: $nombre)
                        CampoFormularioPerfil(titulo: "Teléfono", texto: $telefono)
                        CampoFormularioPerfil(titulo: "Domicilio", texto: $domicilio)
                        
                        if session.role == "profesional" {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Mis Oficios").bold().foregroundColor(Theme.azulTexto)
                                LazyVGrid(columns: [GridItem(), GridItem()], spacing: 10) {
                                    ForEach(listaOficios, id: \.self) { oficio in
                                        Button(action: {
                                            if profesiones.contains(oficio) { profesiones.remove(oficio) }
                                            else { profesiones.insert(oficio) }
                                        }) {
                                            HStack {
                                                Image(systemName: profesiones.contains(oficio) ? "checkmark.circle.fill" : "circle")
                                                Text(oficio)
                                            }
                                            .foregroundColor(Theme.azulTexto)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(10)
                                            .background(Color.white)
                                            .cornerRadius(8)
                                            .shadow(radius: 1)
                                        }
                                    }
                                }
                            }
                        }
                        
                        CampoPasswordPerfil(titulo: "Nueva Contraseña (Opcional)", texto: $password)
                    }
                    .padding(.horizontal, Theme.paddingHorizontal)
                    
                }
            }
            
            // --- BOTÓN DE GUARDAR ---
            Button(action: { Task { await guardarCambios() } }) {
                if guardando {
                    ProgressView().tint(.white)
                } else {
                    Text("Guardar Cambios")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Theme.azulBoton)
            .cornerRadius(Theme.cornerRadiusBoton)
            .shadow(radius: 5)
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
            .padding(.top, 10)
            .disabled(guardando)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Image(Theme.fondoPrincipal).resizable().scaledToFill().ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .alert(mensajeAlerta, isPresented: $mostrarAlerta) { Button("OK", role: .cancel) { } }
        .onAppear {
            self.nombre = session.nombre
            self.fotoBase64 = session.foto
            self.telefono = session.telefono
            self.domicilio = session.domicilio
            self.profesiones = Set(session.profesiones)
        }
    }
    
    // --- FUNCIÓN GUARDAR ---
    func guardarCambios() async {
        guardando = true
        var body: [String: Any] = [
            "id": session.id,
            "name": nombre,
            "telefono": telefono,
            "domicilio": domicilio,
            "foto": fotoBase64
        ]
        
        if session.role == "profesional" {
            body["profesiones"] = Array(profesiones)
        }
        
        if !password.isEmpty { body["password"] = password }
        
        do {
            let exito = try await NetworkService.shared.performSimpleRequest(route: "/perfil/actualizar", method: "POST", body: body)
            if exito {
                session.updateProfile(name: nombre, foto: fotoBase64, telefono: telefono, domicilio: domicilio, profesiones: Array(profesiones))
                dismiss()
            } else {
                mensajeAlerta = "Error: El servidor no pudo actualizar el perfil."
                mostrarAlerta = true
            }
        } catch {
            mensajeAlerta = "Error de conexión: \(error.localizedDescription)"
            mostrarAlerta = true
        }
        guardando = false
    }
}

// ==========================================
// COMPONENTES DE CAJAS DE TEXTO PARA PERFIL
// ==========================================
struct CampoFormularioPerfil: View {
    var titulo: String
    @Binding var texto: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titulo).bold().foregroundColor(Theme.azulTexto)
            TextField("", text: $texto)
                .padding(12)
                .background(Color.white)
                .cornerRadius(Theme.cornerRadiusCampo)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        }
    }
}

struct CampoPasswordPerfil: View {
    var titulo: String
    @Binding var texto: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titulo).bold().foregroundColor(Theme.azulTexto)
            SecureField("Dejar en blanco para no cambiar", text: $texto)
                .padding(12)
                .background(Color.white)
                .cornerRadius(Theme.cornerRadiusCampo)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        }
    }
}
