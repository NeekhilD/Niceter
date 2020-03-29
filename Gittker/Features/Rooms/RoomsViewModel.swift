//
//  HomeViewModel.swift
//  Gittker
//
//  Created by uuttff8 on 3/5/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import AsyncDisplayKit

class RoomsViewModel {
    weak var dataSource : GenericDataSource<RoomSchema>?
    
    var suggestedRoomsData: Array<RoomSchema>?
    
    init(dataSource : GenericDataSource<RoomSchema>?) {
        self.dataSource = dataSource
    }
    
    func fetchRoomsCached() {
        CachedRoomLoader.init(cacheKey: Config.CacheKeys.roomsKey)
            .fetchData { (rooms) in
                // sort by unreadItems
                let rooms = rooms.sorted { (a, b) -> Bool in
                    if let a = a.unreadItems, let b = b.unreadItems {
                        return a > b
                    }
                    return false
                }
                self.dataSource?.data.value = rooms
        }
    }
    
    func fetchSuggestedRooms() {
        CachedSuggestedRoomLoader.init(cacheKey: Config.CacheKeys.suggestedRoomsKey)
            .fetchData { (rooms) in
                self.suggestedRoomsData = rooms
        }
    }
    
    func suggestedRoomsSearchQuery(with text: String, completion: @escaping (([RoomSchema]) -> Void)) {
        GitterApi.shared.searchRooms(query: text) { (result) in
            completion(result!.results)
        }
    }
}

class RoomsDataSource: GenericDataSource<RoomSchema>, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        data.value.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            let room = self.data.value[indexPath.row]
            let cell = RoomTableNode(with: RoomContent(avatarUrl: room.avatarUrl ?? "",
                                                       title: room.name ?? "",
                                                       subtitle: room.topic ?? "",
                                                       unreadItems: room.unreadItems ?? 0))
            
            return cell
        }
    }
}


class RoomsTableViewDelegate: NSObject, ASTableDelegate {
    var dataSource: [RoomSchema]?
    weak var coordinator: RoomsCoordinator?
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        if let roomId = dataSource?[indexPath.item].id {
            coordinator?.showChat(roomId: roomId)
        }
        tableNode.deselectRow(at: indexPath, animated: true)
    }
}
