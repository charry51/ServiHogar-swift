import SwiftUI
import PhotosUI

// ==========================================
// PANTALLA DE PERFIL (Cliente y Profesional)
// ==========================================
struct PerfilView: View {
    @Environment(\.dismiss) var dismiss
    
    // Aquí definimos tu azul corporativo
    let azulTexto = Color(red: 0, green: 0.38, blue: 0.66)
    
    @State var nombre: String
    var id: Int
    @State var fotoBase64: String
    @State var telefono: String
    @State var domicilio: String
    var esProfesional: Bool
    
    var alCerrarSesion: () -> Void
    var alGuardar: (String, String, String, String, String) -> Void
    
    @State private var password = ""
    @State private var fotoSeleccionada: PhotosPickerItem? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // --- CABECERA (Ahora en color Azul) ---
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .bold()
                        .foregroundColor(azulTexto) // Flecha azul
                        .frame(width: 40, height: 40)
                }
                Spacer()
                
                Text("Mi Perfil")
                    .font(.title2)
                    .bold()
                    .foregroundColor(azulTexto) // Letras de arriba en azul
                
                Spacer()
                // Espacio invisible para centrar el texto exactamente en medio
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // --- FOTO DE PERFIL ---
                    ZStack(alignment: .bottomTrailing) {
                        if let data = Data(base64Encoded: fotoBase64, options: .ignoreUnknownCharacters), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundColor(azulTexto.opacity(0.8))
                                .frame(width: 120, height: 120)
                                .background(Circle().fill(Color.white))
                                .shadow(radius: 5)
                        }
                        
                        // Botón para cambiar foto
                        PhotosPicker(selection: $fotoSeleccionada, matching: .images) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(azulTexto)
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
                    VStack(spacing: 15) {
                        CampoFormularioPerfil(titulo: "Nombre", texto: $nombre, colorTexto: azulTexto)
                        CampoFormularioPerfil(titulo: "Teléfono", texto: $telefono, colorTexto: azulTexto)
                        CampoFormularioPerfil(titulo: "Domicilio", texto: $domicilio, colorTexto: azulTexto)
                        CampoPasswordPerfil(titulo: "Nueva Contraseña (Opcional)", texto: $password, colorTexto: azulTexto)
                    }
                    .padding(.horizontal, 20)
                    
                }
            }
            
            // --- BOTÓN DE GUARDAR (Ahora en color Azul) ---
            Button(action: guardarCambios) {
                Text("Guardar Cambios")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white) // Letras blancas
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(azulTexto) // Fondo del botón Azul
                    .cornerRadius(25)
                    .shadow(radius: 5)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Image("FondoPrincipal").resizable().scaledToFill().ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
    
    // --- FUNCIÓN GUARDAR ---
    func guardarCambios() {
        guard let url = URL(string: "http://127.0.0.1:8000/api/perfil/actualizar") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "id": id,
            "name": nombre,
            "telefono": telefono,
            "domicilio": domicilio,
            "foto": fotoBase64
        ]
        
        // Solo enviamos la contraseña si ha escrito una nueva
        if !password.isEmpty {
            body["password"] = password
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, resp, _ in
            if let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                DispatchQueue.main.async {
                    // Actualizamos los datos en la pantalla anterior y cerramos
                    alGuardar(nombre, fotoBase64, telefono, domicilio, password)
                    dismiss()
                }
            }
        }.resume()
    }
}

// ==========================================
// COMPONENTES DE CAJAS DE TEXTO PARA PERFIL
// ==========================================
struct CampoFormularioPerfil: View {
    var titulo: String
    @Binding var texto: String
    var colorTexto: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titulo).bold().foregroundColor(colorTexto)
            TextField("", text: $texto)
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        }
    }
}

struct CampoPasswordPerfil: View {
    var titulo: String
    @Binding var texto: String
    var colorTexto: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titulo).bold().foregroundColor(colorTexto)
            SecureField("Dejar en blanco para no cambiar", text: $texto)
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        }
    }
}
