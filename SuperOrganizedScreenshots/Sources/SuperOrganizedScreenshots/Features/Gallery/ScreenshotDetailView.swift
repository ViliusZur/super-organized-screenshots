import SwiftUI

struct ScreenshotDetailView: View {
    @ObservedObject var screenshot: Screenshot
    @EnvironmentObject var appState: AppState
    @State private var isEditing: Bool = false
    @State private var isRenaming: Bool = false
    @State private var newName: String = ""
    @State private var showingDeleteConfirmation: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            imagePreview
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            infoPanel
        }
        .sheet(isPresented: $isEditing) {
            ImageEditorView(screenshot: screenshot)
                .environmentObject(appState)
        }
        .alert("Rename Screenshot", isPresented: $isRenaming) {
            TextField("New name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                renameScreenshot()
            }
        }
        .alert("Delete Screenshot?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteScreenshot()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    isEditing = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button {
                    newName = screenshot.displayName
                    isRenaming = true
                } label: {
                    Label("Rename", systemImage: "pencil.line")
                }

                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([screenshot.url])
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                }

                Button {
                    shareScreenshot()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var imagePreview: some View {
        ScrollView([.horizontal, .vertical]) {
            if let image = NSImage(contentsOf: screenshot.url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            } else {
                Text("Unable to load image")
                    .foregroundColor(.secondary)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var infoPanel: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(screenshot.filename)
                    .font(.headline)
                Text(screenshot.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let image = NSImage(contentsOf: screenshot.url) {
                Text("\(Int(image.size.width)) × \(Int(image.size.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func renameScreenshot() {
        guard !newName.isEmpty, newName != screenshot.displayName else { return }
        Task {
            try? await appState.renameScreenshot(screenshot, to: newName)
        }
    }

    private func deleteScreenshot() {
        Task {
            try? await appState.deleteScreenshot(screenshot)
        }
    }

    private func shareScreenshot() {
        let picker = NSSharingServicePicker(items: [screenshot.url])
        if let view = NSApp.keyWindow?.contentView {
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }
}
