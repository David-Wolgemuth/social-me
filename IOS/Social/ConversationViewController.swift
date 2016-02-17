//
//  ConversationViewController.swift
//  Social
//
//  Created by Shuhan Ng on 2/7/16.
//  Copyright © 2016 Shuhan Ng. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import JSQSystemSoundPlayer

class ConversationViewController: JSQMessagesViewController,ConnectionDelegate {
    
    var friend: Friend?
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor(red: 10/255, green: 180/255, blue: 230/255, alpha: 1.0))
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.lightGrayColor())
    
    var messages = [Message]()
    
    var avatars = Dictionary<String, JSQMessageAvatarImageDataSource>()
   
    

    
    override func viewDidLoad() {
        Connection.sharedInstance.delegate = self
        super.viewDidLoad()
        self.inputToolbar!.contentView!.leftBarButtonItem = nil
        self.navigationItem.title = friend?.username
        self.senderId = CoreDataManager.sharedInstance.get_user()!.id
        self.senderDisplayName = self.senderId
        automaticallyScrollsToMostRecentMessage = true
     
        messages = CoreDataManager.sharedInstance.get_messages(friend!.id!)!
        
        self.finishReceivingMessage()
        
    }
    
    func didReceiveMessages(data: AnyObject) {
        print("i got new message from server!!")
        let newMessage: Message? = CoreDataManager.sharedInstance.add_message(data["text"]! as! String, senderID: data["senderID"]! as! String, senderDisplayName: friend?.username, receiverID: data["receiverID"]! as! String)
        if let newMessage_saved = newMessage {
            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
            messages.append(newMessage_saved)
            finishReceivingMessage()
        } else {
            print("new Message received did not get saved to the coredata")
        }

    }
    
    
    func setupAvatarImage(name: String, imageUrl: String?, incoming: Bool) {
        let diameter = incoming ? UInt(collectionView!.collectionViewLayout.incomingAvatarViewSize.width) : UInt(collectionView!.collectionViewLayout.outgoingAvatarViewSize.width)
        if let stringUrl = imageUrl {
            if let url = NSURL(string: stringUrl) {
                if let data = NSData(contentsOfURL: url) {
                    let image = UIImage(data: data)
                    let avatarImage = JSQMessagesAvatarImageFactory.avatarImageWithImage(image,diameter: diameter)
                    avatars[name] = avatarImage
                    return
                }
            }
        }
        let defaultAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "profile"), diameter: diameter)
        avatars[name] = defaultAvatar
        
    }

    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        if let avatar = avatars[message.senderId()] { //if avator is already set up
            return avatar
        } else {
            let urlString = "http://192.168.1.227:8000/\(message.senderId()).jpeg"
            setupAvatarImage(message.senderId(), imageUrl: urlString, incoming: true)
            return avatars[message.senderId()]
        }
    }

    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        let newMessage: Message? = CoreDataManager.sharedInstance.add_message(text, senderID: self.senderId, senderDisplayName: self.senderDisplayName, receiverID: friend!.id!)
        if let newMessage_saved = newMessage {
            Connection.sharedInstance.sendMessages(["text":text,"senderID":self.senderId,"receiverID":friend!.id])
            messages.append(newMessage_saved)
            finishSendingMessage()
        } else {
            print("new Message sent did not get saved to the coredata")
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return self.messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        
        if message.senderId() == self.senderId {
            return outgoingBubble
        }
        return incomingBubble
    }
    
    //show timestamp for every 3rd message
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        if (indexPath.item % 3 == 0) {
            let message = self.messages[indexPath.item]
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date())
        }
        return nil
        
    }
    
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        let msg = self.messages[indexPath.item]
        if msg.senderId() == self.senderId {
            cell.textView!.textColor = UIColor.blackColor()
        } else {
            cell.textView!.textColor = UIColor.whiteColor()
        }
        let attribute: [String: AnyObject] = [NSForegroundColorAttributeName: (cell.textView?.textColor)! ,NSUnderlineStyleAttributeName:1]
        cell.textView!.linkTextAttributes = attribute
        return cell
        
    
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0.0 
    }
    

    
    
  
   
    
    
    
    

    
    
    
    
}
