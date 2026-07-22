import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showNewCollection = false
    @State private var showEditGotos = false
    @State private var showEditKnownFor = false
    @State private var collectionTitle = ""
    @State private var collectionNote = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    profileHeader

                    if let authError = appState.authError {
                        Text(authError)
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    sectionBlock(title: "You're a GoTo for") {
                        if appState.profile.knownFor.isEmpty {
                            Text("No tags yet")
                                .foregroundStyle(AppTheme.muted)
                        } else {
                            FlowTags(tags: appState.profile.knownFor)
                        }
                        Button("Edit tags") { showEditKnownFor = true }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.brand)
                            .padding(.top, 4)
                    }

                    sectionBlock(title: "Trusted sources") {
                        if appState.personalGotos.isEmpty {
                            Text("No GoTo's yet")
                                .foregroundStyle(AppTheme.muted)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(appState.personalGotos) { contact in
                                    HStack(spacing: 12) {
                                        AvatarCircle(name: contact.name, hue: contact.avatarHue, size: 44)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(contact.name)
                                                .font(.subheadline.weight(.semibold))
                                            Text(contact.knownFor.prefix(2).joined(separator: " · "))
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.muted)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                        Button("Edit GoTo's") { showEditGotos = true }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.brand)
                            .padding(.top, 4)
                    }

                    sectionBlock(title: "Favorites") {
                        if appState.favoriteBusinesses.isEmpty {
                            Text("No saved places yet")
                                .foregroundStyle(AppTheme.muted)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(appState.favoriteBusinesses) { business in
                                    NavigationLink {
                                        BusinessDetailView(businessId: business.id)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(business.name)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(AppTheme.ink)
                                                Text(business.neighborhood)
                                                    .font(.caption)
                                                    .foregroundStyle(AppTheme.muted)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(AppTheme.muted)
                                        }
                                        .padding(.vertical, 12)
                                    }
                                    .overlay(alignment: .bottom) {
                                        Rectangle().fill(AppTheme.line).frame(height: 1)
                                    }
                                }
                            }
                        }
                    }

                    sectionBlock(title: "Collections") {
                        VStack(spacing: 0) {
                            ForEach(appState.collections) { collection in
                                NavigationLink {
                                    CollectionDetailView(collectionId: collection.id)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(collection.title)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(AppTheme.ink)
                                            Text("\(collection.businessIds.count) places · \(collection.note)")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.muted)
                                                .lineLimit(2)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AppTheme.muted)
                                    }
                                    .padding(.vertical, 12)
                                }
                                .overlay(alignment: .bottom) {
                                    Rectangle().fill(AppTheme.line).frame(height: 1)
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        appState.deleteCollection(id: collection.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }

                            Button {
                                showNewCollection = true
                            } label: {
                                Label("Create collection", systemImage: "plus")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.brand)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 14)
                            }
                        }
                    }

                    #if DEBUG
                    Button("Replay onboarding (Debug)") {
                        appState.resetOnboardingForDemo()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.top, 4)
                    #endif

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Backend")
                            .font(.system(.headline, design: .serif).weight(.semibold))
                        HStack(spacing: 8) {
                            Circle()
                                .fill(appState.isCloudEnabled ? AppTheme.trust : AppTheme.accent)
                                .frame(width: 8, height: 8)
                            Text(appState.backendLabel)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.muted)
                            if appState.isSaving {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                        if appState.isCloudEnabled {
                            Button("Sign out") {
                                appState.signOutCloud()
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.brand)
                        } else {
                            Text("Add GoogleService-Info.plist to enable Firebase cloud mode. See FIREBASE_SETUP.md.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                    .padding(.top, 12)
                }
                .padding(22)
            }
            .background(AppTheme.atmosphere)
            .navigationTitle("Profile")
            .sheet(isPresented: $showNewCollection) {
                NavigationStack {
                    Form {
                        TextField("Title", text: $collectionTitle)
                        TextField("Note", text: $collectionNote, axis: .vertical)
                    }
                    .navigationTitle("New collection")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showNewCollection = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                appState.createCollection(title: collectionTitle, note: collectionNote)
                                collectionTitle = ""
                                collectionNote = ""
                                showNewCollection = false
                            }
                            .disabled(collectionTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showEditGotos) {
                EditGotosSheet()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showEditKnownFor) {
                EditKnownForSheet()
                    .environmentObject(appState)
            }
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 16) {
            AvatarCircle(
                name: appState.profile.name.isEmpty ? "You" : appState.profile.name,
                hue: 0.45,
                size: 72
            )
            VStack(alignment: .leading, spacing: 6) {
                Text(appState.profile.name.isEmpty ? "Your profile" : appState.profile.name)
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(appState.profile.phone)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption2)
                    Text(appState.profile.foodCity)
                        .font(.caption)
                }
                .foregroundStyle(AppTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(AppTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(AppTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func sectionBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(.headline, design: .serif).weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            content()
        }
    }
}

private struct EditGotosSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("On HeyEcho · max 5") {
                    ForEach(appState.selectableGotos) { contact in
                        let selected = appState.selectedGotoIds.contains(contact.id)
                        Button {
                            appState.toggleGoto(contact.id)
                        } label: {
                            HStack {
                                AvatarCircle(name: contact.name, hue: contact.avatarHue, size: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name)
                                        .foregroundStyle(AppTheme.ink)
                                    Text(contact.knownFor.prefix(2).joined(separator: " · "))
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.muted)
                                }
                                Spacer()
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected ? AppTheme.brand : AppTheme.muted)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit GoTo's")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct EditKnownForSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var tags: [String] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(StaticData.foodTaxonomy, id: \.self) { tag in
                        let selected = tags.contains(tag)
                        Button {
                            if selected {
                                tags.removeAll { $0 == tag }
                            } else {
                                tags.append(tag)
                            }
                        } label: {
                            Text(tag)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(selected ? .white : AppTheme.ink)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(selected ? AppTheme.brand : AppTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .navigationTitle("What you're known for")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        appState.updateKnownFor(tags)
                        dismiss()
                    }
                }
            }
            .onAppear { tags = appState.profile.knownFor }
        }
    }
}

private struct FlowTags: View {
    let tags: [String]

    var body: some View {
        FlexibleTagWrap(tags: tags)
    }
}

/// Simple wrapping tag row without a heavy dependency.
private struct FlexibleTagWrap: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.brand)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.brand.opacity(0.09))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
    }

    private var rows: [[String]] {
        stride(from: 0, to: tags.count, by: 2).map { start in
            Array(tags[start..<min(start + 2, tags.count)])
        }
    }
}

struct CollectionDetailView: View {
    @EnvironmentObject private var appState: AppState
    let collectionId: String
    @State private var showEdit = false
    @State private var editTitle = ""
    @State private var editNote = ""

    private var collection: FoodCollection? {
        appState.collections.first { $0.id == collectionId }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let collection {
                    Text(collection.note.isEmpty ? "No note yet" : collection.note)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)

                    Text("Places")
                        .font(.system(.headline, design: .serif).weight(.semibold))

                    if collection.businessIds.isEmpty {
                        Text("Empty list — save a business to add places.")
                            .foregroundStyle(AppTheme.muted)
                    } else {
                        ForEach(collection.businessIds, id: \.self) { id in
                            if let business = appState.business(id: id) {
                                HStack {
                                    NavigationLink {
                                        BusinessDetailView(businessId: id)
                                    } label: {
                                        Text(business.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.ink)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        appState.removeBusiness(id, fromCollectionId: collectionId)
                                    } label: {
                                        Image(systemName: "minus.circle")
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                }
                                .padding(.vertical, 14)
                                .overlay(alignment: .bottom) {
                                    Rectangle().fill(AppTheme.line).frame(height: 1)
                                }
                            }
                        }
                    }
                }
            }
            .padding(22)
        }
        .background(AppTheme.atmosphere)
        .navigationTitle(collection?.title ?? "Collection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit") {
                        editTitle = collection?.title ?? ""
                        editNote = collection?.note ?? ""
                        showEdit = true
                    }
                    Button("Delete", role: .destructive) {
                        appState.deleteCollection(id: collectionId)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                Form {
                    TextField("Title", text: $editTitle)
                    TextField("Note", text: $editNote, axis: .vertical)
                }
                .navigationTitle("Edit collection")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showEdit = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            appState.renameCollection(id: collectionId, title: editTitle, note: editNote)
                            showEdit = false
                        }
                        .disabled(editTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
