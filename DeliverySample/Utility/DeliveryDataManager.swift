//
//  DeliveryDataManager.swift
//  DeliverySample
//

import CoreData
import UIKit

class DeliveryDataManager: DeliveryDataManagerProtocol {
    
    private let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    
    func saveDeliveryContext() {
        appDelegate.saveContext()
    }
}

protocol DeliveryDataManagerProtocol: class {
    var context: NSManagedObjectContext { get }
    func saveDeliveryContext()
}
