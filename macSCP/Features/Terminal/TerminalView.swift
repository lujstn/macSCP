//
//  TerminalView.swift
//  macSCP
//
//  Terminal view with SwiftTerm integration
//

import SwiftUI
import SwiftTerm
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Terminal View

struct TerminalContentView: View {
    @Bindable var viewModel: TerminalViewModel

    var body: some View {
        #if os(iOS)
        NavigationStack {
            terminalContent
                .navigationTitle(statusText)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .status) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                    }
                    ToolbarItem(placement: .primaryAction) {
                        reconnectButton
                    }
                }
        }
        .task {
            await viewModel.connect()
        }
        .onDisappear {
            Task {
                await viewModel.cleanup()
            }
        }
        .errorAlert($viewModel.error)
        #else
        VStack(spacing: 0) {
            // Toolbar
            terminalToolbar

            Divider()

            // Terminal content
            terminalContent
        }
        .frame(minWidth: WindowSize.minTerminal.width, minHeight: WindowSize.minTerminal.height)
        .task {
            await viewModel.connect()
        }
        .onDisappear {
            Task {
                await viewModel.cleanup()
            }
        }
        .errorAlert($viewModel.error)
        #endif
    }

    private var reconnectButton: some View {
        Button {
            Task {
                await viewModel.reconnect()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .disabled(viewModel.state == .connecting)
    }

    #if os(macOS)
    @ViewBuilder
    private var terminalToolbar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            reconnectButton
                .buttonStyle(.plain)
                .help("Reconnect")

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    #endif

    @ViewBuilder
    private var terminalContent: some View {
        switch viewModel.state {
        case .disconnected:
            ContentUnavailableView(
                "Disconnected",
                systemImage: "terminal",
                description: Text("Click Reconnect to establish a connection")
            )

        case .connecting:
            LoadingView(message: "Connecting...")

        case .connected:
            SwiftTermView(viewModel: viewModel)

        case .error(let error):
            ErrorView(error: error) {
                Task {
                    await viewModel.reconnect()
                }
            }
        }
    }

    private var statusColor: SwiftUI.Color {
        switch viewModel.state {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected, .error:
            return .red
        }
    }

    private var statusText: String {
        switch viewModel.state {
        case .connected:
            return viewModel.connectionName
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .error:
            return "Connection Error"
        }
    }
}

// MARK: - SwiftTerm View (Platform-Specific Wrapper)

#if os(macOS)
struct SwiftTermView: NSViewRepresentable {
    @Bindable var viewModel: TerminalViewModel

    func makeNSView(context: Context) -> SwiftTerm.TerminalView {
        let terminal = SwiftTerm.TerminalView()
        terminal.terminalDelegate = context.coordinator
        context.coordinator.terminal = terminal

        // Set up output callback
        viewModel.onOutput = { [weak coordinator = context.coordinator] data in
            DispatchQueue.main.async {
                coordinator?.terminal?.feed(byteArray: ArraySlice([UInt8](data)))
            }
        }

        // Focus after appearing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            terminal.window?.makeFirstResponder(terminal)
        }

        return terminal
    }

    func updateNSView(_ terminal: SwiftTerm.TerminalView, context: Context) {
        context.coordinator.terminal = terminal
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, SwiftTerm.TerminalViewDelegate {
        var viewModel: TerminalViewModel
        weak var terminal: SwiftTerm.TerminalView?

        init(viewModel: TerminalViewModel) {
            self.viewModel = viewModel
        }

        func sizeChanged(source: SwiftTerm.TerminalView, newCols: Int, newRows: Int) {
            guard newCols > 0, newRows > 0 else { return }
            viewModel.resize(columns: newCols, rows: newRows)
        }

        func setTerminalTitle(source: SwiftTerm.TerminalView, title: String) {}

        func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {}

        func send(source: SwiftTerm.TerminalView, data: ArraySlice<UInt8>) {
            viewModel.sendInput(Data(data))
        }

        func scrolled(source: SwiftTerm.TerminalView, position: Double) {}

        func clipboardCopy(source: SwiftTerm.TerminalView, content: Data) {
            if let string = String(data: content, encoding: .utf8) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(string, forType: .string)
            }
        }

        func requestOpenLink(source: SwiftTerm.TerminalView, link: String, params: [String: String]) {
            if let url = URL(string: link) {
                NSWorkspace.shared.open(url)
            }
        }

        func rangeChanged(source: SwiftTerm.TerminalView, startY: Int, endY: Int) {}
    }
}

#else
struct SwiftTermView: UIViewRepresentable {
    @Bindable var viewModel: TerminalViewModel

    func makeUIView(context: Context) -> SwiftTerm.TerminalView {
        let terminal = SwiftTerm.TerminalView()
        terminal.terminalDelegate = context.coordinator
        context.coordinator.terminal = terminal

        // Set up output callback
        viewModel.onOutput = { [weak coordinator = context.coordinator] data in
            DispatchQueue.main.async {
                coordinator?.terminal?.feed(byteArray: ArraySlice([UInt8](data)))
            }
        }

        // Focus after appearing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            terminal.becomeFirstResponder()
        }

        return terminal
    }

    func updateUIView(_ terminal: SwiftTerm.TerminalView, context: Context) {
        context.coordinator.terminal = terminal
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, SwiftTerm.TerminalViewDelegate {
        var viewModel: TerminalViewModel
        weak var terminal: SwiftTerm.TerminalView?

        init(viewModel: TerminalViewModel) {
            self.viewModel = viewModel
        }

        func sizeChanged(source: SwiftTerm.TerminalView, newCols: Int, newRows: Int) {
            guard newCols > 0, newRows > 0 else { return }
            viewModel.resize(columns: newCols, rows: newRows)
        }

        func setTerminalTitle(source: SwiftTerm.TerminalView, title: String) {}

        func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {}

        func send(source: SwiftTerm.TerminalView, data: ArraySlice<UInt8>) {
            viewModel.sendInput(Data(data))
        }

        func scrolled(source: SwiftTerm.TerminalView, position: Double) {}

        func clipboardCopy(source: SwiftTerm.TerminalView, content: Data) {
            if let string = String(data: content, encoding: .utf8) {
                UIPasteboard.general.string = string
            }
        }

        func requestOpenLink(source: SwiftTerm.TerminalView, link: String, params: [String: String]) {
            if let url = URL(string: link) {
                UIApplication.shared.open(url)
            }
        }

        func rangeChanged(source: SwiftTerm.TerminalView, startY: Int, endY: Int) {}
    }
}
#endif

// MARK: - Preview

#Preview {
    TerminalContentView(
        viewModel: TerminalViewModel(
            connectionName: "Test Server",
            session: TerminalSession(),
            connectionData: TerminalWindowData(
                connectionId: UUID(),
                connectionName: "Test",
                host: "localhost",
                port: 2222,
                username: "testuser",
                password: "testpass",
                authMethod: .password,
                privateKeyPath: nil
            )
        )
    )
}
