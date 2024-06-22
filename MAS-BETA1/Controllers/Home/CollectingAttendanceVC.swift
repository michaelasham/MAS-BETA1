//
//  CollectingAttendanceVC.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 23/06/2024.
//

import UIKit
import AVFoundation

class CollectingAttendanceVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var currentCamera: AVCaptureDevice.Position = .back // Default to back camera
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startScanning()
        
        // Example button to switch cameras
        let switchButton = CircleButton(frame: CGRect(x: 20, y: 50, width: 60, height: 60))
        switchButton.layer.cornerRadius = 30
        switchButton.backgroundColor = .brown
        switchButton.tintColor = .white
        switchButton.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        switchButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        let exitBtn = CircleButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        exitBtn.layer.cornerRadius = 30
        exitBtn.backgroundColor = .red
        exitBtn.tintColor = .white
        exitBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        exitBtn.addTarget(self, action: #selector(onCloseClick), for: .touchUpInside)
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        exitBtn.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(switchButton)
        view.addSubview(exitBtn)
        NSLayoutConstraint.activate([
            switchButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            switchButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            exitBtn.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            exitBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
        ])
    }
    
    @objc func startScanning() {
        // Create a new AVCaptureSession
        captureSession = AVCaptureSession()
        
        // Configure the capture session to capture video
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                print("Failed to add video input to capture session")
                return
            }
            
            // Create a new AVCaptureMetadataOutput object and set it as the output device to the capture session
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                
                // Set the delegate on the metadata output to receive metadata objects
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
                
                // Create a preview layer for the capture session and add it to the view
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.frame = view.layer.bounds
                previewLayer.videoGravity = .resizeAspectFill
                view.layer.addSublayer(previewLayer)
                
                // Start the capture session
                captureSession.startRunning()
            } else {
                print("Failed to add metadata output to capture session")
            }
        } catch {
            print("Error creating video input: \(error.localizedDescription)")
        }
    }
    
    @objc func switchCamera() {
        // Check if another camera is available
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else {
            print("No video input found in capture session")
            return
        }
        
        // Determine which camera to switch to
        let newCamera: AVCaptureDevice.Position = (currentInput.device.position == .back) ? .front : .back
        
        // Remove current input
        captureSession.removeInput(currentInput)
        
        // Get new capture device for requested camera
        guard let newVideoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newCamera) else {
            print("Failed to get new capture device")
            return
        }
        
        do {
            let newVideoInput = try AVCaptureDeviceInput(device: newVideoCaptureDevice)
            
            // Add new input to capture session
            if captureSession.canAddInput(newVideoInput) {
                captureSession.addInput(newVideoInput)
                currentCamera = newCamera
            } else {
                print("Failed to add new video input to capture session")
            }
        } catch {
            print("Error creating new video input: \(error.localizedDescription)")
        }
    }

    
    // Implement the delegate method to receive metadata objects (QR codes)
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            print("Detected metadata type: \(metadataObject.type)")
            if metadataObject.type == .qr, let stringValue = metadataObject.stringValue {
                print("Detected QR code: \(stringValue)")
                
                // Handle your QR code data here
                // For example:
                // showAlert(with: "QR Code Detected", message: stringValue)
            }
        }
    }
    
    // Example method to show an alert
    func showAlert(with title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
    
    
    @objc func onCloseClick() {
        dismiss(animated: true)
    }
}
