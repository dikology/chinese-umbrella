//
//  CameraView.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI
import AVFoundation

/// A SwiftUI view that provides camera functionality for capturing book pages
struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Update the image count label
        uiViewController.updateImageCount(capturedImages.count)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func cameraViewController(_ controller: CameraViewController, didCapture image: UIImage) {
            parent.capturedImages.append(image)
        }

        func cameraViewControllerDidFinish(_ controller: CameraViewController) {
            parent.dismiss()
        }
    }
}

/// UIViewController that manages the camera session
class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var delegate: CameraViewControllerDelegate?
    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    // UI Elements
    private var captureButton: UIButton!
    private var doneButton: UIButton!
    private var cancelButton: UIButton!
    private var imageCountLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCameraSession()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopCameraSession()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("Unable to access back camera")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("Error setting up camera input: \(error)")
            return
        }

        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }

    private func setupUI() {
        // Semi-transparent overlay for controls
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = .clear
        view.addSubview(overlayView)

        // Top bar with controls
        let topBar = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 100))
        topBar.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.addSubview(topBar)

        // Cancel button
        cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(cancelButton)

        // Image count label
        imageCountLabel = UILabel()
        imageCountLabel.text = "0 photos"
        imageCountLabel.textColor = .white
        imageCountLabel.font = .systemFont(ofSize: 16, weight: .medium)
        imageCountLabel.textAlignment = .center
        imageCountLabel.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(imageCountLabel)

        // Done button
        doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(.systemBlue, for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(doneButton)

        // Bottom bar with capture button
        let bottomBar = UIView(frame: CGRect(x: 0, y: view.bounds.height - 120, width: view.bounds.width, height: 120))
        bottomBar.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.addSubview(bottomBar)

        // Capture button
        captureButton = UIButton(type: .custom)
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.layer.borderWidth = 3
        captureButton.layer.borderColor = UIColor.gray.cgColor
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        bottomBar.addSubview(captureButton)

        // Instructions label
        let instructionsLabel = UILabel()
        instructionsLabel.text = "Position the page and tap to capture"
        instructionsLabel.textColor = .white
        instructionsLabel.font = .systemFont(ofSize: 14)
        instructionsLabel.textAlignment = .center
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(instructionsLabel)

        // Layout constraints
        NSLayoutConstraint.activate([
            // Top bar
            cancelButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 20),
            cancelButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor, constant: 20),

            imageCountLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            imageCountLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor, constant: 20),

            doneButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -20),
            doneButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor, constant: 20),

            // Bottom bar
            captureButton.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            captureButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 15),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),

            instructionsLabel.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            instructionsLabel.topAnchor.constraint(equalTo: captureButton.bottomAnchor, constant: 10),
            instructionsLabel.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -10)
        ])
    }

    private func startCameraSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    private func stopCameraSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc private func cancelTapped() {
        delegate?.cameraViewControllerDidFinish(self)
    }

    @objc private func doneTapped() {
        delegate?.cameraViewControllerDidFinish(self)
    }

    // MARK: - AVCapturePhotoCaptureDelegate

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to create image from photo data")
            return
        }

        // Update UI on main thread
        DispatchQueue.main.async {
            self.updateImageCount()
        }

        delegate?.cameraViewController(self, didCapture: image)
    }

    func updateImageCount(_ count: Int) {
        DispatchQueue.main.async {
            let plural = count == 1 ? "photo" : "photos"
            self.imageCountLabel.text = "\(count) \(plural)"
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
}

/// Delegate protocol for CameraViewController
protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: CameraViewController, didCapture image: UIImage)
    func cameraViewControllerDidFinish(_ controller: CameraViewController)
}
