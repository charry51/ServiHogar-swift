import SwiftUI

// ==========================================
// PANTALLA PRINCIPAL DEL PROFESIONAL
// ==========================================
struct HomeProfesionalView: View {
    @EnvironmentObject var session: UserSession
    @Environment(\.dismiss) var dismiss
    
    @State private var estaActivo = true
    @State private var pestañaSeleccionada = "Solicitudes"
    @State private var listaSolicitudes: [ModeloSolicitud] = []
    @State private var cargando = false
    
    var body: some View {
        VStack(spacing: 0) {
            // CABECERA
            HStack(alignment: .top) {
                Button(action: { session.logout() }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .bold()
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text("Bienvenido").font(.system(size: 18, weight: .bold)).foregroundColor(Theme.azulTexto)
                    Text(session.nombre).font(.system(size: 24, weight: .bold)).foregroundColor(Theme.azulTexto)
                    Toggle(estaActivo ? "Activo" : "Inactivo", isOn: $estaActivo).labelsHidden().tint(.green)
                }
                
                // NAVEGACIÓN AL PERFIL
                NavigationLink(destination: PerfilView()) {
                    ImagenPerfil(foto: session.foto)
                }
            }.padding(.horizontal, Theme.paddingHorizontal).padding(.top, 10).padding(.bottom, 20)
            
            // PESTAÑAS (Solicitudes / Historial)
            HStack(spacing: 15) {
                BotonPestaña(titulo: "Solicitudes", seleccionada: $pestañaSeleccionada)
                BotonPestaña(titulo: "Historial", seleccionada: $pestañaSeleccionada)
            }.padding(.horizontal, Theme.paddingHorizontal).padding(.bottom, 20).onChange(of: pestañaSeleccionada) { _ in Task { await cargarTrabajos() } }
            
            // LISTA DE TRABAJOS
            ScrollView(showsIndicators: false) {
                VStack(spacing: 15) {
                    if cargando {
                        ProgressView().tint(Theme.azulTexto).padding(.top, 50)
                    } else if !estaActivo {
                        VStack {
                            Spacer()
                            Image(systemName: "moon.zzz.fill").font(.system(size: 50)).foregroundColor(Theme.azulTexto)
                            Text("Estás inactivo").bold().foregroundColor(Theme.azulTexto)
                            Spacer()
                        }.frame(height: 300)
                    } else {
                        ForEach(listaSolicitudes) { sol in
                            TarjetaSolicitud(solicitud: sol) { Task { await cargarTrabajos() } }
                        }
                    }
                }.padding(.horizontal, Theme.paddingHorizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Image(Theme.fondoPrincipal).resizable().scaledToFill().ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear { Task { await cargarTrabajos() } }
    }
    
    // CARGAR DATOS DESDE LARAVEL
    func cargarTrabajos() async {
        cargando = true
        let tipo = pestañaSeleccionada == "Solicitudes" ? "pendientes" : "historial"
        let route = "/solicitudes/\(tipo)/\(session.id)"
        
        do {
            let decodificado: [ModeloSolicitud] = try await NetworkService.shared.performRequest(route: route)
            DispatchQueue.main.async {
                self.listaSolicitudes = decodificado
                self.cargando = false
            }
        } catch {
            print("Error cargando trabajos: \(error)")
            self.cargando = false
        }
    }
}

// ==========================================
// TARJETA DE SOLICITUD INDIVIDUAL (BOTONES GRANDES)
// ==========================================
struct TarjetaSolicitud: View {
    @EnvironmentObject var session: UserSession
    var solicitud: ModeloSolicitud
    var alAceptar: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(solicitud.cliente?.name ?? "Cliente").bold().foregroundColor(Theme.azulTexto)
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
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                
                // LÓGICA DE ESTADOS (Los 3 pasos del trabajo)
                if solicitud.estado == "pendiente" || solicitud.estado == nil {
                    // PASO 1: BOTÓN ACEPTAR (VERDE)
                    Button(action: { Task { await aceptar() } }) {
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
                    .buttonStyle(BorderlessButtonStyle())
                    
                } else if solicitud.estado == "aceptado" {
                    // PASO 2: BOTÓN TERMINAR TAREA (NARANJA)
                    Button(action: { Task { await completar() } }) {
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
                    .buttonStyle(BorderlessButtonStyle())
                    
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
            .padding(.top, 10)
            
        }
        .padding()
        .background(Color.white)
        .cornerRadius(Theme.cornerRadiusTarjeta)
        .shadow(radius: 3)
    }
    
    // --- FUNCIONES DE RED ---
    func aceptar() async {
        let body: [String: Any] = ["solicitud_id": solicitud.id, "profesional_id": session.id]
        do {
            let exito = try await NetworkService.shared.performSimpleRequest(route: "/solicitudes/aceptar", method: "POST", body: body)
            if exito {
                DispatchQueue.main.async { alAceptar() }
            }
        } catch {
            print("Error aceptando: \(error)")
        }
    }
    
    func completar() async {
        let body: [String: Any] = ["solicitud_id": solicitud.id]
        do {
            let exito = try await NetworkService.shared.performSimpleRequest(route: "/solicitudes/completar", method: "POST", body: body)
            if exito {
                DispatchQueue.main.async { alAceptar() }
            }
        } catch {
            print("Error completando: \(error)")
        }
    }
}
