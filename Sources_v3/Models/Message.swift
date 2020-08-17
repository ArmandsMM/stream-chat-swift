//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A unique identifier of a message.
public typealias MessageId = String

/// A type of the message.
public enum MessageType: String, Codable {
    /// A regular message created in the channel.
    case regular
    
    /// A temporary message which is only delivered to one user. It is not stored in the channel history. Ephemeral messages
    /// are normally used by commands (e.g. /giphy) to prompt messages or request for actions.
    case ephemeral
    
    /// An error message generated as a result of a failed command. It is also ephemeral, as it is not stored in the channel
    /// history and is only delivered to one user.
    case error
    
    /// The message is a reply to another message. Use the `parentMessageId` variable of the message to get the parent
    /// message data.
    case reply
    
    /// A message generated by a system event, like updating the channel or muting a user.
    case system
    
    /// A deleted message.
    case deleted
}

/// A convenient type alias for `MessageModel` with `DefaultExtraData`.
public typealias Message = MessageModel<DefaultDataTypes>

/// Additional data fields `MessageModel` can be extended with. You can use it to store your custom data related to a message.
public protocol MessageExtraData: ExtraData {}

public struct MessageModel<ExtraData: ExtraDataTypes> {
    public let id: MessageId
    public let text: String
    public let type: MessageType
    public let command: String?
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let args: String?
    public let parentMessageId: MessageId?
    public let showReplyInChannel: Bool
    public let replyCount: Int
    public let extraData: ExtraData.Message
    public let isSilent: Bool
    public let reactionScores: [String: Int]
    
    public let author: UserModel<ExtraData.User>
    public let mentionedUsers: Set<UserModel<ExtraData.User>>
}

extension MessageModel: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}