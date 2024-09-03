
//  ProfileVC.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import UIKit
import FirebaseStorage
import PDFKit
import PassKit

class ProfileVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet weak var cvBtn: CircleButton!
    @IBOutlet weak var profile: CircleImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var qrCodeBtn: CircleButton!
    @IBOutlet weak var walletBtn: CircleButton!
    @IBOutlet weak var subtitleLbl: UILabel!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var addImageBtn: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var CVBtn: CircleButton!
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
    
    func createScoutCV() {
        let pageSize = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size in points

        // Start a PDF context
        let documentPath = getDocumentsDirectory().appendingPathComponent("ScoutCV.pdf")
        UIGraphicsBeginPDFContextToFile(documentPath.path, pageSize, nil)
        UIGraphicsBeginPDFPageWithInfo(pageSize, nil)
        
    
         let user = UserDataService.instance.user
         let name = user.name ?? "Name not available"
         let userID = user.id ?? "ID not available"
         let userBirthDate = user.dateOfBirth ?? "Date of birth not available"
         let userPhone = user.phone ?? "Phone number not available"
         
         let profileText = """
         Name: \(name)
         ID: \(userID)
         Birth Date: \(userBirthDate)
         Phone Number: \(userPhone)
         """
        
        drawText(name, in: CGRect(x: 50, y: 50, width: pageSize.width - 100, height: 30), fontSize: 20, bold: true)
        drawText("Scout CV", in: CGRect(x: 50, y: 70, width: pageSize.width - 100, height: 30), fontSize: 15, bold: true)
        
        drawText("Personal Details", in: CGRect(x: 50, y: 100, width: pageSize.width - 100, height: 30), fontSize: 15, bold: true)
       
            drawText("Date of birth:", in: CGRect(x: 50, y: 120, width: pageSize.width - 100, height: 30), fontSize: 10, bold: false)
            drawText("Place of birth:", in: CGRect(x: 50, y: 135, width: pageSize.width - 100, height: 30), fontSize: 10, bold: false)
            drawText("Nationality:", in: CGRect(x: 50, y: 150, width: pageSize.width - 100, height: 30), fontSize: 10, bold: false)
            drawText("Marital status:", in: CGRect(x: 50, y: 165, width: pageSize.width - 100, height: 30), fontSize: 10, bold: false)
            drawText("Military status:", in: CGRect(x: 50, y: 180, width: pageSize.width - 100, height: 30), fontSize: 10, bold: false)
        
        drawText("Contact Info", in: CGRect(x: 350, y: 100, width: pageSize.width - 100, height: 30), fontSize: 15, bold: true)
       
            drawText("Address:", in: CGRect(x: 350, y: 120, width: pageSize.width - 100, height: 30), fontSize: 10, bold: false)
            drawText("Phone: \(userPhone)", in: CGRect(x: 350, y: 135, width: pageSize.width - 100, height: 30), fontSize: 10, bold: false)
            drawText("E-mail:", in: CGRect(x: 350, y: 150, width: pageSize.width - 100, height: 30), fontSize: 10, bold: false)
          
        
        // Scout Experience - Assuming you have an array or similar structure
        drawText("Scout Experience", in: CGRect(x: 50, y: 200, width: pageSize.width - 100, height: 30), fontSize: 15, bold: true)
        // You need to loop through experiences and draw each
        // Example: drawText(experience.description, in: CGRect(...))
        
        // Education
        drawText("Achievements & Badges", in: CGRect(x: 50, y: 240, width: pageSize.width - 100, height: 30), fontSize: 15, bold: true)
        // Loop through education entries if available
        
        // Education
        drawText("Education", in: CGRect(x: 50, y: 280, width: pageSize.width - 100, height: 30), fontSize: 15, bold: true)
        // Loop through education entries if available
        
        // Skills
        drawText("Skills", in: CGRect(x: 50, y: 320, width: pageSize.width - 100, height: 30), fontSize: 15, bold: true)
        // Loop through skills
        
        // Languages
        drawText("Languages", in: CGRect(x: 50, y: 360, width: pageSize.width - 100, height: 30), fontSize: 15, bold: true)
        // Loop through languages
        
        // End the PDF context
        UIGraphicsEndPDFContext()
        
        print("Scout CV PDF has been saved to: \(documentPath.path)")
        displayPDFDocument(path: documentPath)
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var pdfURL: URL?  // Property to store the PDF URL

    func displayPDFDocument(path: URL) {
        let pdfViewController = UIViewController()
        let pdfView = PDFView(frame: pdfViewController.view.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.autoScales = true
        pdfViewController.view.addSubview(pdfView)

        if let document = PDFDocument(url: path) {
            pdfView.document = document
        }

        // Setup the navigation controller and buttons
        let navController = UINavigationController(rootViewController: pdfViewController)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissPDFViewer))
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(sharePDF(_:)))
        
        // Assigning the share button to the left of the navigation item
        pdfViewController.navigationItem.leftBarButtonItem = shareButton
        // Keeping the done button on the right side
        pdfViewController.navigationItem.rightBarButtonItem = doneButton
        pdfViewController.navigationItem.title = "Scout CV"

        // Present the navigation controller
        present(navController, animated: true)
    }

    @objc func sharePDF(_ sender: UIBarButtonItem) {
        guard let path = self.pdfURL else {
            print("Failed to get the PDF path for sharing")
            return
        }

        let activityVC = UIActivityViewController(activityItems: [path], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = sender
        activityVC.excludedActivityTypes = []  // Adjust as needed

        present(activityVC, animated: true)
    }
    
    private func drawText(_ text: String, in frame: CGRect, fontSize: CGFloat = 12, bold: Bool = false) {
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor.black
            ]
            let attributedText = NSAttributedString(string: text, attributes: textAttributes)
            attributedText.draw(in: frame)
    }
    
    @objc func dismissPDFViewer() {
        dismiss(animated: true)
    }
    @IBAction func onScoutCVClick(_ sender: Any) {
        createScoutCV()
    }
    @IBAction func onPassClick(_ sender: Any) {
      //  addWalletPassButtonTapped()
    }

}
