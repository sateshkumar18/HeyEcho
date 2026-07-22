import SwiftUI

struct BrowseView: View {
    @EnvironmentObject private var appState: AppState

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Explore by what you're craving — trust signals still lead.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Array(StaticData.categories.enumerated()), id: \.element.id) { index, category in
                            NavigationLink {
                                CategoryResultsView(categoryName: category.name)
                            } label: {
                                categoryTile(category, index: index)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(22)
            }
            .background(AppTheme.atmosphere)
            .navigationTitle("Browse")
        }
    }

    private func categoryTile(_ category: FoodCategory, index: Int) -> some View {
        let tint = index.isMultiple(of: 2) ? AppTheme.brand : AppTheme.accent
        return VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: category.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
            }
            Text(category.name)
                .font(.system(.headline, design: .serif).weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Text(category.subtitle)
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 156, alignment: .topLeading)
        .background(AppTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(AppTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct CategoryResultsView: View {
    @EnvironmentObject private var appState: AppState
    let categoryName: String

    private var results: [TrustRankedResult] {
        appState.browse(category: categoryName)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Text("Trusted recommendations first")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)

                ForEach(results) { result in
                    NavigationLink {
                        BusinessDetailView(businessId: result.business.id)
                    } label: {
                        BusinessCard(result: result)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
        }
        .background(AppTheme.atmosphere)
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
