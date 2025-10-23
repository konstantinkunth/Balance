//
//  architecture.swift
//  Balance
//
//  Created by Konstantin Kunth on 23.10.25.
//
/*
 - ContentView.swift           ← Hauptansicht (hast du schon verschoben ✓)
 - HomeView.swift              ← Verschiedene Bildschirme
 - DetailView.swift
 - SettingsView.swift
 - ProfileView.swift
 ```
 **= Komplette Bildschirme/Seiten**

 ### **Components**
 ```
 - CustomButton.swift          ← Wiederverwendbare UI-Teile
 - TodoRow.swift               ← Einzelne Listenzeilen
 - HeaderView.swift            ← Header-Komponenten
 - CardView.swift              ← Card-Designs
 ```
 **= Kleine, wiederverwendbare UI-Bausteine**

 ### **Resources**
 ```
 - Colors.swift                ← Farb-Definitionen
 - Fonts.swift                 ← Schriftarten
 - Images.swift                ← Bild-Namen als Konstanten
 ```
 **= Design-Ressourcen und Konstanten**

 ---

 ## 📁 **Backend**

 ### **Models**
 ```
 - Todo.xcdatamodeld           ← CoreData Modell-Datei
 - TodoEntity+Extensions.swift ← Extensions für CoreData-Entities
 ```
 **= Datenstrukturen (CoreData-Modelle)**

 ### **ViewModels**
 ```
 - TodoViewModel.swift         ← Verbindung zwischen View und Daten
 - SettingsViewModel.swift
 ```
 **= Logik für spezifische Views (optional, bei MVVM-Pattern)**

 ### **Services**
 ```
 - PersistenceController.swift ← CoreData Stack (hast du erwähnt ✓)
 - TodoManager.swift           ← CRUD-Operationen für Todos
 - DataService.swift           ← Weitere Daten-Services
 ```
 **= Backend-Logik, Datenbank-Zugriff, Business-Logik**

 ---

 ## 📁 **Extensions**
 ```
 - View+Extensions.swift       ← SwiftUI View Extensions
 - Date+Extensions.swift       ← Date Hilfsfunktionen
 - String+Extensions.swift     ← String Hilfsfunktionen
 */
