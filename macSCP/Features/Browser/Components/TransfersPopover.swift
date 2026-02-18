//
//  TransfersPopover.swift
//  macSCP
//
//  Safari-style popover showing file transfer progress
//

import SwiftUI

struct TransfersPopover: View {
    @Bindable var viewModel: FileBrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Content
            if viewModel.allTransfers.isEmpty {
                emptyState
            } else {
                transfersList
            }
        }
        #if os(macOS)
        .frame(width: 320, height: min(CGFloat(viewModel.allTransfers.count * 72 + 52), 400))
        .background(.ultraThickMaterial)
        #endif
    }

    private var header: some View {
        HStack {
            Text("Transfers")
                #if os(iOS)
                .font(.subheadline.weight(.semibold))
                #else
                .font(.system(size: 13, weight: .semibold))
                #endif

            Spacer()

            // Cancel all button (shown when there are active transfers)
            if viewModel.hasActiveTransfers {
                Button("Cancel All") {
                    viewModel.cancelAllTransfers()
                }
                #if os(iOS)
                .buttonStyle(.borderless)
                .font(.footnote)
                #else
                .buttonStyle(.plain)
                .font(.system(size: 12))
                #endif
                .foregroundStyle(.red)
            }

            // Clear completed button
            if !viewModel.recentTransfers.isEmpty {
                Button("Clear") {
                    viewModel.clearCompletedTransfers()
                }
                #if os(iOS)
                .buttonStyle(.borderless)
                .font(.footnote)
                #else
                .buttonStyle(.plain)
                .font(.system(size: 12))
                #endif
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.up.arrow.down.circle")
                #if os(iOS)
                .font(.title.weight(.light))
                #else
                .font(.system(size: 32, weight: .light))
                #endif
                .foregroundStyle(.tertiary)

            Text("No transfers")
                #if os(iOS)
                .font(.footnote)
                #else
                .font(.system(size: 12))
                #endif
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 32)
    }

    private var transfersList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.allTransfers) { transfer in
                    TransferItemView(
                        transfer: transfer,
                        onCancel: {
                            viewModel.cancelTransfer(transfer)
                        },
                        onRemove: {
                            viewModel.removeTransfer(transfer)
                        }
                    )

                    if transfer.id != viewModel.allTransfers.last?.id {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
        }
    }
}

// MARK: - Transfer Item View
struct TransferItemView: View {
    let transfer: TransferProgress
    let onCancel: () -> Void
    let onRemove: () -> Void

    #if os(macOS)
    @State private var isHovering = false
    #endif

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon
                .frame(width: 28, height: 28)

            // File info and progress
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(transfer.fileName)
                        #if os(iOS)
                        .font(.footnote.weight(.medium))
                        #else
                        .font(.system(size: 12, weight: .medium))
                        #endif
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    if transfer.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            #if os(iOS)
                            .font(.footnote)
                            #else
                            .font(.system(size: 12))
                            #endif
                            .foregroundStyle(.green)
                    } else if transfer.status == .failed {
                        Image(systemName: "exclamationmark.circle.fill")
                            #if os(iOS)
                            .font(.footnote)
                            #else
                            .font(.system(size: 12))
                            #endif
                            .foregroundStyle(.red)
                    } else if transfer.status == .cancelled {
                        Image(systemName: "slash.circle.fill")
                            #if os(iOS)
                            .font(.footnote)
                            #else
                            .font(.system(size: 12))
                            #endif
                            .foregroundStyle(.orange)
                    }
                }

                if transfer.isInProgress {
                    // Progress bar
                    ProgressView(value: transfer.fractionCompleted)
                        .progressViewStyle(.linear)
                        .tint(.accentColor)

                    // Progress text
                    HStack {
                        Text(transfer.progressText)
                            #if os(iOS)
                            .font(.caption2)
                            #else
                            .font(.system(size: 10))
                            #endif
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(transfer.percentCompleted)%")
                            #if os(iOS)
                            .font(.caption2.weight(.medium).monospaced())
                            #else
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            #endif
                            .foregroundStyle(.secondary)
                    }
                } else if transfer.isComplete {
                    Text(transfer.totalSizeText)
                        #if os(iOS)
                        .font(.caption2)
                        #else
                        .font(.system(size: 10))
                        #endif
                        .foregroundStyle(.secondary)
                } else if transfer.status == .failed {
                    Text(transfer.error ?? "Upload failed")
                        #if os(iOS)
                        .font(.caption2)
                        #else
                        .font(.system(size: 10))
                        #endif
                        .foregroundStyle(.red)
                        .lineLimit(1)
                } else if transfer.status == .cancelled {
                    Text("Cancelled")
                        #if os(iOS)
                        .font(.caption2)
                        #else
                        .font(.system(size: 10))
                        #endif
                        .foregroundStyle(.orange)
                }
            }

            // Cancel button for active transfers
            if transfer.isInProgress {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        #if os(iOS)
                        .font(.body)
                        #else
                        .font(.system(size: 16))
                        #endif
                        .foregroundStyle(.secondary)
                }
                #if os(iOS)
                .buttonStyle(.borderless)
                #else
                .buttonStyle(.plain)
                .help("Cancel upload")
                #endif
            }

            // Remove button for completed/failed/cancelled
            #if os(iOS)
            if !transfer.isInProgress {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            #else
            // shown on hover for completed/failed/cancelled
            if !transfer.isInProgress && isHovering {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            #endif
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        #if os(macOS)
        .background(isHovering ? Color.primary.opacity(0.04) : .clear)
        .onHover { hovering in
            isHovering = hovering
        }
        #endif
    }

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(statusBackgroundColor)

            if transfer.isInProgress {
                // Animated upload icon
                Image(systemName: "arrow.up")
                    #if os(iOS)
                    .font(.footnote.weight(.semibold))
                    #else
                    .font(.system(size: 12, weight: .semibold))
                    #endif
                    .foregroundStyle(.white)
            } else if transfer.isComplete {
                Image(systemName: "checkmark")
                    #if os(iOS)
                    .font(.footnote.weight(.semibold))
                    #else
                    .font(.system(size: 12, weight: .semibold))
                    #endif
                    .foregroundStyle(.white)
            } else if transfer.status == .failed {
                Image(systemName: "exclamationmark")
                    #if os(iOS)
                    .font(.footnote.weight(.semibold))
                    #else
                    .font(.system(size: 12, weight: .semibold))
                    #endif
                    .foregroundStyle(.white)
            } else if transfer.status == .cancelled {
                Image(systemName: "stop.fill")
                    #if os(iOS)
                    .font(.caption2.weight(.semibold))
                    #else
                    .font(.system(size: 10, weight: .semibold))
                    #endif
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "clock")
                    #if os(iOS)
                    .font(.footnote.weight(.semibold))
                    #else
                    .font(.system(size: 12, weight: .semibold))
                    #endif
                    .foregroundStyle(.white)
            }
        }
    }

    private var statusBackgroundColor: Color {
        switch transfer.status {
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .pending:
            return .orange
        case .cancelled:
            return .gray
        }
    }
}

// MARK: - Toolbar Transfers Button
struct TransfersToolbarButton: View {
    @Bindable var viewModel: FileBrowserViewModel

    #if os(macOS)
    @State private var isHovering = false
    #endif

    var body: some View {
        Button {
            viewModel.isShowingTransfersPopover.toggle()
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: viewModel.hasActiveTransfers ? "arrow.up.circle.fill" : "arrow.up.arrow.down.circle")
                    #if os(iOS)
                    .font(.callout.weight(.medium))
                    #else
                    .font(.system(size: 14, weight: .medium))
                    #endif
                    .foregroundStyle(viewModel.hasActiveTransfers ? .blue : .primary)
                    .frame(width: 28, height: 28)
                    #if os(macOS)
                    .background {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isHovering ? Color.primary.opacity(0.06) : .clear)
                    }
                    #endif
                    .symbolEffect(.pulse, options: .repeating, isActive: viewModel.hasActiveTransfers)

                // Badge for active transfer count
                if viewModel.activeTransferCount > 0 {
                    Text("\(viewModel.activeTransferCount)")
                        #if os(iOS)
                        .font(.caption2.bold())
                        #else
                        .font(.system(size: 9, weight: .bold))
                        #endif
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(.blue))
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
        #if os(iOS)
        .sheet(isPresented: $viewModel.isShowingTransfersPopover) {
            TransfersPopover(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        #else
        .onHover { hovering in
            isHovering = hovering
        }
        .popover(isPresented: $viewModel.isShowingTransfersPopover, arrowEdge: .bottom) {
            TransfersPopover(viewModel: viewModel)
        }
        .help("Transfers")
        #endif
    }
}

// MARK: - Preview
#Preview {
    TransfersPopover(
        viewModel: DependencyContainer.shared.makeFileBrowserViewModel(
            connection: Connection(name: "Test", host: "localhost", username: "user"),
            sftpSession: SFTPSession(),
            password: "test"
        )
    )
}
