import SwiftUI

struct ScreenshotToolbarView: View {
    var body: some View {
        HStack(spacing: 12) {
            Button {
                ScreenshotModeCoordinator.shared.selectRectangleMode()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "rectangle.dashed")
                        .font(.system(size: 16))
                    Text("Rectangle")
                        .font(.caption2)
                }
            }
            .buttonStyle(ToolbarButtonStyle())

            Button {
                ScreenshotModeCoordinator.shared.captureFullScreen()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "macwindow")
                        .font(.system(size: 16))
                    Text("Full Screen")
                        .font(.caption2)
                }
            }
            .buttonStyle(ToolbarButtonStyle())

            Divider()
                .frame(height: 28)

            Button {
                ScreenshotModeCoordinator.shared.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(ToolbarButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        )
    }
}

private struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? Color.white.opacity(0.2) : Color.clear)
            )
            .contentShape(Rectangle())
    }
}
