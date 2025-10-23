//
//  AddMealView.swift
//  Balance
//
//  Created by Konstantin Kunth on 23.10.25.
//


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
    
    // Closure, die beim Speichern aufgerufen wird
    var onSave: (String, Int16) -> Void
    
    // Environment, um Keyboard automatisch zu schließen
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Mahlzeit")) {
                    TextField("Name", text: $name)
                    TextField("Kalorien", text: $calories)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Neue Mahlzeit")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        guard let cal = Int16(calories), !name.isEmpty else { return }
                        onSave(name, cal)
                        dismiss()
                    }
                    .disabled(name.isEmpty || calories.isEmpty)
                }
            }
        }
    }
}

// Preview
#Preview {
    AddMealView { name, calories in
        print("Meal: \(name), \(calories) kcal")
    }
}
