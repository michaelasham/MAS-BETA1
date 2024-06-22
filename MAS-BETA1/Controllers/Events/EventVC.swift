//
//  EventVC.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//


import UIKit
import FirebaseStorage
import AcceptSDK
import Toast_Swift


class EventVC: UIViewController, AcceptSDKDelegate {


    @IBOutlet weak var actionBtn: BorderButton!
    @IBOutlet weak var ticketsLeftLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var descLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var locationBtn: UIButton!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var productImageView: UIImageView!
    
    let event = CommunityService.instance.selectedEvent
    
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    let accept = AcceptSDK()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        accept.delegate = self
    }
    
    func setupView() {
        dateLbl.text = event.date
        descLbl.text = event.desc
        priceLbl.text = "\(event.price) EGP"

        titleLbl.text = event.title
        locationLbl.text = event.locationDesc
        ticketsLeftLbl.text = "\(event.maxLimit - CommunityService.instance.countEventTickets(event: event))"
        if event.maxLimit - CommunityService.instance.countEventTickets(event: event) <= 0 {
            actionBtn.isEnabled = false
            actionBtn.setTitle("SOLD OUT", for: .normal)
        } else {
            actionBtn.isEnabled = true
            actionBtn.setTitle("PURCHASE TICKET", for: .normal)
        }
        productImageView.image = AdminService.instance.findImage(id: event.id, ext: "jpg")
        if productImageView.image?.size.width == 0 {
            let imageRef = storageRef.child("events/\(event.id).jpg")
            imageRef.getData(maxSize: 15 * 1024 * 1024) { [self] data, error in
                if let error = error {
                    // uh-oh
                    print(error.localizedDescription)
                } else {
                    //success
                    self.productImageView.image = UIImage(data: data!)
                    AdminService.instance.saveImage(id: event.id, image: data!, ext: "jpg")
                }
            }
        }
        actionBtn.isEnabled = true
        actionBtn.setTitle("Buy Ticket", for: .normal)
        // check if we already bought this ticket
        for ticket in CommunityService.instance.tickets {
            if ticket.event.id == event.id {
                //already bought
                actionBtn.isEnabled = false
                actionBtn.setTitle("Already bought the ticket", for: .normal)
            }
        }
        // check if max limit reached
        if (event.maxLimit - CommunityService.instance.countEventTickets(event: event)) <= 0 {
            actionBtn.isEnabled = false
            actionBtn.setTitle("Tickets Sold out", for: .normal)
        }
    }

    @IBAction func onActionClick(_ sender: Any) {
        PaymobService.instance.handlePayment(total: event.price, orderID: event.id) { (success) in
            if success {
                do {
                    self.accept.customization?.buttonsColor = UIColor.blue
                    try self.accept.presentPayVC(vC: self, paymentKey: PaymobService.instance.paymentKey, saveCardDefault: true, showSaveCard: true, showAlerts: false)
            } catch AcceptSDKError.MissingArgumentError(let errorMessage){
                print(errorMessage)
            } catch let error {
                print(error.localizedDescription)
            }
            }
        }
    }
    
    @IBAction func onLocClick(_ sender: Any) {
        openLocationInMaps(link: event.locationLink)
    }
    func openLocationInMaps(link: String) {
        let coordinateString = link
        let encodedCoordinateString = coordinateString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        let alertController = UIAlertController(title: "Choose Maps App", message: nil, preferredStyle: .actionSheet)
        
        // Apple Maps action
        let appleMapsAction = UIAlertAction(title: "Apple Maps", style: .default) { _ in
            if let appleMapsURL = URL(string: "http://maps.apple.com/?q=\(encodedCoordinateString)") {
                if UIApplication.shared.canOpenURL(appleMapsURL) {
                    UIApplication.shared.open(appleMapsURL)
                } else {
                    print("Apple Maps app is not installed.")
                    // Optionally, you can provide a fallback action here.
                }
            }
        }
        alertController.addAction(appleMapsAction)
        
        // Google Maps action
        let googleMapsAction = UIAlertAction(title: "Google Maps", style: .default) { _ in
            if let googleMapsURL = URL(string: "comgooglemaps://?q=\(encodedCoordinateString)") {
                if UIApplication.shared.canOpenURL(googleMapsURL) {
                    UIApplication.shared.open(googleMapsURL)
                } else {
                    print("Google Maps app is not installed.")
                    // Optionally, you can provide a fallback action here.
                }
            }
        }
        alertController.addAction(googleMapsAction)
        
        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Present the action sheet
        self.present(alertController, animated: true, completion: nil)
    }
    func userDidCancel() {
        trxCancelled()
    }
    
    func paymentAttemptFailed(_ error: AcceptSDKError, detailedDescription: String) {
        trxDeclined(desc: detailedDescription)
    }
    
    func transactionRejected(_ payData: PayResponse) {
        trxDeclined(desc: "")
    }
    
    func transactionAccepted(_ payData: PayResponse) {
        trxAccepted(payData: payData)
    }
    
    func transactionAccepted(_ payData: PayResponse, savedCardData: SaveCardResponse) {
        trxAccepted(payData: payData)
    }
    
    func userDidCancel3dSecurePayment(_ pendingPayData: PayResponse) {
        trxCancelled()
    }
    func trxAccepted(payData: PayResponse) {
        CommunityService.instance.purchaseTicket(trxID: "\(payData.id)") { Success in
            let toastMsg = "Ticket Purchased Successfully"
            var style = ToastStyle()
            style.messageAlignment = .center
            self.view.makeToast(toastMsg, duration: 3.0, position: .bottom, style: style)
        }
    }
    func trxCancelled() {
        let toastMsg = "Ticket Purchase Cancelled"
        var style = ToastStyle()
        style.messageAlignment = .center
        self.view.makeToast(toastMsg, duration: 3.0, position: .bottom, style: style)
    }
    func trxDeclined(desc: String) {
        let toastMsg = "Transaction Declined. \(desc)"
        var style = ToastStyle()
        style.messageAlignment = .center
        self.view.makeToast(toastMsg, duration: 3.0, position: .bottom, style: style)
    }
}
