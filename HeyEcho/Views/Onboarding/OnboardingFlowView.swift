import SwiftUI
import UIKit

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

                    Text("Trusted local food · Phase 1")
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
                        ? "Use a Firebase test phone number for OTP (see OTP_SETUP.md). Real SMS needs Blaze later."
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

                if appState.isCloudEnabled {
                    Text("Phase 1 test login: tap Send OTP, then enter 123456. (Real SMS Phone Auth is deferred — it hangs on Simulator.)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                field("Your name", text: $appState.profile.name, icon: "person")
                field("Phone number", text: $appState.profile.phone, icon: "phone")
                    .keyboardType(.phonePad)
                    .disabled(isWorking)

                if otpSent {
                    field("OTP code", text: $otp, icon: "lock.shield")
                        .keyboardType(.numberPad)
                    Text("Enter OTP: 123456")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.brand)
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
                        Task { await sendOTP() }
                    } label: {
                        Text("Send OTP")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(
                        appState.profile.phone.filter(\.isNumber).count < 10
                        || appState.profile.name.isEmpty
                    )
                } else {
                    Button {
                        Task {
                            isWorking = true
                            let ok = await appState.verifyOTP(otp.isEmpty ? "123456" : otp)
                            isWorking = false
                            if ok { onContinue() }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isWorking {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isWorking ? "Verifying…" : "Verify & continue")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isWorking)
                }
            }
            .padding(24)
        }
    }

    private func sendOTP() async {
        appState.authError = nil
        await appState.sendOTP()
        // Instant — never waits on Firebase Phone Auth.
        withAnimation {
            otpSent = true
            if otp.isEmpty { otp = "123456" }
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
                subtitle: "Wherever you eat most — listings for that area appear as they’re added."
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(appState.availableFoodCities, id: \.self) { city in
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
                subtitle: "We match your phone contacts to people already on HeyEcho."
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)

            contactsBanner
                .padding(.horizontal, 24)

            HStack {
                Text("\(appState.selectedGotoIds.count)/5 selected")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.brand)
                Spacer()
                if appState.isLoadingContacts {
                    ProgressView()
                        .scaleEffect(0.85)
                }
            }
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(appState.selectableGotos) { contact in
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

                    if !appState.inviteLaterContacts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("In your contacts — not on HeyEcho yet")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.muted)
                                .padding(.top, 8)
                            ForEach(appState.inviteLaterContacts.prefix(20)) { contact in
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
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }

            Button("Continue", action: onContinue)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(appState.selectedGotoIds.isEmpty)
                .padding(24)
        }
        .task {
            await appState.requestAndLoadContacts()
        }
    }

    @ViewBuilder
    private var contactsBanner: some View {
        switch appState.contactsStatus {
        case .authorized:
            Text("Matched against your phone contacts. Pilot directory people also appear so you can still pick GoTo's.")
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
        case .denied, .restricted:
            VStack(alignment: .leading, spacing: 8) {
                Text("Contacts access is off — showing the pilot directory. Enable Contacts in Settings for real matching.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accent)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.brand)
            }
        case .notDetermined, .unavailable:
            Text("Allow Contacts so we can match friends already on HeyEcho.")
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
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
