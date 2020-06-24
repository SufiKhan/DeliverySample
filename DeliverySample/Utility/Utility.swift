//
//  Utility.swift
//  DeliverySample
//

import Foundation
import CoreData
import UIKit

extension Notification.Name {
    static let favoriteStateDidChange = Notification.Name("favoriteStateDidChange")
}

extension CodingUserInfoKey {
    static let context = CodingUserInfoKey(rawValue: "context")!
}

extension JSONDecoder {
    convenience init(context: NSManagedObjectContext) {
        self.init()
        self.userInfo[.context] = context
    }
}

extension UIView {
    func subViewRemoveMaskConstraint() {
        for view in self.subviews {
            view.translatesAutoresizingMaskIntoConstraints = false
        }
    }
}

struct DeliveriesApiConfigProvider: ApiConfigProvider {
    
    var baseURL: String {
        return "https://mock-api-mobile.dev.lalamove.com"
    }
    
    var path: String {
        return "/v2/deliveries"
    }
}

protocol ApiConfigProvider {
    var baseURL: String { get }
    var path: String { get }
}

struct Constants {
    static let zero = 0
    static let one = 1
    static let two = 2
    static let ten: CGFloat = 10
    static let twenty: CGFloat = 20
    static let eighty: CGFloat = 80
    static let rowHeight: CGFloat = 100
    static let italicFont: UIFont = .italicSystemFont(ofSize: 16)
    static let boldFont: UIFont = .boldSystemFont(ofSize: 16)
}
