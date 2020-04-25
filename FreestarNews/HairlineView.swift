//
//  HairlineView.swift
//

import UIKit

class HairlineView : UIView {
  
  // MARK: UINibLoading
  
  override func awakeFromNib() {
    layer.borderColor = backgroundColor?.cgColor
    layer.borderWidth = (1.0 / UIScreen.main.scale) / 2
    backgroundColor = UIColor.clear
  }
}
