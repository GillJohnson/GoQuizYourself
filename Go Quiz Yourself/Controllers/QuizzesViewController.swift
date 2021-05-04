//
//  QuizzesViewController.swift
//  Go Quiz Yourself
//
//  Created by Gillian Johnson on 2021-03-05.
//

import UIKit
import Firebase
import SwiftyJSON
import SwipeCellKit
import UserNotifications
import AppCenterAnalytics


class QuizzesViewController: UITableViewController, UISearchBarDelegate {
        
    @IBOutlet weak var searchBar: UISearchBar!
    var quizArray: [JSON] = []
    var currentQuizIndex: Int = 0
        
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        
        let quizListCell = UINib(nibName: "QuizTableViewCell", bundle: nil)
        self.tableView.register(quizListCell, forCellReuseIdentifier: "QuizListCell")
        
        // Removes back bottom from navigation bar
        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        self.tableView.rowHeight = 80.0
        self.tableView.allowsSelectionDuringEditing = true;
        self.tableView.clipsToBounds = true
        
        loadQuizzes()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
        super.viewDidAppear(animated)
    }
    
    
    //MARK: - TableView Datasource Methods
    
    // creates cells in tableview
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quizArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let quiz = quizArray[indexPath.row]
        
        if let cell = self.tableView.dequeueReusableCell(withIdentifier: "QuizListCell") as? QuizTableViewCell {
            cell.delegate = self
            cell.textLabel?.text = quiz["title"].string
            cell.qVC = self
            cell.index = indexPath.row
            cell.isUserInteractionEnabled = true
            return cell
        }
        
        return UITableViewCell()
    }
    
    
    //MARK: - TableView Delegate Methods
    
    // function called when cell is selected
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        currentQuizIndex = indexPath.row
        performSegue(withIdentifier: Constants.questionSegue, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == Constants.questionSegue) {
            let vc = segue.destination as! QuizQuestionsViewController
            vc.quizzes = quizArray
            vc.currentQuizIndex = currentQuizIndex
            vc.qVC = self
        }
        else if (segue.identifier == Constants.setUpSegue) {
            let vc = segue.destination as! SetUpViewController
            vc.quizzes = quizArray
            vc.currentQuizIndex = currentQuizIndex
            vc.qVC = self
        }
    }
    
    
    //MARK: - Add New Quiz
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Quiz", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Quiz", style: .default) { (action) in
                
            // ADD QUIZ TO DATABASE
            if let quizTitle = textField.text, let uid = Auth.auth().currentUser?.uid {
                    
                // Sets user data
                let newQuiz = JSON(["title": quizTitle, "dateCreated": Date().timeIntervalSince1970])
                
                var quizzesObject = self.quizArray
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
                        Analytics.trackEvent(e.localizedDescription, withProperties: ["Location" : "All Quizzes - Adding New Quiz"])
                        let alert = UIAlertController(title: "Error: Cannot save new quiz", message: "", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Close", style: .default) { (action) in
                            return
                        }
                        
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                    else {
                        self.quizArray.insert(newQuiz, at: 0)
                        self.quizArray = self.sortQuizzesByDate(self.quizArray)
                        self.tableView.reloadData()
                    }
                }
            }
        }
        action.isEnabled = false //to make it disabled while presenting

        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Quiz Title"
            textField = alertTextField
            textField.keyboardType = .numberPad
            textField.addTarget(self, action: #selector(self.alertTitleTextFieldDidChange(field:)), for: UIControl.Event.editingChanged)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            return
        }
        
        alert.addAction(cancelAction)
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func alertTitleTextFieldDidChange(field: UITextField){
        let alertController:UIAlertController = self.presentedViewController as! UIAlertController
        let textField :UITextField  = alertController.textFields![0]
        let addAction: UIAlertAction = alertController.actions[1]
        addAction.isEnabled = (textField.text) != ""
    }
    
    //MARK: - Retrieve User Quizzes
    
    func loadQuizzes() {
        // Retrieves user data
        let uid = Auth.auth().currentUser?.uid
        let DocRefernce:DocumentReference!
        DocRefernce = db.collection("users").document(uid!)
        DocRefernce.getDocument { (docSnapshot, error) in
            self.quizArray = []
            
            if let e = error {
                Analytics.trackEvent(e.localizedDescription, withProperties: ["Location" : "All Quizzes - Loading Quizzes"])
                let alert = UIAlertController(title: "Error: Cannot load quizzes", message: "", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Close", style: .default) { (action) in
                    return
                }
                
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            } else {
                guard let snapshot = docSnapshot, snapshot.exists else { return }
                guard let data = snapshot.data() else { return }
                if let quizzes = data["quizzes"] as? [String] {
                    var array: [JSON] = []
                    for quiz in quizzes {
                        let data = JSON.init(parseJSON: quiz)
                        array.append(data)
                    }
                    self.quizArray = self.sortQuizzesByDate(array)
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    
    //MARK: - Log Out User
    
    @IBAction func logOutPressed(_ sender: Any) {

        do {
            try Auth.auth().signOut()

            // Navigates back to welcome screen
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            Analytics.trackEvent(signOutError.localizedDescription, withProperties: ["Location" : "All Quizzes - Signing Out User"])
            let alert = UIAlertController(title: "Error: Cannot log out user", message: "", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Close", style: .default) { (action) in
                return
            }
            
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
       }
    }
    
    
    //MARK: - Delete Quiz
    
    func deleteCell(_ quizIndex: Int) {
        if let uid = Auth.auth().currentUser?.uid {
            
            // HANDLE QUIZZES
            var updatedQuizArray = self.quizArray
            updatedQuizArray.remove(at: quizIndex)

            var quizzes: [String] = []
            for quizObject in updatedQuizArray {
                if let string = quizObject.rawString() {
                    quizzes.append(string)
                }
            }
            
            self.db.collection("users").document(uid).updateData([
                "quizzes": quizzes
            ]) { (error) in
                if let e = error {
                    Analytics.trackEvent(e.localizedDescription, withProperties: ["Location" : "All Quizzes - Deleting Quiz"])
                    let alert = UIAlertController(title: "Error: Cannot delete quiz", message: "", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Close", style: .default) { (action) in
                        return
                    }
                    
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    self.quizArray.remove(at: quizIndex)
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Quiz Cell Methods
    
    func setUpButtonPressed(_ sender: UIButton) {
        var superview = sender.superview
        while let view = superview, !(view is UITableViewCell) {
            superview = view.superview
        }
        guard let cell = superview as? UITableViewCell else {
            Analytics.trackEvent("Button is not contained in a table view cell", withProperties: ["Location" : "All Quizzes - Setting Up Quiz"])
            return
        }
        guard let indexPath = tableView.indexPath(for: cell) else {
            Analytics.trackEvent("Failed to get index path for cell containing button", withProperties: ["Location" : "All Quizzes - Setting Up Quiz"])
            return
        }
        
        currentQuizIndex = indexPath.row
        performSegue(withIdentifier: Constants.setUpSegue, sender: self)
    }
    
    func stopButtonPressed(_ sender: UIButton) {
        
        // RETRIEVE QUIZ INDEX
        var superview = sender.superview
        while let view = superview, !(view is UITableViewCell) {
            superview = view.superview
        }
        guard let cell = superview as? UITableViewCell else {
            Analytics.trackEvent("Button is not contained in a table view cell", withProperties: ["Location" : "All Quizzes - Stopping Quiz"])
            return
        }
        guard let indexPath = tableView.indexPath(for: cell) else {
            Analytics.trackEvent("Failed to get index path for cell containing button", withProperties: ["Location" : "All Quizzes - Stopping Quiz"])
            return
        }
        
        currentQuizIndex = indexPath.row
        
        // END QUIZZES
        let alert = UIAlertController(title: self.quizArray[currentQuizIndex]["title"].string, message: "Are you sure you want to stop this quiz?", preferredStyle: .alert)
        
        let continueAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            // Do nothing as quiz continues
        }
        let endAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // Handle stop quizzing
            if let uid = Auth.auth().currentUser?.uid {

                let currentQuiz = self.quizArray[self.currentQuizIndex]

                // Sets user data
                let newQuiz = JSON([
                    "title": currentQuiz["title"].string!,
                    "dateCreated": Date().timeIntervalSince1970,
                    "questions": currentQuiz["questions"]
                ])

                // HANDLE QUIZZES
                self.quizArray.remove(at: self.currentQuizIndex)
                var quizzesObject = self.quizArray
                quizzesObject.append(newQuiz)
                self.quizArray.append(newQuiz)

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
                        Analytics.trackEvent(e.localizedDescription, withProperties: ["Location" : "All Quizzes - Stopping Quiz"])
                        let alert = UIAlertController(title: "Error: Cannot stop quiz", message: "", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Close", style: .default) { (action) in
                            return
                        }
                        
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                    else {
                        // STOP NOTIFICATION TIMES
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    }
                }
            }
            self.quizArray = self.sortQuizzesByDate(self.quizArray)
            self.tableView.reloadData()
        }
        
        alert.addAction(continueAction)
        alert.addAction(endAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func sortQuizzesByDate(_ array: [JSON]) -> [JSON] {
        return array.sorted { (quiz1, quiz2) -> Bool in
            if quiz1["dateCreated"] > quiz2["dateCreated"] {
                return true
            }
            return false
        }
    }
    
    func randomDate(_ start: Date, _ end: Date) -> Date {
        let timeDifference = end - start
        let randomTimeAmount = Double.random(in: 0...1) * timeDifference
        let randomDate = start + randomTimeAmount
        return randomDate
    }
    
    func randomQuestion() -> [String] {
        let numberOfQuestions = quizArray[currentQuizIndex]["questions"].count - 1
        let randomIndex = Int.random(in: 0...numberOfQuestions)
        let randomQ = quizArray[currentQuizIndex]["questions"][randomIndex]["q"].string!
        let randomA = quizArray[currentQuizIndex]["questions"][randomIndex]["a"].string!
        let randomQuestion = [randomQ, randomA]
        return randomQuestion
    }
    
    func setUpNotificationTimes(_ startTime: String, _ endTime: String, _ numberOfNotifications: Int) -> [[String]] {
        var notificationTimes: [[String]] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy HH:mm:ss"
        let startDate = dateFormatter.date(from: startTime)
        let endDate = dateFormatter.date(from: endTime)
        
        if numberOfNotifications >= 1 {
            for _ in 1...numberOfNotifications {
                let randomDate = self.randomDate(startDate!, endDate!)
                let stringTime = dateFormatter.string(from: randomDate)
                var randomQuestion = self.randomQuestion()
                randomQuestion.append(stringTime)
                if !notificationTimes.contains(randomQuestion) {
                    notificationTimes.append(randomQuestion)
                                        
                    // SET UP NOTIFICATIONS ON IPHONE
                    let content = UNMutableNotificationContent()
                    content.title = "\(randomQuestion[0])?".capitalized
                    content.body = "Click to submit your answer"
                    content.sound = UNNotificationSound.default
                    content.userInfo = ["question": randomQuestion, "quizTitle": self.quizArray[self.currentQuizIndex]["title"].string!]
                    
                    let triggerDaily = Calendar.current.dateComponents([.hour,.minute,.second,], from: randomDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDaily, repeats: false)
                                  
                    
                    let request = UNNotificationRequest(identifier: "question-\(randomDate)", content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
            }
            
        }
        return notificationTimes
    }
    
    
    //MARK: - Search Bar Methods

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let filteredArray = quizArray.filter({ (q) -> Bool in
            return q["title"].stringValue.lowercased().contains(searchBar.text!.lowercased());})
        self.quizArray = filteredArray
        
        self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadQuizzes()
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
    
}


//MARK: - Swipe Cell Delegate Methods

extension QuizzesViewController: SwipeTableViewCellDelegate {
    
    // handles what happens when user swipes a cell
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }

        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            // handle action by updating model with deletion
            self.deleteCell(indexPath.row)
        }

        // customize the action appearance
        deleteAction.image = UIImage(named: "delete-icon")

        return [deleteAction]
    }
    
//    // changes style to swipe full cell row
//    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
//        var options = SwipeOptions()
//        options.expansionStyle = .destructive
//        return options
//    }
    
}

extension Date {

    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }

}


