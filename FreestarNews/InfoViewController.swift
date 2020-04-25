//
//  InfoViewController.swift
//
//  Created by Dean Chang on 5/14/18.
//  Copyright © 2018 Amit Burstein. All rights reserved.
//

import Foundation
import UIKit
import FSAdSDK
import FSDFP

class InfoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let InfoCellIdentifier = "InfoCell"
    var adEventMessages: [ String? ]?
    var keywordsAttachedCount: Int = 0
    @IBOutlet weak var tableView: UITableView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = false

        tableView.estimatedRowHeight = 40.0 // Replace with your actual estimation
        tableView.rowHeight = UITableView.automaticDimension
    }

    func statusToString(status: FSRegistrationStatus?) -> String {
        if (FSRegistrationStatus.initial == status) {
            return "initial"
        } else if (FSRegistrationStatus.error == status) {
            return "error"
        } else if (FSRegistrationStatus.success == status) {
            return "success"
        }
        return "unknown"
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: InfoCellIdentifier) as UITableViewCell?
        cell?.selectionStyle = .none
        cell?.detailTextLabel?.textColor = UIColor.blue
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        switch indexPath.row {
        case 0:
            cell?.textLabel?.text = "Registration Status"
            let status = appDelegate.registrationStatus
            cell?.detailTextLabel?.text = statusToString(status: status)
        case 1:
            cell?.textLabel?.text = "App Version"
            cell?.detailTextLabel?.text = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        case 2:
            cell?.textLabel?.text = "Bundle Identifier"
            cell?.detailTextLabel?.text = Bundle.main.bundleIdentifier!
        case 3:
            cell?.textLabel?.text = "Registered AdUnits"
            cell?.detailTextLabel?.text = String(appDelegate.registeredAdUnitsCount)
        case 4:
            cell?.textLabel?.text = "Keywords Attached"
            cell?.detailTextLabel?.text = String(keywordsAttachedCount)
        case 5:
            cell?.textLabel?.text = "Banner Response (320x50)"
            cell?.detailTextLabel?.text = adEventMessages?[0]
        case 6:
            cell?.textLabel?.text = "Banner Response (300x250)"
            cell?.detailTextLabel?.text = adEventMessages?[1]
        case 7:
            cell?.textLabel?.text = "Banner Response (320x100)"
            cell?.detailTextLabel?.text = adEventMessages?[2]
        default:
            return cell!
        }
        return cell!
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
