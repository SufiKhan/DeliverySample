//
//  DeliveryTableViewModel.swift
//  DeliverySample
//
//

import Foundation

class DeliveryViewModel {

    private let deliveryModel: Delivery
    
    init(_ delivery: Delivery) {
        deliveryModel = delivery
    }
    
    var from: String {
        return "From: \(deliveryModel.name), \(deliveryModel.start)"
    }
    
    var to: String {
        return "To: \(deliveryModel.end)"
    }
    
    var price: String {
        return "$\(deliveryModel.price)"
    }
    
    var goodsPictureURLString: String {
        return deliveryModel.goodsPicture
    }
    
    var isFavorite: Bool {
        set {
            deliveryModel.isFavorite = newValue
            NotificationCenter.default.post(Notification(name: Notification.Name.favoriteStateDidChange))
        } get {
            return deliveryModel.isFavorite
        }
    }
}
