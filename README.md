# WiFiDiagnostics

A macOS SwiftUI application for scanning and analyzing Wi-Fi networks using CoreWLAN.

---

## ✨ Features

* Displays current Wi-Fi connection information (SSID, BSSID, RSSI, SNR, channel, channel width, and estimated bandwidth).
* Scans and lists all nearby Wi-Fi access points (Wi-Fi neighborhood).
* Displays detailed information for each network:

  * SSID (network name)
  * BSSID (MAC address)
  * RSSI (signal strength)
  * Channel
  * Security type (WPA2, WPA3, Open, etc.)
* Real-time refresh of Wi-Fi environment.
* Automatic periodic logging of Wi-Fi scan data to a file in `~/Documents/wifi_log.txt`.

---

## 🔑 Permissions and Setup

CoreWLAN scanning requires special permissions on macOS to function properly. Follow these steps carefully:

### 1. Add Location Services Permission

* Open your app's `Info.plist`.
* Add:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to scan for Wi-Fi networks.</string>
```

* Make sure when the app first launches, it requests Location Access.

### 2. Enable Full Disk Access for Your App

* Open **System Settings** > **Privacy & Security** > **Full Disk Access**.
* Unlock with your password.
* Click `+`, and **add Xcode** (if building/running from Xcode).
* After building the app, **add your built `.app`** manually as well:

  * Path: `~/Library/Developer/Xcode/DerivedData/<project-folder>/Build/Products/Debug/<YourApp>.app`

### 3. Allow Location Access

* Open **System Settings** > **Privacy & Security** > **Location Services**.
* Find your app name and ensure it is **allowed**.

### 4. Code Sign the App

CoreWLAN requires apps to be signed, even for local development. Use ad-hoc signing:

```bash
codesign --force --deep --sign - /path/to/YourApp.app
```

Example:

```bash
codesign --force --deep --sign - ~/Library/Developer/Xcode/DerivedData/Networking_Tools-abcdefg/Build/Products/Debug/Networking_Tools.app
```

Repeat this after every rebuild, or automate it with a simple script.

### 5. (Optional) Run with Sudo (for Debugging)

Sometimes, you may need to run manually with elevated permissions:

```bash
sudo /path/to/YourApp.app/Contents/MacOS/YourApp
```

This is not always necessary once Full Disk Access and Location are correctly set.

---

## 👨‍💻 Usage

1. Launch the app.
2. It will display your current Wi-Fi connection details.
3. Tap the "Refresh Signal Info" button to scan the Wi-Fi neighborhood.
4. Nearby networks will display with full details.
5. The app automatically logs the scan results every 30 seconds to `Documents/wifi_log.txt`.

---

## 🚀 Future Enhancements

* Group nearby networks by SSID (aggregate BSSIDs).
* Visualize signal strength over time.
* Automatic best-channel recommendations.
* Export scan logs in CSV/JSON format.

---

## ⚠️ Troubleshooting

* If the app shows "Scan failed: could not communicate with helper application":

  * Make sure the app is properly code-signed.
  * Make sure Full Disk Access is enabled.
  * Ensure Location Services permission is granted.
* Always re-sign the app after rebuilding.

---

## 🚀 Author

Edward Hawkson
Project: **WiFiDiagnostics**
Repository: [https://github.com/eddieboi13/WifiDiagnostics](https://github.com/eddieboi13/WifiDiagnostics)

