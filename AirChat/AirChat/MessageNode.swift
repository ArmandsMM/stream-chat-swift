//
//  MessageNode.swift
//  AirChat
//
//  Created by Vojta on 19/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import SpriteKit

class MessageNode: SKLabelNode {
    
    let id: Message.Id
    private let contentInset: CGFloat = -8

    var isPendingWrite: Bool = false {
        didSet {
            alpha = isPendingWrite ? 0.5 : 1
        }
    }

    var isPendingDelete: Bool = false {
        didSet {
            alpha = isPendingWrite ? 0.5 : 1
        }
    }

    var isInErrorState: Bool = false {
        didSet {
            errorNode.isHidden = !isInErrorState
        }
    }

    init(text: String, id: Message.Id) {
        self.id = id
        
        super.init()
        
        numberOfLines = 0
        self.text = text
        fontName = "SanFranciscoUIDisplay"
        fontSize = 15
        
        isUserInteractionEnabled = true
        
        physicsBody = SKPhysicsBody(polygonFrom: CGPath(rect: frame.insetBy(dx: contentInset, dy: contentInset), transform: nil))
        physicsBody?.isDynamic = true
    }

    var backgroundColor: UIColor {
        set { backgroundNode.fillColor = newValue }
        get { backgroundNode.fillColor }
    }

    var borderColor: UIColor {
        set { backgroundNode.strokeColor = newValue }
        get { backgroundNode.strokeColor }
    }

    lazy var backgroundNode: SKShapeNode = {
        let shapeNode = SKShapeNode(rect: frame.insetBy(dx: contentInset, dy: contentInset), cornerRadius: 5)
        shapeNode.lineWidth = 0
        shapeNode.alpha = 0.4
        addChild(shapeNode)
        _ = self.errorNode
        return shapeNode
    }()

    lazy var errorNode: SKShapeNode = {
        let shapeNode = SKShapeNode(rect: frame.insetBy(dx: contentInset, dy: contentInset), cornerRadius: 5)
        shapeNode.lineWidth = 0
        shapeNode.fillColor = .red
        shapeNode.isHidden = true
        addChild(shapeNode)
        return shapeNode
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

