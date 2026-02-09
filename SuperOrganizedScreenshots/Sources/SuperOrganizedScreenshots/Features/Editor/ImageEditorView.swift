import SwiftUI

struct ImageEditorView: View {
    @StateObject private var viewModel: ImageEditorViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    init(screenshot: Screenshot) {
        _viewModel = StateObject(wrappedValue: ImageEditorViewModel(screenshot: screenshot))
    }

    var body: some View {
        HSplitView {
            toolPalette
                .frame(width: 80)

            canvasArea
        }
        .frame(minWidth: 800, minHeight: 600)
        .toolbar {
            ToolbarItemGroup(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItemGroup(placement: .principal) {
                Button {
                    viewModel.undo()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!viewModel.canUndo)
                .keyboardShortcut("z", modifiers: .command)

                Button {
                    viewModel.redo()
                } label: {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .disabled(!viewModel.canRedo)
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }

            ToolbarItemGroup(placement: .confirmationAction) {
                Button {
                    copyToClipboard()
                } label: {
                    Label("Copy to Clipboard", systemImage: "doc.on.doc")
                }
                .help("Copy image with edits to clipboard")

                Button("Save") {
                    saveAndDismiss()
                }
                .disabled(!viewModel.hasUnsavedChanges)
                .keyboardShortcut("s", modifiers: .command)
            }
        }
    }

    private var toolPalette: some View {
        VStack(spacing: 16) {
            toolSelector

            Divider()

            colorPicker

            Divider()

            strokeWidthControl

            Spacer()
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var toolSelector: some View {
        VStack(spacing: 8) {
            ForEach(ToolType.allCases) { tool in
                Button {
                    viewModel.selectedTool = tool
                } label: {
                    Image(systemName: tool.iconName)
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.selectedTool == tool ? Color.accentColor : Color.clear)
                        )
                        .foregroundColor(viewModel.selectedTool == tool ? .white : .primary)
                }
                .buttonStyle(.plain)
                .help(tool.displayName)
            }
        }
    }

    private var colorPicker: some View {
        VStack(spacing: 8) {
            Text("Color")
                .font(.caption)
                .foregroundColor(.secondary)

            ColorPicker("", selection: $viewModel.selectedColor)
                .labelsHidden()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 20))], spacing: 4) {
                ForEach(presetColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(viewModel.selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            viewModel.selectedColor = color
                        }
                }
            }
        }
    }

    private var presetColors: [Color] {
        [.red, .orange, .yellow, .green, .blue, .purple, .black, .white]
    }

    private var strokeWidthControl: some View {
        VStack(spacing: 4) {
            Text("Size")
                .font(.caption)
                .foregroundColor(.secondary)

            Slider(value: $viewModel.strokeWidth, in: 1...20, step: 1)

            Text("\(Int(viewModel.strokeWidth))px")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var canvasArea: some View {
        CanvasView(viewModel: viewModel)
            .background(Color(nsColor: .windowBackgroundColor))
    }

    private func copyToClipboard() {
        let image = viewModel.renderFinalImage()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        dismiss()
    }

    private func saveAndDismiss() {
        Task {
            try? await viewModel.save()
            try? await appState.updateScreenshot(viewModel.screenshot, with: viewModel.image)
            dismiss()
        }
    }
}
