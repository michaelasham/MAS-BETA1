//
//  Constants.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import Foundation

typealias CompletionHandler = (_ Success: Bool) -> ()

let NSP_STR = "log=\(true),forcePolling=\(true)"

let LOGGED_IN_KEY = "loggedIn"
let EMAIL_KEY = "email"
let ID_KEY = "id"
let VERCODE = "VerCode"


let NOTIF_LOGIN_CHANGED = Notification.Name("NotifLoginChanged")
let NOTIF_CART_CHANGED = Notification.Name("NotifCartChanged")
let NOTIF_ORDER_PLACED = Notification.Name("NotifOrderPlaced")
let NOTIF_HOST_CREATED = Notification.Name("NotifHostCreated")
let NOTIF_DUEL_WILL_START = Notification.Name("NotifDuelWillStart")
let NOTIF_INACTIVE_DUEL_CANCELLED = Notification.Name("NotifInactiveDuelCancelled")
let NOTIF_ACCEPT_FINISHED = Notification.Name("NotifAcceptFinished")
let NOTIF_KIOSK_FINISHED = Notification.Name("NotifKioskFinished")
let NOTIF_TICKET_CHANGE = Notification.Name("NotifTicketChange")
let NOTIF_DORM_SELECTED = Notification.Name("NotifDormSelected")
let NOTIF_COMMUNITY_CHANGED = Notification.Name("NotifDuelEnded")
let NOTIF_CONNECTED = Notification.Name("NotifConnected")
let NOTIF_USER_REFRESH = Notification.Name("NotifUserRefresh")
let NOTIF_GO_TO_INTENDED_CHATROOM = Notification.Name("NotifGoToIntendedChatroom")
let NOTIF_MARKETPLACE_UPDATE = Notification.Name("NotifMarketplaceUpdate")
let NOTIF_INITIATE_TOKEN_BUY = Notification.Name("NotifInitiateTokenBuy")
let NOTIF_MATERIAL_UPDATE = Notification.Name("NotifMaterialUpdate")
let NOTIF_PATROL_MEMBER_UPDATE = Notification.Name("NotifPatrolMemberUpdate")
let NOTIF_EVENT_CREATION_REQUEST = Notification.Name("NotifEventCreationRequest")

let ACCEPT_KEY = "ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SnVZVzFsSWpvaWFXNXBkR2xoYkNJc0ltTnNZWE56SWpvaVRXVnlZMmhoYm5RaUxDSndjbTltYVd4bFgzQnJJam96TVRjeWZRLlEyek1kOEFPSG5ZMjVSdkJtbW02OUlZNXBQZUNxNldTVmh4bm51QnNybGhfZVdDQVRuZ0pqYnZqdm9nNFRUanNrUGNDOVBSdEdWZTRJVVhVUm43RUt3"
let BASE_URL = "https://accept.paymobsolutions.com/api/"
let AUTH_URL = "\(BASE_URL)auth/tokens"
let ORDER_REG_URL = "\(BASE_URL)ecommerce/orders"
let PAYMENT_KEY_URL = "\(BASE_URL)acceptance/payment_keys"
let PAY_URL = "\(BASE_URL)acceptance/payments/pay"
let CHECK_TRANSACTION_URL = "\(BASE_URL)acceptance/transactions/"
