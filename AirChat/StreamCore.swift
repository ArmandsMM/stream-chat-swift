//
//  StreamCore.swift
//  AirChat
//
//  Created by Vojta on 18/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import Foundation

//////////////////////////////////////////////////
///         Everything here is just mock
//////////////////////////////////////////////////

typealias Cancellable = Void

class Client {
    var currentUser: User = User(name: "Vojta")
    
    func channelReference(id: Channel.Id) -> ChannelReference {
        ChannelReference(client: self)
    }
}

class Reference {
    init(client: Client) {
        self.client = client
    }
    
    fileprivate let client: Client
}

extension Reference {
    var currentUser: User { client.currentUser }
}

struct Channel {
    typealias Id = String
    let name: String
}

struct Member: Hashable { }

struct Message {
    typealias Id = String
    let id: Id = UUID().uuidString
    let text: String
    let user: User
}

struct CurrentUser { }

struct User: Equatable {
    typealias Id = String
    let id: Id = UUID().uuidString
    let name: String
}

struct QueryOptions { }
struct Pagination { }

protocol ChannelExtraDataCodable: Codable { }

class ChannelListReference {
    
}

protocol Event { }

protocol ChannelEvent: Event { }
protocol MemberEvent: Event { }

protocol TypingEvent: Event { }
struct TypingStarted: TypingEvent {
    let user: User
}

struct TypingStopped: TypingEvent {
    let user: User
}

extension String: Error { }

class ChannelReference: Reference {

    let bahadir = User(name: "Bahadir")
    
    override init(client: Client) {
        super.init(client: client)
        
        let rnd = TimeInterval.random(in: 5...10)
        DispatchQueue.main.asyncAfter(deadline: .now() + rnd) {
            self.simulateTypingEvent(user: self.bahadir)
        }
    }
    
    func simulateTypingEvent(user: User) {
        delegate?.didReceiveTypingEvent(self, event: TypingStarted(user: user), metadata: .init())
        
        let rnd = TimeInterval.random(in: 2...5)
        DispatchQueue.main.asyncAfter(deadline: .now() + rnd) {
            self.delegate?.didReceiveTypingEvent(self, event: TypingStopped(user: user), metadata: .init())
            
            self.simulateReceivedMessage(user: user)
            
            let rnd = TimeInterval.random(in: 5...8)
            DispatchQueue.main.asyncAfter(deadline: .now() + rnd) {
                self.simulateTypingEvent(user: user)
            }
        }
    }

    func simulateReceivedMessage(user: User) {
        let message = Message(text: Lorem.words(1...8), user: user)
        delegate?.messagesChanged(self, changes: [.added(message)], metadata: .init())
    }

    struct Snapshot {
        let metadata: ChangeMatadata
        
        let channel: Channel
        let messages: [Message]
        let members: [Member]
        let watchers: [Member]
    }

    weak var delegate: ChannelReferenceDelegate?

    /// Loads the current data snapshot for this channel.
    ///
    /// - Parameters:
    ///   - includeLocalStorage: When `true`, the completion block will be called twice.
    ///
    ///     The first call is done using the locally stored data while the client makes a call to the servers. The completion block
    ///     is called the second time with the updated data.
    ///
    ///     Check the value of `snapshot.metadata.isFromLocalCache` to determine the source of the data.
    ///
    ///   - completion:
    /// - Returns:
    func currentSnapshot(includeLocalStorage: Bool = false, completion: @escaping (_ data: Result<Snapshot, Error>) -> Void) -> Cancellable {
        
        let messages = initialMessages(currentUser: client.currentUser)
        
        if includeLocalStorage {
            let snapshot = Snapshot(metadata: .init(isPendingWrite: false, isFromLocalCache: true),
                                    channel: .init(name: "Chat with Bahadir"),
                                    messages: Array(messages.prefix(3)),
                                    members: [],
                                    watchers: [])
            
            completion(.success(snapshot))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            let snapshot = Snapshot(metadata: .init(isPendingWrite: false, isFromLocalCache: false),
                                    channel: .init(name: "Chat with Bahadir"),
                                    messages: messages,
                                    members: [],
                                    watchers: [])
            
            completion(.success(snapshot))
        }
    }

    // Actions

    func send(message: Message, completion: ((Error?) -> Void)? = nil) -> Cancellable {
        delegate?.messagesChanged(self,
                                  changes: [.added(message)],
                                  metadata: .init(isPendingWrite: true, isFromLocalCache: false))

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let isFailure = Int.random(in: 0...3) == 3
            guard isFailure == false else { completion?("Error sending this message."); return }
            
            self.delegate?.messagesChanged(self,
                                      changes: [.added(message)],
                                      metadata: .init(isPendingWrite: false, isFromLocalCache: false))
        }
    }
    
    func send(event: TypingEvent, completion: ((Error?) -> Void)? = nil) -> Cancellable {  }

    func startWatchingChannel(options: QueryOptions, completion: (Error?) -> Void) -> Cancellable {  }
    func stopWatchingChannel(options: QueryOptions, completion: (Error?) -> Void) -> Cancellable {  }
    
    func load(pagination: Pagination, completion: (Error?) -> Void) -> Cancellable {  }
    
    func delete(image: URL, completion: (Error?) -> Void) -> Cancellable {  }
    func delete(file: URL, completion: (Error?) -> Void) -> Cancellable {  }
    
    func delete(message: Message, completion: ((Error?) -> Void)? = nil) -> Cancellable {
        delegate?.messagesChanged(self,
                                  changes: [.removed(message)],
                                  metadata: .init(isPendingWrite: true, isFromLocalCache: false))

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let isFailure = Int.random(in: 0...2) == 2
            guard isFailure == false else { completion?("Too many bugs..."); return }
            
            self.delegate?.messagesChanged(self,
                                      changes: [.removed(message)],
                                      metadata: .init(isPendingWrite: false, isFromLocalCache: false))
        }
    }

    func hide(clearHistory: Bool = false, completion: (Error?) -> Void) -> Cancellable {  }
    func show(completion: (Error?) -> Void) -> Cancellable {  }
    
    func ban(member: Member, completion: (Error?) -> Void) -> Cancellable {  }
    func add(members: Set<Member>, completion: (Error?) -> Void) -> Cancellable {  }
    func remove(members: Set<Member>, completion: (Error?) -> Void) -> Cancellable {  }
    
    func invite(members: Set<Member>, completion: (Error?) -> Void) -> Cancellable {  }
    func acceptInvite(with message: Message? = nil, completion: (Error?) -> Void) -> Cancellable {  }
    func rejectInvite(with message: Message? = nil, completion: (Error?) -> Void) -> Cancellable {  }
    
    func markRead(completion: (Error?) -> Void) -> Cancellable {  }
    func update(name: String? = nil,
                imageURL: URL? = nil,
                exatraData: ChannelExtraDataCodable? = nil,
                completion: (Error?) -> Void) -> Cancellable {  }
    func delete(completion: (Error?) -> Void) -> Cancellable {  }
}

protocol ChannelReferenceDelegate: AnyObject {
    func channelDataUpdated(_ reference: ChannelReference, data: Channel, metadata: ChangeMatadata)
    
    func messagesChanged(_ reference: ChannelReference, changes: [Change<Message>], metadata: ChangeMatadata)

    func didReceiveChannelEvent(_ reference: ChannelReference, event: ChannelEvent, metadata: ChangeMatadata)
    func didReceiveTypingEvent(_ reference: ChannelReference, event: TypingEvent, metadata: ChangeMatadata)
    func didReceiveMemeberEvent(_ reference: ChannelReference, event: MemberEvent, metadata: ChangeMatadata)
}

extension ChannelReferenceDelegate {
    func channelDataUpdated(_ reference: ChannelReference, data: Channel, metadata: ChangeMatadata) {}
    func messagesChanged(_ reference: ChannelReference, changes: [Change<Message>], metadata: ChangeMatadata) {}
    func didReceiveChannelEvent(_ reference: ChannelReference, event: ChannelEvent, metadata: ChangeMatadata) {}
    func didReceiveTypingEvent(_ reference: ChannelReference, event: TypingEvent, metadata: ChangeMatadata) {}
    func didReceiveMemeberEvent(_ reference: ChannelReference, event: MemberEvent, metadata: ChangeMatadata) {}
}

enum Change<T> {
    case added(_ item: T)
    case updated(_ item: T)
    case moved(_ item: T)
    case removed(_ item: T)
}

struct ChangeMatadata {
    /// This change is done only locally and is not confirmed from the backend. You can use it for optimistic UI updates.
    var isPendingWrite: Bool = false
    
    /// Tha data comes from the local storage. Another update with the live data from the backend may came momentarily.
    var isFromLocalCache: Bool = false
}

// ==================

private let john = User(name: "John")

private func initialMessages(currentUser: User) -> [Message] {
    [
        .init(text: "Hey!", user: currentUser),
        .init(text: "Hey there :)", user: john),
        .init(text: "How's it going today?", user: john),

        .init(text: "Hey!", user: currentUser),
        .init(text: "Hey there :)", user: john),
        .init(text: "How's it going today?", user: john),

        .init(text: "Hey!", user: currentUser),
        .init(text: "Hey there :)", user: john),
        .init(text: "How's it going today?", user: john),
    ]
}

