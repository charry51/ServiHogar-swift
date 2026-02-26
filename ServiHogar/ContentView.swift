import SwiftUI
import PhotosUI

// ==========================================
// 1. MODELOS DE DATOS (Compartidos para toda la app)
// ==========================================
struct ModeloSolicitud: Codable, Identifiable {
    let id: Int
    let categoria, descripcion, ubicacion, foto, estado: String?
    let cliente: DatosUsuario?
}

struct RespuestaLogin: Codable {
    let user: DatosUsuario?
}

struct DatosUsuario: Codable {
    let id: Int?
    let role, name, telefono, foto, domicilio: String?
}

// ==========================================
// 2. PANTALLA DE LOGIN (Punto de entrada)
// ==========================================
struct ContentView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    let azulTexto = Color(red: 0, green: 0.38, blue: 0.66)
    
    @State private var mensajeError: String = ""
    @State private var navegarCliente: Bool = false
    @State private var navegarProfesional: Bool = false
    
    @State private var nombreUsuario: String = ""
    @State private var idUsuario: Int = 0
    @State private var fotoUsuario: String = ""
    @State private var telefonoUsuario: String = ""
    @State private var domicilioUsuario: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer(); Spacer(); Spacer()
                
                CampoFormulario(titulo: "Correo electrónico", texto: $email, colorTexto: .white).padding(.top, 80)
                CampoPassword(titulo: "Contraseña", texto: $password, colorTexto: .white).padding(.bottom, 10)
                
                if !mensajeError.isEmpty {
                    Text(mensajeError).foregroundColor(.red).font(.system(size: 14, weight: .bold))
                }
                
                Button(action: hacerLogin) {
                    Text("Enviar").font(.system(size: 18, weight: .bold)).foregroundColor(azulTexto)
                        .frame(width: 160, height: 45).background(Color.white).cornerRadius(25).shadow(radius: 5)
                }
                .padding(.top, 10)
                Spacer()
                
                NavigationLink(destination: BienvenidoView()) {
                    Text("Registrarme").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                }.padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Image("FondoLogin").resizable().scaledToFill().ignoresSafeArea())
            // NAVEGACIÓN HACIA LOS ARCHIVOS INDEPENDIENTES
            .navigationDestination(isPresented: $navegarCliente) {
                HomeClienteView(nombreUsuario: $nombreUsuario, idUsuario: idUsuario, fotoUsuario: $fotoUsuario, telefonoUsuario: $telefonoUsuario, domicilioUsuario: $domicilioUsuario, alCerrarSesion: { navegarCliente = false; resetearApp() })
            }
            .navigationDestination(isPresented: $navegarProfesional) {
                HomeProfesionalView(nombreUsuario: $nombreUsuario, idUsuario: idUsuario, fotoUsuario: $fotoUsuario, telefonoUsuario: $telefonoUsuario, domicilioUsuario: $domicilioUsuario, alCerrarSesion: { navegarProfesional = false; resetearApp() })
            }
        }
    }
    
    func resetearApp() {
        email = ""; password = ""; nombreUsuario = ""; idUsuario = 0; fotoUsuario = ""; telefonoUsuario = ""; domicilioUsuario = ""
    }
    
    func hacerLogin() {
        guard let url = URL(string: "http://127.0.0.1:8000/api/login") else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let bodyDatos = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyDatos)
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            DispatchQueue.main.async {
                if let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if let resultado = try? JSONDecoder().decode(RespuestaLogin.self, from: data) {
                        self.nombreUsuario = resultado.user?.name ?? "Usuario"
                        self.idUsuario = resultado.user?.id ?? 0
                        self.fotoUsuario = resultado.user?.foto ?? ""
                        self.telefonoUsuario = resultado.user?.telefono ?? ""
                        self.domicilioUsuario = resultado.user?.domicilio ?? ""
                        if resultado.user?.role == "cliente" { self.navegarCliente = true }
                        else { self.navegarProfesional = true }
                    }
                } else { self.mensajeError = "Credenciales incorrectas" }
            }
        }.resume()
    }
}

// ==========================================
// 3. VISTAS DE REGISTRO
// ==========================================
struct BienvenidoView: View {
    let azulTexto = Color(red: 0, green: 0.38, blue: 0.66)
    var body: some View {
        VStack(spacing: 40) {
            Text("¡ Bienvenido !").font(.system(size: 28, weight: .bold)).foregroundColor(azulTexto).padding(.top, 60)
            NavigationLink(destination: RegistroClienteView()) {
                Text("Cliente").font(.system(size: 18, weight: .bold)).foregroundColor(azulTexto).frame(width: 200, height: 50).background(Color.white).cornerRadius(25).shadow(radius: 5)
            }
            NavigationLink(destination: RegistroProfesionalView()) {
                Text("Trabajador").font(.system(size: 18, weight: .bold)).foregroundColor(azulTexto).frame(width: 200, height: 50).background(Color.white).cornerRadius(25).shadow(radius: 5)
            }
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Image("FondoPrincipal").resizable().scaledToFill().ignoresSafeArea())
    }
}

struct RegistroClienteView: View {
    let azulTexto = Color(red: 0, green: 0.38, blue: 0.66)
    @State private var nombre = ""; @State private var dni = ""; @State private var domicilio = ""; @State private var telefono = ""
    var body: some View {
        VStack(spacing: 15) {
            Text("Registro Cliente").font(.title2.bold()).foregroundColor(azulTexto).padding(.top, 20)
            CampoFormulario(titulo: "Nombre y Apellidos", texto: $nombre, colorTexto: azulTexto)
            CampoFormulario(titulo: "DNI", texto: $dni, colorTexto: azulTexto)
            CampoFormulario(titulo: "Domicilio", texto: $domicilio, colorTexto: azulTexto)
            CampoFormulario(titulo: "Teléfono", texto: $telefono, colorTexto: azulTexto)
            Spacer()
            NavigationLink(destination: RegistroClientePaso2View(nombre: nombre, dni: dni, domicilio: domicilio, telefono: telefono)) {
                Text("Siguiente >").bold().foregroundColor(azulTexto).frame(width: 140, height: 45).background(Color.white).cornerRadius(25).shadow(radius: 5)
            }.padding(.bottom, 40)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Image("FondoPrincipal").resizable().scaledToFill().ignoresSafeArea())
    }
}

struct RegistroClientePaso2View: View {
    var nombre, dni, domicilio, telefono: String
    @State private var email = ""; @State private var pass = ""; @State private var exito = false
    var body: some View {
        VStack(spacing: 15) {
            Text("Datos de Acceso").font(.title2.bold()).foregroundColor(Color(red: 0, green: 0.38, blue: 0.66)).padding(.top, 20)
            CampoFormulario(titulo: "Email", texto: $email, colorTexto: Color(red: 0, green: 0.38, blue: 0.66))
            CampoPassword(titulo: "Contraseña", texto: $pass, colorTexto: Color(red: 0, green: 0.38, blue: 0.66))
            Spacer()
            Button(action: registrar) {
                Text("Finalizar").bold().foregroundColor(.white).frame(width: 160, height: 45).background(Color(red: 0, green: 0.38, blue: 0.66)).cornerRadius(25)
            }.padding(.bottom, 40)
            .navigationDestination(isPresented: $exito) { ContentView().navigationBarBackButtonHidden(true) }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Image("FondoPrincipal").resizable().scaledToFill().ignoresSafeArea())
    }
    func registrar() {
        guard let url = URL(string: "http://127.0.0.1:8000/api/register") else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["name": nombre, "email": email, "password": pass, "role": "cliente", "dni": dni, "telefono": telefono, "domicilio": domicilio]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body); URLSession.shared.dataTask(with: request) { _, resp, _ in if (resp as? HTTPURLResponse)?.statusCode == 201 { DispatchQueue.main.async { exito = true }} }.resume()
    }
}

struct RegistroProfesionalView: View {
    let azulTexto = Color(red: 0, green: 0.38, blue: 0.66)
    @State private var nombre = ""; @State private var dni = ""; @State private var telefono = ""; @State private var profs: Set<String> = []
    let lista = ["Fontanero", "Electricista", "Carpintero", "Limpieza", "Pintor"]
    var body: some View {
        VStack(spacing: 12) {
            Text("Registro Trabajador").font(.title2.bold()).foregroundColor(azulTexto).padding(.top, 10)
            CampoFormulario(titulo: "Nombre", texto: $nombre, colorTexto: azulTexto)
            CampoFormulario(titulo: "DNI", texto: $dni, colorTexto: azulTexto)
            CampoFormulario(titulo: "Teléfono", texto: $telefono, colorTexto: azulTexto)
            Text("Oficios:").font(.caption.bold()).foregroundColor(azulTexto)
            LazyVGrid(columns: [GridItem(), GridItem()]) {
                ForEach(lista, id:\.self) { p in
                    Button(action: { if profs.contains(p) { profs.remove(p) } else { profs.insert(p) }}) {
                        HStack { Image(systemName: profs.contains(p) ? "checkmark.circle.fill" : "circle"); Text(p) }.foregroundColor(azulTexto)
                    }
                }
            }.padding(.horizontal)
            Spacer()
            NavigationLink(destination: RegistroProfesionalPaso2View(nombre: nombre, dni: dni, telefono: telefono, profesiones: Array(profs))) {
                Text("Siguiente").bold().foregroundColor(azulTexto).frame(width: 140, height: 45).background(Color.white).cornerRadius(25).shadow(radius: 5)
            }.padding(.bottom, 30)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Image("FondoPrincipal").resizable().scaledToFill().ignoresSafeArea())
    }
}

struct RegistroProfesionalPaso2View: View {
    var nombre, dni, telefono: String; var profesiones: [String]
    @State private var email = ""; @State private var pass = ""; @State private var exito = false
    var body: some View {
        VStack(spacing: 15) {
            Text("Datos de Acceso").bold().foregroundColor(Color(red: 0, green: 0.38, blue: 0.66))
            CampoFormulario(titulo: "Email", texto: $email, colorTexto: Color(red: 0, green: 0.38, blue: 0.66))
            CampoPassword(titulo: "Contraseña", texto: $pass, colorTexto: Color(red: 0, green: 0.38, blue: 0.66))
            Button("Registrarme") { registrar() }.buttonStyle(.borderedProminent).padding()
            .navigationDestination(isPresented: $exito) { ContentView().navigationBarBackButtonHidden(true) }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Image("FondoPrincipal").resizable().scaledToFill().ignoresSafeArea())
    }
    func registrar() {
        guard let url = URL(string: "http://127.0.0.1:8000/api/register") else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["name": nombre, "email": email, "password": pass, "role": "profesional", "dni": dni, "telefono": telefono, "profesiones": profesiones]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body); URLSession.shared.dataTask(with: request) { _, resp, _ in if (resp as? HTTPURLResponse)?.statusCode == 201 { DispatchQueue.main.async { exito = true }} }.resume()
    }
}

// ==========================================
// 4. COMPONENTES GLOBALES (Usados en toda la App)
// ==========================================
struct ImagenBase64: View {
    let base64String: String
    var body: some View {
        if let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters), let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage).resizable().scaledToFill().frame(height: 150).frame(maxWidth: .infinity).cornerRadius(12).clipped()
        }
    }
}

struct BotonPestaña: View {
    var titulo: String; @Binding var seleccionada: String
    var body: some View {
        Button(action: { seleccionada = titulo }) {
            Text(titulo).bold().foregroundColor(seleccionada == titulo ? Color(red: 0, green: 0.38, blue: 0.66) : .gray).frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.white).cornerRadius(25).shadow(radius: 2)
        }
    }
}

struct CampoFormulario: View {
    var titulo: String; @Binding var texto: String; var colorTexto: Color
    var body: some View {
        VStack(alignment: .leading) {
            Text(titulo).bold().foregroundColor(colorTexto); TextField("", text: $texto).padding(10).background(Color.white).cornerRadius(5).autocorrectionDisabled()
        }.padding(.horizontal, 40)
    }
}

struct CampoPassword: View {
    var titulo: String; @Binding var texto: String; var colorTexto: Color
    var body: some View {
        VStack(alignment: .leading) {
            Text(titulo).bold().foregroundColor(colorTexto); SecureField("", text: $texto).padding(10).background(Color.white).cornerRadius(5)
        }.padding(.horizontal, 40)
    }
}

struct ContentView_Previews: PreviewProvider { static var previews: some View { ContentView() } }
