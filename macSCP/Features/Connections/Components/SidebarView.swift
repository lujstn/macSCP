//
//  SidebarView.swift
//  macSCP
//
//  Sidebar view for connection folders - Minimal macOS style
//

import SwiftUI

struct SidebarView: View {
    @Bindable var viewModel: ConnectionListViewModel
    @Environment(\.openURL) private var openURL

    private let gitHubIssuesURL = URL(string: "https://github.com/macnev2013/macSCP/issues")!

    // Check if All Connections is selected
    private var isAllConnectionsSelected: Bool {
        viewModel.selectedSidebarItem == .allConnections
    }

    // Check if a specific folder is selected
    private func isFolderSelected(_ folderId: UUID) -> Bool {
        if case .folder(let id) = viewModel.selectedSidebarItem {
            return id == folderId
        }
        return false
    }

    private var sidebarSelection: Binding<SidebarSelection?> {
        Binding(
            get: { viewModel.selectedSidebarItem },
            set: { viewModel.selectedSidebarItem = $0 ?? .allConnections }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            List(selection: sidebarSelection) {
                // All Connections
                NavigationLink(value: SidebarSelection.allConnections) {
                    Label {
                        Text("All Connections")
                    } icon: {
                        Image(systemName: "server.rack")
                            #if os(macOS)
                            .foregroundStyle(Color(red: 0, green: 122/255.0, blue: 1))
                            #endif
                    }
                }
                #if os(macOS)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isAllConnectionsSelected ? Color.black.opacity(0.05) : .clear)
                        .padding(.horizontal, 4)
                )
                #endif

                // Folders Section
                Section("Folders") {
                    ForEach(viewModel.folders) { folder in
                        NavigationLink(value: SidebarSelection.folder(folder.id)) {
                            FolderRowView(
                                folder: folder,
                                connectionCount: viewModel.connectionCount(for: folder.id),
                                isSelected: isFolderSelected(folder.id),
                                onRename: { newName in
                                    Task {
                                        await viewModel.renameFolder(folder, to: newName)
                                    }
                                },
                                onDelete: {
                                    viewModel.confirmDeleteFolder(folder)
                                }
                            )
                        }
                        #if os(macOS)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isFolderSelected(folder.id) ? Color.black.opacity(0.05) : .clear)
                                .padding(.horizontal, 4)
                        )
                        #endif
                    }

                    // New Folder Button
                    Button {
                        viewModel.isShowingNewFolderSheet = true
                    } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                            .foregroundStyle(.secondary)
                    }
                    #if os(iOS)
                    .buttonStyle(.borderless)
                    #else
                    .buttonStyle(.plain)
                    #endif
                }
                #if os(iOS)
                .headerProminence(.increased)
                #endif
            }
            .listStyle(.sidebar)
            #if os(macOS)
            .scrollContentBackground(.hidden)
            #endif

            // Report Bug Card
            Button {
                openURL(gitHubIssuesURL)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "ladybug.fill")
                        #if os(iOS)
                        .font(.headline)
                        #else
                        .font(.system(size: 17))
                        #endif
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Found a bug?")
                            #if os(iOS)
                            .font(.callout.weight(.medium))
                            #else
                            .font(.system(size: 14, weight: .medium))
                            #endif
                            .foregroundStyle(.primary)
                        Text("Report it on GitHub")
                            #if os(iOS)
                            .font(.subheadline)
                            #else
                            .font(.system(size: 13))
                            #endif
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        #if os(iOS)
                        .font(.subheadline.weight(.medium))
                        #else
                        .font(.system(size: 13, weight: .medium))
                        #endif
                        .foregroundStyle(.tertiary)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.05))
                )
            }
            #if os(iOS)
            .buttonStyle(.borderless)
            #else
            .buttonStyle(.plain)
            #endif
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        #if os(macOS)
        .background(Color(red: 247/255.0, green: 247/255.0, blue: 247/255.0))
        .frame(minWidth: 230, idealWidth: 230)
        #endif
    }
}

// MARK: - Folder Row
struct FolderRowView: View {
    let folder: Folder
    let connectionCount: Int
    let isSelected: Bool
    let onRename: (String) -> Void
    let onDelete: () -> Void

    @State private var isRenaming = false
    @State private var newName: String = ""

    var body: some View {
        Label {
            if isRenaming {
                TextField("Name", text: $newName)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        if !newName.trimmed.isEmpty {
                            onRename(newName.trimmed)
                        }
                        isRenaming = false
                    }
                    .onAppear {
                        newName = folder.name
                    }
            } else {
                Text(folder.name)
            }
        } icon: {
            Image(systemName: "folder.fill")
                .foregroundStyle(.cyan)
        }
        .contextMenu {
            Button {
                newName = folder.name
                isRenaming = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SidebarView(viewModel: DependencyContainer.shared.makeConnectionListViewModel())
        .frame(width: 250)
}
