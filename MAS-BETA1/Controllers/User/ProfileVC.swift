//
//  ProfileVC.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import UIKit
import FirebaseStorage

class ProfileVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet weak var profile: CircleImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var qrCodeBtn: CircleButton!
    @IBOutlet weak var walletBtn: CircleButton!
    @IBOutlet weak var subtitleLbl: UILabel!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var addImageBtn: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    var imageUpdated = false
    let imagePicker = UIImagePickerController()
    let user = UserDataService.instance.user
    
    let badges = BadgeService.instance.badgeActivities
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        imagePicker.delegate = self
        setupView()
        
    }
    func setupView() {
        if AuthService.instance.isLoggedIn {
            nameLbl.text = user.name
            //profile photo
            profile.image = AdminService.instance.findImage(id: user.id, ext: "jpg")
            if AdminService.instance.findImage(id: user.id, ext: "jpg") == UIImage() {
                let imageRef = storageRef.child("users/\(user.id).jpg")
                imageRef.getData(maxSize: 15 * 1024 * 1024) { data, error in
                    if let error = error {
                        // uh-oh
                        print("pfperror")
                        print(error.localizedDescription)
                        // might be no image
                        self.addImageBtn.isHidden = false
                        self.spinner.stopAnimating()
                    } else {
                        //success
                        self.addImageBtn.isHidden = true
                        self.profile.image = UIImage(data: data!)
                        AdminService.instance.saveImage(id: self.user.id, image: data!, ext: "jpg")
                        self.spinner.stopAnimating()
                    }
                }
            } else {
                self.spinner.stopAnimating()
                self.addImageBtn.isHidden = true
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return badges.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MiniBadgeCell", for: indexPath) as? MiniBadgeCell {
            cell.setupCell(badgeActivity: badges[indexPath.row])
            return cell
        }
        return MiniBadgeCell()
    }
    
    @IBAction func onAddImageClick(_ sender: Any) {
        present(imagePicker, animated: true)
    }
    
    @IBAction func onWalletClick(_ sender: Any) {
        
    }
    
    @IBAction func onQRClick(_ sender: Any) {
        QuickQR()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageUpdated = true
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.spinner.startAnimating()
            self.profile.image = image
            self.imageUpdated = true
            dismiss(animated: true)
            AdminService.instance.updateImage(filename: UserDataService.instance.user.id, ext: "jpg",
                                                  folderName: "users",
                                                  image: image) { Success in
                AdminService.instance.saveImage(id: UserDataService.instance.user.id, image: image.jpegData(compressionQuality: 0.25)!, ext: "jpg")
                self.spinner.stopAnimating()
                self.addImageBtn.isHidden = true
                }
            }
      }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
    func showQR() {
        // Check if the selected text contains the word "ClickableOption"
        let selectedText = user.id
        if selectedText!.contains("-") {
            // Show an alert with the QR code
            let alert = UIAlertController(title: "Generate QR Code", message: "Make sure your friend has downloaded the app, logged in and has navigated to Join a Community Button located in the Profile Page", preferredStyle: .alert)
            
            // Generate QR code action
            let generateQRCodeAction = UIAlertAction(title: "Proceed", style: .default) { _ in
                // Call the generate QR code function
                if let qrCodeImage = self.generateQRCode(from: selectedText!) {
                    // Create a new alert controller to display the QR code
//                    UIImageWriteToSavedPhotosAlbum(qrCodeImage, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)

                    let qrCodeAlert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
                    
                    // Add an image view to display the QR code
                    let qrCodeImageView = UIImageView(image: qrCodeImage)
                    qrCodeAlert.view.addSubview(qrCodeImageView)
                    
                    // Add constraints to center the image view
                    qrCodeImageView.translatesAutoresizingMaskIntoConstraints = false
                    qrCodeImageView.centerXAnchor.constraint(equalTo: qrCodeAlert.view.centerXAnchor).isActive = true
                    qrCodeImageView.topAnchor.constraint(equalTo: qrCodeAlert.view.topAnchor, constant: 70).isActive = true
                    
                    // Add a close action
                    qrCodeAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
                    
                    // Present the QR code alert
                    self.present(qrCodeAlert, animated: true)
                }
            }
            
            // Cancel action
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            // Add actions to the alert
            alert.addAction(generateQRCodeAction)
            alert.addAction(cancelAction)
            
            // Present the alert
            present(alert, animated: true)
        }
    }
    
    func QuickQR() {
        // Call the generate QR code function
        if let qrCodeImage = self.generateQRCode(from: UserDataService.instance.user.id) {
            // Create a new alert controller to display the QR code
//                    UIImageWriteToSavedPhotosAlbum(qrCodeImage, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)

            let qrCodeAlert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            
            // Add an image view to display the QR code
            let qrCodeImageView = UIImageView(image: qrCodeImage)
            qrCodeAlert.view.addSubview(qrCodeImageView)
            
            // Add constraints to center the image view
            qrCodeImageView.translatesAutoresizingMaskIntoConstraints = false
            qrCodeImageView.centerXAnchor.constraint(equalTo: qrCodeAlert.view.centerXAnchor).isActive = true
            qrCodeImageView.topAnchor.constraint(equalTo: qrCodeAlert.view.topAnchor, constant: 70).isActive = true
            
            // Add a close action
            qrCodeAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
            
            // Present the QR code alert
            self.present(qrCodeAlert, animated: true)
        }
    }
    
}
