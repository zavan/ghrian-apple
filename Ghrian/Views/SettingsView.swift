import SwiftUI
import GhrianKit

/// Onboarding + settings: server URL, API token, poll interval, sign out. The API
/// has no login flow, so the user pastes a token created in the web admin's
/// "API Tokens" page.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var isOnboarding = false

    @State private var serverURL = ""
    @State private var token = ""
    @State private var error: String?
    @State private var connecting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                Card("Server") {
                    field("Server URL", text: $serverURL, prompt: "http://192.168.1.10:3000")
                        #if !os(macOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                        .autocorrectionDisabled()
                    field("API Token", text: $token, prompt: "Paste from the web admin → API Tokens", secure: true)
                        .autocorrectionDisabled()

                    if let error {
                        Text(error).font(.callout).foregroundStyle(GhrianColor.offline)
                    }

                    Button(action: connect) {
                        HStack {
                            if connecting { ProgressView().controlSize(.small) }
                            Text(connecting ? "Connecting…" : (isOnboarding ? "Connect" : "Save"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(connecting)
                }

                if !isOnboarding {
                    Button("Sign Out", role: .destructive) {
                        model.signOut()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(20)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(GhrianColor.background)
        .navigationTitle(isOnboarding ? "Welcome" : "Settings")
        .onAppear {
            serverURL = model.store.serverURL?.absoluteString ?? ""
            token = model.store.token ?? ""
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("ghrian", systemImage: "sun.max.fill")
                .font(.largeTitle.bold())
                .foregroundStyle(GhrianColor.inverter)
            if isOnboarding {
                Text("Connect to your ghrian server to see live power flow, daily energy, and charts.")
                    .foregroundStyle(GhrianColor.textSecondary)
            }
        }
    }

    private func field(_ label: String, text: Binding<String>, prompt: String, secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.callout).foregroundStyle(GhrianColor.textSecondary)
            Group {
                if secure {
                    SecureField(label, text: text, prompt: Text(prompt))
                } else {
                    TextField(label, text: text, prompt: Text(prompt))
                }
            }
            .textFieldStyle(.plain)
            .padding(10)
            .background(GhrianColor.background, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(GhrianColor.cardBorder, lineWidth: 1))
            .foregroundStyle(GhrianColor.textPrimary)
        }
    }

    private func connect() {
        error = nil
        connecting = true
        Task {
            let result = await model.connect(urlString: serverURL, token: token)
            connecting = false
            if let result {
                error = result
            } else if !isOnboarding {
                dismiss()
            }
        }
    }
}
