//
//  ViewController.swift
//  DeliverySample
//

import UIKit
import CoreData

class DeliveryTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
   
    // MARK: DECLARATION
    private var fetchedResultsController: NSFetchedResultsController<Delivery>?
    lazy var request: NSFetchRequest<Delivery> = {
        let req: NSFetchRequest<Delivery> = Delivery.fetchRequest()
        req.returnsObjectsAsFaults = false
        req.fetchLimit = currentLimit
        return req
    }()
    private var currentOffset: Int = Constants.zero
    private var currentLimit: Int = Int(Constants.twenty)
    private var isLastPage: Bool = false
    var contentUpdated = false
    private(set) var arrayDelivery = [Delivery]()
    
    private var activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .gray)
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicatorView
    }()
    
    private var retry = Constants.zero
    
    lazy var indicatorBgView: UIView = {
        let view = UIView()
       return view
    }()
    
    var selectedIndexPath: IndexPath?

    private var isFetchingDeliveries: Bool = false {
        didSet {
            if self.isFetchingDeliveries {
                tableView.tableFooterView = indicatorBgView
                activityIndicatorView.startAnimating()
                activityIndicatorView.isHidden = false
            } else {
                DispatchQueue.main.async {
                    self.tableView.tableFooterView = UIView(frame: .zero)
                    self.activityIndicatorView.stopAnimating()
                }
            }
        }
    }
    private var observerForFavoriteDelivery: NSObjectProtocol?
    private let dataManager: DeliveryDataManagerProtocol
    private let apiClientManager: DeliveryNetworkManager
    // MARK: END OF DECLARATION
    
    init(dataManager: DeliveryDataManagerProtocol, apiClientManager: DeliveryNetworkManager) {
        self.dataManager = dataManager
        self.apiClientManager = apiClientManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        fetchDeliveriesFromNetworkManager()
        observerForFavoriteDelivery = NotificationCenter.default.addObserver(forName: Notification.Name.favoriteStateDidChange, object: nil, queue: OperationQueue.main, using: { _ in
            self.dataManager.saveDeliveryContext()
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !contentUpdated {
            selectedIndexPath = nil
            return
        }
        guard let indexPath = selectedIndexPath else { return }
        tableView.reloadRows(at: [indexPath], with: .none)
        selectedIndexPath = nil
    }
    
    private func setUpView() {
        view.backgroundColor = .white
        self.title = "My Deliveries"
        indicatorBgView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 50)
        indicatorBgView.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: indicatorBgView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: indicatorBgView.centerYAnchor)
        ])
        tableView.register(DeliveryTableViewCell.self, forCellReuseIdentifier: DeliveryTableViewCell.CellIdentifier)
        tableView.showsVerticalScrollIndicator = false
    }
    
    func fetchDeliveriesFromNetworkManager() {
        if isFetchingDeliveries || isLastPage {
            return
        }
        isFetchingDeliveries = true
        apiClientManager.fetchDeliveriesFromServer(offset: currentOffset, limit: currentLimit) { [weak self] (result) in
            guard let self = self else { return }
            self.isFetchingDeliveries = false
                switch result {
                case .success(_) :
                    self.loadResultsInTableView(error: nil)
                case .failure(let error):
                    self.loadResultsInTableView(error: error as NSError)
                }
        }
    }
    
    func loadResultsInTableView(error: NSError?) {
        if isLastPage { return }
        request.fetchOffset = currentOffset
        do {
            if fetchedResultsController == nil {
                let sort = NSSortDescriptor(key: "dateCreated", ascending: true)
                request.sortDescriptors = [sort]
                fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataManager.context, sectionNameKeyPath: nil, cacheName: nil)
                fetchedResultsController?.delegate = self
            }
            try fetchedResultsController?.performFetch()
            let fetchedObjects = try dataManager.context.fetch(request)
            if !fetchedObjects.isEmpty {
                arrayDelivery.append(contentsOf: fetchedObjects)
                tableView.reloadData()
            }
            if fetchedObjects.count == Constants.zero && error != nil {
                self.showAlert(error: error)
                return
            } else {
                // update the offset for next page fetch
                self.currentOffset += fetchedObjects.count
                self.isLastPage = fetchedObjects.count == Constants.zero
            }
        } catch {}
    }
    
    func showAlert(error : NSError?) {
        if retry > Constants.zero {
            return
        }
        var message = "Unexpected error occured. Please try again"
        if let msg = error?.localizedDescription {
            message = msg
        }
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in
            self.retry += Constants.one
            self.fetchDeliveriesFromNetworkManager()
        }))
        navigationController?.present(alertController, animated: true, completion: nil)
    }
    
    deinit {
        if let observer = observerForFavoriteDelivery {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: UITABLEVIEW METHODS
extension DeliveryTableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayDelivery.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DeliveryTableViewCell.CellIdentifier, for: indexPath) as? DeliveryTableViewCell else {
            return UITableViewCell()
        }
        cell.viewModel = DeliveryViewModel(arrayDelivery[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.rowHeight
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == arrayDelivery.count - 1 {
            if !isFetchingDeliveries {
                fetchDeliveriesFromNetworkManager()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVc = DeliveryDetailViewController(viewModel: DeliveryViewModel(arrayDelivery[indexPath.row]))
        selectedIndexPath = indexPath
        self.navigationController?.pushViewController(detailVc, animated: true)
    }
}

extension DeliveryTableViewController {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        contentUpdated = true
        guard let index = selectedIndexPath?.row else {
            return
        }
        if anObject is Delivery {
            arrayDelivery[index] = anObject as! Delivery
        }
    }
}
