//
//  PeopleViewController.swift
//  Niceter
//
//  Created by uuttff8 on 3/3/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import AsyncDisplayKit
import DeepDiff

class PeopleViewController: ASDKViewController<ASTableNode> {
    
    weak var coordinator: PeopleCoordinator?
    
    private let refreshControl = UIRefreshControl()
    private lazy var tableManager = PeopleTableManager(with: self)
    
    private var tableNode: ASTableNode {
        return node
    }
    
    lazy var viewModel: PeopleViewModel = {
        return PeopleViewModel(dataSource: self.tableManager)
    }()
    
    init(coordinator: PeopleCoordinator) {
        self.coordinator = coordinator
        super.init(node: ASTableNode())
        
        refreshControl.addTarget(self, action: #selector(reloadPeople(_:)), for: .valueChanged)
        self.tableNode.delegate = self.tableManager
        self.tableNode.dataSource = self.tableManager
        self.tableNode.view.refreshControl = self.refreshControl
        
        tableNode.view.separatorStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "People".localized()
        self.setupSearchBar()
        
        self.viewModel.updateFirstly = {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableManager.coordinator = self.coordinator
                self.tableNode.reloadData()
            }
        }
        self.viewModel.fetchRoomsCached()
        
        subscribeOnEvents()
    }
    
    private func setupSearchBar() {
        navigationItem.searchController = UISearchController()
        navigationItem.searchController?.delegate = self
        navigationItem.searchController?.searchBar.delegate = self
        // we can tap inside view with that
        navigationItem.searchController?.obscuresBackgroundDuringPresentation = false
    }
    
    private func subscribeOnEvents() {
        guard let userId = ShareData().userdata?.id else { return }
        
        FayeEventRoomBinder(with: userId)
            .subscribe(
                onNew: { (roomSchema) in
                    self.insertRoom(with: roomSchema)
            },
                onRemove: { (roomId) in
                    self.deleteRoom(by: roomId)
            },
                onPatch: { (roomSchema) in
                    self.diffRoomById(with: roomSchema)
            }
        )
    }
    
    // MARK: - Objc Action
    @objc func reload(_ searchBar: UISearchBar) {
        if let text = searchBar.text, text != "" {
            self.viewModel.searchUsers(with: text) { (userSchema) in
                DispatchQueue.main.async { [weak self] in
                    self?.coordinator?.showSuggestedRoom(with: userSchema,
                                                         currentlyJoinedRooms: (self?.viewModel.dataSource?.data.value)!)
                }
            }
        } else {
            showSuggestedRooms()
        }
    }
    
    @objc func reloadPeople(_ sender: Any) {
        self.viewModel.fetchRooms() { [unowned self] newRooms in
            self.tableManager.data.value = newRooms
            self.tableNode.reloadData()

            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
        }
    }
}

// MARK: - Inserting and Deleting
extension PeopleViewController {
    private func deleteRoom(by passedId: String) {
        if let index = self.viewModel.dataSource?.data.value.firstIndex(where: { (room) in
            room.id == passedId
        }) {
            self.viewModel.dataSource?.data.value.remove(at: index)
            
            self.tableNode.performBatch(animated: true, updates: {
                tableNode.deleteRows(at: [IndexPath(row: index - 1, section: 0)], with: .fade)
            }, completion: nil)
        }
    }
    
    private func insertRoom(with room: RoomSchema) {
        if checkIfOneToOne(room: room) { return }
        
        guard var current = ShareData().currentlyJoinedUsers else { return }
        current.append(room)
        ShareData().currentlyJoinedUsers = current
        
        self.viewModel.dataSource?.data.value.append(room)
        self.tableNode.performBatch(animated: true, updates: { [weak self] in
            if let counted = self?.viewModel.dataSource?.data.value.count {
                self?.tableNode.insertRows(at: [IndexPath(row: counted - 1, section: 0)], with: .fade)
            } else {
                self?.tableNode.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
            }
            }, completion: nil)
    }
    
    private func diffRoomById(with room: RoomSchema) {
        if room.oneToOne == false { return }
        
        if let index = viewModel.dataSource?.data.value.firstIndex(where: { (roomSchema) -> Bool in
            room.id == roomSchema.id
        }) {
            
            if let newUnreadedItems = room.unreadItems {
                self.tableManager.data.value[index].unreadItems = newUnreadedItems
                self.tableNode.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                self.tableManager.data.value.move(from: index, to: self.viewModel.numberOfFavourites())
                UIView.performWithoutAnimation {
                    self.tableNode.moveRow(at: IndexPath(row: index, section: 0),
                                           to: IndexPath(row: self.viewModel.numberOfFavourites(), section: 0))
                }
            }
            
            if let newTopic = room.topic {
                self.viewModel.dataSource?.data.value[index].topic = newTopic
                self.tableNode.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            }
        }
    }
    
    private func checkIfOneToOne(room: RoomSchema) -> Bool {
        room.oneToOne == false
    }
}

// MARK: - Search UI Logic
extension PeopleViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        showSuggestedRooms()
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        view = tableNode.view
    }
    
    private func showSuggestedRooms() {
        coordinator?.showSuggestedRoom(with: self.viewModel.suggestedRoomsData, currentlyJoinedRooms: (self.viewModel.dataSource?.data.value)!)
    }
}

// MARK: - Seatch Logic
extension PeopleViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(reload(_:)), object: searchBar)
        self.perform(#selector(reload(_:)), with: searchBar, afterDelay: 0.5)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.coordinator?.removeSuggestedCoordinator()
    }
}

extension PeopleViewController: TabBarReselectHandling {
    func handleReselect() {
        tableNode.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}
