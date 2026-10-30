import SwiftUI
import UniformTypeIdentifiers

@main
struct ClassicIconsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ShortcutItem {
    let name: String
    let targetURL: String
    let iconImage: UIImage
}

class ProfileGenerator {
    static func generateMobileConfig(item: ShortcutItem) -> URL? {
        guard let preparedIcon = item.iconImage.resizedAndRounded(to: CGSize(width: 180, height: 180)),
              let iconData = preparedIcon.pngData() else {
            return nil
        }
        
        let base64Icon = iconData.base64EncodedString()
        let payloadUUID = UUID().uuidString
        let topUUID = UUID().uuidString
        
        let plistString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>PayloadContent</key>
            <array>
                <dict>
                    <key>Icon</key>
                    <data>\(base64Icon)</data>
                    <key>IsRemovable</key>
                    <true/>
                    <key>Label</key>
                    <string>\(item.name)</string>
                    <key>PayloadDescription</key>
                    <string>Classic Icon WebClip</string>
                    <key>PayloadDisplayName</key>
                    <string>\(item.name)</string>
                    <key>PayloadIdentifier</key>
                    <string>com.classicicons.webclip.\(payloadUUID)</string>
                    <key>PayloadType</key>
                    <string>com.apple.webClip.managed</string>
                    <key>PayloadUUID</key>
                    <string>\(payloadUUID)</string>
                    <key>PayloadVersion</key>
                    <integer>1</integer>
                    <key>URL</key>
                    <string>\(item.targetURL)</string>
                </dict>
            </array>
            <key>PayloadDisplayName</key>
            <string>Classic Icon: \(item.name)</string>
            <key>PayloadIdentifier</key>
            <string>com.classicicons.profile.\(topUUID)</string>
            <key>PayloadRemovalDisallowed</key>
            <false/>
            <key>PayloadType</key>
            <string>Configuration</string>
            <key>PayloadUUID</key>
            <string>\(topUUID)</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
        </dict>
        </plist>
        """
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(item.name).mobileconfig")
        
        do {
            try plistString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}

extension UIImage {
    func resizedAndRounded(to targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: targetSize)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: targetSize.width * 0.225)
            path.addClip()
            self.draw(in: rect)
        }
    }
}

struct ContentView: View {
    @State private var appName: String = "Настройки"
    @State private var targetScheme: String = "App-Prefs:"
    @State private var isProcessing: Bool = false
    @State private var exportedProfileURL: URL? = nil
    @State private var showShareSheet: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Параметры иконки")) {
                    TextField("Название приложения", text: $appName)
                    TextField("URL Scheme / Ссылка", text: $targetScheme)
                }
                
                Section {
                    Button(action: generateProfile) {
                        HStack {
                            Spacer()
                            if isProcessing {
                                ProgressView()
                            } else {
                                Text("Создать классическую иконку")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(isProcessing || appName.isEmpty || targetScheme.isEmpty)
                }
            }
            .navigationTitle("Classic Icons")
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedProfileURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private func generateProfile() {
        isProcessing = true
        let iconToUse = UIImage(systemName: "gear.circle.fill") ?? UIImage()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let item = ShortcutItem(name: appName, targetURL: targetScheme, iconImage: iconToUse)
            let profileURL = ProfileGenerator.generateMobileConfig(item: item)
            
            DispatchQueue.main.async {
                self.exportedProfileURL = profileURL
                self.isProcessing = false
                if profileURL != nil {
                    self.showShareSheet = true
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
