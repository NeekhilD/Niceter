//
//  RoomChatCoordinator.swift
//  Niceter
//
//  Created by uuttff8 on 3/15/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import AsyncDisplayKit

class RoomChatCoordinator: Coordinator {
    enum Flow {
        case full
        case preview
    }

    weak var navigationController: ASNavigationController?
    var childCoordinators = [Coordinator]()
    var currentController: RoomChatViewController?
    let currentFlow: RoomChatCoordinator.Flow
    
    private var roomSchema: RoomSchema
    private var isJoined: Bool
    
    init(with navigationController: ASNavigationController?, roomSchema: RoomSchema, isJoined: Bool, flow: Flow) {
        self.navigationController = navigationController
        self.isJoined = isJoined
        self.roomSchema = roomSchema
        self.currentFlow = flow
        
        currentController = RoomChatViewController(coordinator: self, roomSchema: roomSchema, isJoined: isJoined)
    }
    
    func start() {
        navigationController?.pushViewController(currentController!, animated: true)
    }
    
    func showProfileScreen(username: String) {
        let coord = ProfileCoordinator(with: navigationController,
                                       username: username,
                                       flow: ProfileCoordinator.Flow.fromChat)
        childCoordinators.append(coord)
        coord.start()
    }
    
    func showRoomInfoScreen(roomSchema: RoomSchema, prefetchedUsers: [UserSchema]) {
        let coord = RoomInfoCoordinator(with: self.navigationController!,
                                        roomSchema: roomSchema,
                                        prefetchedUsers: prefetchedUsers)
        self.childCoordinators.append(coord)
        coord.start()
    }
    
    func showReplies(roomRecreates: [RoomRecreateSchema], roomId: String) {
        let coord = ShowRepliesCoordinator(with: navigationController, roomRecreates: roomRecreates, roomId: roomId)
        self.childCoordinators.append(coord)
        coord.start()
    }
}
