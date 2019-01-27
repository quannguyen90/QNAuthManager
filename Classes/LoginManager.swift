//
//  LoginManager.swift
//  Gongcha
//
//  Created by QUANNV on 11/4/17.
//  Copyright © 2017 quannv. All rights reserved.
//

import UIKit
import AccountKit
import GoogleSignIn
import Firebase
//import GGLCore

import FacebookCore
import FacebookLogin
import FBSDKCoreKit

import ZaloSDK

let accountKitPrimaryColor = UIColor(red: 242/255.0, green: 147/255.0, blue: 46/255.0, alpha: 1.0)
let zaloAppId = "2823200096954276202"
let zaloAppSecret = "54SDTzx92P3My3CXVD5G"

enum AUKLoginType: Int {
    case facebook = 0
    case google = 1
    case accountKit = 2
    case zalo = 3
}

class AUKUser: NSObject {
    var name: String?
    var token: String?
    var facebookId: String?
    var googleId: String?
    var zaloId: String?
    var accountKitId: String?
    var email: String?
    var imageURL: String?

    init(accessTokenAccountKit: AKFAccessToken) {
        self.token = accessTokenAccountKit.tokenString
        self.accountKitId = accessTokenAccountKit.accountID
    }

    init(googleUserInfo: GIDGoogleUser) {
        self.googleId = googleUserInfo.userID                  // For client-side use only!
        self.name = googleUserInfo.profile.name
        self.email = googleUserInfo.profile.email
        self.token = googleUserInfo.authentication.accessToken
    }

    init(facebook token: String) {
        self.token = token
    }

    init(fromFacebook user: FBSDKAccessToken) {
        self.token = user.tokenString
        self.facebookId = user.userID
        self.imageURL = "http://graph.facebook.com/\(user.userID!)/picture?type=large"
        if FBSDKProfile.current() != nil {
            self.name = FBSDKProfile.current().name
        }

    }

    init(zaloObjectAuthen: ZOOauthResponseObject) {
        self.token = zaloObjectAuthen.oauthCode
        self.name = zaloObjectAuthen.displayName
        self.zaloId = zaloObjectAuthen.userId
    }

    override var description: String {
        let nameString = "name: " + (name ?? "")
        let tokenString = "token: " + (token ?? "")
        let facebookIdString = "facebookId: " + (facebookId ?? "")
        let googleIdString = "googleId: " + (googleId ?? "")
        let zaloIdString = "zaloId: " + (zaloId ?? "")
        let accountKitIdString = "accountKitId: " + (accountKitId ?? "")
        return [nameString, tokenString, facebookIdString, googleIdString, zaloIdString, accountKitIdString].joined(separator: ", ")
    }
}

let kUserToken = "AUKUser_token"
let kUserType = "AUKUser_type"

func saveToken(token: String?) {
    let userDefault = UserDefaults.standard
    userDefault.setValue(token, forKey: kUserToken)
    userDefault.synchronize()
}

func getToken() -> String? {
    let userDefault = UserDefaults.standard
    return (userDefault.value(forKey: kUserToken) as? String)
}

func saveType(type: Int) {
    let userDefault = UserDefaults.standard
    userDefault.set(type, forKey: kUserType)
    userDefault.synchronize()
}

func getType() -> Int {
    let userDefault = UserDefaults.standard
    return (userDefault.value(forKey: kUserType) as? Int) ?? AUKLoginType.facebook.rawValue
}

class AUKLoginManager: NSObject {

    static let manager: AUKLoginManager = AUKLoginManager()
    var phone = ""

    var type: AUKLoginType = .facebook {
        didSet {
            saveType(type: type.rawValue)
        }
    }
    var user: AUKUser? {
        didSet {
            saveToken(token: user?.token)
        }
    }

    var token: String? {
        return getToken()
    }
    var sourcePresent: UIViewController?

    var isSetupGoogle = false
    var isSetupZalo = false

    var authSuccessBlock: (AUKUser) -> Void = {
        user in
    }

    var authFailBlock: (Error) -> Void = {
        error in
    }

    func setupGoogleSignIn() {
        // Initialize sign-in
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
    }

    // MARK: - Authen
    private func loginByAccountKit() {

        let accountKit = AKFAccountKit(responseType: .accessToken)
        let uiManager = AKFSkinManager(skinType: .translucent, primaryColor: accountKitPrimaryColor, backgroundImage: nil, backgroundTint: AKFBackgroundTint.white, tintIntensity: 1)

        let loginViewController: AKFViewController = accountKit.viewControllerForPhoneLogin(with: AKFPhoneNumber(countryCode: "+84", phoneNumber: phone), state: nil) as AKFViewController
        loginViewController.delegate = self
        loginViewController.uiManager = uiManager
        sourcePresent?.present(loginViewController as! UIViewController, animated: true, completion: nil)
    }

    private func loginByGoogle() {
        if !isSetupGoogle {
            setupGoogleSignIn()
            isSetupGoogle = true
        }

        GIDSignIn.sharedInstance().signIn()
    }

    private func loginByFacebook() {
        if (FBSDKAccessToken.current() != nil) && FBSDKAccessToken.current().expirationDate.timeIntervalSinceNow > 0 {
            let request = FBSDKGraphRequest(graphPath: "me", parameters: nil)

            request?.start(completionHandler: { (_, data, _) in
                if let dict = data as? [String: Any] {

                    let userName = (dict["name"] as? String) ?? ""
                    let user = AUKUser(fromFacebook: FBSDKAccessToken.current())
                    user.name = userName
                    self.user = user
                    self.authSuccessBlock(user)

                } else {
                    let user = AUKUser(fromFacebook: FBSDKAccessToken.current())
                    self.user = user
                    self.authSuccessBlock(user)
                }
            })
        } else {
            let loginManager = LoginManager()
            loginManager.logOut()
            loginManager.loginBehavior = .systemAccount
            loginManager.logIn(readPermissions: [.publicProfile, .email], viewController: sourcePresent) { (result) in
                switch result {
                case.cancelled:
                    let error = NSError(domain: "", code: -9999, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Có lỗi xảy ra", comment: "")])
                    self.authFailBlock(error)

                case .failed(let error):
                    debugPrint("Error: \(error.localizedDescription)")
                    let error1 = NSError(domain: "", code: -9999, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Có lỗi xảy ra", comment: "")])
                    self.authFailBlock(error1)

                case .success:
                    if FBSDKProfile.current() == nil {
                        let request = FBSDKGraphRequest(graphPath: "me", parameters: nil)
                        request?.start(completionHandler: { (_, data, _) in
                            if let dict = data as? [String: Any] {

                                let userName = (dict["name"] as? String) ?? ""
                                //                                var email = (dict["email"] as? String) ?? ""

                                let user = AUKUser(fromFacebook: FBSDKAccessToken.current())
                                user.name = userName
                                self.user = user
                                self.authSuccessBlock(user)

                            } else {
                                let user = AUKUser(fromFacebook: FBSDKAccessToken.current())
                                self.user = user
                                self.authSuccessBlock(user)
                            }
                        })
                    } else {
                        let user = AUKUser(fromFacebook: FBSDKAccessToken.current())
                        self.user = user
                        self.authSuccessBlock(user)
                    }
                }
            }
        }
    }

    private func loginByZalo() {
        if !isSetupZalo {
            setupZalo()
            isSetupZalo = true
        }

        ZaloSDK.sharedInstance().authenticateZalo(with: ZAZaloSDKAuthenType.init(2), parentController: sourcePresent!) { (zaloObject) in
            guard let userInfo = zaloObject else {
                self.authFailBlock(AUKError())
                return
            }

            let user = AUKUser(zaloObjectAuthen: userInfo)
            self.user = user
            self.authSuccessBlock(user)

        }
    }

    func setupZalo() {
        ZaloSDK.sharedInstance().initialize(withAppId: zaloAppId)
    }

    private func excuteAuth() {

        switch type {
        case .accountKit:
            loginByAccountKit()
        case .facebook:
            loginByFacebook()
        case .google:
            loginByGoogle()
        case .zalo:
            loginByZalo()
        }
    }

    func login(type: AUKLoginType,
               sourcePresent: UIViewController,
               onSuccess successBlock: @escaping (_ user: AUKUser) -> Void,
               orFail failBlock: @escaping (_ error: Error) -> Void) {

        self.authSuccessBlock = successBlock
        self.authFailBlock = failBlock
        if self.type != type {
            logout()
        }
        self.type = type

        self.sourcePresent = sourcePresent
        excuteAuth()
    }

    // MARK: - Unauthen
    func logout() {
        user = nil

        switch type {
        case .accountKit:
            logoutAccountKit()
        case .facebook:
            logoutFacebook()
        case .google:
            logoutGoogle()
        case .zalo:
            logoutZalo()
        }
    }

    private func logoutFacebook() {
        LoginManager().logOut()
    }

    private func logoutAccountKit() {
        AKFAccountKit(responseType: .accessToken).logOut()
    }

    private func logoutGoogle() {
        GIDSignIn.sharedInstance().signOut()
    }

    private func logoutZalo() {

    }

}

extension AUKLoginManager: GIDSignInUIDelegate {
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        viewController.dismiss(animated: true, completion: nil)
    }

    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {

    }

    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        sourcePresent?.present(viewController, animated: true, completion: nil)
    }
}

extension AUKLoginManager: GIDSignInDelegate {

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error == nil {
            let socialAccount = AUKUser(googleUserInfo: user)
            self.user = socialAccount
            self.authSuccessBlock(socialAccount)
        } else {
            debugPrint("\(error.localizedDescription)")
            authFailBlock(error)
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        authFailBlock(error)
    }

}

extension AUKLoginManager: AKFViewControllerDelegate {

    func viewControllerDidCancel(_ viewController: (UIViewController & AKFViewController)!) {
        let error = NSError(domain: "", code: -9999, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Người dùng huỷ", comment: "")])
        self.authFailBlock(error)
        showMessage(error.localizedDescription)
    }

    func viewController(_ viewController: (UIViewController & AKFViewController)!, didFailWithError error: Error!) {
        self.authFailBlock(error)
        showMessage(error.localizedDescription)

    }

    func viewController(_ viewController: (UIViewController & AKFViewController)!, didCompleteLoginWith accessToken: AKFAccessToken!, state: String!) {
        debugPrint("accessToken", accessToken.tokenString)
        let user = AUKUser(accessTokenAccountKit: accessToken)
        self.user = user
        self.authSuccessBlock(user)
    }

    func viewController(_ viewController: (UIViewController & AKFViewController)!, didCompleteLoginWithAuthorizationCode code: String!, state: String!) {

    }

}

class AUKError: Error {

}
