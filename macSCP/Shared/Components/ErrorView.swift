//
//  ErrorView.swift
//  macSCP
//
//  Reusable error display view - Modern macOS style
//

import SwiftUI

struct ErrorView: View {
    let error: AppError
    let retryAction: (() -> Void)?

    init(error: AppError, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 20) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.red.opacity(0.15), .orange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "exclamationmark.triangle.fill")
                    #if os(iOS)
                    .font(.title.weight(.medium))
                    #else
                    .font(.system(size: 32, weight: .medium))
                    #endif
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.red)
            }

            VStack(spacing: 8) {
                Text("Something Went Wrong")
                    #if os(iOS)
                    .font(.headline)
                    #else
                    .font(.system(size: 17, weight: .semibold))
                    #endif
                    .foregroundStyle(.primary)

                Text(error.localizedDescription)
                    #if os(iOS)
                    .font(.subheadline)
                    #else
                    .font(.system(size: 13))
                    #endif
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        #if os(iOS)
                        .font(.footnote)
                        #else
                        .font(.system(size: 12))
                        #endif
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }

            if let retryAction = retryAction {
                Button {
                    retryAction()
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        #if os(iOS)
                        .font(.subheadline.weight(.medium))
                        #else
                        .font(.system(size: 13, weight: .medium))
                        #endif
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Compact Error View
struct CompactErrorView: View {
    let message: String
    let dismissAction: (() -> Void)?

    @State private var isHovering = false

    init(message: String, dismissAction: (() -> Void)? = nil) {
        self.message = message
        self.dismissAction = dismissAction
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                #if os(iOS)
                .font(.callout.weight(.medium))
                #else
                .font(.system(size: 14, weight: .medium))
                #endif
                .foregroundStyle(.red)

            Text(message)
                #if os(iOS)
                .font(.footnote)
                #else
                .font(.system(size: 12))
                #endif
                .foregroundStyle(.primary)

            Spacer()

            if let dismissAction = dismissAction {
                Button {
                    dismissAction()
                } label: {
                    Image(systemName: "xmark")
                        #if os(iOS)
                        .font(.caption2.bold())
                        #else
                        .font(.system(size: 10, weight: .bold))
                        #endif
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                        .background {
                            Circle()
                                .fill(isHovering ? Color.primary.opacity(0.1) : .clear)
                        }
                }
                #if os(iOS)
                .buttonStyle(.borderless)
                #else
                .buttonStyle(.plain)
                #endif
                .onHover { hovering in
                    isHovering = hovering
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.red.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.red.opacity(0.2), lineWidth: 1)
                }
        }
    }
}

// MARK: - Banner Error View
struct ErrorBannerView: View {
    let message: String
    let dismissAction: (() -> Void)?

    init(message: String, dismissAction: (() -> Void)? = nil) {
        self.message = message
        self.dismissAction = dismissAction
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                #if os(iOS)
                .font(.body)
                #else
                .font(.system(size: 16))
                #endif
                .foregroundStyle(.white)

            Text(message)
                #if os(iOS)
                .font(.subheadline.weight(.medium))
                #else
                .font(.system(size: 13, weight: .medium))
                #endif
                .foregroundStyle(.white)

            Spacer()

            if let dismissAction = dismissAction {
                Button {
                    dismissAction()
                } label: {
                    Image(systemName: "xmark")
                        #if os(iOS)
                        .font(.footnote.bold())
                        #else
                        .font(.system(size: 12, weight: .bold))
                        #endif
                        .foregroundStyle(.white.opacity(0.8))
                }
                #if os(iOS)
                .buttonStyle(.borderless)
                #else
                .buttonStyle(.plain)
                #endif
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [.red, .red.opacity(0.9)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Error Alert Modifier
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?

    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                ),
                presenting: error
            ) { _ in
                Button("OK", role: .cancel) {
                    error = nil
                }
            } message: { error in
                Text(error.localizedDescription)
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<AppError?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}

// MARK: - Preview
#Preview("Error View") {
    ErrorView(
        error: .connectionFailed("Connection refused"),
        retryAction: {}
    )
    .frame(width: 350, height: 350)
    .background(Color.platformWindowBackground)
}

#Preview("Compact Error") {
    VStack(spacing: 16) {
        CompactErrorView(
            message: "Failed to load files",
            dismissAction: {}
        )

        CompactErrorView(
            message: "Network connection lost"
        )
    }
    .padding()
    .frame(width: 350)
}

#Preview("Error Banner") {
    VStack {
        ErrorBannerView(
            message: "Unable to connect to server",
            dismissAction: {}
        )
        Spacer()
    }
    .padding()
    .frame(width: 400, height: 200)
    .background(Color.platformWindowBackground)
}
