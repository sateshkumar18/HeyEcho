import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var appState: AppState
    @State private var query = ""
    @FocusState private var focused: Bool

    private var results: [TrustRankedResult] {
        appState.search(query: query)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .padding(.bottom, 14)

                if query.isEmpty {
                    suggestions
                }

                ScrollView {
                    LazyVStack(spacing: 0) {
                        if !query.isEmpty {
                            Text(results.isEmpty ? "No matches in \(appState.profile.foodCity)" : "Trust-ranked results")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 8)

                            if results.isEmpty {
                                Text("Try another dish, hotel, or category — or browse by neighborhood.")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.muted)
                                    .padding(.bottom, 12)
                            }
                        }
                        ForEach(results) { result in
                            NavigationLink {
                                BusinessDetailView(businessId: result.business.id)
                            } label: {
                                BusinessCard(result: result)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)
                }
            }
            .background(AppTheme.atmosphere)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(focused ? AppTheme.brand : AppTheme.muted)
            TextField("Search dosa, biryani, cafe…", text: $query)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($focused)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.muted)
                }
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(focused ? AppTheme.brand.opacity(0.35) : AppTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: focused)
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Try searching")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
                .padding(.horizontal, 22)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["dosa", "biryani", "coffee", "chaat", "dessert"], id: \.self) { tip in
                        ChipButton(title: tip.capitalized, isSelected: false) {
                            query = tip
                        }
                    }
                }
                .padding(.horizontal, 22)
            }
        }
        .padding(.bottom, 10)
    }
}
