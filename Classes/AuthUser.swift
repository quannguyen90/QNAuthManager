//
//  AuthUser.swift
//  Gongcha
//
//  Created by QUANNV on 11/4/17.
//  Copyright © 2017 quannv. All rights reserved.
//

import UIKit

enum AuthType {
    case google
    case accountKit
    case facebook
    case zalo
}

class AuthUser: NSObject {
    var token: String?
    var facebookId: String?
    var googleId: String?
    var name: String?
    var email: String?

    override init() {
    }
}
