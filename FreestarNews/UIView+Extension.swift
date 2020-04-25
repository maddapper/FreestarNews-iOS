//
//  UIView+Extension.swift
//  FreestarNews
//
//  Created by Dean Chang on 5/23/18.
//  Copyright © 2018 Freestar. All rights reserved.
//

import Foundation
import UIKit

extension UIView {    
    func removeAllSubViewOfType<T: UIView>(type: T.Type) {
        self.subviews.filter({ $0 is T }).forEach({ $0.removeFromSuperview() })
    }
}
