//
//  FileEditorView.swift
//  macSCP
//
//  Main file editor view
//

import SwiftUI

struct FileEditorView: View {
    @Bindable var viewModel: FileEditorViewModel

    init(viewModel: FileEditorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        #if os(iOS)
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isShowingSearch {
                    SearchReplaceBar(viewModel: viewModel)
                }

                EditorContentView(viewModel: viewModel)
            }
            .navigationTitle(viewModel.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        viewModel.toggleSearch()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .keyboardShortcut("f", modifiers: .command)

                    Button {
                        Task { await viewModel.reload() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }

                    Button {
                        viewModel.revertChanges()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(!viewModel.hasChanges)

                    Button {
                        Task { await viewModel.save() }
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .keyboardShortcut("s", modifiers: .command)
                    .disabled(!viewModel.hasChanges)
                }

                ToolbarItem(placement: .status) {
                    if viewModel.hasChanges {
                        Circle()
                            .fill(.orange)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                EditorStatusBar(viewModel: viewModel)
                    .background(.bar)
            }
        }
        .errorAlert($viewModel.error)
        #else
        VStack(spacing: 0) {
            // Header
            EditorHeaderView(viewModel: viewModel)

            Divider()

            // Search bar (conditional)
            if viewModel.isShowingSearch {
                SearchReplaceBar(viewModel: viewModel)
                Divider()
            }

            // Editor content
            EditorContentView(viewModel: viewModel)

            Divider()

            // Status bar
            EditorStatusBar(viewModel: viewModel)
        }
        .frame(minWidth: WindowSize.fileEditor.width, minHeight: WindowSize.fileEditor.height)
        .errorAlert($viewModel.error)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.toggleSearch()
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .keyboardShortcut("f", modifiers: .command)

                Button {
                    Task {
                        await viewModel.save()
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!viewModel.hasChanges)
            }
        }
        #endif
    }
}

// MARK: - Preview
#Preview {
    FileEditorView(viewModel: FileEditorViewModel(
        filePath: "/home/user/test.txt",
        fileName: "test.txt",
        initialContent: "Hello, World!\n\nThis is a test file.",
        fileRepository: FileRepository(sftpSession: SFTPSession())
    ))
}
