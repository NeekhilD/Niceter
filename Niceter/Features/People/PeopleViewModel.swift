//
//  PeopleViewModel.swift
//  Niceter
//
//  Created by uuttff8 on 4/5/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import AsyncDisplayKit

class PeopleViewModel {
    weak var dataSource : GenericDataSource<RoomSchema>?
    
    var suggestedRoomsData: Array<UserSchema>?
    
    init(dataSource : GenericDataSource<RoomSchema>?) {
        self.dataSource = dataSource
    }
    
    func fetchRooms() {
        CachedPeopleLoader.init(cacheKey: Config.CacheKeys.peopleKey)
            .fetchNewAndCache { (rooms) in
                let filteredRooms = rooms.filterByPeople().sortByUnreadAndFavourite()
                self.dataSource?.data.value = filteredRooms
                ShareData().currentlyJoinedUsers = filteredRooms
        }
    }
    
    func fetchRoomsCached() {
        CachedPeopleLoader.init(cacheKey: Config.CacheKeys.peopleKey)
            .fetchData { (rooms) in
                let filteredRooms = rooms.filterByPeople().sortByUnreadAndFavourite()
                self.dataSource?.data.value = filteredRooms
                ShareData().currentlyJoinedUsers = filteredRooms
        }
    }
    
    func fetchSuggestedRooms() {
        CachedSuggestedRoomLoader.init(cacheKey: Config.CacheKeys.suggestedRoomsKey)
            .fetchData { (rooms) in
//                self.suggestedRoomsData = rooms
        }
    }
    
    func searchUsers(with text: String, completion: @escaping (([UserSchema]) -> Void)) {
        GitterApi.shared.searchUsers(query: text) { (result) in
            completion(result!.results)
        }
    }
    
    func leaveFromRoom(roomId: String, userId: String, completion: @escaping (SuccessSchema) -> Void) {
        GitterApi.shared.hideRoom(userId: userId, roomId: roomId) { (res) in
            completion(res)
        }
    }
}

class PeopleDataSource: GenericDataSource<RoomSchema>, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        data.value.count
    }
    
    func tableNode(
        _ tableNode: ASTableNode,
        nodeBlockForRowAt indexPath: IndexPath
    ) -> ASCellNodeBlock {
        return {
            let room = self.data.value[indexPath.row]
            let cell = RoomTableNode(with: RoomTableNode.Content(avatarUrl: room.avatarUrl ?? "",
                                                                 title: room.name ?? "",
                                                                 subtitle: room.topic ?? "",
                                                                 unreadItems: room.unreadItems ?? 0))
            
            return cell
        }
    }
    
    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            guard let userId = ShareData().userdata?.id else { return }
            let room = data.value[indexPath.row]
            
            data.value.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            
            leaveFromRoom(roomId: room.id, userId: userId) { (suc) in
                print(suc)
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    func leaveFromRoom(roomId: String, userId: String, completion: @escaping (SuccessSchema) -> Void) {
        GitterApi.shared.hideRoom(userId: userId, roomId: roomId) { (res) in
            completion(res)
        }
    }
}

// MARK: - TableView Delegate
class PeopleTableViewDelegate: NSObject, ASTableDelegate {
    var dataSource: [RoomSchema]?
    weak var coordinator: PeopleCoordinator?
    
    private var vc: UIViewController
    
    init(with vc: UIViewController) {
        self.vc = vc
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        if let room = dataSource?[indexPath.item] {
            coordinator?.showChat(roomSchema: room)
        }
        tableNode.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let room = dataSource?[indexPath.row] else { return nil }
        
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: { () -> UIViewController? in
            return self.coordinator!.previewChat(roomSchema: room)
        }) { _ -> UIMenu? in
            let copyAction = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { action in
                RoomsService.share(room: room, in: self.vc)
            }
            return UIMenu(title: "", children: [copyAction])
        }
        return configuration
    }
}
