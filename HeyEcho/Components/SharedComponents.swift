import SwiftUI

struct AvatarCircle: View {
    let name: String
    var hue: Double = 0.45
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hue: hue, saturation: 0.38, brightness: 0.92),
                            Color(hue: hue, saturation: 0.55, brightness: 0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(initials)
                .font(.system(size: size * 0.34, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.ink.opacity(0.85))
        }
        .frame(width: size, height: size)
        .overlay(Circle().strokeBorder(.white.opacity(0.55), lineWidth: 1.5))
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map(String.init) }
        return letters.joined().uppercased()
    }
}

struct TrustBadge: View {
    let count: Int
    var names: [String] = []

    var body: some View {
        if count > 0 {
            HStack(spacing: 8) {
                Image(systemName: "hands.sparkles.fill")
                    .font(.caption2.weight(.semibold))
                Text(label)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
            }
            .foregroundStyle(AppTheme.trust)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(AppTheme.trust.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var label: String {
        if names.isEmpty {
            return "Recommended by \(count) people you trust"
        }
        if names.count == 1 {
            return "Recommended by \(names[0])"
        }
        if names.count == 2 {
            return "Recommended by \(names[0]) & \(names[1])"
        }
        return "Recommended by \(names[0]) + \(names.count - 1) more"
    }
}

struct BusinessCard: View {
    let result: TrustRankedResult

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.brand.opacity(0.14),
                                AppTheme.accent.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: result.business.imageSymbol)
                    .font(.title2)
                    .foregroundStyle(AppTheme.brand)
            }
            .frame(width: 68, height: 68)

            VStack(alignment: .leading, spacing: 6) {
                Text(result.business.name)
                    .font(.system(.headline, design: .serif).weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.leading)
                Text("\(result.business.neighborhood) · \(priceText)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                Text(result.business.categories.prefix(2).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                TrustBadge(
                    count: result.trustedRecommenders.count,
                    names: result.trustedRecommenders.map(\.name)
                )
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.line)
                .frame(height: 1)
        }
    }

    private var priceText: String {
        result.business.priceLabel
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTheme.sectionFont)
                .foregroundStyle(AppTheme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ChipButton: View {
    let title: String
    var isSelected: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? .white : AppTheme.brand)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? AppTheme.brand : AppTheme.brand.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
