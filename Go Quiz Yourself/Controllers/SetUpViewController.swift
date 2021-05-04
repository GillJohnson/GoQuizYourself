//
//  SetUpViewController.swift
//  Go Quiz Yourself
//
//  Created by Gillian Johnson on 2021-03-18.
//

import UIKit
import Firebase
import SwiftyJSON
import AppCenterAnalytics

class SetUpViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var startTextField: UITextField!
    @IBOutlet weak var endTextField: UITextField!
    @IBOutlet weak var numberOfQuestionsPicker: UIPickerView!
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var beginButton: UIButton!
    
    var startTimePicker = UIDatePicker()
    var endTimePicker = UIDatePicker()
    
    var numberOfQuestionsPickerData: [Int] = [Int]()
    
    var numberOfQuestionsSelected: Int = 1
    
    var isStartTimeSet = false
    var isEndTimeSet = false
    
    var qVC = QuizzesViewController()
    var quizzes: [JSON] = []
    var currentQuizIndex: Int = 0
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.numberOfQuestionsPicker.delegate = self
        self.numberOfQuestionsPicker.dataSource = self
        
        numberOfQuestionsPickerData = Array(1...50)
                        
        createDatePicker(startTimePicker, startTextField, "start")
        createDatePicker(endTimePicker, endTextField, "end")
        
        numberOfQuestionsPicker.selectRow(9, inComponent: 0, animated: true)
        numberOfQuestionsSelected = numberOfQuestionsPickerData[9]
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
        cancelButton.tintColor = UIColor.systemOrange
        navigationItem.leftBarButtonItem = cancelButton
        
        beginButton.isEnabled = false
        checkButtonEnabled()
    }

    @objc func cancel(){
        navigationController?.popViewController(animated: true)
    }
    
    func createStartToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(startDoneButtonPressed))
        toolbar.setItems([doneButton], animated: true)
        
        return toolbar
    }
    
    func createEndToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(endDoneButtonPressed))
        toolbar.setItems([doneButton], animated: true)
        
        return toolbar
    }
    
    func createDatePicker(_ picker: UIDatePicker, _ textField: UITextField, _ timeType: String) {
        picker.preferredDatePickerStyle = .wheels
        
        textField.textAlignment = .center
        if timeType == "start" {
            textField.inputView = startTimePicker
            textField.inputAccessoryView = createStartToolbar()
        }
        else {
            textField.inputView = endTimePicker
            textField.inputAccessoryView = createEndToolbar()
        }
    }
    
    @objc func startDoneButtonPressed() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.dateFormat = "MMM dd, yyyy HH:mm:ss"
        self.startTextField.text = dateFormatter.string(from: startTimePicker.date)
        self.view.endEditing(true)
        
        isStartTimeSet = true
        checkButtonEnabled()
    }
    
    @objc func endDoneButtonPressed() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.dateFormat = "MMM dd, yyyy HH:mm:ss"

        self.endTextField.text = dateFormatter.string(from: endTimePicker.date)
        self.view.endEditing(true)
        
        isEndTimeSet = true
        checkButtonEnabled()
    }
    
    func checkButtonEnabled() {
        if isStartTimeSet && isEndTimeSet && (startTimePicker.date < endTimePicker.date) {
            beginButton.isEnabled = true
            beginButton.backgroundColor = .black
        }
        else {
            beginButton.isEnabled = false
            beginButton.backgroundColor = .gray
        }
    }
    
    @IBAction func beginButtonPressed(_ sender: UIButton) {

        if let uid = Auth.auth().currentUser?.uid {

            let currentQuiz = qVC.quizArray[qVC.currentQuizIndex]
            
            // HANDLE NOTIFICATIONS
            let notifications = qVC.setUpNotificationTimes(startTextField.text!, endTextField.text!, numberOfQuestionsSelected)

            // Sets user data
            let newQuiz = JSON([
                "title": currentQuiz["title"].string!,
                "dateCreated": Date().timeIntervalSince1970,
                "questions": currentQuiz["questions"],
                "startTime": startTextField.text!,
                "endTime": endTextField.text!,
                "notifications": notifications
            ])

            // HANDLE QUIZZES
            var quizzesObject = qVC.quizArray
            quizzesObject.remove(at: qVC.currentQuizIndex)
            quizzesObject.insert(newQuiz, at: 0)

            var quizzes: [String] = []
            for quizObject in quizzesObject {
                if let string = quizObject.rawString() {
                    quizzes.append(string)
                }
            }

            self.db.collection("users").document(uid).updateData([
                "quizzes": quizzes
            ]) { (error) in
                if let e = error {
                    Analytics.trackEvent(e.localizedDescription, withProperties: ["Location" : "Set Up Quiz - Starting Quiz"])
                    let alert = UIAlertController(title: "Error: Cannot begin quiz", message: "", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Close", style: .default) { (action) in
                        return
                    }
                    
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    self.qVC.quizArray.remove(at: self.qVC.currentQuizIndex)
                    self.qVC.quizArray.insert(newQuiz, at: 0)
                }
            }
            
        }
        qVC.quizArray = qVC.sortQuizzesByDate(qVC.quizArray)
        qVC.tableView.reloadData()
        
        navigationController?.popViewController(animated: true)
    }
    
    
// MARK: - PickerView Methods
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return numberOfQuestionsPickerData.count
    }
    
    internal func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(numberOfQuestionsPickerData[row])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        numberOfQuestionsSelected = numberOfQuestionsPickerData[row]
    }
}
