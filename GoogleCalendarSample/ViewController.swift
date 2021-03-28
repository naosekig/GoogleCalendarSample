//
//  ViewController.swift
//  GoogleCalendarSample
//
//  Created by NAOAKI SEKIGUCHI on 2020/09/26.
//

import UIKit
import AppAuth
import GTMAppAuth
import GoogleAPIClientForREST

class ViewController: UIViewController {
    private let tableView: UITableView = UITableView()
    private let addButton: UIButton = UIButton()
    private let updateButton: UIButton = UIButton()
    private let deleteButton: UIButton = UIButton()
    private var dialogViewController: DialogViewController!
    private var selectedIndex: Int = 0
    private var googleCalendarEventList: [GoogleCalendaraEvent] = []
    private var authorization: GTMAppAuthFetcherAuthorization?
    private let clientID = ""
    private let iOSUrlScheme = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.white
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TableViewCell")
        tableView.backgroundColor = UIColor.clear
        self.view.addSubview(tableView)
        
        addButton.setTitle("Add", for: .normal)
        addButton.addTarget(self, action: #selector(self.touchUpButtonAdd(_:)), for: .touchUpInside)
        addButton.setTitleColor(UIColor.black, for: .normal)
        self.view.addSubview(addButton)
        
        updateButton.setTitle("Update", for: .normal)
        updateButton.addTarget(self, action: #selector(self.touchUpButtonUpdate(_:)), for: .touchUpInside)
        updateButton.setTitleColor(UIColor.black, for: .normal)
        self.view.addSubview(updateButton)
        
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.addTarget(self, action: #selector(self.touchUpButtonDelete(_:)), for: .touchUpInside)
        deleteButton.setTitleColor(UIColor.black, for: .normal)
        self.view.addSubview(deleteButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.changeScreen()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.getEvents()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(
            alongsideTransition: nil,
            completion: {(UIViewControllerTransitionCoordinatorContext) in
                self.changeScreen()
        }
        )
    }

    private func changeScreen() {
        tableView.frame = CGRect(x: 0, y: 100, width: self.view.frame.width, height: self.view.frame.height - 200)
        addButton.frame = CGRect(x: 20, y: self.view.frame.height - 50, width: 100, height: 40)
        updateButton.frame = CGRect(x: self.view.frame.width / 2 - 50, y: self.view.frame.height - 50, width: 100, height: 40)
        deleteButton.frame = CGRect(x: self.view.frame.width - 120, y: self.view.frame.height - 50, width: 100, height: 40)
    }
    
    @objc private func touchUpButtonAdd(_ sender: UIButton) {
        showDialogViewController(type: Type.add)
    }
    
    @objc private func touchUpButtonUpdate(_ sender: UIButton) {
        showDialogViewController(type: Type.update)
    }

    @objc private func touchUpButtonDelete(_ sender: UIButton) {
        self.delete(eventId: self.googleCalendarEventList[self.selectedIndex].id)
    }
    
    private func showDialogViewController(type: Type) {
        self.dialogViewController = DialogViewController()
        self.dialogViewController.type = type
        if type == Type.update {
            self.dialogViewController.googleCalendarEvent = self.googleCalendarEventList[self.selectedIndex]
        }
        self.dialogViewController.modalPresentationStyle = .overFullScreen
        self.dialogViewController.delegate = self
        self.present(self.dialogViewController, animated: true, completion: nil)
    }
    
    private func hideDialogViewController() {
        if let dialogViewController = self.dialogViewController {
            dialogViewController.dismiss(animated: true, completion: {
                self.dialogViewController = nil
            })
        }
    }
    
    typealias showAuthorizationDialogCallBack = ((Error?) -> Void)
    private func showAuthorizationDialog(callBack: @escaping showAuthorizationDialogCallBack) {
        let scopes = [
            "https://www.googleapis.com/auth/calendar",
            "https://www.googleapis.com/auth/calendar.readonly",
            "https://www.googleapis.com/auth/calendar.events",
            "https://www.googleapis.com/auth/calendar.events.readonly"
        ]
        
        let configuration = GTMAppAuthFetcherAuthorization.configurationForGoogle()
        let redirectURL = URL.init(string: iOSUrlScheme + ":/oauthredirect")
        
        let request = OIDAuthorizationRequest.init(configuration: configuration,
                                                   clientId: clientID,
                                                   scopes: scopes,
                                                   redirectURL: redirectURL!,
                                                   responseType: OIDResponseTypeCode,
                                                   additionalParameters: nil)
        
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentAuthorizationFlow = OIDAuthState.authState(
            byPresenting: request,
            presenting: self,
            callback: { (authState, error) in
                if let error = error {
                    NSLog("\(error)")
                } else {
                    if let authState = authState {
                        // 認証情報オブジェクトを生成
                        self.authorization = GTMAppAuthFetcherAuthorization.init(authState: authState)
                        GTMAppAuthFetcherAuthorization.save(self.authorization!, toKeychainForName: "authorization")
                    }
                }
                callBack(error)
        })
    }
    
    private func getEvents() {
        googleCalendarEventList.removeAll()
        let today = Date()
        let startDateTime = Calendar.init(identifier: .gregorian).date(byAdding: .year, value: -1, to: today)
        let endDateTime = Calendar.init(identifier: .gregorian).date(byAdding: .year, value: 1, to: today)
        
        self.get(startDateTime: startDateTime!, endDateTime: endDateTime!)
    }
    
    private func get(startDateTime: Date, endDateTime: Date) {
        if GTMAppAuthFetcherAuthorization(fromKeychainForName: "authorization") != nil {
            self.authorization = GTMAppAuthFetcherAuthorization(fromKeychainForName: "authorization")!
        }
        
        if self.authorization == nil {
            showAuthorizationDialog(callBack: {(error) -> Void in
                if error == nil {
                    self.getCalendarEvents(startDateTime: startDateTime, endDateTime: endDateTime)
                }
            })
        } else {
            self.getCalendarEvents(startDateTime: startDateTime, endDateTime: endDateTime)
        }
    }
    
    private func getCalendarEvents(startDateTime: Date, endDateTime: Date) {
        let calendarService = GTLRCalendarService()
        calendarService.authorizer = self.authorization
        calendarService.shouldFetchNextPages = true
        
        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
        query.timeMin = GTLRDateTime(date: startDateTime)
        query.timeMax = GTLRDateTime(date: endDateTime)
        
        calendarService.executeQuery(query, completionHandler: { (ticket, event, error) -> Void in
            if let error = error {
                NSLog("\(error)")
            } else {
                if let event = event as? GTLRCalendar_Events, let items = event.items {
                    for item in items {
                        let id: String = item.identifier ?? ""
                        let name: String = item.summary ?? ""
                        let startDate: Date? = item.start?.dateTime?.date
                        let endDate: Date? = item.end?.dateTime?.date
                        self.googleCalendarEventList.append(GoogleCalendaraEvent(id: id, name: name, startDate: startDate, endDate: endDate))
                    }
                }
                self.tableView.reloadData()
            }
        })
    }
    
    private func add(eventName: String, startDateTime: Date, endDateTime: Date) {
        
        if GTMAppAuthFetcherAuthorization(fromKeychainForName: "authorization") != nil {
            self.authorization = GTMAppAuthFetcherAuthorization(fromKeychainForName: "authorization")!
        }
        
        if self.authorization == nil {
            showAuthorizationDialog(callBack: {(error) -> Void in
                if error == nil {
                    self.addCalendarEvent(eventName: eventName, startDateTime: startDateTime, endDateTime: endDateTime)
                }
            })
        } else {
            self.addCalendarEvent(eventName: eventName, startDateTime: startDateTime, endDateTime: endDateTime)
        }
    }
    
    private func addCalendarEvent(eventName: String, startDateTime: Date, endDateTime: Date) {
        
        let calendarService = GTLRCalendarService()
        calendarService.authorizer = self.authorization
        calendarService.shouldFetchNextPages = true
        let event = GTLRCalendar_Event()
        event.summary = eventName
        
        let gtlrDateTimeStart: GTLRDateTime = GTLRDateTime(date: startDateTime)
        let startEventDateTime: GTLRCalendar_EventDateTime = GTLRCalendar_EventDateTime()
        startEventDateTime.dateTime = gtlrDateTimeStart
        event.start = startEventDateTime
        
        let gtlrDateTimeEnd: GTLRDateTime = GTLRDateTime(date: endDateTime)
        let endEventDateTime: GTLRCalendar_EventDateTime = GTLRCalendar_EventDateTime()
        endEventDateTime.dateTime = gtlrDateTimeEnd
        event.end = endEventDateTime

        let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: "primary")
        calendarService.executeQuery(query, completionHandler: { (ticket, event, error) -> Void in
            if let error = error {
                NSLog("\(error)")
            }
            self.getEvents()
        })
    }
    
    private func update(eventId: String, eventName: String, startDateTime: Date, endDateTime: Date) {
        
        if GTMAppAuthFetcherAuthorization(fromKeychainForName: "authorization") != nil {
            self.authorization = GTMAppAuthFetcherAuthorization(fromKeychainForName: "authorization")!
        }
        
        if self.authorization == nil {
            showAuthorizationDialog(callBack: {(error) -> Void in
                if error == nil {
                    self.updateCalendarEvent(eventId: eventId, eventName: eventName, startDateTime: startDateTime, endDateTime: endDateTime)
                }
            })
        } else {
            self.updateCalendarEvent(eventId: eventId, eventName: eventName, startDateTime: startDateTime, endDateTime: endDateTime)
        }
    }
    
    private func updateCalendarEvent(eventId: String, eventName: String, startDateTime: Date, endDateTime: Date) {
        let calendarService = GTLRCalendarService()
        calendarService.authorizer = self.authorization
        calendarService.shouldFetchNextPages = true
        let event = GTLRCalendar_Event()
        event.identifier = eventId
        event.summary = eventName
        
        let gtlrDateTimeStart: GTLRDateTime = GTLRDateTime(date: startDateTime)
        let startEventDateTime: GTLRCalendar_EventDateTime = GTLRCalendar_EventDateTime()
        startEventDateTime.dateTime = gtlrDateTimeStart
        event.start = startEventDateTime
        
        let gtlrDateTimeEnd: GTLRDateTime = GTLRDateTime(date: endDateTime)
        let endEventDateTime: GTLRCalendar_EventDateTime = GTLRCalendar_EventDateTime()
        endEventDateTime.dateTime = gtlrDateTimeEnd
        event.end = endEventDateTime

        let query = GTLRCalendarQuery_EventsUpdate.query(withObject: event, calendarId: "primary", eventId: eventId)
        calendarService.executeQuery(query, completionHandler: { (ticket, event, error) -> Void in
            if let error = error {
                NSLog("\(error)")
            }
            self.getEvents()
        })
    }
    
    private func delete(eventId: String) {
        
        if GTMAppAuthFetcherAuthorization(fromKeychainForName: "authorization") != nil {
            self.authorization = GTMAppAuthFetcherAuthorization(fromKeychainForName: "authorization")!
        }
        
        if self.authorization == nil {
            showAuthorizationDialog(callBack: {(error) -> Void in
                if error == nil {
                    self.deleteCalendarEvent(eventId: eventId)
                }
            })
        } else {
            self.deleteCalendarEvent(eventId: eventId)
        }
    }
    
    private func deleteCalendarEvent(eventId: String) {
        let calendarService = GTLRCalendarService()
        calendarService.authorizer = self.authorization
        calendarService.shouldFetchNextPages = true
        
        let query = GTLRCalendarQuery_EventsDelete.query(withCalendarId: "primary", eventId: eventId)
        calendarService.executeQuery(query, completionHandler: { (ticket, event, error) -> Void in
            if let error = error {
                NSLog("\(error)")
            }
            self.getEvents()
        })
    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return googleCalendarEventList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let tableViewCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath)
        tableViewCell.textLabel?.text = googleCalendarEventList[indexPath.row].name
        return tableViewCell
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndex = indexPath.row
    }
}

extension ViewController: DialogViewControllerDelegate {
    
    func touchUpOkButton(type: Type, googleCalendarEvent: GoogleCalendaraEvent) {
        self.hideDialogViewController()
        if type == Type.add {
            self.add(eventName: googleCalendarEvent.name, startDateTime: googleCalendarEvent.startDate!, endDateTime: googleCalendarEvent.endDate!)
        } else {
            self.update(eventId: googleCalendarEvent.id, eventName: googleCalendarEvent.name, startDateTime: googleCalendarEvent.startDate!, endDateTime: googleCalendarEvent.endDate!)
        }
    }
    
    func touchUpCancelButton() {
        self.hideDialogViewController()
    }
}

enum Type {
    case add
    case update
    case delete
}
