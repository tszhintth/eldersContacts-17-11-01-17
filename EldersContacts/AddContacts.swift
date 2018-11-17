//
//  AddContacts.swift
//  EldersContacts
//
//  Created by HUI Lam on 8/11/2018.
//  Copyright © 2018 EE4304_kelvin_kong. All rights reserved.
//

import UIKit
import Contacts
import AudioToolbox
import AVFoundation

class AddContacts: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet var FirstName: UITextField!
    @IBOutlet var FamilyName: UITextField!
    @IBOutlet var Phone: UITextField!
    @IBOutlet var viewForInput: UIView!
    @IBOutlet var profilePic: UIImageView!
    @IBOutlet var viewForImage: UIView!
    @IBOutlet weak var buttonForImage: UIButton!
    
    //move up keyboard when cover textfield
    @objc func keyboardWillChange(notification: Notification){
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
            view.frame.origin.y = -keyboardRect.height
        } else {
            view.frame.origin.y = 0
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    
    
    //dismiss when touch outside of the popup view
    @IBAction func cancelAddContact(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        let string = "cancel add contact"
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FirstName.delegate = self
        FamilyName.delegate = self
        Phone.delegate = self
        
        //move up keyboard when cover textfield
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        
        viewForImage.layer.cornerRadius = viewForImage.frame.width/2
        viewForImage.clipsToBounds = true
        buttonForImage.layer.cornerRadius = viewForImage.frame.width/2
        buttonForImage.clipsToBounds = true
        viewForInput.layer.cornerRadius = viewForInput.frame.width/2.5
        viewForInput.clipsToBounds = true
        let string = "add contact"
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    //Add the contact to coredata
    @IBAction func AddContact(_ sender: Any , view : Any) {
        dismiss(animated: true, completion: nil)
        vibration()
        checkAddContact()
    }
    
    @IBAction func AddPhoto(_ sender: Any) {
        FirstName.resignFirstResponder()
        FamilyName.resignFirstResponder()
        Phone.resignFirstResponder()
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
        let string = "add photo"
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
        vibration()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        profilePic.image = image
        profilePic.layer.cornerRadius = profilePic.frame.width/2
        profilePic.clipsToBounds = true
        dismiss(animated:true, completion: nil)
    }
    
    func checkAddContact() {
        guard let firstName = FirstName.text else {
            print("FirstName Error")
            return
        }
        guard let familyName = FamilyName.text else {
            print("FamilyName Error")
            return
        }
        guard var phone = Phone.text else {
            let string = "Phone number can not be empty"
            let utterance = AVSpeechUtterance(string: string)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            let synth = AVSpeechSynthesizer()
            synth.speak(utterance)
            return
        }
        phone = phone.components(separatedBy: CharacterSet.whitespaces).joined()
        phone = phone.toValidPhoneNum()
        print("phoneNUM: \(phone)")
        
        if firstName == "" || familyName == "" {
            print("failed")
            let string = "Both first name and family name cannot be empty"
            let utterance = AVSpeechUtterance(string: string)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            let synth = AVSpeechSynthesizer()
            synth.speak(utterance)
        }else if phone == ""{
            print("failed")
            let string = "Invalid phone number"
            let utterance = AVSpeechUtterance(string: string)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            let synth = AVSpeechSynthesizer()
            synth.speak(utterance)
        } else {
            print("success")
            let contact = CNMutableContact()
            contact.givenName = firstName
            contact.familyName = familyName
            contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberiPhone, value: CNPhoneNumber(stringValue: phone))]
            if let imageData = profilePic.image {
                contact.imageData = imageData.jpegData(compressionQuality: 1)
            }
            let store = CNContactStore()
            let saveRequest = CNSaveRequest()
            saveRequest.add(contact, toContainerWithIdentifier: nil)
            try! store.execute(saveRequest)
            let string = "\(contact.givenName) \(contact.familyName) is added to contact"
            let utterance = AVSpeechUtterance(string: string)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            let synth = AVSpeechSynthesizer()
            synth.speak(utterance)
        }
        
        
        self.performSegue(withIdentifier: "addedSegue", sender: self)
    }
    func vibration () {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        print("vibrate")
    }
}

extension String{
    private func matches(for regex: String, in text: String) -> [String] {
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
    
    func toValidPhoneNum() -> String{
        let matched = matches(for: "(\\+?\\d{1,4}[\\s-]?)?(?!0+\\s+,?$)\\d{8}\\s*", in: self)         // only extract the digits
        return matched.joined(separator: "")
    }
}
