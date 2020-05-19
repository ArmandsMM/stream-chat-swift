//
//  GameViewController.swift
//  AirChat
//
//  Created by Vojta on 14/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class ChatViewController: UIViewController {

    var channelRef: ChannelReference!
    
    @IBOutlet weak var inputField: UITextField!
    var scene: SKScene!
    
    // Optimistic UI update helpers
    private var pendingWritesMessageIds: Set<Message.Id> = []
    private var sendErrorMessageIds: Set<Message.Id> = []
    private var pendingRemovesMessageIds: Set<Message.Id> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupChannelReference()
    }
    
    func setupUI() {
        scene = SKScene(size: skView.bounds.size)
        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true
        
        scene.physicsWorld.gravity = .init(dx: 0, dy: 0.5)
        scene.physicsBody = SKPhysicsBody(edgeLoopFrom: scene.frame)
        
        inputField.delegate = self
    }
    
    func setupChannelReference() {
        // Load the initial data
        channelRef.currentSnapshot(includeLocalStorage: true) { [weak self] (result) in
            switch result {
            case let .success(snapshot):
                self?.title = snapshot.channel.name
                self?.reloadMessages(messages: snapshot.messages)
                
                if snapshot.metadata.isFromLocalCache {
                    // If the data come from the local storage, show the activity indicator
                    let spinner = UIActivityIndicatorView()
                    spinner.startAnimating()
                    self?.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
                    
                } else {
                    self?.navigationItem.rightBarButtonItem = nil
                }
                
            case let .failure(error):
                self?.navigationItem.rightBarButtonItem = nil
                print("Can't load the channel: \(error)")
            }
        }
        
        channelRef.delegate = self
    }
    
    var skView: SKView { view as! SKView }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let touchPosition = touch.location(in: skView)
        let converted = skView.convert(touchPosition, to: scene)
        let touchedNodes = scene.nodes(at: converted)
        
        guard let tappedNode = touchedNodes.first(where: { $0 is MessageNode }) as? MessageNode else { return }
        let message = messages.first(where: { $0.id == tappedNode.id })!
        
        if sendErrorMessageIds.contains(tappedNode.id) {
            presentResendOptions(message: message)
        }
        
        if message.user == channelRef.currentUser {
            presentMyMessageOptions(message: message)
        }
    }
    
    func sendMessage(text: String) {
        let message = Message(text: text, user: channelRef.currentUser)
        sendMessage(message: message)
    }

    func sendMessage(message: Message) {
        self.sendErrorMessageIds.remove(message.id)
        
        channelRef.send(message: message) { error in
            if let error = error {
                print("Error sending message: \(error)")
                self.sendErrorMessageIds.insert(message.id)
                self.updateMessageNodeState(message: message)
            }
        }
    }

    var messageNodes: [MessageNode] { scene.children.compactMap { $0 as? MessageNode } }
    var messages: [Message] = []
    
    /// Remove all messages and reload them
    func reloadMessages(messages: [Message]) {
        scene.physicsWorld.speed = 10000
        
        messageNodes.forEach { $0.removeFromParent() }
        
        messages.forEach {
            addMessageNode(message: $0, animate: false)
        }
        
        self.messages = messages
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scene.physicsWorld.speed = 1
        }
    }
    
    /// Adds a new message
    func addMessageNode(message: Message, animate: Bool = true) {
        let messageNode = MessageNode(text: message.text, id: message.id)
        
        let yPosition = animate ? 100 : view.frame.height - 50
        
        if message.user == channelRef.currentUser {
            messageNode.fontColor = .white
            messageNode.backgroundColor = .systemBlue
            messageNode.position = .init(x: view.bounds.width - messageNode.frame.width / 2.0 - 15, y: yPosition)

        } else {
            messageNode.fontColor = .black
            messageNode.backgroundColor = .lightGray
            messageNode.position = .init(x: 15, y: yPosition)
        }
        
        updateMessageNodeState(message: message, node: messageNode)
        
        messages.append(message)
        scene.addChild(messageNode)
    }
    
    /// Update the appearance of the node to reflect UI only state.
    func updateMessageNodeState(message: Message, node: MessageNode? = nil) {
        let node = node ?? messageNodes.first(where: { $0.id == message.id })!
        
        node.isPendingWrite = pendingWritesMessageIds.contains(message.id)
        
        if sendErrorMessageIds.contains(message.id) {
            node.isInErrorState = true
            node.text = "❌ " + message.text
        } else {
            node.text = message.text
            node.isInErrorState = false
        }
        
        if pendingRemovesMessageIds.contains(message.id) {
            node.isPendingDelete = true
            node.text = "Removing ..."
        }
        
        let idx = messages.firstIndex(where: { $0.id == message.id })!
        messages[idx] = message
    }
    
    func removeMessageNode(message: Message) {
        pendingWritesMessageIds.remove(message.id)
        sendErrorMessageIds.remove(message.id)
        pendingRemovesMessageIds.remove(message.id)
        
        messages.removeAll(where: { $0.id == message.id })
        messageNodes.first(where: { $0.id == message.id })?.removeFromParent()
    }
}

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Send message on Enter
        if let text = textField.text, text.isEmpty == false {
            sendMessage(text: text)
            textField.text = ""
            return true
        }
        
        return false
    }
}

// MARK: - Channel reference delegate

extension ChatViewController: ChannelReferenceDelegate {
    
    func didReceiveTypingEvent(_ reference: ChannelReference, event: TypingEvent, metadata: ChangeMatadata) {
        
        if let event = event as? TypingStarted {
            let label = UILabel()
            label.text = "\(event.user.name) is typing..."
            label.font = .italicSystemFont(ofSize: 8)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: label)
        }
        
        if event is TypingStopped {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    func channelDataUpdated(_ reference: ChannelReference, data: Channel, metadata: ChangeMatadata) {
        title = data.name
    }
    
    func messagesChanged(_ reference: ChannelReference, changes: [Change<Message>], metadata: ChangeMatadata) {
        changes.forEach {
            switch $0 {
            case let .added(message):
                if pendingWritesMessageIds.contains(message.id) {
                    if metadata.isPendingWrite == false {
                        pendingWritesMessageIds.remove(message.id)
                        updateMessageNodeState(message: message)
                    }
                    
                } else {
                    if metadata.isPendingWrite {
                        pendingWritesMessageIds.insert(message.id)
                    }
                    
                    addMessageNode(message: message)
                }
                
            case let .removed(message):
                if metadata.isPendingWrite {
                    pendingRemovesMessageIds.insert(message.id)
                    updateMessageNodeState(message: message)
                } else {
                    removeMessageNode(message: message)
                }
                
            case let .updated(message):
                updateMessageNodeState(message: message)
                    
            case .moved:
                // The order of the messages doesn't matter in our UI
                break
            }
        }
    }
}

// MARK: - Alert helpers

extension ChatViewController {
    
    func presentResendOptions(message: Message) {
        let alert = UIAlertController(title: "Message", message: "", preferredStyle: .actionSheet)
        alert.addAction(
            UIAlertAction(title: "Resend", style: .default, handler: { (_) in
                self.sendMessage(message: message)
                self.updateMessageNodeState(message: message)
            })
        )

        alert.addAction(
            UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
                self.removeMessageNode(message: message)
            })
        )
        
        present(alert, animated: true, completion: nil)
    }
    
    func presentMyMessageOptions(message: Message) {
        let alert = UIAlertController(title: "Message", message: "", preferredStyle: .actionSheet)
        alert.addAction(
            UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
                self.channelRef.delete(message: message) { error in
                    if let error = error {
                        print("Error deleting message! \(error)")
                        self.pendingRemovesMessageIds.remove(message.id)
                        self.updateMessageNodeState(message: message)
                        
                        self.showErrorAlert(text: "Can't delete message. Try again later. \nError: \(error).")
                    }
                }
            })
        )
        
        present(alert, animated: true, completion: nil)
    }
    
    func showErrorAlert(text: String) {
        let alert = UIAlertController(title: "Error", message: text, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
