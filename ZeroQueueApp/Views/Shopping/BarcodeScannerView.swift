import SwiftUI
import AVFoundation

// MARK: - SwiftUI wrapper
struct BarcodeScannerView: UIViewRepresentable {
    var onScanned: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanned: onScanned)
    }

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        // Delegate must be set BEFORE setupCamera() so the
        // metadata output has a valid delegate when the session starts.
        view.setupCamera(delegate: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}

    // MARK: - Coordinator
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var onScanned: (String) -> Void
        private var lastCode: String = ""
        private var lastTime: Date = .distantPast

        init(onScanned: @escaping (String) -> Void) {
            self.onScanned = onScanned
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard
                let obj  = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                let code = obj.stringValue
            else { return }

            // Debounce: ignore repeat scans of same code within 2 s
            let now = Date()
            guard code != lastCode || now.timeIntervalSince(lastTime) > 2.0 else { return }
            lastCode = code
            lastTime = now

            DispatchQueue.main.async { self.onScanned(code) }
        }
    }
}

// MARK: - UIView holding the AVCaptureSession
class CameraPreviewView: UIView {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // Called explicitly from makeUIView after the coordinator exists
    func setupCamera(delegate: AVCaptureMetadataOutputObjectsDelegate) {
        let session = AVCaptureSession()

        guard
            let device = AVCaptureDevice.default(for: .video),
            let input  = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            print("ZeroQueue: camera device unavailable")
            return
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        // Delegate is now guaranteed non-nil
        output.setMetadataObjectsDelegate(delegate, queue: .main)
        output.metadataObjectTypes = [
            .ean8, .ean13, .upce,
            .code128, .code39, .code39Mod43,
            .interleaved2of5
        ]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        layer.addSublayer(preview)
        self.previewLayer  = preview
        self.captureSession = session

        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    deinit {
        captureSession?.stopRunning()
    }
}
