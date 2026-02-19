//
//  AppLockView.swift
//  macSCP
//
//  Full-screen lock overlay requiring Touch ID to unlock
//

import LocalAuthentication
import SwiftUI

struct AppLockView: View {
    @State private var appLockManager = AppLockManager.shared

    private var biometryIconName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch context.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock.shield"
        }
    }

    private var biometryLabel: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch context.biometryType {
        case .faceID: return "Unlock with Face ID"
        case .touchID: return "Unlock with Touch ID"
        case .opticID: return "Unlock with Optic ID"
        default: return "Unlock"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("macSCP is Locked")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Authenticate to continue")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let error = appLockManager.authenticationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                appLockManager.unlock()
            } label: {
                Label(biometryLabel, systemImage: biometryIconName)
                    .frame(minWidth: 200)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .disabled(appLockManager.isAuthenticating)

            if appLockManager.isAuthenticating {
                ProgressView()
                    .controlSize(.small)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .task {
            // Auto-prompt biometric auth on appear
            if !appLockManager.isAuthenticating {
                appLockManager.unlock()
            }
        }
    }
}

#Preview {
    AppLockView()
}
