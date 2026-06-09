import SwiftUI
import GhrianKit

/// Onboarding + settings as a native `Form`. The API has no login flow, so the user pastes
/// a token created in the web admin's "API Tokens" page. Primary actions use Liquid Glass
/// button styles.
struct SettingsScreen: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var isOnboarding = false

    @State private var serverURL = ""
    @State private var token = ""
    @State private var error: String?
    @State private var connecting = false

    var body: some View {
        Form {
            if isOnboarding {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("ghrian", systemImage: "sun.max.fill")
                            .font(.largeTitle.bold())
                            .foregroundStyle(GhrianColor.inverter)
                        Text("Connect to your ghrian server to see live power flow, daily energy, and charts.")
                            .foregroundStyle(GhrianColor.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                TextField("Server URL", text: $serverURL, prompt: Text("http://192.168.1.10:3000"))
                    #if !os(macOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    #endif
                    .autocorrectionDisabled()
                SecureField("API Token", text: $token, prompt: Text("Paste from the web admin → API Tokens"))
                    .autocorrectionDisabled()
            } header: {
                Text("Server")
            } footer: {
                if let error {
                    Text(error).foregroundStyle(GhrianColor.offline)
                } else {
                    Text("Create a token in the ghrian web admin's API Tokens page.")
                }
            }

            Section {
                Button(action: connect) {
                    HStack {
                        if connecting { ProgressView().controlSize(.small) }
                        Text(connecting ? "Connecting…" : (isOnboarding ? "Connect" : "Save"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .disabled(connecting)
            }

            if !isOnboarding {
                Section("Connection") {
                    LabeledContent("Status") {
                        Text(statusText).foregroundStyle(statusColor)
                    }
                    LabeledContent("Last updated", value: GhrianFormat.relativeUpdated(model.lastUpdated))
                    LabeledContent("Inverters", value: "\(model.inverters.count)")
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    Link("Project on GitHub", destination: URL(string: "https://github.com/zavan/ghrian-apple")!)
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        model.signOut()
                        dismiss()
                    }
                    .buttonStyle(.glass)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(isOnboarding ? "Welcome" : "Settings")
        .onAppear {
            serverURL = model.store.serverURL?.absoluteString ?? ""
            token = model.store.token ?? ""
        }
    }

    private var statusText: String {
        if model.errorMessage != nil { "Connection failed" }
        else if model.lastUpdated != nil { "Connected" }
        else { "Not connected" }
    }

    private var statusColor: Color {
        if model.errorMessage != nil { GhrianColor.offline }
        else if model.lastUpdated != nil { GhrianColor.online }
        else { GhrianColor.textSecondary }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
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
