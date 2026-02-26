import SwiftUI

// ==========================================
// PANTALLA PRINCIPAL DEL PROFESIONAL
// ==========================================
struct HomeProfesionalView: View {
    let azulTexto = Color(red: 0, green: 0.38, blue: 0.66)
    @Environment(\.dismiss) var dismiss
    
    @Binding var nombreUsuario: String
    var idUsuario: Int
    @Binding var fotoUsuario: String
    @Binding var telefonoUsuario: String
    @Binding var domicilioUsuario: String
    var alCerrarSesion: () -> Void
    
    @State private var estaActivo = true
    @State private var pestañaSeleccionada = "Solicitudes"
    @State private var listaSolicitudes: [ModeloSolicitud] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // CABECERA
            HStack(alignment: .top) {
                Button(action: alCerrarSesion) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .bold()
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text("Bienvenido").font(.system(size: 18, weight: .bold)).foregroundColor(azulTexto)
                    Text(nombreUsuario).font(.system(size: 24, weight: .bold)).foregroundColor(azulTexto)
                    Toggle(estaActivo ? "Activo" : "Inactivo", isOn: $estaActivo).labelsHidden().tint(.green)
                }
                
                // NAVEGACIÓN AL PERFIL
                NavigationLink(destination: PerfilView(
                    nombre: nombreUsuario,
                    id: idUsuario,
                    fotoBase64: fotoUsuario,
                    telefono: telefonoUsuario,
                    domicilio: domicilioUsuario,
                    esProfesional: true,
                    alCerrarSesion: { dismiss(); self.alCerrarSesion() },
                    alGuardar: { n, f, t, d, _ in
                        self.nombreUsuario = n
                        self.fotoUsuario = f
                        self.telefonoUsuario = t
                        self.domicilioUsuario = d
                    }
                )) {
                    ZStack {
                        if let data = Data(base64Encoded: fotoUsuario), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage).resizable().scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill").resizable().foregroundColor(.white)
                        }
                    }.frame(width: 50, height: 50).clipShape(Circle()).background(Circle().fill(azulTexto)).padding(.leading, 10)
                }
            }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 20)
            
            // PESTAÑAS (Solicitudes / Historial)
            HStack(spacing: 15) {
                BotonPestaña(titulo: "Solicitudes", seleccionada: $pestañaSeleccionada)
                BotonPestaña(titulo: "Historial", seleccionada: $pestañaSeleccionada)
            }.padding(.horizontal, 20).padding(.bottom, 20).onChange(of: pestañaSeleccionada) { _ in self.cargarTrabajos() }
            
            // LISTA DE TRABAJOS
            ScrollView(showsIndicators: false) {
                VStack(spacing: 15) {
                    if !estaActivo {
                        VStack {
                            Spacer()
                            Image(systemName: "moon.zzz.fill").font(.system(size: 50)).foregroundColor(azulTexto)
                            Text("Estás inactivo").bold().foregroundColor(azulTexto)
                            Spacer()
                        }.frame(height: 300)
                    } else {
                        ForEach(listaSolicitudes) { sol in
                            TarjetaSolicitud(solicitud: sol, profesionalID: idUsuario) { self.cargarTrabajos() }
                        }
                    }
                }.padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Image("FondoPrincipal").resizable().scaledToFill().ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear { self.cargarTrabajos() }
    }
    
    // CARGAR DATOS DESDE LARAVEL
    func cargarTrabajos() {
        let tipo = pestañaSeleccionada == "Solicitudes" ? "pendientes" : "historial"
        guard let url = URL(string: "http://127.0.0.1:8000/api/solicitudes/\(tipo)/\(idUsuario)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let decodificado = try? JSONDecoder().decode([ModeloSolicitud].self, from: data) {
                DispatchQueue.main.async { self.listaSolicitudes = decodificado }
            }
        }.resume()
    }
}

// ==========================================
// TARJETA DE SOLICITUD INDIVIDUAL (BOTONES GRANDES)
// ==========================================
struct TarjetaSolicitud: View {
    var solicitud: ModeloSolicitud
    var profesionalID: Int
    var alAceptar: () -> Void
    let azulTexto = Color(red: 0, green: 0.38, blue: 0.66)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(solicitud.cliente?.name ?? "Cliente").bold().foregroundColor(azulTexto)
                    Text(solicitud.categoria ?? "").font(.caption).foregroundColor(.gray)
                }
                Spacer()
            }
            
            Divider()
            if let foto = solicitud.foto, !foto.isEmpty { ImagenBase64(base64String: foto) }
            Text(solicitud.descripcion ?? "").font(.subheadline)
            if let ubi = solicitud.ubicacion { Label(ubi, systemImage: "mappin").font(.caption).foregroundColor(.gray) }
            
            // --- ZONA DE BOTONES GIGANTES ---
            HStack(spacing: 15) {
                
                // 1. BOTÓN LLAMAR (AZUL)
                if let tel = solicitud.cliente?.telefono {
                    let numeroLimpio = tel.replacingOccurrences(of: " ", with: "")
                    if let url = URL(string: "tel://\(numeroLimpio)") {
                        Button(action: {
                            if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
                        }) {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("Llamar")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .buttonStyle(BorderlessButtonStyle()) // Previene bloqueos táctiles
                    }
                }
                
                // LÓGICA DE ESTADOS (Los 3 pasos del trabajo)
                if solicitud.estado == "pendiente" || solicitud.estado == nil {
                    // PASO 1: BOTÓN ACEPTAR (VERDE)
                    Button(action: aceptar) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Aceptar")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(BorderlessButtonStyle()) // Previene bloqueos táctiles
                    
                } else if solicitud.estado == "aceptado" {
                    // PASO 2: BOTÓN TERMINAR TAREA (NARANJA)
                    Button(action: completar) {
                        HStack {
                            Image(systemName: "flag.checkered.circle.fill")
                            Text("Terminar")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(BorderlessButtonStyle()) // Previene bloqueos táctiles
                    
                } else {
                    // PASO 3: TRABAJO COMPLETADO (GRIS INACTIVO)
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Terminado")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.top, 10) // Un poco de espacio respecto a la descripción
            
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 3)
    }
    
    // --- FUNCIONES DE RED ---
    func aceptar() {
        guard let url = URL(string: "http://127.0.0.1:8000/api/solicitudes/aceptar") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["solicitud_id": solicitud.id, "profesional_id": profesionalID]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, resp, _ in
            if let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                DispatchQueue.main.async { alAceptar() }
            }
        }.resume()
    }
    
    func completar() {
        guard let url = URL(string: "http://127.0.0.1:8000/api/solicitudes/completar") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["solicitud_id": solicitud.id]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, resp, _ in
            if let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                DispatchQueue.main.async { alAceptar() }
            }
        }.resume()
    }
}
