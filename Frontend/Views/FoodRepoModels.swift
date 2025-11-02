import Foundation

// MARK: - API Client

struct ProductAPI {
    
    /// Ruft eine generische URL ab und dekodiert die erwartete Antwort.
    func fetchProduct(from url: URL, headers: [String: String]) async throws -> ProductResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Füge alle Header zur Anfrage hinzu
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Ungültige Antwort oder Statuscode vom Server")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        // Die API verwendet snake_case (z.B. api_version, display_name_translations)
        // .convertFromSnakeCase wandelt dies in Swift-camelCase (z.B. apiVersion) um
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(ProductResponse.self, from: data)
    }
}

// MARK: - Datenmodelle für FoodRepo API

// Das Haupt-Antwortobjekt der API
struct ProductResponse: Decodable {
    let data: Product
    let meta: Meta
}

// Die Meta-Informationen der API-Antwort
struct Meta: Decodable {
    let apiVersion: String
}

// Das Produkt-Modell.
// Enthält alle Felder, die sowohl von `fetchFoodRepoSample` als auch vom Barcode-Scanner verwendet werden.
struct Product: Decodable, Identifiable {
    let id: Int
    let barcode: String?
    let name: String // Wird vom Barcode-Scanner verwendet
    let brand: String? // Wird vom Barcode-Scanner verwendet
    
    // Für `fetchFoodRepoSample`
    let displayNameTranslations: [String: String]
    let nameTranslations: [String: String]
    let ingredientsTranslations: [String: String]
    let nutrients: Nutrients
    let images: [ProductImage]
    
    // Vom Barcode-Scanner verwendetes, vereinfachtes Feld.
    // Die API liefert dies möglicherweise auf der obersten Ebene ODER in `nutrients`.
    // Wir verwenden ein optionales Feld, um beide Fälle abzudecken.
    let energyKcalPer100g: Double?
}

// Die Nährwert-Struktur (verschachtelt im Produkt)
struct Nutrients: Decodable {
    let energyCaloriesKcal: NutrientValue
}

// Der Nährwert (verschachtelt in Nutrients)
struct NutrientValue: Decodable {
    let perHundred: Double?
}

// Die Bild-Struktur (verschachtelt im Produkt)
// Wir brauchen keine Details, nur damit es dekodiert werden kann.
struct ProductImage: Decodable, Hashable {}
