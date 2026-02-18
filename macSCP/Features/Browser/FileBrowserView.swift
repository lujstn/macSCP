//
//  FileBrowserView.swift
//  macSCP
//
//  Main file browser view
//

import SwiftUI

struct FileBrowserView: View {
    @Bindable var viewModel: FileBrowserViewModel
    @Environment(\.openWindow) private var openWindow

    init(viewModel: FileBrowserViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        #if os(iOS)
        iOSBody
        #else
        macOSBody
        #endif
    }

    // MARK: - macOS Body

    #if os(macOS)
    private var macOSBody: some View {
        VStack(spacing: 0) {
            // Toolbar
            BrowserToolbar(viewModel: viewModel)

            Divider()

            // Breadcrumb
            BreadcrumbView(
                components: viewModel.pathComponents,
                onNavigate: { path in
                    Task {
                        await viewModel.navigateTo(path)
                    }
                }
            )

            Divider()

            // Content
            contentView

            Divider()

            // Status Bar
            statusBar
        }
        .frame(minWidth: WindowSize.minFileBrowser.width, minHeight: WindowSize.minFileBrowser.height)
        .modifier(SharedFileBrowserModifiers(viewModel: viewModel, openWindow: openWindow))
    }
    #endif

    // MARK: - iOS Body

    #if os(iOS)
    private var iOSBody: some View {
        NavigationStack {
            contentView
                .navigationTitle(viewModel.connection.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // Navigation buttons
                    ToolbarItemGroup(placement: .navigation) {
                        Button {
                            Task { await viewModel.goBack() }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(!viewModel.canGoBack)

                        Button {
                            Task { await viewModel.goForward() }
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(!viewModel.canGoForward)
                    }

                    // Primary actions
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            Task { await viewModel.goUp() }
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                        .disabled(!viewModel.canGoUp)

                        Button {
                            Task { await viewModel.goHome() }
                        } label: {
                            Image(systemName: "house")
                        }

                        Button {
                            Task { await viewModel.refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }

                        Menu {
                            Button {
                                viewModel.isShowingNewFolderSheet = true
                            } label: {
                                Label("New Folder", systemImage: "folder.badge.plus")
                            }

                            Button {
                                viewModel.isShowingNewFileSheet = true
                            } label: {
                                Label("New File", systemImage: "doc.badge.plus")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }

                    // Secondary actions
                    ToolbarItemGroup(placement: .secondaryAction) {
                        Button {
                            viewModel.copySelectedFiles()
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .disabled(viewModel.selectedFiles.isEmpty)

                        Button {
                            viewModel.cutSelectedFiles()
                        } label: {
                            Label("Cut", systemImage: "scissors")
                        }
                        .disabled(viewModel.selectedFiles.isEmpty)

                        Button {
                            Task { await viewModel.paste() }
                        } label: {
                            Label("Paste", systemImage: "doc.on.clipboard")
                        }
                        .disabled(!viewModel.canPaste)

                        Button(role: .destructive) {
                            viewModel.confirmDeleteSelected()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(viewModel.selectedFiles.isEmpty)

                        Divider()

                        if viewModel.connection.connectionType == .sftp {
                            Button {
                                viewModel.openTerminal()
                            } label: {
                                Label("Terminal", systemImage: "terminal")
                            }
                            .disabled(!viewModel.isConnected)
                        }

                        TransfersToolbarButton(viewModel: viewModel)

                        Divider()

                        Toggle(isOn: $viewModel.showHiddenFiles) {
                            Label("Hidden Files", systemImage: viewModel.showHiddenFiles ? "eye.fill" : "eye.slash")
                        }

                        Menu {
                            ForEach(RemoteFile.SortCriteria.allCases, id: \.self) { criteria in
                                Button {
                                    if viewModel.sortCriteria == criteria {
                                        viewModel.sortAscending.toggle()
                                    } else {
                                        viewModel.sortCriteria = criteria
                                        viewModel.sortAscending = true
                                    }
                                } label: {
                                    HStack {
                                        Text(criteria.rawValue)
                                        Spacer()
                                        if viewModel.sortCriteria == criteria {
                                            Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                        }
                    }
                }
                .safeAreaInset(edge: .top) {
                    BreadcrumbView(
                        components: viewModel.pathComponents,
                        onNavigate: { path in
                            Task {
                                await viewModel.navigateTo(path)
                            }
                        }
                    )
                }
                .safeAreaInset(edge: .bottom) {
                    statusBar
                        .background(.bar)
                }
        }
        .modifier(SharedFileBrowserModifiers(viewModel: viewModel, openWindow: openWindow))
    }
    #endif

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView(message: viewModel.isConnected ? "Loading..." : "Connecting...")

        case .success:
            if viewModel.sortedFiles.isEmpty {
                EmptyStateView.noFiles
            } else {
                FileListView(
                    viewModel: viewModel,
                    onOpenEditor: openFileInEditor,
                    onGetInfo: showFileInfo
                )
            }

        case .error(let error):
            ErrorView(error: error) {
                Task {
                    if viewModel.isConnected {
                        await viewModel.refresh()
                    } else {
                        await viewModel.connect()
                    }
                }
            }
        }
    }

    private var statusBar: some View {
        HStack(spacing: 16) {
            // Connection status
            HStack(spacing: 6) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: viewModel.isConnected
                                ? [.green.opacity(0.8), .green]
                                : [.red.opacity(0.8), .red],
                            center: .center,
                            startRadius: 0,
                            endRadius: 4
                        )
                    )
                    .frame(width: 8, height: 8)
                    .shadow(color: viewModel.isConnected ? .green.opacity(0.5) : .red.opacity(0.5), radius: 2)

                Text(viewModel.isConnected ? viewModel.connection.connectionString : "Disconnected")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Active transfers indicator (clicking opens the popover)
            if viewModel.hasActiveTransfers {
                ActiveTransfersIndicator(viewModel: viewModel)
            }

            // Clipboard status
            if viewModel.hasClipboardItems && !viewModel.hasActiveTransfers {
                ClipboardStatusView(displayText: viewModel.clipboardDisplayText)
            }

            Spacer()

            // File count
            HStack(spacing: 8) {
                Text("\(viewModel.sortedFiles.count) items")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                if !viewModel.selectedFiles.isEmpty {
                    Text("\(viewModel.selectedFiles.count) selected")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1), in: Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func openFileInEditor(_ file: RemoteFile) {
        Task {
            do {
                let content = try await viewModel.getFileContent(file)
                viewModel.openEditor(for: file, content: content)
            } catch {
                viewModel.error = AppError.from(error)
            }
        }
    }

    private func showFileInfo(_ file: RemoteFile) {
        viewModel.showFileInfo(file)
    }
}

// MARK: - Shared Modifiers

/// Shared modifiers applied to both macOS and iOS body variants.
/// Contains sheets, alerts, lifecycle tasks, and window-opening handlers.
private struct SharedFileBrowserModifiers: ViewModifier {
    @Bindable var viewModel: FileBrowserViewModel
    var openWindow: OpenWindowAction

    func body(content: Content) -> some View {
        content
            .task {
                await viewModel.connect()
            }
            .sheet(isPresented: $viewModel.isShowingNewFolderSheet) {
                NameInputSheet.newFolder(
                    onConfirm: { name in
                        Task {
                            await viewModel.createFolder(name: name)
                        }
                    },
                    onCancel: {
                        viewModel.isShowingNewFolderSheet = false
                    }
                )
            }
            .sheet(isPresented: $viewModel.isShowingNewFileSheet) {
                NameInputSheet.newFile(
                    onConfirm: { name in
                        Task {
                            await viewModel.createFile(name: name)
                        }
                    },
                    onCancel: {
                        viewModel.isShowingNewFileSheet = false
                    }
                )
            }
            .sheet(isPresented: $viewModel.isShowingRenameSheet) {
                if let file = viewModel.fileToRename {
                    NameInputSheet.rename(
                        currentName: file.name,
                        onConfirm: { newName in
                            Task {
                                await viewModel.renameFile(file, to: newName)
                            }
                        },
                        onCancel: {
                            viewModel.isShowingRenameSheet = false
                            viewModel.fileToRename = nil
                        }
                    )
                }
            }
            .alert("Delete Files", isPresented: $viewModel.isShowingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteFiles(viewModel.filesToDelete)
                    }
                }
            } message: {
                let count = viewModel.filesToDelete.count
                Text("Are you sure you want to delete \(count) item\(count == 1 ? "" : "s")? This cannot be undone.")
            }
            .errorAlert($viewModel.error)
            .onDisappear {
                Task {
                    await viewModel.disconnect()
                }
            }
            .onChange(of: viewModel.pendingFileInfoWindowId) { _, windowId in
                if let windowId = windowId {
                    openWindow(id: WindowID.fileInfo, value: windowId)
                    viewModel.clearPendingFileInfoWindow()
                }
            }
            .onChange(of: viewModel.pendingEditorWindowId) { _, windowId in
                if let windowId = windowId {
                    openWindow(id: WindowID.fileEditor, value: windowId)
                    viewModel.clearPendingEditorWindow()
                }
            }
            .onChange(of: viewModel.pendingTerminalWindowId) { _, windowId in
                if let windowId = windowId {
                    openWindow(id: WindowID.terminal, value: windowId)
                    viewModel.clearPendingTerminalWindow()
                }
            }
    }
}

// MARK: - Clipboard Status View
struct ClipboardStatusView: View {
    let displayText: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.blue)

            Text(displayText)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(.blue.opacity(0.1))
                .overlay {
                    Capsule()
                        .strokeBorder(.blue.opacity(0.2), lineWidth: 1)
                }
        }
    }
}

// MARK: - Active Transfers Indicator
struct ActiveTransfersIndicator: View {
    @Bindable var viewModel: FileBrowserViewModel

    var body: some View {
        Button {
            viewModel.isShowingTransfersPopover = true
        } label: {
            HStack(spacing: 8) {
                // Upload icon with animation
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, options: .repeating)

                // Transfer count and overall progress
                Text("Uploading \(viewModel.activeTransferCount) file\(viewModel.activeTransferCount == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .medium))

                // Overall progress bar
                ProgressView(value: viewModel.overallProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 60)

                // Percentage
                Text("\(Int(viewModel.overallProgress * 100))%")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(.blue.opacity(0.1))
                    .overlay {
                        Capsule()
                            .strokeBorder(.blue.opacity(0.3), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    FileBrowserView(
        viewModel: DependencyContainer.shared.makeFileBrowserViewModel(
            connection: Connection(name: "Test", host: "localhost", username: "user"),
            sftpSession: SFTPSession(),
            password: "test"
        )
    )
}
