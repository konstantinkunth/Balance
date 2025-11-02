//
//  ContentView.swift
//  Balance
//
//  Created by Konstantin Kunth on 23.10.25.
//
//  DIES IST DIE FINALE VERSION MIT DER NEUEN SUCHFUNKTION
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // FetchRequest für Meal-Entity
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Meal.date, ascending: true)],
        animation: .default)
    private var meals: FetchedResults<Meal>

    @State private var showingActionBar = false
    @State private var showingFoodSearch = false
    @State private var showingScanner = false
    
    // Verwendet den v6-Schlüssel, der zum v6-Client (FoodRepoClient.swift) passt
    private let foodRepoClient = FoodRepoClient(apiKey: "3ce90a15c668deefc35392d660875a53")

    enum DateFilter: String, CaseIterable, Identifiable {
        case day = "Tag"
        case week = "Woche"
        case month = "Monat"
        case year = "Jahr"
        
        var id: String { rawValue }
    }
    
    @State private var selectedFilter: DateFilter = .day
    @State private var selectedPage: Int = 0 // 0: Add, 1: Home, 2: Analytics
    
    private var filteredMeals: [Meal] {
        let calendar = Calendar.current
        let now = Date()
        
        func isInSelectedRange(_ date: Date) -> Bool {
            switch selectedFilter {
            case .day:
                return calendar.isDate(date, inSameDayAs: now)
            case .week:
                guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
                      let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { return false }
                return (weekStart...nextWeekStart).contains(date)
            case .month:
                guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start,
                      let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return false }
                return (monthStart...nextMonthStart).contains(date)
            case .year:
                guard let yearStart = calendar.dateInterval(of: .year, for: now)?.start,
                      let nextYearStart = calendar.date(byAdding: .year, value: 1, to: yearStart) else { return false }
                return (yearStart...nextYearStart).contains(date)
            }
        }
        
        return meals
            .compactMap { $0 }
            .filter { meal in
                guard let d = meal.date else { return false }
                return isInSelectedRange(d)
            }
            .sorted { (m1, m2) in
                let d1 = m1.date ?? .distantPast
                let d2 = m2.date ?? .distantPast
                return d1 > d2
            }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedPage) {
                    // Page 0: Add actions
                    VStack {
                        Spacer()
                        ActionBar(showingFoodSearch: $showingFoodSearch, showingScanner: $showingScanner)
                            .padding(.horizontal, 16)
                        Spacer(minLength: 120)
                    }
                    .tag(0)

                    // Page 1: Home
                    VStack(spacing: 0) {
                        VStack(spacing: 8) {
                            Picker("Zeitraum", selection: $selectedFilter) {
                                ForEach(DateFilter.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding([.horizontal, .top])

                            List {
                                ForEach(filteredMeals) { meal in
                                    NavigationLink {
                                        VStack(alignment: .leading) {
                                            Text(meal.name ?? "Unbekannt")
                                                .font(.headline)
                                            Text("\(meal.calories) kcal")
                                                .foregroundColor(.secondary)
                                            Text(meal.date ?? Date(), formatter: itemFormatter)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                    } label: {
                                        HStack {
                                            Text(meal.name ?? "Unbekannt")
                                            Spacer()
                                            Text("\(meal.calories) kcal")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .onDelete(perform: deleteMeals)
                            }
                            .listStyle(.plain)
                        }
                        Spacer(minLength: 0)
                    }
                    .tag(1)

                    // Page 2: Analytics
                    AnalyticsView(meals: filteredMeals)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom bottom bar
                BottomBar(selectedPage: $selectedPage, onAnalytics: {
                    selectedPage = 2
                })
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(titleForPage(selectedPage))
            
            // HIER IST DIE ÄNDERUNG:
            .sheet(isPresented: $showingFoodSearch) {
                // Übergibt die "addMeal"-Funktion an die FoodSearchView.
                // Die FoodDetailView wird sie aufrufen und das Sheet schließen.
                FoodSearchView(client: foodRepoClient, onAddMeal: { name, kcal in
                    addMeal(name: name, calories: kcal)
                    showingFoodSearch = false // Schließt das gesamte Sheet
                })
            }
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView { code in
                    Task {
                        let ean = code.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if let product = try? await foodRepoClient.getProductByBarcode(ean: ean) {
                            await MainActor.run {
                                let title = product.brand != nil && !product.brand!.isEmpty ? "\(product.name) (\(product.brand!))" : product.name
                                let kcal = Int16(Int(product.energyKcalPer100g ?? 0))
                                addMeal(name: title, calories: kcal)
                                showingScanner = false
                            }
                        } else {
                            await MainActor.run { showingScanner = false }
                        }
                    }
                }
            }
        }
    }

    // Core Data hinzufügen
    private func addMeal(name: String, calories: Int16) {
        withAnimation {
            let newMeal = Meal(context: viewContext)
            newMeal.name = name
            newMeal.calories = calories
            newMeal.date = Date()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // Core Data löschen
    private func deleteMeals(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredMeals[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // Hintergrund-Speichern: Rezepte mit Zutaten
    private func saveRecipeInBackground(name: String, ingredients: [(name: String, amount: Double, unit: String)]) {
        guard let persistentStoreCoordinator = viewContext.persistentStoreCoordinator else { return }
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.persistentStoreCoordinator = persistentStoreCoordinator

        backgroundContext.perform {
            // ... (Ihre Logik zum Erstellen von Rezepten)
            do {
                try backgroundContext.save()
            } catch {
                print("Background save error (Recipe):", error)
            }
        }
    }
}


// DateFormatter für Anzeige
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

// MARK: - Subviews (ActionBar, ActionTile, BottomBar)

private struct ActionBar: View {
    @Binding var showingFoodSearch: Bool
    @Binding var showingScanner: Bool

    var body: some View {
        VStack(spacing: 16) {
            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ActionTile(systemName: "camera.viewfinder", title: "Barcode scannen") {
                    showingScanner = true
                }
                ActionTile(systemName: "magnifyingglass", title: "Suchen") {
                    showingFoodSearch = true
                }
                ActionTile(systemName: "doc.text", title: "Rezept hinzufügen") {
                    // TODO: Implement recipe add flow
                }
                ActionTile(systemName: "doc.text.fill.badge.plus", title: "Rezept erstellen") {
                    // TODO: Implement recipe create flow
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(radius: 8, y: 2)
        .padding(.horizontal, 16)
    }
}

private struct ActionTile: View {
    let systemName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.system(size: 26, weight: .semibold))
                Text(title)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 90)
            .padding(10)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private func titleForPage(_ index: Int) -> String {
    switch index {
    case 0: return "Hinzufügen"
    case 1: return "Balance"
    case 2: return "Analyse"
    default: return "Balance"
    }
}

private struct BottomBar: View {
    @Binding var selectedPage: Int
    var onAnalytics: () -> Void

    var body: some View {
        HStack(spacing: 36) {
            Spacer()
            Button {
                selectedPage = 0
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 30, weight: .semibold))
            }
            Spacer()
            Button {
                selectedPage = 1
            } label: {
                Image(systemName: "house.fill")
                    .font(.system(size: 30, weight: .bold))
            }
            Spacer()
            Button {
                onAnalytics()
            } label: {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 30, weight: .semibold))
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(.bar)
    }
}

// MARK: - Preview

#Preview("Mit Beispieldaten und Filter") {
    // In-Memory Persistence für die Preview
    let container = NSPersistentContainer(name: "Balance")
    container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
    container.loadPersistentStores(completionHandler: { _, error in
        if let error = error as NSError? {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    })
    let context = container.viewContext
    
    // Beispiel-Daten
    let cal = Calendar.current
    let now = Date()
    
    func makeMeal(name: String, calories: Int16, date: Date) {
        let m = Meal(context: context)
        m.name = name
        m.calories = calories
        m.date = date
    }
    
    makeMeal(name: "Frühstück", calories: 450, date: now)
    makeMeal(name: "Mittagessen", calories: 720, date: now)
    
    if let yesterday = cal.date(byAdding: .day, value: -1, to: now) {
        makeMeal(name: "Snack", calories: 200, date: yesterday)
    }
    if let tenDaysAgo = cal.date(byAdding: .day, value: -10, to: now) {
        makeMeal(name: "Pasta", calories: 800, date: tenDaysAgo)
    }
    if let twoMonthsAgo = cal.date(byAdding: .month, value: -2, to: now) {
        makeMeal(name: "Salat", calories: 350, date: twoMonthsAgo)
    }
    
    do {
        try context.save()
    } catch {
        fatalError("Preview save error: \(error)")
    }
    
    return ContentView()
        .environment(\.managedObjectContext, context)
}
