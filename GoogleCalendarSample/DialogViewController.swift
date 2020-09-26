//
//  DialogViewController.swift
//  GoogleCalendarSample
//
//  Created by NAOAKI SEKIGUCHI on 2020/09/26.
//

import UIKit

protocol DialogViewControllerDelegate: class {
    func touchUpOkButton(type: Type, googleCalendarEvent: GoogleCalendaraEvent)
    func touchUpCancelButton()
}

class DialogViewController: UIViewController {
    private let dialogView: UIView = UIView()
    private let nameLabel: UILabel = UILabel()
    private let nameText: UITextField = UITextField()
    private let startDateLabel: UILabel = UILabel()
    private let startDatePicker: UIDatePicker = UIDatePicker()
    private let endDateLabel: UILabel = UILabel()
    private let endDatePicker: UIDatePicker = UIDatePicker()
    private let okButton: UIButton = UIButton()
    private let cancelButton: UIButton = UIButton()
    
    var type: Type = Type.add
    var googleCalendarEvent: GoogleCalendaraEvent?
    weak var delegate: DialogViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.init(displayP3Red: 0, green: 0, blue: 0, alpha: 0.5)
        
        dialogView.backgroundColor = UIColor.white
        self.view.addSubview(dialogView)
        
        nameLabel.text = "Event Name"
        dialogView.addSubview(nameLabel)
        
        nameText.layer.cornerRadius = 6
        nameText.layer.borderWidth = 1
        nameText.layer.borderColor = UIColor.gray.cgColor
        dialogView.addSubview(nameText)
        
        startDateLabel.text = "Start Date"
        dialogView.addSubview(startDateLabel)
        
        startDatePicker.layer.cornerRadius = 6
        startDatePicker.layer.borderWidth = 1
        startDatePicker.layer.borderColor = UIColor.gray.cgColor
        startDatePicker.preferredDatePickerStyle = .wheels
        dialogView.addSubview(startDatePicker)
        
        endDateLabel.text = "End Date"
        dialogView.addSubview(endDateLabel)
        
        endDatePicker.layer.cornerRadius = 6
        endDatePicker.layer.borderWidth = 1
        endDatePicker.layer.borderColor = UIColor.gray.cgColor
        endDatePicker.preferredDatePickerStyle = .wheels
        dialogView.addSubview(endDatePicker)
        
        okButton.setTitle("OK", for: .normal)
        okButton.addTarget(self, action: #selector(self.touchUpOkButton(_:)), for: .touchUpInside)
        okButton.setTitleColor(UIColor.black, for: .normal)
        dialogView.addSubview(okButton)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(self.touchUpButtonCancel(_:)), for: .touchUpInside)
        cancelButton.setTitleColor(UIColor.black, for: .normal)
        dialogView.addSubview(cancelButton)
        
        if let googleCalendarEvent = self.googleCalendarEvent {
            nameText.text = googleCalendarEvent.name
            startDatePicker.date = googleCalendarEvent.startDate ?? Date()
            endDatePicker.date = googleCalendarEvent.endDate ?? Date()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.changeScreen()
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
        let width = self.view.frame.width
        let height = self.view.frame.height
        let dialogWidth = width * 0.8
        let dialogHeight = height * 0.8
        
        dialogView.frame = CGRect(x: width * 0.1 , y: height * 0.1, width: dialogWidth, height: dialogHeight)
        
        nameLabel.frame = CGRect(x: 10, y: 10, width: dialogWidth - 20, height: 20)
        nameText.frame = CGRect(x: 10, y: 30, width: dialogWidth - 20, height: 40)
        startDateLabel.frame = CGRect(x: 10, y: 70, width: dialogWidth - 20, height: 20)
        startDatePicker.frame = CGRect(x: 10, y: 90, width: dialogWidth - 20, height: 60)
        endDateLabel.frame = CGRect(x: 10, y: 150, width: dialogWidth - 20, height: 20)
        endDatePicker.frame = CGRect(x: 10, y: 170, width: dialogWidth - 20, height: 60)
        okButton.frame = CGRect(x: 10, y: dialogHeight - 50, width: dialogWidth / 3, height: 44)
        cancelButton.frame = CGRect(x: dialogWidth - 10 - dialogWidth / 3, y: dialogHeight - 50, width: dialogWidth / 3, height: 44)
        
    }
    
    @objc private func touchUpOkButton(_ sender: UIButton) {
        if let delegate = delegate {
            var id: String = ""
            if type == Type.update {
                id = googleCalendarEvent!.id
            }
            delegate.touchUpOkButton(type: type, googleCalendarEvent: GoogleCalendaraEvent(id: id, name: nameText.text!, startDate: startDatePicker.date, endDate: endDatePicker.date))
        }
    }
    
    @objc private func touchUpButtonCancel(_ sender: UIButton) {
        if let delegate = delegate {
            delegate.touchUpCancelButton()
        }
    }
}
