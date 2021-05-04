//
//  QuestionTableViewCell.swift
//  Go Quiz Yourself
//
//  Created by Gillian Johnson on 2021-04-25.
//

import UIKit
import SwipeCellKit

class QuestionTableViewCell: SwipeTableViewCell {
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerLabel: UILabel!
    
    var index: Int = 0
    var qqVC = QuizQuestionsViewController()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func editButtonPressed(_ sender: UIButton) {
        qqVC.editButtonPressed(sender)
    }
}
