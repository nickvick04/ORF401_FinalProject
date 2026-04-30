# ZeroQueue iOS App — Setup Guide

## 1. Create the Xcode Project

1. Open **Xcode** → **Create New Project**
2. Choose **iOS → App**
3. Fill in:
   - **Product Name:** `ZeroQueue`
   - **Team:** Your Apple ID / Developer account
   - **Organization Identifier:** `com.yourname.zeroqueue` (or anything you like)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Uncheck** "Include Tests" for now
4. Click **Next** and save the project wherever you like

---

## 2. Add the Source Files

In Finder, open the `ZeroQueueApp/` folder from this repo. You'll see:

```
ZeroQueueApp/
├── ZeroQueueApp.swift
├── ContentView.swift
├── AppState.swift
├── Theme.swift
├── Models/
│   ├── User.swift
│   ├── CartItem.swift
│   └── ShoppingSession.swift
├── Services/
│   └── ProductLookupService.swift
└── Views/
    ├── Onboarding/
    │   └── OnboardingView.swift
    ├── Main/
    │   └── MainTabView.swift
    ├── Home/
    │   ├── HomeView.swift
    │   └── CheckInView.swift
    ├── Shopping/
    │   ├── BarcodeScannerView.swift
    │   └── ScanView.swift
    ├── Cart/
    │   └── CartView.swift
    ├── Checkout/
    │   └── CheckoutView.swift
    └── Profile/
        └── ProfileView.swift
```

**In Xcode:**

1. Delete the auto-generated `ContentView.swift` Xcode created (right-click → Delete → Move to Trash)
2. Drag the entire `ZeroQueueApp/` folder into the Xcode Project Navigator (left sidebar)
3. In the dialog that appears:
   - Check **"Copy items if needed"**
   - Select **"Create groups"**
   - Make sure your app target is checked
4. Click **Finish**

---

## 3. Configure Info.plist (Camera Permission)

The barcode scanner requires camera access. Add this to your `Info.plist`:

1. In Xcode, click your project in the Navigator → select your **Target** → go to the **Info** tab
2. Click **+** to add a new key
3. Add: **Privacy - Camera Usage Description**
   - Value: `"ZeroQueue uses your camera to scan item barcodes while you shop."`

Or if you edit Info.plist as source XML, add:
```xml
<key>NSCameraUsageDescription</key>
<string>ZeroQueue uses your camera to scan item barcodes while you shop.</string>
```

---

## 4. Run the App

- Select your iPhone from the device list at the top of Xcode (or choose a simulator — note: the barcode scanner won't work in the simulator, but all other screens will)
- Press **⌘R** or click the Play button
- On first run on a real device, go to **Settings → General → VPN & Device Management** and trust your developer certificate

---

## 5. App Flow

1. **Welcome screen** → tap "Get Started"
2. **Sign Up** → enter any name/email/password (6+ chars)
3. **Add Payment** → enter any card details (or skip)
4. **Home** → you're in. Tap "Check In" to select a store
5. **Scan tab** → scan real grocery barcodes; items look up via Open Food Facts API with a mock price
6. **Cart tab** → review items, adjust quantities, checkout
7. **Checkout** → confirms order, ends session

---

## 6. TestFlight (Beta Distribution)

To share with testers:

1. You need an **Apple Developer Program** membership ($99/yr) at developer.apple.com
2. In Xcode: **Product → Archive**
3. In the Organizer window that opens: **Distribute App → App Store Connect → Upload**
4. In **App Store Connect** (appstoreconnect.apple.com): go to your app → **TestFlight** → add tester emails
5. Testers install the **TestFlight** app and accept your invite

For free device testing (up to 3 devices, no developer account needed):
- Connect your iPhone via USB
- Select it as the target in Xcode
- Press ⌘R — Xcode will install directly

---

## Notes

- **Prices are mocked.** The app generates random plausible grocery prices since Open Food Facts doesn't include retail pricing. In production you'd integrate a store's inventory/POS API.
- **Payment is simulated.** No real charges occur. In production you'd integrate Stripe or a similar SDK.
- **The barcode scanner requires a physical device.** AVFoundation camera capture doesn't work in the iOS Simulator.
- **Internet connection recommended** for product lookups. The app includes an offline mock database of ~15 common barcodes as a fallback.
