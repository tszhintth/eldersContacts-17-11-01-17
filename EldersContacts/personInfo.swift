//
//  personInfo.swift
//  EldersContacts
//
//  Created by Chun Yin Kong on 6/11/2018.
//  Copyright © 2018 EE4304_kelvin_kong. All rights reserved.
//

import UIKit
import Contacts
import CallKit
import AudioToolbox
import AVFoundation

class personInfo: UIViewController {
    var content: CNContact?     // the contact that have been selected from the contact list
    
    @IBOutlet var personImage: UIImageView!
    
    @IBOutlet var callButton: UIButton!
    @IBOutlet var messageButton: UIButton!
    
    @IBAction func message(_ sender: Any) {
        let string = "message"
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        if let temp = content{
            let phoneNum = temp.phoneNumbers.first?.value.stringValue
            let url = URL(string: "sms:\(toValidPhoneNum(phoneNum!))")
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url!)
            } else {
                UIApplication.shared.openURL(url!)
            }
        }else{
            print("content is nil")
        }
        
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
        vibration()
    }
    
    @IBAction func call(_ sender: Any) {
        let string = "call"
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
        
        if let temp = content{
            let phoneNum = temp.phoneNumbers.first?.value.stringValue
            let url = URL(string: "tel:\(toValidPhoneNum(phoneNum!))")
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url!)
            } else {
                UIApplication.shared.openURL(url!)
            }
        }else{
            print("content is nil")
        }
        vibration()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let temp = content{
            printAllContactInfo(temp)
            let fName = temp.givenName
            let lName = temp.familyName
            if fName != "" && lName != ""{
                self.title = fName + " " + lName
            }else if fName == ""{
                self.title = lName
            }else{
                self.title = fName
            }
            
            personImage.image = UIImage.init(data: temp.imageData ?? Data.init())// temporary solution
            personImage.layer.cornerRadius = personImage.frame.size.width/2
            personImage.clipsToBounds = true
        }else{
            print("the contact is not formed/assigned")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setting the background image
        let backgroundImage = UIImage.init(named: "personImage.jpg")
        let backgroundImageView = UIImageView.init(frame: self.view.frame)
        
        
        backgroundImageView.image = backgroundImage
        backgroundImageView.contentMode = .scaleAspectFill
        //how saturate is the image
        backgroundImageView.alpha = 0.3
        
        self.view.insertSubview(backgroundImageView, at: 0)
        
        if let temp = content{
            if let phoneNum = temp.phoneNumbers.first?.value.stringValue{
                if phoneNum.contains("*") || phoneNum.contains("#"){
                    callButton.isEnabled = false
                    messageButton.isEnabled = false
                    let alert = UIAlertController(title: "Invalid Phone Number", message: "Call and Message buttons are disabled", preferredStyle: .alert)
                    alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (UIAlertAction) in
                        print("Buttons disabled")
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }else{
                callButton.isEnabled = false
                messageButton.isEnabled = false
                let alert = UIAlertController(title: "Invalid Phone Number", message: "Call and Message buttons are disabled", preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (UIAlertAction) in
                    print("Buttons disabled")
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier{
            if identifier == "info"{
                let temp: Edit = segue.destination as! Edit
                temp.contect = content
            }else{
                print("identifier failed")
            }
        }else{
            print("identifier is nil")
        }
    }
    
    private func printAllContactInfo(_ contact: CNContact){
        print("PERSONINFO: \(contact.givenName)")
        print("PERSONINFO: \(contact.familyName)")
        print("PERSONINFO: \(contact.phoneNumbers.first?.value.stringValue ?? "")")
        let string = "\(contact.givenName) \(contact.familyName)"
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    
    func vibration () {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        print("vibrate")
    }
}

func matches(for regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}

private func toValidPhoneNum(_ string: String) -> String{
    let matched = matches(for: "\\d", in: string)         // only extract the digits
    return matched.joined(separator: "")
}
