import Foundation

// DEFINITION 1: FoodProduct
struct FoodProduct: Identifiable, Decodable {
    let id: String
    let name: String
    let brand: String?
    
    let energyKcalPer100g: Double?
    let fatPer100g: Double?
    let carbohydratesPer100g: Double?
    let proteinPer100g: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, brand, nutrients
    }

    enum NutrientsKeys: String, CodingKey {
        case energyKcal = "energy_calories_kcal"
        case fat, carbohydrates, protein
    }
    
    enum ValueKeys: String, CodingKey {
        case perHundred = "per_hundred"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Unbekannt"
        self.brand = try? container.decodeIfPresent(String.self, forKey: .brand)
        
        if let nutrientsContainer = try? container.nestedContainer(keyedBy: NutrientsKeys.self, forKey: .nutrients) {
            
            if let kcalContainer = try? nutrientsContainer.nestedContainer(keyedBy: ValueKeys.self, forKey: .energyKcal) {
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

// DEFINITION 2: FoodRepoSearchResponse
struct FoodRepoSearchResponse: Decodable {
    let products: [FoodProduct]
}

// DEFINITION 3: FoodRepoClient
final class FoodRepoClient {
    private let session: URLSession
    private let apiKey: String

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func searchProducts(query: String) async throws -> [FoodProduct] {
        guard var components = URLComponents(string: "https://www.foodrepo.org/api/v6/products") else { return [] }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "per_page", value: "10"),
            URLQueryItem(name: "lang", value: "de")
        ]
        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Token token=\(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "FoodRepoClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        if let wrapper = try? decoder.decode(FoodRepoSearchResponse.self, from: data) {
            return wrapper.products
        } else if let products = try? decoder.decode([FoodProduct].self, from: data) {
            return products
        } else {
            return []
        }
    }

    func getProductByBarcode(ean: String) async throws -> FoodProduct? {
        guard let url = URL(string: "https://www.foodrepo.org/api/v6/products/barcode/\(ean)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Token token=\(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(FoodProduct.self, from: data)
    }
}
