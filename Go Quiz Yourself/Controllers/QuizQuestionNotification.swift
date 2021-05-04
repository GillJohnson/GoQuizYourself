//
//  QuizQuestionNotification.swift
//  Go Quiz Yourself
//
//  Created by Gillian Johnson on 2021-03-30.
//

import UIKit
import SwiftyJSON

class QuizQuestionNotificationViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var quizTitleLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerTextField: UITextField!
    
    var question: [String] = []
    var questionLabelText = ""
    var quizTitleLabelText = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        questionLabel.text = questionLabelText
        quizTitleLabel.text = quizTitleLabelText
        
        self.answerTextField.delegate = self
        
        let backButton = UIBarButtonItem(title: "All Quizzes", style: .plain, target: self, action: #selector(back))
        backButton.tintColor = UIColor.systemOrange
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc func back(){
        navigationController?.popViewController(animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()  //if desired
        checkAnswer(answerTextField.text!)
        return true
    }
    
    @IBAction func submitButtonPressed(_ sender: UIButton) {
        checkAnswer(answerTextField.text!)
    }
    
    func checkAnswer(_ givenAnswer: String) {
        let correctAnswer = question[1]
        var result = "CORRECT!"
        let cancel = UIAlertAction(title: "Cancel", style: .default) { (action) in
            self.back()
        }
        
        if correctAnswer.lowercased() == givenAnswer.lowercased() {
            let alert = UIAlertController(title: result, message: nil, preferredStyle: .alert)
            alert.addAction(cancel)
            present(alert, animated: true, completion: nil)
        }
        else {
            result = "WRONG!"
            let alert = UIAlertController(title: result, message: nil, preferredStyle: .alert)
            let resubmit = UIAlertAction(title: "Resubmit", style: .default) { (action) in
                // Closes alert to allow for re-entering answer
            }
            alert.addAction(cancel)
            alert.addAction(resubmit)
            present(alert, animated: true, completion: nil)
        }
        
    }
    
}
