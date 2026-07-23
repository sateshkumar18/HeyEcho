import SwiftUI

struct BusinessDetailView: View {
    @EnvironmentObject private var appState: AppState
    let businessId: String
    @State private var showSaveSheet = false
    @State private var appeared = false

    private var business: Business? {
        appState.business(id: businessId)
    }

    private var trustedRecommenders: [ContactPerson] {
        guard let business else { return [] }
        return appState.contacts.filter {
            appState.selectedGotoIds.contains($0.id) && business.recommendedByContactIds.contains($0.id)
        }
    }

    var body: some View {
        Group {
            if let business {
                content(business)
            } else {
                Text("Listing not found")
                    .foregroundStyle(AppTheme.muted)
            }
        }
    }

    private func content(_ business: Business) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Edge-to-edge visual header
                ZStack {
                    LinearGradient(
                        colors: [
                            AppTheme.brandDeep,
                            AppTheme.brand,
                            Color(red: 0.12, green: 0.42, blue: 0.40)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [AppTheme.accentSoft.opacity(0.3), .clear],
                        center: .topTrailing,
                        startRadius: 20,
                        endRadius: 260
                    )
                    Image(systemName: business.imageSymbol)
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.white.opacity(0.9))
                        .scaleEffect(appeared ? 1 : 0.88)
                        .opacity(appeared ? 1 : 0)
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(business.name)
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.ink)
                        Text("\(business.neighborhood), \(business.city)")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)

                        TrustBadge(
                            count: trustedRecommenders.count,
                            names: trustedRecommenders.map(\.name)
                        )
                    }

                    Text(business.shortDescription)
                        .font(.body)
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 14) {
                        infoRow(title: "Categories", value: business.categories.joined(separator: " · "))
                        infoRow(title: "Perfect for", value: business.perfectFor.joined(separator: " · "))
                        infoRow(title: "Address", value: business.address)
                        infoRow(title: "Hours", value: business.hours)
                        if let lat = business.latitude, let lng = business.longitude {
                            infoRow(title: "Location", value: String(format: "%.5f, %.5f", lat, lng))
                        }
                    }
                    .padding(.vertical, 4)

                    if !trustedRecommenders.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trusted sources")
                                .font(.system(.headline, design: .serif).weight(.semibold))
                            ForEach(trustedRecommenders) { person in
                                HStack(spacing: 12) {
                                    AvatarCircle(name: person.name, hue: person.avatarHue, size: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(person.name)
                                            .font(.subheadline.weight(.semibold))
                                        Text(person.knownFor.prefix(2).joined(separator: " · "))
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.muted)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.brand.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    HStack(spacing: 12) {
                        Button {
                            appState.toggleFavorite(business.id)
                        } label: {
                            Label(
                                appState.isFavorite(business.id) ? "Saved" : "Save",
                                systemImage: appState.isFavorite(business.id) ? "heart.fill" : "heart"
                            )
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button("Add to list") { showSaveSheet = true }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(.top, 4)
                }
                .padding(22)
            }
        }
        .background(AppTheme.atmosphere)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) { appeared = true }
        }
        .sheet(isPresented: $showSaveSheet) {
            SaveToCollectionSheet(businessId: business.id)
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.6)
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.body)
                .foregroundStyle(AppTheme.ink)
        }
    }
}

private struct SaveToCollectionSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let businessId: String
    @State private var newTitle = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Your collections") {
                    ForEach(appState.collections) { collection in
                        Button {
                            appState.addBusiness(businessId, toCollectionId: collection.id)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(collection.title).foregroundStyle(AppTheme.ink)
                                Text("\(collection.businessIds.count) places")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                            }
                        }
                    }
                }
                Section("New collection") {
                    TextField("Title", text: $newTitle)
                    Button("Create & add") {
                        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !title.isEmpty else { return }
                        appState.createCollection(title: title, note: "")
                        if let id = appState.collections.first?.id {
                            appState.addBusiness(businessId, toCollectionId: id)
                        }
                        dismiss()
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Save business")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
