import SwiftUI
import PhotosUI

// ==========================================
// 1. PANTALLA DE LOGIN (Punto de entrada)
// ==========================================
struct ContentView: View {
    @EnvironmentObject var session: UserSession
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var mensajeError: String = ""
    @State private var cargando: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
                Spacer(); Spacer(); Spacer()
                
                CampoFormulario(titulo: "Correo electrónico", texto: $email, colorTexto: .white).padding(.top, 80)
                CampoPassword(titulo: "Contraseña", texto: $password, colorTexto: .white).padding(.bottom, 10)
                
                if !mensajeError.isEmpty {
                    Text(mensajeError).foregroundColor(.red).font(.system(size: 14, weight: .bold))
                }
                
                Button(action: { Task { await hacerLogin() } }) {
                    Group {
                        if cargando {
                            ProgressView().tint(Theme.azulTexto)
                        } else {
                            Text("Enviar")
                        }
                    }
                    .estiloBotonPrincipal()
                }
                .padding(.top, 10)
                .disabled(cargando)
                
                Spacer()
                
                NavigationLink(destination: BienvenidoView()) {
                    Text("Registrarme").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                }.padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Image(Theme.fondoLogin).resizable().scaledToFill().ignoresSafeArea())
    }
    
    func hacerLogin() async {
        cargando = true; mensajeError = ""
        do {
            let body = ["email": email, "password": password]
            let respuesta: RespuestaLogin = try await NetworkService.shared.performRequest(route: "/login", method: "POST", body: body)
            
            if let user = respuesta.user {
                session.login(user: user)
            } else {
                mensajeError = "No se pudo recuperar el usuario"
            }
        } catch {
            mensajeError = "Credenciales incorrectas o error de conexión"
        }
        cargando = false
    }
}

// ==========================================
// 2. VISTAS DE REGISTRO
// ==========================================
struct BienvenidoView: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("¡ Bienvenido !").font(.system(size: 28, weight: .bold)).foregroundColor(Theme.azulTexto).padding(.top, 60)
            NavigationLink(destination: RegistroClienteView()) {
                Text("Cliente").estiloBotonPrincipal(ancho: 200)
            }
            NavigationLink(destination: RegistroProfesionalView()) {
                Text("Trabajador").estiloBotonPrincipal(ancho: 200)
            }
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Image(Theme.fondoPrincipal).resizable().scaledToFill().ignoresSafeArea())
    }
}

struct RegistroClienteView: View {
    @State private var nombre = ""; @State private var dni = ""; @State private var domicilio = ""; @State private var telefono = ""
    var body: some View {
        VStack(spacing: 15) {
            Text("Registro Cliente").font(.title2.bold()).foregroundColor(Theme.azulTexto).padding(.top, 20)
            CampoFormulario(titulo: "Nombre y Apellidos", texto: $nombre, colorTexto: Theme.azulTexto)
            CampoFormulario(titulo: "DNI", texto: $dni, colorTexto: Theme.azulTexto)
            CampoFormulario(titulo: "Domicilio", texto: $domicilio, colorTexto: Theme.azulTexto)
            CampoFormulario(titulo: "Teléfono", texto: $telefono, colorTexto: Theme.azulTexto)
            Spacer()
            NavigationLink(destination: RegistroClientePaso2View(nombre: nombre, dni: dni, domicilio: domicilio, telefono: telefono)) {
                Text("Siguiente >").estiloBotonPrincipal(ancho: 160)
            }.padding(.bottom, 40)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Image(Theme.fondoPrincipal).resizable().scaledToFill().ignoresSafeArea())
    }
}

struct RegistroClientePaso2View: View {
    @EnvironmentObject var session: UserSession
    var nombre, dni, domicilio, telefono: String
    @State private var email = ""; @State private var pass = ""; @State private var cargando = false
    var body: some View {
        VStack(spacing: 15) {
            Text("Datos de Acceso").font(.title2.bold()).foregroundColor(Theme.azulTexto).padding(.top, 20)
            CampoFormulario(titulo: "Email", texto: $email, colorTexto: Theme.azulTexto)
            CampoPassword(titulo: "Contraseña", texto: $pass, colorTexto: Theme.azulTexto)
            Spacer()
            Button(action: { Task { await registrar() } }) {
                Group {
                    if cargando {
                        ProgressView().tint(.white)
                    } else {
                        Text("Finalizar")
                    }
                }
                .estiloBotonPrincipal(colorFondo: Theme.azulBoton, colorTexto: .white)
            }
            .padding(.bottom, 40)
            .disabled(cargando)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Image(Theme.fondoPrincipal).resizable().scaledToFill().ignoresSafeArea())
    }
    
    func registrar() async {
        cargando = true
        let body: [String: Any] = ["name": nombre, "email": email, "password": pass, "role": "cliente", "dni": dni, "telefono": telefono, "domicilio": domicilio]
        do {
            let _: RespuestaLogin = try await NetworkService.shared.performRequest(route: "/register", method: "POST", body: body)
            DispatchQueue.main.async { session.popToRoot() }
        } catch {
            print("Error en registro: \(error)")
        }
        cargando = false
    }
}

struct RegistroProfesionalView: View {
    @State private var nombre = ""; @State private var dni = ""; @State private var telefono = ""; @State private var profs: Set<String> = []
    let lista = ["Fontanero", "Electricista", "Carpintero", "Limpieza", "Pintor"]
    var body: some View {
        VStack(spacing: 12) {
            Text("Registro Trabajador").font(.title2.bold()).foregroundColor(Theme.azulTexto).padding(.top, 10)
            CampoFormulario(titulo: "Nombre", texto: $nombre, colorTexto: Theme.azulTexto)
            CampoFormulario(titulo: "DNI", texto: $dni, colorTexto: Theme.azulTexto)
            CampoFormulario(titulo: "Teléfono", texto: $telefono, colorTexto: Theme.azulTexto)
            Text("Oficios:").font(.caption.bold()).foregroundColor(Theme.azulTexto)
            LazyVGrid(columns: [GridItem(), GridItem()]) {
                ForEach(lista, id:\.self) { p in
                    Button(action: { if profs.contains(p) { profs.remove(p) } else { profs.insert(p) }}) {
                        HStack { Image(systemName: profs.contains(p) ? "checkmark.circle.fill" : "circle"); Text(p) }.foregroundColor(Theme.azulTexto)
                    }
                }
            }.padding(.horizontal)
            Spacer()
            NavigationLink(destination: RegistroProfesionalPaso2View(nombre: nombre, dni: dni, telefono: telefono, profesiones: Array(profs))) {
                Text("Siguiente").estiloBotonPrincipal(ancho: 160)
            }.padding(.bottom, 30)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Image(Theme.fondoPrincipal).resizable().scaledToFill().ignoresSafeArea())
    }
}

struct RegistroProfesionalPaso2View: View {
    @EnvironmentObject var session: UserSession
    var nombre, dni, telefono: String; var profesiones: [String]
    @State private var email = ""; @State private var pass = ""; @State private var cargando = false
    var body: some View {
        VStack(spacing: 15) {
            Text("Datos de Acceso").bold().foregroundColor(Theme.azulTexto)
            CampoFormulario(titulo: "Email", texto: $email, colorTexto: Theme.azulTexto)
            CampoPassword(titulo: "Contraseña", texto: $pass, colorTexto: Theme.azulTexto)
            Button(action: { Task { await registrar() } }) {
                Group {
                    if cargando {
                        ProgressView().tint(.white)
                    } else {
                        Text("Registrarme")
                    }
                }
                .estiloBotonPrincipal(colorFondo: Theme.azulBoton, colorTexto: .white)
            }
            .padding(.bottom, 40)
            .disabled(cargando)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Image(Theme.fondoPrincipal).resizable().scaledToFill().ignoresSafeArea())
    }
    
    func registrar() async {
        cargando = true
        let body: [String: Any] = ["name": nombre, "email": email, "password": pass, "role": "profesional", "dni": dni, "telefono": telefono, "profesiones": profesiones]
        do {
            let _: RespuestaLogin = try await NetworkService.shared.performRequest(route: "/register", method: "POST", body: body)
            DispatchQueue.main.async { session.popToRoot() }
        } catch {
            print("Error en registro: \(error)")
        }
        cargando = false
    }
}

// ==========================================
// 3. COMPONENTES GLOBALES (Usados en toda la App)
// ==========================================
struct ImagenPerfil: View {
    let foto: String
    var size: CGFloat = 50
    
    var body: some View {
        ZStack {
            if foto.hasPrefix("http") || foto.contains("storage/") {
                let fullURL = foto.hasPrefix("http") ? foto : "\(NetworkService.Constants.baseURL.replacingOccurrences(of: "/api", with: ""))/\(foto)"
                AsyncImage(url: URL(string: fullURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                }
            } else if let data = Data(base64Encoded: foto, options: .ignoreUnknownCharacters), let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill").resizable().foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .background(Circle().fill(Theme.azulTexto))
    }
}

struct ImagenBase64: View {
    let base64String: String
    var body: some View {
        if base64String.hasPrefix("http") || base64String.contains("storage/") {
            let fullURL = base64String.hasPrefix("http") ? base64String : "\(NetworkService.Constants.baseURL.replacingOccurrences(of: "/api", with: ""))/\(base64String)"
            AsyncImage(url: URL(string: fullURL)) { status in
                switch status {
                case .empty: ProgressView()
                case .success(let image): image.resizable().scaledToFill()
                case .failure: Image(systemName: "photo").foregroundColor(.gray)
                @unknown default: EmptyView()
                }
            }
            .frame(height: 150).frame(maxWidth: .infinity).cornerRadius(12).clipped()
        } else if let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters), let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage).resizable().scaledToFill().frame(height: 150).frame(maxWidth: .infinity).cornerRadius(12).clipped()
        }
    }
}

struct BotonPestaña: View {
    var titulo: String; @Binding var seleccionada: String
    var body: some View {
        Button(action: { seleccionada = titulo }) {
            Text(titulo).bold().foregroundColor(seleccionada == titulo ? Theme.azulTexto : .gray).frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.white).cornerRadius(Theme.cornerRadiusBoton).shadow(radius: 2)
        }
    }
}

struct CampoFormulario: View {
    var titulo: String; @Binding var texto: String; var colorTexto: Color
    var body: some View {
        VStack(alignment: .leading) {
            Text(titulo).bold().foregroundColor(colorTexto)
            TextField("", text: $texto)
                .padding(10)
                .background(Color.white)
                .cornerRadius(Theme.cornerRadiusCampo)
                .autocorrectionDisabled()
                .shadow(color: Color.black.opacity(0.05), radius: 2)
        }.padding(.horizontal, 40)
    }
}

struct CampoPassword: View {
    var titulo: String; @Binding var texto: String; var colorTexto: Color
    var body: some View {
        VStack(alignment: .leading) {
            Text(titulo).bold().foregroundColor(colorTexto)
            SecureField("", text: $texto)
                .padding(10)
                .background(Color.white)
                .cornerRadius(Theme.cornerRadiusCampo)
                .shadow(color: Color.black.opacity(0.05), radius: 2)
        }.padding(.horizontal, 40)
    }
}

struct EstiloBotonVisual: ViewModifier {
    var ancho: CGFloat
    var colorFondo: Color
    var colorTexto: Color
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(colorTexto)
            .frame(width: ancho, height: 45)
            .background(colorFondo)
            .cornerRadius(Theme.cornerRadiusBoton)
            .shadow(radius: 5)
    }
}

extension View {
    func estiloBotonPrincipal(ancho: CGFloat = 160, colorFondo: Color = .white, colorTexto: Color = Theme.azulTexto) -> some View {
        self.modifier(EstiloBotonVisual(ancho: ancho, colorFondo: colorFondo, colorTexto: colorTexto))
    }
}

struct ContentView_Previews: PreviewProvider { static var previews: some View { ContentView().environmentObject(UserSession()) } }
