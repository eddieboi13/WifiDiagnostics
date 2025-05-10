import SwiftUI
import CoreWLAN
import CoreLocation
import Foundation

@main
struct WiFiSignalApp: App {
    var body: some Scene {
        WindowGroup {
            WifiSignalView()
        }
    }
}

// Location manager to request permission
class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location authorization status changed: \(status.rawValue)")
    }
}

struct WifiSignalView: View {
    @StateObject private var locationManager = LocationManager()

    @State private var wifiSSID: String = "Not connected"
    @State private var wifiSignalStrength: String = "N/A"
    @State private var wifiChannel: String = "N/A"
    @State private var wifiChannelWidth: String = "N/A"
    @State private var wifiBSSID: String = "N/A"
    @State private var wifiSNR: String = "N/A"
    @State private var wifiBandwidth: String = "N/A"
    @State private var wifiNeighborhood: [String] = []
    @State private var scanStatus: String = "Not scanned"

    let noiseFloor = -90
    let logFilePath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Documents/wifi_log.txt")

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack {
                        Image(systemName: "wifi")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                        Text("Wi-Fi Signal Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                            )
                    }
                    .padding(.top, 20)

                    // Current Connection Info
                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Current Connection", icon: "antenna.radiowaves.left.and.right")

                        connectionRow("SSID", wifiSSID)
                        connectionRow("BSSID", wifiBSSID)
                        connectionRow("Signal Strength", "\(wifiSignalStrength)")

                        if let rssi = Int(wifiSignalStrength.components(separatedBy: " ").first ?? "-100") {
                            signalStrengthBar(rssi: rssi)
                        }

                        connectionRow("Channel", wifiChannel)
                        connectionRow("Channel Width", "\(wifiChannelWidth) MHz")
                        connectionRow("SNR", wifiSNR)
                        connectionRow("Bandwidth", "\(wifiBandwidth) Mbps")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: NSColor.windowBackgroundColor)))
                    .padding(.horizontal)

                    // Nearby Networks
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("Nearby Networks", icon: "network")

                        Text(scanStatus)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        if wifiNeighborhood.isEmpty {
                            Text("No nearby networks found")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(wifiNeighborhood, id: \.self) { entry in
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(entry.components(separatedBy: "\n"), id: \.self) { line in
                                        Text(line)
                                            .font(line.contains("SSID:") ? .headline : .subheadline)
                                            .foregroundColor(line.contains("RSSI:") ? .secondary : .primary)
                                    }
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: NSColor.windowBackgroundColor)))
                    .padding(.horizontal)
                }
            }

            Button(action: {
                withAnimation { getWiFiInfo() }
            }) {
                Label("Refresh Signal Info", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .background(Color(nsColor: NSColor.windowBackgroundColor).ignoresSafeArea())
        .onAppear {
            getWiFiInfo()
            startLogging()
        }
    }

    // MARK: - UI Helpers

    func sectionTitle(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
        }
    }

    func connectionRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text("\(label):")
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.accentColor)
        }
    }

    func signalStrengthBar(rssi: Int) -> some View {
        let quality = max(0.0, min(1.0, Double(rssi + 100) / 60.0))
        let color = rssi >= -60 ? Color.green : (rssi >= -75 ? Color.orange : Color.red)
        return ProgressView(value: quality)
            .progressViewStyle(LinearProgressViewStyle(tint: color))
            .frame(height: 6)
            .cornerRadius(3)
            .padding(.vertical, 2)
    }

    // MARK: - WiFi Scanning Logic

    func getWiFiInfo() {
        guard let interface = CWWiFiClient.shared().interface() else {
            wifiSSID = "No interface found"
            wifiSignalStrength = "N/A"
            wifiBSSID = "N/A"
            wifiChannel = "N/A"
            wifiChannelWidth = "N/A"
            wifiSNR = "N/A"
            wifiBandwidth = "N/A"
            wifiNeighborhood = []
            scanStatus = "No Wi-Fi interface detected"
            return
        }

        print("Interface: \(interface.interfaceName ?? "N/A")")

        wifiSSID = interface.ssid() ?? "Unknown SSID"
        wifiBSSID = interface.bssid() ?? "Unknown BSSID"
        let rssi = interface.rssiValue()
        wifiSignalStrength = "\(rssi) dBm"
        wifiSNR = "\(rssi - noiseFloor) dB"

        if let channel = interface.wlanChannel() {
            wifiChannel = "\(channel.channelNumber)"
            let width = channel.channelWidth.rawValue * 20
            wifiChannelWidth = "\(width)"
            wifiBandwidth = "\(estimateBandwidth(signalStrength: rssi, channelWidth: width))"
        }

        do {
            let scanResults = try interface.scanForNetworks(withSSID: nil)
            scanStatus = "Found \(scanResults.count) networks"
            wifiNeighborhood = scanResults.map { network in
                let ssid = network.ssid ?? "Hidden"
                let bssid = network.bssid ?? "Unknown BSSID"
                let rssi = network.rssiValue
                let channel = network.wlanChannel?.channelNumber ?? 0

                let security: String = {
                    if network.supportsSecurity(.wpa3Personal) { return "WPA3" }
                    if network.supportsSecurity(.wpa2Personal) { return "WPA2" }
                    if network.supportsSecurity(.wpaPersonal) { return "WPA" }
                    if network.supportsSecurity(.none) { return "Open" }
                    return "Unknown"
                }()

                return """
                SSID: \(ssid)
                BSSID: \(bssid)
                RSSI: \(rssi) dBm
                Channel: \(channel)
                Security: \(security)
                """
            }
        } catch {
            scanStatus = "Scan failed: \(error.localizedDescription)"
            wifiNeighborhood = []
        }

        logWiFiInfo()
    }

    func estimateBandwidth(signalStrength: Int, channelWidth: Int) -> Int {
        let qualityFactor = max(0, min(100, (signalStrength + 100)))
        return (qualityFactor * channelWidth) / 10
    }

    func logWiFiInfo() {
        let timestamp = Date().formatted(date: .numeric, time: .standard)
        let logEntry =
        "[\(timestamp)], SSID: \(wifiSSID), BSSID: \(wifiBSSID), Signal Strength: \(wifiSignalStrength), Channel: \(wifiChannel), Channel Width: \(wifiChannelWidth) MHz, SNR: \(wifiSNR) dB, Estimated Bandwidth: \(wifiBandwidth) Mbps\nNearby Networks:\n\(wifiNeighborhood.joined(separator: "\n\n"))\n"

        do {
            let logData = (logEntry + "\n").data(using: .utf8)!
            if FileManager.default.fileExists(atPath: logFilePath.path) {
                let fileHandle = try FileHandle(forWritingTo: logFilePath)
                fileHandle.seekToEndOfFile()
                fileHandle.write(logData)
                fileHandle.closeFile()
            } else {
                try logData.write(to: logFilePath, options: .atomic)
            }
        } catch {
            print("Failed to write to log file: \(error)")
        }
    }

    func startLogging() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            getWiFiInfo()
        }
    }
}
