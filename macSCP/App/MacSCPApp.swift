//
//  MacSCPApp.swift
//  macSCP
//
//  Main application entry point
//

import SwiftUI
import SwiftData
#if os(macOS)
import Sparkle
#endif

@main
struct MacSCPApp: App {
    @StateObject private var container = DependencyContainer.shared

    #if os(macOS)
    private let updaterController: SPUStandardUpdaterController
    @StateObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    #endif

    init() {
        AnalyticsService.initialize()
        AppLockManager.shared.lockIfNeeded()

        #if os(macOS)
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        self.updaterController = controller
        self._checkForUpdatesViewModel = StateObject(
            wrappedValue: CheckForUpdatesViewModel(updater: controller.updater)
        )
        #endif
    }

    var body: some Scene {
        // Main Window - Connection List
        WindowGroup {
            ConnectionListView(viewModel: container.makeConnectionListViewModel())
                .appLockOverlay()
        }
        .modelContainer(container.modelContainer)
        #if os(macOS)
        .defaultSize(WindowSize.main)
        .commands {
            appCommands
        }
        #endif

        // File Browser Window
        WindowGroup(id: WindowID.fileBrowser, for: String.self) { $windowId in
            if let windowId = windowId {
                FileBrowserWindow(windowId: windowId)
                    .appLockOverlay()
            }
        }
        .modelContainer(container.modelContainer)
        #if os(macOS)
        .defaultSize(WindowSize.fileBrowser)
        #endif

        // File Editor Window
        WindowGroup(id: WindowID.fileEditor, for: String.self) { $windowId in
            if let windowId = windowId {
                FileEditorWindow(windowId: windowId)
                    .appLockOverlay()
            }
        }
        .modelContainer(container.modelContainer)
        #if os(macOS)
        .defaultSize(WindowSize.fileEditor)
        #endif

        // File Info Window
        WindowGroup(id: WindowID.fileInfo, for: String.self) { $windowId in
            if let windowId = windowId {
                FileInfoWindow(windowId: windowId)
                    .appLockOverlay()
            }
        }
        .modelContainer(container.modelContainer)
        #if os(macOS)
        .defaultSize(WindowSize.fileInfo)
        .windowResizability(.contentSize)
        #endif

        // Terminal Window
        WindowGroup(id: WindowID.terminal, for: String.self) { $windowId in
            if let windowId = windowId {
                TerminalWindow(windowId: windowId)
                    .appLockOverlay()
            }
        }
        .modelContainer(container.modelContainer)
        #if os(macOS)
        .defaultSize(WindowSize.terminal)
        #endif

        // Settings Window (Cmd+, on macOS)
        #if os(macOS)
        Settings {
            SettingsView()
                .appLockOverlay()
        }
        #endif
    }

    // MARK: - Commands (macOS only)
    #if os(macOS)
    @CommandsBuilder
    private var appCommands: some Commands {
        CommandGroup(after: .appInfo) {
            CheckForUpdatesView(viewModel: checkForUpdatesViewModel)
        }

        CommandGroup(replacing: .newItem) {
            Button("New Connection") {
                // Handled by main window
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New Folder") {
                // Handled by main window
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        CommandGroup(after: .toolbar) {
            Button("Refresh") {
                // Handled by active window
            }
            .keyboardShortcut("r", modifiers: .command)
        }
    }
    #endif
}
