//
//  LoadingViewController.swift
//  Go Quiz Yourself
//
//  Created by Gillian Johnson on 2021-04-26.
//

import UIKit
import Firebase

class LoadingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Auth.auth().currentUser != nil {
            performSegue(withIdentifier: Constants.loadingQuizzesSegue, sender: nil)
        }
        else {
            performSegue(withIdentifier: Constants.loadingWelcomeSegue, sender: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil {
            performSegue(withIdentifier: Constants.loadingQuizzesSegue, sender: nil)
        }
        else {
            performSegue(withIdentifier: Constants.loadingWelcomeSegue, sender: nil)
        }
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }
}

