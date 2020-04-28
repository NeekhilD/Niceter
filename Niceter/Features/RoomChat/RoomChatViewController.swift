//
//  ChatViewController.swift
//  Niceter
//
//  Created by uuttff8 on 3/15/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import MessageKit

extension BidirectionalCollection where Element : Equatable {
  public func difference<C: BidirectionalCollection>(
    from other: C
  ) -> CollectionDifference<Element> where C.Element == Self.Element {
    return difference(from: other, by: ==)
  }
}

final class RoomChatViewController: RoomChatAutocompleteExtend {
    weak var coordinator: RoomChatCoordinator?
    
    //MARK: -  Private Elements
    private lazy var viewModel = RoomChatViewModel(roomSchema: roomSchema)
    private var fayeClient: FayeEventMessagesBinder
    
    private var isJoined: Bool
    private var roomSchema: RoomSchema
    
    private var cached = 1
    
    private var percentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition!
    private var panGestureRecognizer: UIPanGestureRecognizer!

    //MARK: - Init
    init(coordinator: RoomChatCoordinator, roomSchema: RoomSchema, isJoined: Bool) {
        self.coordinator = coordinator
        self.roomSchema = roomSchema
        self.isJoined = isJoined
        self.fayeClient = FayeEventMessagesBinder(roomId: roomSchema.id)
        
        super.init(rightBarImage: roomSchema.avatarUrl!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Faye
    override func loadFirstMessages() {
        viewModel.loadFirstMessages() { (gittMessages) in
            DispatchQueue.main.async { [weak self] in
                self?.messageList = gittMessages
                self?.messagesCollectionView.reloadData()
                self?.configureScrollAndPaginate()
            }
        }
    }
        
    override func subscribeOnMessagesEvent() {
        fayeClient
            .subscribe(
                onNew: { [weak self] (message: NiceterMessage) in
                    self?.viewModel.addNewMessageToCache(message: message)
                    self?.addToMessageMap(message: message, isFirstly: true)
                }, onDeleted: { [weak self] (id) in
                    self?.deleteMessageUI(by: id)
                }, onUpdate: { [weak self] (message: NiceterMessage) in
                    self?.updateMessageUI(message)
                }
        )
    }
    
    // MARK: - Message actions
    override func loadOlderMessages() {
        self.canFetchMoreResults = false
        
        if let firstMessageId = messageList.first?.message.messageId {
            viewModel.loadOlderMessages(messageId: firstMessageId)
            { (gittMessages: [NiceterMessage]) in
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
    
    override func deleteMessage(message: MockMessage) {
        self.viewModel.deleteMessage(messageId: message.messageId) { () in }
    }
            
    override func sendMessage(tmpMessage: MockMessage) {
        viewModel.sendMessage(text: tmpMessage.originalText) { (result) in
            switch result {
            case .success(_): break
            case .failure(_): break
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
    
    
    override func reportMessage(message: MockMessage) {
        self.viewModel.reportMessage(messageId: message.messageId) { (reportMessageSchema) in
            super.showOkAlert(config: SystemAlertConfiguration(title:
                "Thank You!\n\nYour report will be reviewed by Gitter team very soon.".localized(),
                                                               subtitle: nil))
        }
    }
    
    override func editMessage(message: MockMessage) {
        guard case MessageKind.attributedText(let messageText) = message.kind else { return }
        self.viewModel.editMessage(text: messageText.string, messageId: message.messageId) { (roomRecrSchema) in
//            print(roomRecrSchema)
            self.editingMessage(self.editingMessagePlugin, shouldBecomeVisible: false)
        }
    }
    
    // MARK: - Navigating
    override func showProfileScreen(username: String) {
        coordinator?.showProfileScreen(username: username)
    }
    
    override func onAvatarTapped() {
        coordinator?.showRoomInfoScreen(roomSchema: self.roomSchema,
                                        prefetchedUsers: self.viewModel.roomUsersIn)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.viewModel.prefetchRoomUsers()
        title = roomSchema.name
        
        if !isJoined {
            showJoinButton()
        } else {
            super.configureMessageInputBarForChat()
        }
    }
        
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fayeClient.cancel()
    }
    
    
    #warning("refactor")
    private func configureScrollAndPaginate() {
        // scroll to unread message
        // note: unread limit is 100
//        if let indexPath = self.viewModel.findFirstUnreadMessage() {
//            // paginate if scrolls at top
//            if indexPath.section <= 20 {
//                self.loadOlderMessages()
//                if cached == 0 {
//                    self.messagesCollectionView.reloadSections(IndexSet(integer: indexPath.section))
//                }
//            }
//            self.messagesCollectionView.scrollToItem(at: indexPath, at: .top, animated: false)
//
//        } else {
//            UIView.performWithoutAnimation {
                self.messagesCollectionView.scrollToBottom(animated: false)
//            }
//        }
    }
    
}
