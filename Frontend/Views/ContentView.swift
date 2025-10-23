//
//  ContentView.swift
//  Balance
//
//  Created by Konstantin Kunth on 23.10.25.
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

    @State private var showingAddMeal = false

    var body: some View {
        NavigationView {
            List {
                ForEach(meals) { meal in
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
            .navigationTitle("Balance")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMeal = true }) {
                        Label("Add Meal", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView { name, calories in
                    addMeal(name: name, calories: calories)
                    showingAddMeal = false
                }
                .environment(\.managedObjectContext, viewContext)
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
            offsets.map { meals[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
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

// Preview
#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

