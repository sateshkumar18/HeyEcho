import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var appeared = false

    /// Places your GoTo's actually recommend.
    private var trustedRecommendations: [TrustRankedResult] {
        appState.search(query: "").filter { !$0.trustedRecommenders.isEmpty }
    }

    /// All places in the selected food city (always browsable).
    private var nearbyPlaces: [TrustRankedResult] {
        Array(appState.search(query: "").prefix(12))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                    gotosRow
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                    if appState.needsThinNetworkFallback {
                        thinNetworkCard
                    }

                    if appState.businesses.isEmpty {
                        directoryEmptyState
                    } else {
                        if !trustedRecommendations.isEmpty {
                            placeSection(
                                title: "Recommended for you",
                                subtitle: "Ranked by voices you trust",
                                results: Array(trustedRecommendations.prefix(8))
                            )
                        }

                        placeSection(
                            title: "In \(shortCity)",
                            subtitle: trustedRecommendations.isEmpty
                                ? "Restaurants & hotels near you — open Search or Browse for more"
                                : "More restaurants & hotels in your area",
                            results: nearbyPlaces
                        )
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(AppTheme.atmosphere)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("HeyEcho")
                        .font(.system(.headline, design: .serif).weight(.bold))
                        .foregroundStyle(AppTheme.brand)
                }
            }
            .refreshable {
                await appState.refreshDirectory()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.55)) { appeared = true }
            }
        }
    }

    private var shortCity: String {
        guard let first = appState.profile.foodCity.split(separator: ",").first else {
            return appState.profile.foodCity
        }
        return String(first).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func placeSection(title: String, subtitle: String, results: [TrustRankedResult]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(title: title, subtitle: subtitle)
            if results.isEmpty {
                emptyState
                    .padding(.top, 12)
            } else {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    NavigationLink {
                        BusinessDetailView(businessId: result.business.id)
                    } label: {
                        BusinessCard(result: result)
                    }
                    .buttonStyle(.plain)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(
                        .easeOut(duration: 0.4).delay(0.05 * Double(index)),
                        value: appeared
                    )
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hey \(firstName)")
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.ink)
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption)
                Text(appState.profile.foodCity)
                    .font(.subheadline)
            }
            .foregroundStyle(AppTheme.muted)
            Text("\(appState.businesses.count) places · pull down to refresh from cloud")
                .font(.caption)
                .foregroundStyle(AppTheme.muted.opacity(0.9))
        }
    }

    private var firstName: String {
        appState.profile.name.split(separator: " ").first.map(String.init) ?? "there"
    }

    private var gotosRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your GoTo's")
                .font(.system(.headline, design: .serif).weight(.semibold))
                .foregroundStyle(AppTheme.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(appState.personalGotos) { contact in
                        gotoAvatar(contact, badge: nil)
                    }
                    ForEach(appState.pendingGotos) { contact in
                        gotoAvatar(contact, badge: "Pending")
                    }
                    if appState.personalGotos.isEmpty && appState.pendingGotos.isEmpty {
                        Text("Add GoTo's to personalize recommendations")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                            .padding(.vertical, 20)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func gotoAvatar(_ contact: ContactPerson, badge: String?) -> some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                AvatarCircle(name: contact.name, hue: contact.avatarHue, size: 60)
                if badge != nil {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 12, height: 12)
                        .offset(x: 2, y: -2)
                }
            }
            Text(contact.name.split(separator: " ").first.map(String.init) ?? contact.name)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
            if let badge {
                Text(badge)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .frame(width: 76)
    }

    private var thinNetworkCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Grow your trust circle")
                .font(.headline)
            Text("Follow local experts until more of your friends join HeyEcho.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
            ForEach(appState.localExpertSuggestions.prefix(3)) { expert in
                let selected = appState.selectedGotoIds.contains(expert.id)
                Button {
                    appState.toggleGoto(expert.id)
                } label: {
                    HStack(spacing: 12) {
                        AvatarCircle(name: expert.name, hue: expert.avatarHue, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(expert.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.ink)
                            Text(expert.knownFor.prefix(2).joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(AppTheme.muted)
                        }
                        Spacer()
                        Text(selected ? "Following" : "Follow")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selected ? AppTheme.muted : AppTheme.brand)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.brand.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No places matched yet")
                .font(.headline)
            Text("Try Browse → Hotels or Biryani, or open Search.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.brand.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var directoryEmptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Directory still loading")
                .font(.headline)
            Text(appState.authError ?? "Reopen the app after Firebase seed finishes.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
