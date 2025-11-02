import SwiftUI

struct FoodDetailView: View {
    let product: FoodProduct // Dieser Typ MUSS 'FoodProduct' aus FoodRepoClient.swift sein
    let onAddMeal: (String, Int16) -> Void
    
    @State private var amountString: String = "100"
    @Environment(\.dismiss) private var dismiss
    
    var calculatedAmount: Double { Double(amountString) ?? 0 }
    var calculatedKcal: Double { (product.energyKcalPer100g ?? 0) * (calculatedAmount / 100.0) }
    var calculatedFat: Double { (product.fatPer100g ?? 0) * (calculatedAmount / 100.0) }
    var calculatedCarbs: Double { (product.carbohydratesPer100g ?? 0) * (calculatedAmount / 100.0) }
    var calculatedProtein: Double { (product.proteinPer100g ?? 0) * (calculatedAmount / 100.0) }
    
    var body: some View {
        Form {
            Section("Menge") {
                HStack {
                    TextField("Menge", text: $amountString)
                        .keyboardType(.decimalPad)
                    Text("Gramm")
                }
            }
            
            Section("Berechnete Nährwerte") {
                NutrientRow(label: "Kalorien", value: calculatedKcal, unit: "kcal")
                NutrientRow(label: "Fett", value: calculatedFat, unit: "g")
                NutrientRow(label: "Kohlenhydrate", value: calculatedCarbs, unit: "g")
                NutrientRow(label: "Protein", value: calculatedProtein, unit: "g")
            }
        }
        .navigationTitle(product.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Hinzufügen") {
                    let finalName = product.brand != nil && !product.brand!.isEmpty ? "\(product.name) (\(product.brand!))" : product.name
                    let finalKcal = Int16(calculatedKcal)
                    onAddMeal(finalName, finalKcal)
                }
                .disabled(calculatedAmount <= 0)
            }
        }
    }
}

private struct NutrientRow: View {
    let label: String
    let value: Double
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(value, specifier: "%.1f") \(unit)")
        }
    }
}

// Preview
#Preview {
    // KORREKTUR: Die ID ist jetzt eine Zahl (Int), kein String
    let previewProduct = FoodProduct(
        id: 1, // <--- HIER WAR DER FEHLER (war "1")
        name: "Beispiel-Mango",
        brand: "Vorschau",
        energyKcalPer100g: 67,
        fatPer100g: 0.0,
        carbohydratesPer100g: 15.0,
        proteinPer100g: 0.5
    )
    
    NavigationView {
        FoodDetailView(product: previewProduct, onAddMeal: { name, kcal in
            print("Vorschau: \(name) mit \(kcal) kcal hinzugefügt.")
        })
    }
}
