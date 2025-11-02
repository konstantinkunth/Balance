import SwiftUI

struct AnalyticsView: View {
    // Accept an optional meals array to match usage in ContentView
    var meals: [Meal] = []

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(.secondary)
            Text("Analytics kommen später")
                .font(.headline)
                .foregroundStyle(.secondary)
            if !meals.isEmpty {
                Text("\(meals.count) Einträge")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .navigationTitle("Analyse")
    }
}

#Preview {
    AnalyticsView(meals: [])
}
