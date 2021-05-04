//
//  LoginViewController.swift
//  Go Quiz Yourself
//
//  Created by Gillian Johnson on 2021-03-05.
//

import UIKit
import Firebase
import AppCenterAnalytics

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(back))
        backButton.tintColor = UIColor.systemOrange
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc func back(){
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func loginPressed(_ sender: UIButton) {
        
        if let email = emailTextField.text, let password = passwordTextField.text {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let e = error {
                    Analytics.trackEvent(e.localizedDescription, withProperties: ["Location" : "Login - Signing In User"])
                    let alert = UIAlertController(title: "Error: Cannot login user", message: e.localizedDescription, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Close", style: .default) { (action) in
                        return
                    }
                    
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    // Navigate to QuizzesViewController
                    self.performSegue(withIdentifier: Constants.loginSegue, sender: self)
                }
            }
        }
        
    }
}
