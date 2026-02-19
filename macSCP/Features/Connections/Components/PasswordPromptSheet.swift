//
//  PasswordPromptSheet.swift
//  macSCP
//
//  Password prompt for connecting to a server
//

import SwiftUI

struct PasswordPromptSheet: View {
    let connectionName: String
    let onConnect: (String) -> Void
    let onCancel: () -> Void

    @State private var password: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        #if os(iOS)
        NavigationStack {
            Form {
                Section {
                    Text("Enter the password for \"\(connectionName)\"")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    SecureField("Password", text: $password)
                        .focused($isFocused)
                        .onSubmit {
                            if !password.isEmpty { onConnect(password) }
                        }
                }
            }
            .navigationTitle("Enter Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { onCancel() } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") { onConnect(password) }
                        .disabled(password.isEmpty)
                        .padding(.horizontal, 4)
                }
            }
        }
        .presentationDetents([.height(250)])
        .onAppear { isFocused = true }
        #else
        VStack(spacing: UIConstants.spacing) {
            Image(systemName: "key.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("Enter Password")
                .font(.headline)

            Text("Enter the password for \"\(connectionName)\"")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit {
                    if !password.isEmpty {
                        onConnect(password)
                    }
                }

            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Connect") {
                    onConnect(password)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(password.isEmpty)
            }
        }
        .padding(UIConstants.spacing * 2)
        .frame(width: 300)
        .onAppear {
            isFocused = true
        }
        #endif
    }
}

// MARK: - Preview
#Preview {
    PasswordPromptSheet(
        connectionName: "Production Server",
        onConnect: { _ in },
        onCancel: {}
    )
}
