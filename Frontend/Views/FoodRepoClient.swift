import Foundation

struct FoodProduct: Identifiable, Decodable {
    let id: String
    let name: String
    let brand: String?
    let energyKcalPer100g: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case nutrients
    }

    enum NutrientsKeys: String, CodingKey {
        case energyKcalPer100g = "energy_kcal_per_100g"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Unbekannt"
        self.brand = try? container.decodeIfPresent(String.self, forKey: .brand)
        if let nutrients = try? container.nestedContainer(keyedBy: NutrientsKeys.self, forKey: .nutrients) {
            self.energyKcalPer100g = try? nutrients.decodeIfPresent(Double.self, forKey: .energyKcalPer100g)
        } else {
            self.energyKcalPer100g = nil
        }
    }
}

struct FoodRepoSearchResponse: Decodable {
    let products: [FoodProduct]
}

final class FoodRepoClient {
    private let session: URLSession
    private let apiKey: String

    // Replace "YOUR_API_KEY" with your actual FoodRepo API key.
    init(apiKey: String = "YOUR_API_KEY", session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    /// Searches products by text query.
    /// - Parameters:
    ///   - query: Search term.
    ///   - limit: Maximum number of results.
    /// - Returns: Array of FoodProduct.
    func searchProducts(query: String, limit: Int = 20) async throws -> [FoodProduct] {
        guard var components = URLComponents(string: "https://www.foodrepo.org/api/v6/products") else { return [] }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "per_page", value: String(limit))
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

    /// Retrieves a product by barcode.
    /// - Parameter ean: Barcode string.
    /// - Returns: Optional FoodProduct.
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
