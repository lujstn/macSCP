//
//  FileRowView.swift
//  macSCP
//
//  Row view for a single file in the file list - Modern macOS style
//

import SwiftUI

struct FileRowView: View {
    let file: RemoteFile
    let isSelected: Bool
    let onDoubleClick: () -> Void

    private var rowContent: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: FileTypeService.iconName(for: file))
                .font(.system(size: 20))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(FileTypeService.iconColor(for: file))
                .frame(width: 24)

            // Name
            Text(file.name)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            #if os(iOS)
            // Size — flexible width on iOS
            Text(file.displaySize)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            // Date — flexible width on iOS
            Text(file.modificationDate?.fileListDisplayString ?? "—")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            #else
            // Size
            Text(file.displaySize)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)

            // Date
            Text(file.modificationDate?.fileListDisplayString ?? "—")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .trailing)

            // Permissions — hidden on iOS
            Text(file.permissions)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 90, alignment: .trailing)
            #endif
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    var body: some View {
#if os(iOS)
        Button(action: onDoubleClick) {
            rowContent
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
#else
        rowContent
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                onDoubleClick()
            }
#endif
    }
}

// MARK: - File Icon View
struct FileIconView: View {
    let file: RemoteFile

    var body: some View {
        Image(systemName: FileTypeService.iconName(for: file))
            .font(.title3)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(FileTypeService.iconColor(for: file))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 0) {
        FileRowView(
            file: RemoteFile(
                name: "Documents",
                path: "/home/user/Documents",
                isDirectory: true,
                size: 0,
                permissions: "drwxr-xr-x",
                modificationDate: Date()
            ),
            isSelected: false,
            onDoubleClick: {}
        )

        Divider()
            .padding(.leading, 48)

        FileRowView(
            file: RemoteFile(
                name: "config.json",
                path: "/home/user/config.json",
                isDirectory: false,
                size: 1024,
                permissions: "-rw-r--r--",
                modificationDate: Date()
            ),
            isSelected: true,
            onDoubleClick: {}
        )

        Divider()
            .padding(.leading, 48)

        FileRowView(
            file: RemoteFile(
                name: "photo.jpg",
                path: "/home/user/photo.jpg",
                isDirectory: false,
                size: 2048576,
                permissions: "-rw-r--r--",
                modificationDate: nil
            ),
            isSelected: false,
            onDoubleClick: {}
        )
    }
    .padding()
    .background(Color.platformWindowBackground)
}
