import SwiftUI

struct FoodSearchView: View {
    @State private var query: String = ""
    @State private var isLoading: Bool = false
    @State private var results: [FoodProduct] = []
    @State private var errorMessage: String?

    let client: FoodRepoClient
    let onPick: (String, Int16) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Lebensmittel suchen", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .onSubmit { Task { await performSearch() } }
                    Button {
                        Task { await performSearch() }
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()

                if isLoading {
                    ProgressView("Suche...")
                        .padding()
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                List(results) { product in
                    Button {
                        let name = product.brand != nil && !product.brand!.isEmpty ? "\(product.name) (\(product.brand!))" : product.name
                        let kcal = Int16(product.energyKcalPer100g ?? 0)
                        onPick(name, kcal)
                        dismiss()
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
        }
    }

    private func performSearch() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            let items = try await client.searchProducts(query: q)
            await MainActor.run {
                self.results = items
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

#Preview {
    let client = FoodRepoClient(apiKey: "DEMO_KEY")
    return FoodSearchView(client: client) { name, calories in
        print(name, calories)
    }
}
