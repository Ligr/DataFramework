//
//  ViewController.swift
//  DataFramework
//
//  Created by Aliaksandr Huryn on 06/15/2018.
//  Copyright (c) 2018 Aliaksandr Huryn. All rights reserved.
//

import UIKit
import DataFramework

class ViewController: UIViewController {

    @IBAction func testWebServiceBtnAction() {
        let view = TestWebServiceView()
        navigationController?.pushViewController(view, animated: true)
    }

}

