import SwiftUI

enum AppTheme {
    // Brand — coastal teal + warm mango (India food discovery)
    static let brand = Color(red: 0.04, green: 0.32, blue: 0.36)
    static let brandDeep = Color(red: 0.02, green: 0.22, blue: 0.26)
    static let accent = Color(red: 0.93, green: 0.42, blue: 0.12)
    static let accentSoft = Color(red: 0.98, green: 0.78, blue: 0.55)
    static let ink = Color(red: 0.10, green: 0.13, blue: 0.14)
    static let muted = Color(red: 0.42, green: 0.46, blue: 0.48)
    static let surface = Color(red: 0.96, green: 0.955, blue: 0.94)
    static let surfaceWarm = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let card = Color.white.opacity(0.92)
    static let trust = Color(red: 0.10, green: 0.52, blue: 0.40)
    static let line = Color.black.opacity(0.06)

    // Typography — expressive serif for brand/display, clean sans for UI
    static let brandFont = Font.system(size: 48, weight: .bold, design: .serif)
    static let titleFont = Font.system(.largeTitle, design: .serif).weight(.bold)
    static let headlineFont = Font.system(.title2, design: .serif).weight(.semibold)
    static let sectionFont = Font.system(.title3, design: .serif).weight(.semibold)
    static let bodyFont = Font.system(.body, design: .default)
    static let labelFont = Font.system(.subheadline, design: .default).weight(.medium)

    static var atmosphere: some View {
        ZStack {
            surface
            LinearGradient(
                colors: [
                    surfaceWarm,
                    Color(red: 0.93, green: 0.95, blue: 0.94),
                    Color(red: 0.88, green: 0.93, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [brand.opacity(0.10), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 380
            )
            RadialGradient(
                colors: [accent.opacity(0.08), .clear],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 320
            )
        }
        .ignoresSafeArea()
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .default).weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        AppTheme.brand.opacity(configuration.isPressed ? 0.88 : 1),
                        AppTheme.brandDeep.opacity(configuration.isPressed ? 0.88 : 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .default).weight(.semibold))
            .foregroundStyle(AppTheme.brand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.brand.opacity(configuration.isPressed ? 0.14 : 0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.brand.opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SoftFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(AppTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppTheme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

extension View {
    func softField() -> some View {
        modifier(SoftFieldModifier())
    }
}
