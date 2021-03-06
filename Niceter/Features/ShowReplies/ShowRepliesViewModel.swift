//
//  ShowRepliesViewModel.swift
//  Niceter
//
//  Created by uuttff8 on 7/16/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import AsyncDisplayKit

class ShowRepliesViewModel {
    private let parentId: String
    private let roomRecreates: [RoomRecreateSchema]
    private let roomId: String
    
    init (roomRecreates: [RoomRecreateSchema], roomId: String) {
        self.roomRecreates = roomRecreates
        self.parentId = roomRecreates[0].parentId ?? ""
        self.roomId = roomId
    }
    
    func sendMessageInThread(
        text: String,
        completion: @escaping (Result<RoomRecreateSchema, GitterApiErrors.MessageFailedError>) -> Void
    ) {
        GitterApi.shared.sendMessageInThread(roomId: roomId, text: text, parentId: parentId, completion: { (res) in
            guard let res = res else { return }
            completion(res)
        })
    }
}
