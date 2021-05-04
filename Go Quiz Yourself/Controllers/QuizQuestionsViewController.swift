//
//  QuizQuestionViewController.swift
//  Go Quiz Yourself
//
//  Created by Gillian Johnson on 2021-03-09.
//

import UIKit
import Firebase
import SwiftyJSON
import SwipeCellKit
import AppCenterAnalytics

class QuizQuestionsViewController: UITableViewController {

    var quizzes: [JSON] = []
    var currentQuizIndex: Int = 0
    var questions: [JSON] = []
    
    var qVC = QuizzesViewController()
    var questionExists = false
    var answerExists = false
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 80.0
        let questionListCell = UINib(nibName: "QuestionTableViewCell", bundle: nil)
        tableView.register(questionListCell, forCellReuseIdentifier: "QuestionListCell")
        
        let backButton = UIBarButtonItem(title: "All Quizzes", style: .plain, target: self, action: #selector(back))
        backButton.tintColor = UIColor.systemOrange
        navigationItem.leftBarButtonItem = backButton
        
        loadQuestions()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            qVC.loadQuizzes()
        }
    }
    
    @objc func back(){
        navigationController?.popViewController(animated: true)
    }
    
    
    //MARK: - TableView Datasource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let question = questions[indexPath.row]
        
        if let cell = self.tableView.dequeueReusableCell(withIdentifier: "QuestionListCell") as? QuestionTableViewCell {
            cell.delegate = self
            cell.index = indexPath.row
            cell.qqVC = self
            if let q = question["q"].string, let a = question["a"].string {
                cell.questionLabel.text = q
                cell.answerLabel.text = a
            }
            else {
                cell.questionLabel.text = ""
                cell.answerLabel.text = ""
            }
            return cell
        }
        
        return UITableViewCell()
    }
    
    
    //MARK: - Add New Questions
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var questionTextField = UITextField()
        var answerTextField = UITextField()
        
        let alert = UIAlertController(title: "Add New Question", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
                            
            // ADD QUESTION AND ANSWER TO DATABASE
            if let question = questionTextField.text, let answer = answerTextField.text, let uid = Auth.auth().currentUser?.uid {

                // Sets user data
                let newQuestion = JSON(["q": question, "a": answer, "dateCreated": Date().timeIntervalSince1970])

                
                // HANDLE QUESTION
                var questionsObject = self.questions
                questionsObject.insert(newQuestion, at: 0)

                var questions: [String] = []
                for questionObject in questionsObject {
                    if let string = questionObject.rawString() {
                        questions.append(string)
                    }
                }
                
                let questionJSON: JSON = JSON(questionsObject)
                
                // HANDLE QUIZZES
                var updatedQuiz = self.quizzes[self.currentQuizIndex]
                updatedQuiz["questions"] = questionJSON
                self.quizzes.remove(at: self.currentQuizIndex)
                var quizzesObject = self.quizzes
                quizzesObject.insert(updatedQuiz, at: 0)
                
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
                        Analytics.trackEvent(e.localizedDescription, withProperties: ["Location" : "Quiz Questions - Adding New Question"])
                        let alert = UIAlertController(title: "Error: Cannot add question", message: "", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Close", style: .default) { (action) in
                            return
                        }
                        
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                    else {
                        self.quizzes.insert(updatedQuiz, at: 0)
                        self.questions.insert(newQuestion, at: 0)
                        self.questions = self.qVC.sortQuizzesByDate(self.questions)
                        self.currentQuizIndex = 0
                        self.tableView.reloadData()
                    }
                }
            }

        }
        action.isEnabled = false; //to make it disable while presenting
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            return
        }
        
        alert.addAction(cancelAction)
        alert.addAction(action)
        
        alert.addTextField { (field) in
            questionTextField = field
            questionTextField.placeholder = "Add Question"
            questionTextField.keyboardType = .numberPad
            questionTextField.addTarget(self, action: #selector(self.alertQuestionTextFieldDidChange(field:)), for: UIControl.Event.editingChanged)
        }
        alert.addTextField { (field) in
            answerTextField = field
            answerTextField.placeholder = "Add Answer"
            answerTextField.keyboardType = .numberPad
            answerTextField.addTarget(self, action: #selector(self.alertAnswerTextFieldDidChange(field:)), for: UIControl.Event.editingChanged)
        }
        present(alert, animated: true, completion: nil)
    }
    
    @objc func alertQuestionTextFieldDidChange(field: UITextField){
        let alertController:UIAlertController = self.presentedViewController as! UIAlertController;
        let textField :UITextField  = alertController.textFields![0];
        let addAction: UIAlertAction = alertController.actions[1];
        self.answerExists = (textField.text) != "";
        addAction.isEnabled = self.answerExists && self.questionExists
    }
    
    @objc func alertAnswerTextFieldDidChange(field: UITextField){
        let alertController:UIAlertController = self.presentedViewController as! UIAlertController;
        let textField :UITextField  = alertController.textFields![1];
        let addAction: UIAlertAction = alertController.actions[1];
        self.questionExists = (textField.text) != "";
        addAction.isEnabled = self.answerExists && self.questionExists
    }
    
    
    //MARK: - Retrieve User Quiz Questions
    
    func loadQuestions() {
        
        // Retrieves user data
        let uid = Auth.auth().currentUser?.uid
        let DocRefernce:DocumentReference!
        DocRefernce = db.collection("users").document(uid!)
        DocRefernce.getDocument { (docSnapshot, error) in
            self.quizzes = []
            self.questions = []
            
            if let e = error {
                Analytics.trackEvent(e.localizedDescription, withProperties: ["Location" : "Quiz Questions - Loading Questions"])
                let alert = UIAlertController(title: "Error: Cannot load questions", message: "", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Close", style: .default) { (action) in
                    return
                }
                
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            } else {
                guard let snapshot = docSnapshot, snapshot.exists else { return }
                guard let data = snapshot.data() else { return }
                if let quizzes = data["quizzes"] as? [String] {
                    // Set Quizzes
                    var quizArray: [JSON] = []
                    for quiz in quizzes {
                        let data = JSON.init(parseJSON: quiz)
                        quizArray.append(data)
                    }
                    quizArray = self.qVC.sortQuizzesByDate(quizArray)
                    self.quizzes = quizArray
                    
                    // Set Questions
                    var questionsArray: [JSON] = []
                    let currentQuiz = self.quizzes[self.currentQuizIndex]
                    for question in currentQuiz["questions"] {
                        questionsArray.append(question.1)
                    }
                    self.questions = self.qVC.sortQuizzesByDate(questionsArray)
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    
    //MARK: - Delete Quiz Question
    
    func deleteCell(_ questionIndex: Int) {
        if let uid = Auth.auth().currentUser?.uid {
            
            // HANDLE QUESTIONS
            var questionsObject = self.questions
            questionsObject.remove(at: questionIndex)

            var questions: [String] = []
            for questionObject in questionsObject {
                if let string = questionObject.rawString() {
                    questions.append(string)
                }
            }
            let questionJSON: JSON = JSON(questionsObject)
            
            // HANDLE QUIZZES
            var updatedQuiz = quizzes[currentQuizIndex]
            updatedQuiz["questions"] = questionJSON
            updatedQuiz["dateCreated"] = JSON(Date().timeIntervalSince1970)

            var updatedQuizzes = self.quizzes
            updatedQuizzes.remove(at: currentQuizIndex)
            updatedQuizzes.insert(updatedQuiz, at: 0)
            
            var quizzes: [String] = []
            for quizObject in updatedQuizzes {
                if let string = quizObject.rawString() {
                    quizzes.append(string)
                }
            }
            
            self.db.collection("users").document(uid).updateData([
                "quizzes": quizzes
            ]) { (error) in
                if let e = error {
                    Analytics.trackEvent(e.localizedDescription, withProperties: ["Location" : "Quiz Questions - Deleting Question"])
                    let alert = UIAlertController(title: "Error: Cannot delete question", message: "", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Close", style: .default) { (action) in
                        return
                    }
                    
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    self.quizzes.remove(at: self.currentQuizIndex)
                    self.quizzes.insert(updatedQuiz, at: 0)
                    self.questions.remove(at: questionIndex)
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    
    //MARK: - Edit Question
    
    @IBAction func editButtonPressed(_ sender: UIButton) {

        var superview = sender.superview
        while let view = superview, !(view is UITableViewCell) {
            superview = view.superview
        }
        guard let cell = superview as? UITableViewCell else {
            Analytics.trackEvent("Button is not contained in a table view cell", withProperties: ["Location" : "Quiz Questions - Editing Question"])
            return
        }
        guard let indexPath = tableView.indexPath(for: cell) else {
            Analytics.trackEvent("Failed to get index path for cell containing button", withProperties: ["Location" : "Quiz Questions - Editing Question"])
            return
        }

        let question = self.questions[indexPath.row]
        
        var questionTextField = UITextField()
        var answerTextField = UITextField()
        
        let alert = UIAlertController(title: "Edit Question", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Done", style: .default) { (action) in
            
            if let question = questionTextField.text, let answer = answerTextField.text, let uid = Auth.auth().currentUser?.uid {
                
                self.deleteCell(indexPath.row)
                
                // Sets user data
                let newQuestion = JSON(["q": question, "a": answer, "dateCreated": Date().timeIntervalSince1970])

                
                // HANDLE QUESTION
                var questionsObject = self.questions
                questionsObject.append(newQuestion)
                

                var questions: [String] = []
                for questionObject in questionsObject {
                    if let string = questionObject.rawString() {
                        questions.append(string)
                    }
                }
                
                let questionJSON: JSON = JSON(questionsObject)
                
                // HANDLE QUIZZES
                var updatedQuiz = self.quizzes[self.currentQuizIndex]
                updatedQuiz["questions"] = questionJSON
                
                var quizzes: [String] = []
                for quizObject in self.quizzes {
                    if let string = quizObject.rawString() {
                        quizzes.append(string)
                    }
                }
                
                self.db.collection("users").document(uid).updateData([
                    "quizzes": quizzes
                ]) { (error) in
                    if let e = error {
                        Analytics.trackEvent(e.localizedDescription, withProperties: ["Location" : "Quiz Questions - Editing Question"])
                        let alert = UIAlertController(title: "Error: Cannot save edited question", message: "", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Close", style: .default) { (action) in
                            return
                        }
                        
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                    else {
                        self.questions.insert(newQuestion, at: 0)
                        self.quizzes.remove(at: self.currentQuizIndex)
                        self.quizzes.insert(updatedQuiz, at: 0)
                        self.questions = self.qVC.sortQuizzesByDate(self.questions)
                        self.tableView.reloadData()
                    }
                }
            }
        }
        
        alert.addAction(action)
        
        alert.addTextField { (field) in
            questionTextField = field
            questionTextField.text = question["q"].string!
            questionTextField.placeholder = "Edit Question"
        }
        alert.addTextField { (field) in
            answerTextField = field
            answerTextField.text = question["a"].string!
            answerTextField.placeholder = "Edit Answer"
        }
        present(alert, animated: true, completion: nil)
    }
    
}


//MARK: - Swipe Cell Delegate Methods

extension QuizQuestionsViewController: SwipeTableViewCellDelegate {
    
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
    
}

//MARK: - Search Bar Methods

extension QuizQuestionsViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
            let filteredArray = questions.filter({ (q) -> Bool in
                return q["q"].stringValue.lowercased().contains(searchBar.text!.lowercased());})
            self.questions = filteredArray
            
            self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text?.count == 0 {
            loadQuestions()
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }

}
