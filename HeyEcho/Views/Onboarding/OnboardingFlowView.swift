import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState
    @State private var step = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if step > 0 {
                    progress
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        .padding(.bottom, 4)
                        .transition(.opacity)
                }

                Group {
                    switch step {
                    case 0: LandingStep(onContinue: { withAnimation(.easeInOut(duration: 0.35)) { step = 1 } })
                    case 1: ProfileSetupStep(onContinue: { withAnimation { step = 2 } })
                    case 2: CityPickerStep(onContinue: { withAnimation { step = 3 } })
                    case 3: ContactsGotoStep(onContinue: { withAnimation { step = 4 } })
                    default: KnownForStep(onFinish: {
                        appState.completeOnboarding()
                    })
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(step)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .background(AppTheme.atmosphere)
            .navigationBarBackButtonHidden(step == 0)
            .toolbar {
                if step > 0 {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) { step -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AppTheme.brand)
                        }
                    }
                }
            }
        }
    }

    private var progress: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AppTheme.brand.opacity(0.12))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.brand, AppTheme.brandDeep],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, geo.size.width * CGFloat(step) / 4))
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
            }
        }
        .frame(height: 5)
    }
}

private struct LandingStep: View {
    var onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-bleed atmospheric hero
            LinearGradient(
                colors: [
                    AppTheme.brandDeep,
                    AppTheme.brand,
                    Color(red: 0.08, green: 0.40, blue: 0.38)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Soft light wash / food atmosphere
            RadialGradient(
                colors: [AppTheme.accentSoft.opacity(0.35), .clear],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()

            // Abstract plate / table motif (visual anchor, not decorative noise)
            Circle()
                .strokeBorder(.white.opacity(0.12), lineWidth: 1.5)
                .frame(width: 280, height: 280)
                .offset(x: 90, y: -180)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.85)

            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 160, height: 160)
                .offset(x: -110, y: -90)
                .opacity(appeared ? 1 : 0)

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 18) {
                    Text("HeyEcho")
                        .font(AppTheme.brandFont)
                        .foregroundStyle(.white)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                    Text("Voices you trust.\nPlaces you'll love.")
                        .font(.system(size: 26, weight: .semibold, design: .serif))
                        .foregroundStyle(.white.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 18)

                    Text("Local food discovery powered by people you actually know — not star ratings.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.trailing, 24)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                }
                .padding(.horizontal, 28)

                Spacer().frame(height: 48)

                VStack(spacing: 14) {
                    Button("Get started", action: onContinue)
                        .buttonStyle(LandingCTAStyle())
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 24)

                    Text("Indiranagar pilot · Phase 1")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.75)) {
                appeared = true
            }
        }
    }
}

private struct LandingCTAStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppTheme.brandDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white.opacity(configuration.isPressed ? 0.88 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct ProfileSetupStep: View {
    @EnvironmentObject private var appState: AppState
    var onContinue: () -> Void
    @State private var otpSent = false
    @State private var otp = ""
    @State private var isWorking = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeader(
                    title: "Create your profile",
                    subtitle: appState.isCloudEnabled
                        ? "Sign in with your phone. OTP is verified by Firebase Auth."
                        : "Local mode — add Firebase to go live (see FIREBASE_SETUP.md)."
                )

                HStack(spacing: 8) {
                    Circle()
                        .fill(appState.isCloudEnabled ? AppTheme.trust : AppTheme.accent)
                        .frame(width: 8, height: 8)
                    Text(appState.backendLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                }

                field("Your name", text: $appState.profile.name, icon: "person")
                field("Phone number", text: $appState.profile.phone, icon: "phone")
                    .keyboardType(.phonePad)

                if otpSent {
                    field("OTP code", text: $otp, icon: "lock.shield")
                        .keyboardType(.numberPad)
                    Text(appState.isCloudEnabled
                         ? "Enter the SMS code (or your Firebase test-number code)."
                         : "Local mode test OTP: 123456")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }

                if let authError = appState.authError {
                    Text(authError)
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 28)

                if !otpSent {
                    Button {
                        Task {
                            isWorking = true
                            await appState.sendOTP()
                            isWorking = false
                            if appState.authError == nil || !appState.isCloudEnabled {
                                withAnimation { otpSent = true }
                                if !appState.isCloudEnabled { appState.authError = nil }
                            }
                        }
                    } label: {
                        if isWorking {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            Text("Send OTP")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(
                        isWorking
                        || appState.profile.phone.filter(\.isNumber).count < 10
                        || appState.profile.name.isEmpty
                    )
                } else {
                    Button {
                        Task {
                            isWorking = true
                            let ok = await appState.verifyOTP(otp)
                            isWorking = false
                            if ok { onContinue() }
                        }
                    } label: {
                        if isWorking {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            Text("Verify & continue")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isWorking || otp.count < 6)
                }
            }
            .padding(24)
        }
    }

    private func field(_ title: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.labelFont)
                .foregroundStyle(AppTheme.muted)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.brand.opacity(0.7))
                    .frame(width: 20)
                TextField(title, text: text)
            }
            .softField()
        }
    }
}

private struct CityPickerStep: View {
    @EnvironmentObject private var appState: AppState
    var onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Choose your food city",
                subtitle: "Start with the neighborhood where you eat most often."
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(StaticData.foodCities, id: \.self) { city in
                        let selected = appState.profile.foodCity == city
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.profile.foodCity = city
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(city.components(separatedBy: ",").first ?? city)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.ink)
                                    if city.contains(",") {
                                        Text(city.components(separatedBy: ",").dropFirst().joined(separator: ",").trimmingCharacters(in: .whitespaces))
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.muted)
                                    }
                                }
                                Spacer()
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selected ? AppTheme.brand : AppTheme.muted.opacity(0.4))
                            }
                            .padding(16)
                            .background(selected ? AppTheme.brand.opacity(0.08) : AppTheme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(selected ? AppTheme.brand.opacity(0.35) : AppTheme.line, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }

            Button("Continue", action: onContinue)
                .buttonStyle(PrimaryButtonStyle())
                .padding(24)
        }
    }
}

private struct ContactsGotoStep: View {
    @EnvironmentObject private var appState: AppState
    var onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Pick up to 5 GoTo's",
                subtitle: "These voices power your trust-ranked recommendations."
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)

            HStack {
                Text("\(appState.selectedGotoIds.count)/5 selected")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.brand)
                Spacer()
            }
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(appState.contacts.filter(\.isOnHeyEcho)) { contact in
                        let selected = appState.selectedGotoIds.contains(contact.id)
                        Button {
                            appState.toggleGoto(contact.id)
                        } label: {
                            HStack(spacing: 14) {
                                AvatarCircle(name: contact.name, hue: contact.avatarHue, size: 48)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(contact.name)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.ink)
                                    Text(contact.knownFor.prefix(2).joined(separator: " · "))
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.muted)
                                }
                                Spacer()
                                Image(systemName: selected ? "checkmark.circle.fill" : "plus.circle")
                                    .font(.title3)
                                    .foregroundStyle(selected ? AppTheme.brand : AppTheme.muted.opacity(0.45))
                            }
                            .padding(14)
                            .background(selected ? AppTheme.brand.opacity(0.07) : AppTheme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(selected ? AppTheme.brand.opacity(0.3) : AppTheme.line, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Not on HeyEcho yet")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.muted)
                            .padding(.top, 8)
                        ForEach(appState.contacts.filter { !$0.isOnHeyEcho }) { contact in
                            HStack(spacing: 12) {
                                AvatarCircle(name: contact.name, hue: contact.avatarHue, size: 36)
                                Text(contact.name)
                                    .foregroundStyle(AppTheme.ink.opacity(0.7))
                                Spacer()
                                Text("Invite later")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }

            Button("Continue", action: onContinue)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(appState.selectedGotoIds.isEmpty)
                .padding(24)
        }
    }
}

private struct KnownForStep: View {
    @EnvironmentObject private var appState: AppState
    var onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "What are you a GoTo for?",
                subtitle: "Help friends know when to ask you."
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(StaticData.foodTaxonomy, id: \.self) { tag in
                        let selected = appState.profile.knownFor.contains(tag)
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                if selected {
                                    appState.profile.knownFor.removeAll { $0 == tag }
                                } else {
                                    appState.profile.knownFor.append(tag)
                                }
                            }
                        } label: {
                            Text(tag)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(selected ? .white : AppTheme.ink)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .padding(.horizontal, 8)
                                .background {
                                    if selected {
                                        LinearGradient(
                                            colors: [AppTheme.brand, AppTheme.brandDeep],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    } else {
                                        AppTheme.card
                                    }
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(selected ? .clear : AppTheme.line, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }

            Button("Enter HeyEcho", action: onFinish)
                .buttonStyle(PrimaryButtonStyle())
                .padding(24)
        }
    }
}
