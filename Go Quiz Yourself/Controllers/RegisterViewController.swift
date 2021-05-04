//
//  RegisterViewController.swift
//  Go Quiz Yourself
//
//  Created by Gillian Johnson on 2021-03-05.
//

import UIKit
import Firebase
import AppCenterAnalytics

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(back))
        backButton.tintColor = UIColor.systemOrange
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc func back(){
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func registerPressed(_ sender: UIButton) {
        
        if let email = emailTextField.text, let password = passwordTextField.text {

            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let e = error {
                    // HANDLE ERROR
                    Analytics.trackEvent(e.localizedDescription, withProperties: ["Location" : "Register - Creating User"])
                    let alert = UIAlertController(title: "Error: Cannot register user", message: e.localizedDescription, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Close", style: .default) { (action) in
                        return
                    }
                    
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    // Navigate to the QuizzesViewController
                    self.performSegue(withIdentifier: Constants.registerSegue, sender: self)
                    if let newUserId = authResult?.user.uid {
                        self.db.collection("users").document(newUserId).setData([
                            "quizzes": []
                        ]) { error in
                            if let e = error {
                                Analytics.trackEvent(e.localizedDescription, withProperties: ["Location" : "Register - Saving New User"])
                                let alert = UIAlertController(title: "Error: Cannot save new user", message: e.localizedDescription, preferredStyle: .alert)
                                let cancelAction = UIAlertAction(title: "Close", style: .default) { (action) in
                                    return
                                }
                                
                                alert.addAction(cancelAction)
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    
}
