import Foundation

// DEFINITION 1: FoodProduct (Angepasst für V3-JSON)
struct FoodProduct: Identifiable, Decodable {
    let id: Int // ID ist eine Zahl in v3
    let name: String
    let brand: String? // Brand ist in v3 oft nicht vorhanden, daher optional
    
    let energyKcalPer100g: Double?
    let fatPer100g: Double?
    let carbohydratesPer100g: Double?
    let proteinPer100g: Double?

    // Manueller Initializer für die #Preview (behebt Build-Fehler)
    init(id: Int, name: String, brand: String?, energyKcalPer100g: Double?, fatPer100g: Double?, carbohydratesPer100g: Double?, proteinPer100g: Double?) {
        self.id = id
        self.name = name
        self.brand = brand
        self.energyKcalPer100g = energyKcalPer100g
        self.fatPer100g = fatPer100g
        self.carbohydratesPer100g = carbohydratesPer100g
        self.proteinPer100g = proteinPer100g
    }
    
    // Keys für das Parsen der V3-API
    enum CodingKeys: String, CodingKey {
        case id, brand, nutrients
        case nameTranslations = "display_name_translations" // v3 verwendet 'display_name_translations'
    }
    
    enum NameKeys: String, CodingKey {
        case de // Wir wollen den deutschen Namen
    }

    enum NutrientsKeys: String, CodingKey {
        case energyCaloriesKcal = "energy_calories_kcal"
        case fat, carbohydrates, protein
    }
    
    enum ValueKeys: String, CodingKey {
        case perHundred = "per_hundred"
    }

    // Manueller Decoder für die V3-JSON-Struktur
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.brand = try? container.decodeIfPresent(String.self, forKey: .brand)
        
        // Namen auf Deutsch parsen
        if let nameContainer = try? container.nestedContainer(keyedBy: NameKeys.self, forKey: .nameTranslations) {
            self.name = (try? nameContainer.decode(String.self, forKey: .de)) ?? "Unbekannter Name"
        } else {
            self.name = "Unbekannter Name"
        }
        
        // Nährwerte parsen (aus dem v3-Beispiel)
        if let nutrientsContainer = try? container.nestedContainer(keyedBy: NutrientsKeys.self, forKey: .nutrients) {
            
            if let kcalContainer = try? nutrientsContainer.nestedContainer(keyedBy: ValueKeys.self, forKey: .energyCaloriesKcal) {
                self.energyKcalPer100g = try? kcalContainer.decodeIfPresent(Double.self, forKey: .perHundred)
            } else { self.energyKcalPer100g = nil }
            
            if let fatContainer = try? nutrientsContainer.nestedContainer(keyedBy: ValueKeys.self, forKey: .fat) {
                self.fatPer100g = try? fatContainer.decodeIfPresent(Double.self, forKey: .perHundred)
            } else { self.fatPer100g = nil }

            if let carbContainer = try? nutrientsContainer.nestedContainer(keyedBy: ValueKeys.self, forKey: .carbohydrates) {
                self.carbohydratesPer100g = try? carbContainer.decodeIfPresent(Double.self, forKey: .perHundred)
            } else { self.carbohydratesPer100g = nil }
            
            if let proteinContainer = try? nutrientsContainer.nestedContainer(keyedBy: ValueKeys.self, forKey: .protein) {
                self.proteinPer100g = try? proteinContainer.decodeIfPresent(Double.self, forKey: .perHundred)
            } else { self.proteinPer100g = nil }
            
        } else {
            self.energyKcalPer100g = nil
            self.fatPer100g = nil
            self.carbohydratesPer100g = nil
            self.proteinPer100g = nil
        }
    }
}

// DEFINITION 2: FoodRepoSearchResponse (Angepasst für V3)
// Die v3-API verpackt Suchergebnisse in einem "data"-Objekt
struct FoodRepoSearchResponse: Decodable {
    let data: [FoodProduct]
}

// DEFINITION 3: FoodRepoClient (Angepasst für V3)
final class FoodRepoClient {
    private let session: URLSession
    private let apiKey: String

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    // Suchfunktion für V3-API
    func searchProducts(query: String) async throws -> [FoodProduct] {
        // V3-Endpunkt für die Suche
        guard var components = URLComponents(string: "https://www.foodrepo.org/api/v3/products/_search") else { return [] }
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "10"),
            URLQueryItem(name: "lang", value: "de")
        ]
        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // V3 verwendet "Authorization: Token token=..."
        request.setValue("Token token=\(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "FoodRepoClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // V3 gibt ein "data"-Objekt zurück
        let wrapper = try decoder.decode(FoodRepoSearchResponse.self, from: data)
        return wrapper.data
    }

    // Barcode-Funktion für V3-API
    func getProductByBarcode(ean: String) async throws -> FoodProduct? {
        // V3-Endpunkt für Barcode
        guard let url = URL(string: "https://www.foodrepo.org/api/v3/products/barcode/\(ean)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Token token=\(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // V3 verpackt auch Barcode-Ergebnisse in "data"
        let wrapper = try decoder.decode(FoodRepoSearchResponse.self, from: data)
        return wrapper.data.first
    }
}
