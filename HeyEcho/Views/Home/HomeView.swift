import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var appeared = false

    private var recommendations: [TrustRankedResult] {
        appState.search(query: "").filter { $0.trustScore > 0 }
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

                    VStack(alignment: .leading, spacing: 4) {
                        SectionHeader(
                            title: "Recommended for you",
                            subtitle: "Ranked by your Personal GoTo's"
                        )

                        if recommendations.isEmpty {
                            emptyState
                                .padding(.top, 12)
                        } else {
                            ForEach(Array(recommendations.prefix(8).enumerated()), id: \.element.id) { index, result in
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
            .onAppear {
                withAnimation(.easeOut(duration: 0.55)) { appeared = true }
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
                        VStack(spacing: 10) {
                            AvatarCircle(name: contact.name, hue: contact.avatarHue, size: 60)
                            Text(contact.name.split(separator: " ").first.map(String.init) ?? contact.name)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.ink)
                                .lineLimit(1)
                        }
                        .frame(width: 76)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No trust matches yet")
                .font(.headline)
            Text("Pick more GoTo's or browse categories to discover places.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.brand.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
