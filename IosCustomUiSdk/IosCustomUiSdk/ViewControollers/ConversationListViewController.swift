//
//  MessagesViewController.swift
//  IosCustomUiSdk
//
//  Created by Sunil on 27/09/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import Foundation
import UIKit
import MessageKit
import MapKit
import Applozic

public class ConversationListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate

    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)

    fileprivate let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.estimatedRowHeight = 75
        tv.rowHeight = 75
        tv.separatorStyle = .none
        tv.backgroundColor = UIColor.white
        tv.keyboardDismissMode = .onDrag
        return tv
    }()


    var allMessages = [ALMessage]()

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allMessages.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: MessageCell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell

        guard let alMessage = allMessages[indexPath.row] as? ALMessage  else {
            return UITableViewCell()
        }

        cell.update(viewModel: alMessage)
        return cell;
    }


    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let alMessage = allMessages[indexPath.row] as? ALMessage  else {
            return
        }

        let viewController = ConversationViewController()

        if(alMessage.groupId != nil && alMessage.groupId != 0) {
            viewController.groupId = alMessage.groupId;
        } else {
            viewController.userId = alMessage.to;
        }
        viewController.createdAtTime = alMessage.createdAtTime
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupView()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        activityIndicator.center = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
        activityIndicator.color = UIColor.gray
        view.addSubview(activityIndicator)
        self.view.bringSubview(toFront: activityIndicator)
        self.activityIndicator.startAnimating()
        appDelegate?.applozicClient.subscribeToConversation()
        self.loadMessages()
    }

    func loadMessages()  {

        if (self.allMessages.count>0) {
            self.allMessages.removeAll()
        }

        appDelegate?.applozicClient.getLatestMessages(false, withCompletionHandler: { messageList, error in
            if error == nil {

                guard let list = messageList else {
                    return
                }
                self.allMessages = list as! [ALMessage];
                self.activityIndicator.stopAnimating()
                self.tableView.reloadData()

            }
        })
    }

    private func setupView() {

        title = "My Chats"

        let back = NSLocalizedString("Back", value: "Back", comment: "")
        let leftBarButtonItem = UIBarButtonItem(title: back, style: .plain, target: self, action: #selector(customBackAction))


        navigationItem.leftBarButtonItem = leftBarButtonItem

        let rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_exit_to_app_white", in: Bundle(for: ConversationListViewController.self), compatibleWith: nil), style: .plain, target: self, action: #selector(logout))

        navigationItem.rightBarButtonItem = rightBarButtonItem

        self.addViewsForAutolayout(views: [tableView])

        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true

        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.automaticallyAdjustsScrollViewInsets = false
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")

    }

    @objc func logout() {

        let registerUserClientService: ALRegisterUserClientService = ALRegisterUserClientService()
        registerUserClientService.logout { (response, error) in
            if(error == nil && response?.status == "success") {
                self.dismiss(animated: false, completion: nil)
            }
        }
    }

    @objc func customBackAction() {
        guard let nav = self.navigationController else { return }
        let dd = nav.popViewController(animated: true)
        if dd == nil {
            self.dismiss(animated: true, completion: nil)
        }
    }

    func addViewsForAutolayout(views: [UIView]) {
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(view)
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        appDelegate?.applozicClient.unsubscribeToConversation()
    }

    public func onMessageReceived(_ alMessage: ALMessage!) {

        self.addMessage(alMessage)
    }

    public func onMessageSent(_ alMessage: ALMessage!) {

        self.addMessage(alMessage)

    }

    public func onUserDetailsUpdate(_ userDetail: ALUserDetail!) {

    }

    public func onMessageDelivered(_ message: ALMessage!) {
    }

    public func onMessageDeleted(_ messageKey: String!) {

    }

    public func onMessageDeliveredAndRead(_ message: ALMessage!, withUserId userId: String!) {

    }

    public func onConversationDelete(_ userId: String!, withGroupId groupId: NSNumber!) {

    }

    public func conversationRead(byCurrentUser userId: String!, withGroupId groupId: NSNumber!) {

    }

    public func onUpdateTypingStatus(_ userId: String!, status: Bool) {

    }

    public func onUpdateLastSeen(atStatus alUserDetail: ALUserDetail!) {

    }

    public func onUserBlockedOrUnBlocked(_ userId: String!, andBlockFlag flag: Bool) {

    }

    public func onChannelUpdated(_ channel: ALChannel!) {

    }

    public func onAllMessagesRead(_ userId: String!) {

    }

    public func onMqttConnectionClosed() {
        appDelegate?.applozicClient.subscribeToConversation()
    }

    public func onMqttConnected() {

    }

    public func addMessage(_ alMessage: ALMessage) {

        if(alMessage.type != nil && alMessage.type  != AL_OUT_BOX && !alMessage.isMsgHidden()){
            appDelegate?.sendLocalPush(message: alMessage)
        }

        var messagePresent = [ALMessage]()

        if let _ = alMessage.groupId {
            messagePresent = allMessages.filter { ($0.groupId != nil) ? $0.groupId == alMessage.groupId:false }
        } else {
            messagePresent = allMessages.filter {
                $0.groupId == nil ? (($0.contactIds != nil) ? $0.contactIds == alMessage.contactIds:false) : false
            }
        }

        if let firstElement = messagePresent.first, let index = allMessages.index(of: firstElement) {
            allMessages[index] = alMessage
            self.allMessages[index] = alMessage
        } else {
            allMessages.append(alMessage)
            self.allMessages.append(alMessage)
        }

        if (self.allMessages.count) > 1 {
            self.allMessages = allMessages.sorted { ($0.createdAtTime != nil && $1.createdAtTime != nil) ? Int(truncating: $0.createdAtTime) > Int(truncating: $1.createdAtTime): false }
        }

        self.tableView.reloadData()

    }

}

