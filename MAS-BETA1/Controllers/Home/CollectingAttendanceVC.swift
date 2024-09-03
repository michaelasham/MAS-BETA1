//
//  CollectingAttendanceVC.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 23/06/2024.
//

import UIKit
import AVFoundation
import FirebaseStorage

class CollectingAttendanceVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var currentCamera: AVCaptureDevice.Position = .back // Default to back camera
    
    var lastNotificationTime: Date? // Variable to track the last notification time
    let notificationTimeout: TimeInterval = 5.0
    
    let selectedMode = CommunityService.instance.attendanceMode
    
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        startScanning()
        // Example usage with a 1-second delay

    }
    
    func triggerNotification(user: User, status: String) {
        let notificationView = CustomNotificationView()

        let patrol = CommunityService.instance.queryPatrol(user: user)
        let count = CommunityService.instance.countPatrolLiveAttendances(patrolName: patrol.name ?? "")
        
        notificationView.titleLabel.text = user.name
        var comment = ""
        switch status {
        case "ok":
            notificationView.backgroundColor = .green
            if selectedMode == "meeting" {
                comment = "\(patrol.members.count - count) more members left for \(patrol.name!) to be fully present"
            } else {
                comment = "ticket found and stamped on the system!"
            }
        case "repeat":
            notificationView.backgroundColor = .yellow
            comment = "You have already scanned before"
        case "invalid":
            notificationView.backgroundColor = .red
            notificationView.titleLabel.text = "INVALID CODE"
            comment = "This code is either invalid or belongs to a user who does not have access"
        default:
            notificationView.backgroundColor = .blue
        }

        notificationView.detailLabel.text = comment
        
        notificationView.iconImageView.image = generatePlaceholderImage(forName: user.name)
        notificationView.iconImageView.image = AdminService.instance.findImage(id: user.id, ext: "jpg")
        if AdminService.instance.findImage(id: user.id, ext: "jpg") == UIImage() {
            let imageRef = storageRef.child("users/\(user.id!).jpg")
            imageRef.getData(maxSize: 15 * 1024 * 1024) { [self] data, error in
                if let error = error {
                    // uh-oh
                    print("pfperror")
                    print(error.localizedDescription)
                    notificationView.iconImageView.image = generatePlaceholderImage(forName: user.name)
                    // might be no image
                } else {
                    //success
                    AdminService.instance.saveImage(id: user.id, image: data!, ext: "jpg")
                    notificationView.iconImageView.image = UIImage(data: data!)
                }
            }
        }
        
        
        
        notificationView.showIn(view: self.view)
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        CommunityService.instance.stopCollectingAttendance()
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
                addButtons()

                // Start the capture session
                captureSession.startRunning()
            } else {
                print("Failed to add metadata output to capture session")
            }
        } catch {
            print("Error creating video input: \(error.localizedDescription)")
        }
    }



    func addButtons() {
        let switchButton = CircleButton(frame: CGRect(x: 20, y: 50, width: 60, height: 60))
        switchButton.layer.cornerRadius = 30
        switchButton.backgroundColor = .brown
        switchButton.tintColor = .white
        switchButton.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        switchButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        let exitBtn = CircleButton(frame: CGRect(x: 0, y: 40, width: 60, height: 60))
        exitBtn.layer.cornerRadius = 30
        exitBtn.backgroundColor = .red
        exitBtn.tintColor = .white
        exitBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        exitBtn.addTarget(self, action: #selector(onCloseClick), for: .touchUpInside)
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        exitBtn.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(switchButton)
        view.addSubview(exitBtn)

        // Ensure these buttons are in front of all other subviews
        view.bringSubviewToFront(switchButton)
        view.bringSubviewToFront(exitBtn)
        NSLayoutConstraint.activate([
            switchButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            switchButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            exitBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            exitBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
        ])
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

    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            print("Detected metadata type: \(metadataObject.type)")
            if metadataObject.type == .qr, let stringValue = metadataObject.stringValue {
                print("Detected QR code: \(stringValue)")
                
                // Check if enough time has passed since the last notification
                if shouldTriggerNotification() {
                    let user = CommunityService.instance.queryUser(UserID: stringValue)
                    if selectedMode == "meeting" {
                        if CommunityService.instance.didMemberClockInBefore(user: user) {
                            triggerNotification(user: user, status: "repeat")
                        } else {
                            CommunityService.instance.clockInMember(id: user.id) { Success in
                                if Success {
                                    self.triggerNotification(user: user, status: "ok")
                                } else {
                                    self.triggerNotification(user: user, status: "invalid")
                                }
                            }
                        }
                    } else {
                        //ticket
                        if CommunityService.instance.checkIfTicketIsScanned(user: user) {
                            //scanned
                            triggerNotification(user: user, status: "repeat")
                        } else {
                            CommunityService.instance.scanTicket(user: user) { Success in
                                if Success {
                                    self.triggerNotification(user: user, status: "ok")

                                } else {
                                    self.triggerNotification(user: user, status: "invalid")

                                }
                            }
                        }
                    }

                    lastNotificationTime = Date() // Update the last notification time
                }
            }
        }
    }
    
    private func shouldTriggerNotification() -> Bool {
        guard let lastTime = lastNotificationTime else {
            return true // If no notification has been triggered yet, allow it
        }
        // Check if the time since the last notification exceeds the timeout interval
        return Date().timeIntervalSince(lastTime) >= notificationTimeout
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
    
    func generatePlaceholderImage(forName name: String, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let initials = name.components(separatedBy: " ").compactMap { $0.first }.prefix(2)
        let initialsString = String(initials).uppercased()

        // Generate a random color
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemRed, .systemOrange, .systemPurple]
        let backgroundColor = colors.randomElement() ?? .systemGray

        // Create a UILabel to draw the initials
        let label = UILabel(frame: CGRect(origin: .zero, size: size))
        label.backgroundColor = backgroundColor
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: size.width / 2)
        label.textAlignment = .center
        label.text = initialsString

        // Render the label as an image
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        label.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()

        return image
    }
}



class CustomNotificationView: UIView {
    
    let iconImageView = UIImageView()
    let titleLabel = UILabel()
    let detailLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.layer.cornerRadius = 12
        self.clipsToBounds = true
        
        // Set up the iconImageView
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = 30 // 60 / 2 for circular image
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up the titleLabel
        titleLabel.text = "Title"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .white
        
        // Set up the detailLabel
        detailLabel.text = "Detail message goes here"
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = .white
        detailLabel.numberOfLines = 0
        
        // Create a horizontal stack view for the image and text
        let stackView = UIStackView(arrangedSubviews: [iconImageView, createTextStackView()])
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .center
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    
    private func createTextStackView() -> UIStackView {
        let textStackView = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 4
        textStackView.alignment = .leading
        return textStackView
    }
    
    func showIn(view: UIView, duration: TimeInterval = 3.0) {
        let notificationHeight: CGFloat = 80
        self.frame = CGRect(x: 16, y: -notificationHeight, width: view.frame.width - 32, height: notificationHeight)
        view.addSubview(self)
        
        // Slide in
        UIView.animate(withDuration: 0.5, animations: {
            self.frame.origin.y = 44 // or some value depending on your navigation bar height
        }) { _ in
            // Slide out after delay
            UIView.animate(withDuration: 0.5, delay: duration, options: [], animations: {
                self.frame.origin.y = -notificationHeight
            }) { _ in
                self.removeFromSuperview()
            }
        }
    }
    

}
