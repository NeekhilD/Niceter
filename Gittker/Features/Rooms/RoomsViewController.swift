//
//  RoomsViewController.swift
//  Gittker
//
//  Created by uuttff8 on 3/3/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import AsyncDisplayKit

class RoomsViewController: ASViewController<ASTableNode> {
    weak var coordinator: RoomsCoordinator? {
        didSet {
            guard let _ = self.coordinator else { print("HomeCoordinator is not loaded"); return }
        }
    }
    
    private let dataSource = RoomsDataSource()
    private var tableDelegate = RoomsTableViewDelegate()
    
    private var tableNode: ASTableNode {
        return node
    }
    
    lazy var viewModel: RoomsViewModel = {
        return RoomsViewModel(dataSource: self.dataSource)
    }()

    init() {
        super.init(node: ASTableNode())
        
        self.tableNode.delegate = self.tableDelegate
        self.tableNode.dataSource = self.dataSource
        
        tableNode.backgroundColor = UIColor.systemBackground
        tableNode.view.separatorStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Rooms"
        self.setupSearchBar()
        
        self.dataSource.data.addAndNotify(observer: self) { [weak self] in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableDelegate.coordinator = self.coordinator
                self.tableDelegate.dataSource = self.dataSource.data.value
                self.tableNode.reloadData()
            }
        }
        
        self.viewModel.fetchRoomsCached()
        self.viewModel.fetchSuggestemRooms()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = self.tableNode.indexPathForSelectedRow {
            self.tableNode.view.deselectRow(at: indexPath, animated: true)
        }
    }
    
    private func setupSearchBar() {
        navigationItem.searchController = HomeSearchController()
        navigationItem.searchController?.delegate = self
        // we can tap inside view with that
        navigationItem.searchController?.obscuresBackgroundDuringPresentation = false
    }
}

extension RoomsViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        view = SuggestedRoomsNode(rooms: viewModel.suggestedRoomsData).view
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        view = tableNode.view
    }
}