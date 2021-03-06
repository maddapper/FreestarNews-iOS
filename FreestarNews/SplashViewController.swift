//
//  SplashViewController.swift
//  FreestarNews
//
//  Created by Dean Chang on 5/23/18.
//  Copyright © 2018 Freestar. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        performSegue(withIdentifier: "showMainViewController", sender: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Navigation
    @IBAction func unwindToSplashViewControllerFromMain(segue: UIStoryboardSegue) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "showPrivacyViewController", sender: self)
        }
    }
    
    @IBAction func unwindToSplashViewControllerFromPrivacy(segue: UIStoryboardSegue) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "showMainViewController", sender: self)
        }
    }
        
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
