import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedScreenshot: Screenshot?
    @State private var isEditing: Bool = false
    @State private var searchText: String = ""
    @State private var showingDeleteConfirmation: Bool = false
    @State private var screenshotToDelete: Screenshot?

    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
    ]

    var filteredScreenshots: [Screenshot] {
        if searchText.isEmpty {
            return appState.screenshots
        }
        return appState.screenshots.filter {
            $0.filename.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .searchable(text: $searchText, prompt: "Search screenshots")
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $isEditing) {
            if let screenshot = selectedScreenshot {
                ImageEditorView(screenshot: screenshot)
                    .environmentObject(appState)
            }
        }
        .alert("Delete Screenshot?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let screenshot = screenshotToDelete {
                    deleteScreenshot(screenshot)
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .onAppear {
            Task {
                await appState.loadScreenshots()
            }
        }
    }

    @ViewBuilder
    private var sidebarContent: some View {
        if !appState.hasScreenRecordingPermission {
            permissionRequestView
        } else if appState.screenshots.isEmpty {
            emptyStateView
        } else {
            screenshotGrid
        }
    }

    private var permissionRequestView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Screen Recording Permission Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Super Organized Screenshots needs permission to capture your screen.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Open System Settings") {
                appState.requestPermissions()
            }
            .buttonStyle(.borderedProminent)

            Button("Check Again") {
                Task {
                    await appState.checkPermissions()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Screenshots Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Press ⌘⇧3 for full screen or ⌘⇧4 for selection")
                .foregroundColor(.secondary)

            Button("Take Full Screen Screenshot") {
                Task {
                    try? await appState.captureFullScreen()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var screenshotGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredScreenshots) { screenshot in
                    ScreenshotThumbnailView(
                        screenshot: screenshot,
                        isSelected: selectedScreenshot?.id == screenshot.id
                    )
                    .onTapGesture {
                        selectedScreenshot = screenshot
                    }
                    .contextMenu {
                        contextMenuItems(for: screenshot)
                    }
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        if let screenshot = selectedScreenshot {
            ScreenshotDetailView(screenshot: screenshot)
                .environmentObject(appState)
        } else {
            Text("Select a screenshot")
                .foregroundColor(.secondary)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                ScreenshotModeCoordinator.shared.activate()
            } label: {
                Label("Screenshot Mode", systemImage: "camera.viewfinder")
            }
            .help("Enter screenshot mode (\(HotkeyManager.shared.shortcut.displayString))")
        }

        ToolbarItem {
            Button {
                Task {
                    await appState.loadScreenshots()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .help("Refresh screenshot list")
        }
    }

    @ViewBuilder
    private func contextMenuItems(for screenshot: Screenshot) -> some View {
        Button {
            selectedScreenshot = screenshot
            isEditing = true
        } label: {
            Label("Edit", systemImage: "pencil")
        }

        Button {
            NSWorkspace.shared.activateFileViewerSelecting([screenshot.url])
        } label: {
            Label("Show in Finder", systemImage: "folder")
        }

        Divider()

        Button(role: .destructive) {
            screenshotToDelete = screenshot
            showingDeleteConfirmation = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func deleteScreenshot(_ screenshot: Screenshot) {
        Task {
            try? await appState.deleteScreenshot(screenshot)
            if selectedScreenshot?.id == screenshot.id {
                selectedScreenshot = nil
            }
        }
    }
}
