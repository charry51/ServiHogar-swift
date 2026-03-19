import Foundation

struct NetworkService {
    static let shared = NetworkService()
    
    struct Constants {
        // Cambiar por la IP local de tu servidor si pruebas en dispositivo real
        static let baseURL = "http://127.0.0.1:8000/api"
    }
    
    private init() {}
    
    func performRequest<T: Codable>(route: String, method: String = "GET", body: [String: Any]? = nil) async throws -> T {
        guard let url = URL(string: "\(Constants.baseURL)\(route)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // Helper para peticiones que no devuelven datos o cuyo éxito es solo el código de estado
    func performSimpleRequest(route: String, method: String = "POST", body: [String: Any]? = nil) async throws -> Bool {
        guard let url = URL(string: "\(Constants.baseURL)\(route)") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        return (200...299).contains(httpResponse?.statusCode ?? 0)
    }
}
