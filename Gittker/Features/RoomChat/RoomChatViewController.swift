//
//  ChatViewController.swift
//  Gittker
//
//  Created by uuttff8 on 3/15/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import MessageKit

extension UIColor {
    static let primaryColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
}

final class RoomChatViewController: RoomChatBaseViewController {
    weak var coordinator: RoomChatCoordinator?
    private lazy var viewModel = RoomChatViewModel(roomSchema: roomSchema)
    
    private var isJoined: Bool
    private var roomSchema: RoomSchema
    
    private var cached = 2
    
    init(coordinator: RoomChatCoordinator, roomSchema: RoomSchema, isJoined: Bool) {
        self.coordinator = coordinator
        self.roomSchema = roomSchema
        self.isJoined = isJoined
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadFirstMessages() {
        viewModel.loadFirstMessages() { (gittMessages) in
            DispatchQueue.main.async { [weak self] in
                self?.messageList = gittMessages
                if self!.cached > 0 {
                    self?.messagesCollectionView.reloadData()
                    let _ = self!.cached - 1
                }
                
                self?.configureScrollAndPaginate()
            }
        }
    }
    
    override func subscribeOnMessagesEvent() {
        FayeEventMessagesBinder(roomId: roomSchema.id)
            .subscribe(
                onNew: { [weak self] (message: GittkerMessage) in
                    self?.addToMessageMap(message: message, isFirstly: true)
                }, onDeleted: { [weak self] (id) in
                    self?.deleteMessage(by: id)
                }, onUpdate: { [weak self] (message: GittkerMessage) in
                    self?.updateMessage(message)
                }
        )
    }
    
    override func loadOlderMessages() {
        self.canFetchMoreResults = false
        if let firstMessageId = messageList.first?.message.messageId {
            viewModel.loadOlderMessages(messageId: firstMessageId)
            { (gittMessages: [GittkerMessage]) in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.messageList.insert(contentsOf: gittMessages, at: 0)
                    self.insertSectionsAndKeepOffset(gittMessages: gittMessages)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.canFetchMoreResults = true
                    }
                }
            }
        }
    }
    
    //    func appendItems(_ items: [GittkerMessage]) {
    //        guard let collectionView = collectionView else { return }
    //        let contentOffset = messagesCollectionView.contentOffset
    //
    //        let startRange = 0
    //        self.messageList.append(contentsOf: items)
    //        let endRange = items.count - 1
    //        let indexPaths = IndexSet(Array(startRange..<endRange))
    //
    //        CATransaction.begin()
    //        CATransaction.setDisableActions(true)
    //        messagesCollectionView.performBatchUpdates({
    //            messagesCollectionView.insertSections(indexPaths)
    //        }, completion: { (finished) in
    //            self.messagesCollectionView.setContentOffset(CGPoint(x: 0, y: contentOffset.y), animated: false)
    //        })
    //        CATransaction.commit()
    //    }
    
    private func insertSectionsAndKeepOffset(gittMessages: [GittkerMessage]) {
        
        //         stop scrolling
        messagesCollectionView.setContentOffset(messagesCollectionView.contentOffset, animated: false)
        //         calculate the offset and reloadData
        let beforeContentSize = messagesCollectionView.contentSize
        
        //        CATransaction.begin()
        //        CATransaction.setDisableActions(true)
        self.messagesCollectionView.performBatchUpdates({
            let array = Array(0..<gittMessages.count)
            self.messagesCollectionView.insertSections(IndexSet(array))
        }, completion: { _ in
            //            self.messagesCollectionView.setContentOffset(CGPoint(x: 0, y: contentOffset.y), animated: false)
            self.messagesCollectionView.layoutIfNeeded()
            let afterContentSize = self.messagesCollectionView.contentSize
            
            //             reset the contentOffset after data is updated
            let newOffset = CGPoint(
                x: self.messagesCollectionView.contentOffset.x + (afterContentSize.width - beforeContentSize.width),
                y: self.messagesCollectionView.contentOffset.y + (afterContentSize.height - beforeContentSize.height))
            self.messagesCollectionView.setContentOffset(newOffset, animated: false)
        })
        
    }
    
    override func sendMessage(tmpMessage: MockMessage) {
        if case let MessageKind.text(text) = tmpMessage.kind {
            
            viewModel.sendMessage(text: text) { (result) in
                switch result {
                case .success(_):
                    print("All is ok")
                case .failure(_):
                    print("All is bad")
                }
            }
            
        }
    }
    
    override func joinButtonHandlder() {
        viewModel.joinToChat(userId: userdata.senderId, roomId: roomSchema.id) { (success) in
            self.configureMessageInputBarForChat()
        }
    }
    
    override func markMessagesAsRead(messagesId: [String]) {
        self.viewModel.markMessagesAsRead(userId: userdata.senderId, messagesId: messagesId)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isJoined {
            showJoinButton()
        } else {
            configureMessageInputBarForChat()
        }
    }
    
    private func configureScrollAndPaginate() {
        // scroll to unread message
        // note: unread limit is 100
        if let indexPath = self.viewModel.findFirstUnreadMessage() {
            // paginate if scrolls at top
            if indexPath.section <= 20 {
                self.loadOlderMessages()
                if cached == 0 {
                    self.messagesCollectionView.reloadSections(IndexSet(integer: 100))
                }
            }
            self.messagesCollectionView.scrollToItem(at: indexPath, at: .top, animated: false)
            
        } else {
            self.messagesCollectionView.scrollToBottom()
        }
    }
    
}
