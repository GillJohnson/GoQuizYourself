//
//  QuizTableViewCell.swift
//  Go Quiz Yourself
//
//  Created by Gillian Johnson on 2021-03-19.
//

import UIKit
import SwiftyJSON
import SwipeCellKit

class QuizTableViewCell: SwipeTableViewCell {

    @IBOutlet weak var quizTitle: UILabel!
    @IBOutlet weak var setUpButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var addQuestionLabel: UILabel!
    
    var qVC = QuizzesViewController()
    
    var index: Int = 0
    var notificationsExist = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateNotifications()
        
        if qVC.quizArray[index]["questions"].exists() && !qVC.quizArray[index]["questions"].isEmpty {
            if qVC.quizArray[index]["startTime"].exists() && notificationsExist {
                setUpButton.isHidden = true
                addQuestionLabel.isHidden = true
                stopButton.isHidden = false
            }
            else {
                setUpButton.isHidden = false
                addQuestionLabel.isHidden = true
                stopButton.isHidden = true
            }
        }
        else {
            setUpButton.isHidden = true
            addQuestionLabel.isHidden = false
            stopButton.isHidden = true
        }
     }
    
    @IBAction func setUpButtonPressed(_ sender: UIButton) {
        qVC.setUpButtonPressed(sender)
    }
    
    @IBAction func stopButtonPressed(_ sender: UIButton) {
        qVC.stopButtonPressed(sender)
    }
    
    func findLastNotification() -> Date {
        let notifications = qVC.quizArray[index]["notifications"]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy HH:mm:ss"
        let lastNotification = notifications[0][2].string
        var lastNotificationDate = dateFormatter.date(from: lastNotification!)!
        
        if notifications.count >= 2 {
            for i in 1..<notifications.count {
                let currentNotificationDate = notifications[i][2].string
                let date = dateFormatter.date(from: currentNotificationDate!)!
                
                if date > lastNotificationDate {
                    lastNotificationDate = date
                }
            }
        }
        return lastNotificationDate
    }
    
    func updateNotifications() {
        if qVC.quizArray[index]["notifications"].exists() && qVC.quizArray[index]["notifications"] != [] {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy HH:mm:ss"
            let currentDate = Date()
            let endDate = findLastNotification()
            
            if endDate < currentDate {
                qVC.quizArray[index]["startTime"].string = ""
                qVC.quizArray[index]["endTime"].string = ""
                qVC.quizArray[index]["notifications"].arrayObject = []
                self.notificationsExist = false
            }
            else {
                self.notificationsExist = true
            }
        }
    }
    
}

