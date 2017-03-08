//
//  TableViewCell.swift
//  BusTrakr
//
//  Created by Jason Ma on 2/4/17.
//  Copyright © 2017 Jason Ma. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet weak var busType: UILabel!
    @IBOutlet weak var busTime: UILabel!
    @IBOutlet weak var busName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
