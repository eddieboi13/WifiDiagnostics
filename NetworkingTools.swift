import SwiftUI
import CoreWLAN
import Foundation

@main
struct WiFiSignalApp: App {
    var body: some Scene {
        WindowGroup {
            WifiSignalView()
        }
    }
}

struct WifiSignalView: View {
    @State private var wifiSSID: String = "Not connected"
    @State private var wifiSignalStrength: String = "N/A"
    @State private var wifiChannel: String = "N/A"
    @State private var wifiChannelWidth: String = "N/A"
    @State private var wifiBSSID: String = "N/A"
    @State private var wifiSNR: String = "N/A"
    @State private var wifiBandwidth: String = "N/A"
    @State private var wifiNeighborhood: [String] = []
    
    let noiseFloor = -90
    let logFilePath = FileManager.default.homeDirectoryForCurrentUser
           .appendingPathComponent("Documents/wifi_log.txt")

    var body: some View {
        VStack(spacing: 16) {
            Text("Wi-Fi Signal Information")
                .font(.title)
                .padding()
            
            Text("SSID: \(wifiSSID)")
            Text("BSSID: \(wifiBSSID)")
            Text("Signal Strength (RSSI): \(wifiSignalStrength) dBm")
            Text("Channel Number: \(wifiChannel)")
            Text("Channel Width: \(wifiChannelWidth) MHz")
            Text("Signal-to-Noise Ratio (SNR): \(wifiSNR) dB")
            Text("Estimated Bandwidth: \(wifiBandwidth) Mbps")
            
            Divider()
            
            Text("Nearby Wi-Fi Networks")
                .font(.headline)
            
            List(wifiNeighborhood, id: \.self) { network in
                Text(network)
            }
            
            Button("Refresh Signal Info") {
                getWiFiInfo()
            }
            .padding()
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            getWiFiInfo()
            startLogging()
        }
    }
    
    func getWiFiInfo() {
        guard let interface = CWWiFiClient.shared().interface() else {
            wifiSSID = "No interface found"
            wifiSignalStrength = "N/A"
            wifiBSSID = "N/A"
            wifiChannel = "N/A"
            wifiChannelWidth = "N/A"
            wifiSNR = "N/A"
            wifiBandwidth = "N/A"
            return
        }
        
        wifiSSID = interface.ssid() ?? "Unknown SSID"
        wifiBSSID = interface.bssid() ?? "Unknown BSSID"
        let rssi = interface.rssiValue()
        wifiSignalStrength = "\(rssi) dBm"

        if let channel = interface.wlanChannel() {
            wifiChannel = "\(channel.channelNumber)"
            let width = channel.channelWidth.rawValue * 20
            wifiChannelWidth = "\(width) MHz"
            
            
            wifiBandwidth = "\(estimateBandwidth(signalStrength: rssi, channelWidth: width)) Mbps"
        }
        
        let snr = rssi - noiseFloor
        wifiSNR = "\(snr) dB"

        if let scanResults = try? CWWiFiClient.shared().interface()?.scanForNetworks(withSSID: nil) {
            wifiNeighborhood = scanResults.map { network in
                let ssid = network.ssid ?? "Unknown SSID"
                let rssi = network.rssiValue
                return "\(ssid) - \(rssi) dBm SNR: \(rssi - noiseFloor) dB"
            }
        } else {
            wifiNeighborhood = ["Unable to scan Wi-Fi networks"]
        }

        logWiFiInfo()
    }

    func estimateBandwidth(signalStrength: Int, channelWidth: Int) -> Int {
        let qualityFactor = max(0, min(100, (signalStrength + 100)))
        let bandwidth = (qualityFactor * channelWidth) / 10  
        return bandwidth
    }

    func logWiFiInfo() {
        let timestamp = Date().formatted(date: .numeric, time: .standard)
        let logEntry =
        "[\(timestamp)], SSID: \(wifiSSID), BSSID: \(wifiBSSID), Signal Strength: \(wifiSignalStrength) dBm, Channel: \(wifiChannel), Channel Width: \(wifiChannelWidth) MHz, SNR: \(wifiSNR) dB, Estimated Bandwidth: \(wifiBandwidth) Mbps, Nearby Networks: \(wifiNeighborhood.joined(separator: "\n"))"


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

