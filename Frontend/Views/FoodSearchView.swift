import SwiftUI
import Combine

struct FoodSearchView: View {
    @State private var query: String = ""
    @State private var isLoading: Bool = false
    @State private var results: [FoodProduct] = []
    @State private var errorMessage: String?
    
    @StateObject private var debouncer = Debouncer(delay: 0.5)

    let client: FoodRepoClient
    let onAddMeal: (String, Int16) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                TextField("Lebensmittel (auf Deutsch) suchen", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .submitLabel(.search)
                
                if isLoading && results.isEmpty {
                    ProgressView("Suche...")
                        .padding()
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                List(results) { product in
                    NavigationLink {
                        FoodDetailView(product: product, onAddMeal: onAddMeal)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name)
                                .font(.headline)
                            if let brand = product.brand, !brand.isEmpty {
                                Text(brand)
                                    .foregroundStyle(.secondary)
                            }
                            if let kcal = product.energyKcalPer100g {
                                Text("\(Int(kcal)) kcal / 100g")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("FoodRepo Suche")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") { dismiss() }
                }
            }
            // KORREKTUR für die Warnung 'onChange(of:perform:)'
            // Verwendet die neuere Version von onChange
            .onChange(of: query) { oldValue, newValue in
                isLoading = true
                debouncer.run {
                    Task { await performSearch(query: newValue) }
                }
            }
        }
    }

    private func performSearch(query: String) async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            await MainActor.run {
                self.results = []
                self.isLoading = false
            }
            return
        }
        
        do {
            let items = try await client.searchProducts(query: q)
            await MainActor.run {
                self.results = items
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                // Zeigt einen hilfreichen Fehler an, falls der v3-Schlüssel doch falsch ist
                self.errorMessage = "Fehler: \(error.localizedDescription). Prüfen Sie den API-Schlüssel."
                self.isLoading = false
            }
        }
    }
}

final class Debouncer: ObservableObject {
    private var cancellable: AnyCancellable?
    private let delay: TimeInterval
    
    init(delay: TimeInterval = 0.5) {
        self.delay = delay
    }
    
    func run(action: @escaping () -> Void) {
        cancellable?.cancel()
        cancellable = Just(())
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .sink(receiveValue: { _ in action() })
    }
}

#Preview {
    // Dieser Schlüssel ist jetzt korrekt, da der Client auf v3 läuft
    let client = FoodRepoClient(apiKey: "3ce90a15c668deefc35392d660875a53")
    
    FoodSearchView(client: client) { name, calories in
        print("Mahlzeit hinzugefügt: \(name), \(calories) kcal")
    }
}
