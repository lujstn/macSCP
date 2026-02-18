//
//  SettingsView.swift
//  macSCP
//
//  Application settings view (Cmd+, shortcut via Settings scene)
//

import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @State private var appLockManager = AppLockManager.shared
    private let biometricService: BiometricAuthServiceProtocol = BiometricAuthService.shared

    private var isBiometricAvailable: Bool {
        biometricService.isBiometricAvailable()
    }

    private var isEnabled: Bool {
        appLockManager.isBiometricLockEnabled
    }

    private var biometryIconName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch context.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        @unknown default: return "lock.shield"
        }
    }

    var body: some View {
        Form {
            securitySection
        }
        .formStyle(.grouped)
        #if os(macOS)
        .frame(width: 450)
        .fixedSize(horizontal: false, vertical: true)
        #endif
    }

    // MARK: - Security Section

    @ViewBuilder
    private var securitySection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { appLockManager.isBiometricLockEnabled },
                set: { newValue in
                    if newValue {
                        appLockManager.enableBiometricLock()
                    } else {
                        Task {
                            await appLockManager.disableBiometricLock()
                        }
                    }
                }
            )) {
                #if os(macOS)
                Label("Require Touch ID", systemImage: "touchid")
                #else
                Label("Require Biometric Auth", systemImage: biometryIconName)
                #endif
            }
            .disabled(!isBiometricAvailable)

            if !isBiometricAvailable {
                #if os(macOS)
                Text("Touch ID is not available on this Mac. Use a Mac with Touch ID or an Apple Watch to enable this feature.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                #else
                Text("Biometric authentication is not available on this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                #endif
            }

            if isEnabled {
                Toggle(isOn: Bindable(appLockManager).lockOnAppResume) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lock when switching apps")
                        #if os(macOS)
                        Text("Require authentication when returning to macSCP")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        #else
                        Text("Require authentication when returning to the app")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        #endif
                    }
                }

                Toggle(isOn: Bindable(appLockManager).lockBeforeConnection) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Require before each connection")
                        Text("Authenticate before connecting to any server")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Toggle(isOn: Bindable(appLockManager).lockAfterInactivity) {
                        Text("Lock after inactivity")
                    }

                    Spacer()

                    Picker("", selection: Bindable(appLockManager).inactivityTimeout) {
                        ForEach(InactivityTimeout.allCases) { timeout in
                            Text(timeout.label).tag(timeout)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .disabled(!appLockManager.lockAfterInactivity)
                }
            }
        } header: {
            Text("Security")
        } footer: {
            if isEnabled {
                Text("The app always requires authentication on launch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
}
