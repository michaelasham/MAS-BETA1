//
//  PaymobService.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import Foundation
import Alamofire

class PaymobService {
    
    static let instance = PaymobService()
    var token = ""
    var orderId: Int?
    var paymentKey = ""
    var billingData = [String : String]()
    
    func handlePayment(total: Int, orderID: String, completion: @escaping CompletionHandler) {
        print("handlePayment()")
        self.billingData.removeAll()
        let billingData = [
            "building": "0",
            "apartment": "0",
            "floor": "0",
            "email": "user@wnnreg.com",
            "first_name": UserDataService.instance.user.name!,
            "street": "n/a",
            "phone_number": "0\(UserDataService.instance.user.phone!)",
            "shipping_method": "None",
            "postal_code": "11531",
            "city": "Cairo",
            "country": "EGY",
            "last_name": ".",
            "state": "."
            ]
        self.billingData = billingData
        self.authenticate { (success) in
            if success {
                let randomInt = Int.random(in: 0...100)
                let randomOrderID = "#\(orderID)-\(randomInt)"
                self.registerOrder(internalOrderID: randomOrderID, total: total) { (success) in
                    if success {
                        print("ORDER REGISTERED")
                        self.generatePaymentKey(total: total) { (success) in
                            if success {
                                print("PAYMENTCODE GENERATED")
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }

    func authenticate(completion: @escaping CompletionHandler) {
        if token.count < 5 {
            AF.request(AUTH_URL, method: .post, parameters: [ "api_key": ACCEPT_KEY], encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
                if response.error == nil {
                    if let json = response.value as? Dictionary<String, Any> {
                        if let token = json["token"] as? String {
                            self.token = token
                            completion(true)
                        }
                    }
                } else {
                    debugPrint(response.error as Any)
                    completion(false)
                }
            }
        } else {
            completion(true)
        }
    }
    
    func registerOrder(internalOrderID: String, total: Int, completion: @escaping CompletionHandler) {
        let body: [String: Any] = [
            "auth_token": self.token, // auth token obtained from step1
            "delivery_needed": "false",
            "merchant_id": "3172",      // merchant_id obtained from step 1
            "amount_cents": total*100, // x100 (amount is in cents)
            "currency": "EGP",
            "merchant_order_id": internalOrderID,  // unique alpha-numerice value, example: E6RR3 -<  ORDER ID
            "items": []
            ]
        
        AF.request(ORDER_REG_URL, method: .post, parameters: body, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            if response.error == nil {
                if let json = response.value as? Dictionary<String, Any> {
                    if let orderId = json["id"] as? Int {
                        self.orderId = orderId
                        completion(true)
                    }
                }
            }
        }
    }
    
    func generatePaymentKey(total: Int, completion: @escaping CompletionHandler) {
        var integrationID = 4850
        print("generatePaymentKey STARTED")
        print(self.billingData)
        let body: [String: Any] = [
            "auth_token": self.token, // auth token obtained from step1
            "amount_cents": total*100,
            "expiration": 3600,
            "order_id": self.orderId,    // id obtained in step 2
            "billing_data": self.billingData,
            "currency": "EGP",
            "integration_id": integrationID
        ]
        AF.request(PAYMENT_KEY_URL, method: .post, parameters: body, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            print(response.result)
            if response.error == nil {
                if let json = response.value as? Dictionary<String, Any> {
                    print(json)
                    if let paymentToken = json["token"] as? String {
                        self.paymentKey = paymentToken
                        print("paymentKey:")
                        print(paymentToken)
                        completion(true)
                    }
                }
            } else {
                print(response.error)
            }
        }
    }
}
