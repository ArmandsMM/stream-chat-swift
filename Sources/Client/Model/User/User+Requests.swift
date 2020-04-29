//
//  User+Requests.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 04/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public extension User {
    
    /// Update or create the user.
    /// - Parameter completion: a completion block with `User`.
    @discardableResult
    func update(_ completion: @escaping Client.Completion<User>) -> Cancellable {
        client.update(user: self, completion)
    }
    
    /// Mute the user.
    /// - Parameter completion: a completion block with `MutedUsersResponse`.
    @discardableResult
    func mute(_ completion: @escaping Client.Completion<MutedUsersResponse>) -> Cancellable {
        client.mute(user: self, completion)
    }
    
    /// Unmute the user.
    /// - Parameter completion: an empty completion block.
    @discardableResult
    func unmute(_ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        client.unmute(user: self, completion)
    }
    
    /// Flag the user.
    /// - Parameter completion: a completion block with `FlagUserResponse`.
    @discardableResult
    func flag(user: User, _ completion: @escaping Client.Completion<FlagUserResponse>) -> Cancellable {
        client.flag(user: self, completion)
    }
    
    /// Unflag the user.
    /// - Parameter completion: a completion block with `FlagUserResponse`.
    @discardableResult
    func unflag(user: User, _ completion: @escaping Client.Completion<FlagUserResponse>) -> Cancellable {
        client.unflag(user: self, completion)
    }
}
