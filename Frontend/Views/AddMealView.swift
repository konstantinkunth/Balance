//
//  AddMealView.swift
//  Balance
//
//  Created by Konstantin Kunth on 23.10.25.
//

import SwiftUI

struct AddMealView: View {
    @State private var name: String = ""
    @State private var calories: String = ""
    @State private var showingFoodSearch = false
    @State private var showingScanner = false
    
    // Closure, die beim Speichern aufgerufen wird
    var onSave: (String, Int16) -> Void
    
    // WARN: Replace with secure storage or Info.plist in production
    private let foodRepoClient = FoodRepoClient(apiKey: "d77c76c541fcc21b4cae215349930079")
    
    // Environment, um Keyboard automatisch zu schließen
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 2x2 Grid of actions
                let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
                LazyVGrid(columns: columns, spacing: 16) {
                    // Barcode scannen
                    ActionTile(systemName: "camera.viewfinder", title: "Barcode scannen") {
                        showingScanner = true
                    }
                    // Suchen
                    ActionTile(systemName: "magnifyingglass", title: "Suchen") {
                        showingFoodSearch = true
                    }
                    // Rezept hinzufügen (Platzhalter)
                    ActionTile(systemName: "doc.text", title: "Rezept hinzufügen") {
                        // TODO: Implement recipe add flow
                    }
                    // Rezept erstellen (Platzhalter)
                    ActionTile(systemName: "doc.text.fill.badge.plus", title: "Rezept erstellen") {
                        // TODO: Implement recipe create flow
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .navigationTitle("Neue Mahlzeit")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .sheet(isPresented: $showingFoodSearch) {
                FoodSearchView(client: foodRepoClient) { pickedName, pickedCalories in
                    self.name = pickedName
                    self.calories = String(pickedCalories)
                }
            }
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView { code in
                    Task {
                        let ean = code.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let product = try? await foodRepoClient.getProductByBarcode(ean: ean) {
                            await MainActor.run {
                                self.name = product.brand != nil ? "\(product.name) (\(product.brand!))" : product.name
                                self.calories = String(Int(product.energyKcalPer100g ?? 0))
                                self.showingScanner = false
                            }
                        } else {
                            await MainActor.run { self.showingScanner = false }
                        }
                    }
                }
            }
        }
    }
}

private struct ActionTile: View {
    let systemName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 110)
            .padding(12)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// Preview
#Preview {
    AddMealView { name, calories in
        print("Meal: \(name), \(calories) kcal")
    }
}
