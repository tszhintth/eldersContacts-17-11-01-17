import UIKit
import Speech
import MessageUI
import CallKit
import CoreData

class VoiceViewController: UIViewController , UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let task = tasks[indexPath.row]
        cell.textLabel?.text = "Command: \(task.toCall!)      Phone: \(task.phone!)"
        return cell
    }
    override func viewWillAppear(_ animated: Bool) {
        getData()
        tableView.reloadData()
    }
    func getData(){
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        do{
            tasks = try context.fetch(Contacts.fetchRequest())
        }catch{
            print("Fetching Failed")
        }
    }
    var tasks : [Contacts] = []
    func authorizeSR() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.transcribeButton.isEnabled = true
                    
                case .denied:
                    self.transcribeButton.isEnabled = false
                    self.transcribeButton.setTitle("Speech recognition access denied by user", for: .disabled)
                    
                case .restricted:
                    self.transcribeButton.isEnabled = false
                    self.transcribeButton.setTitle("Speech recognition restricted on device", for: .disabled)
                    
                case .notDetermined:
                    self.transcribeButton.isEnabled = false
                    self.transcribeButton.setTitle("Speech recognition not authorized", for: .disabled)
                }
            }
        }
    }
    
    
    @IBOutlet var transcribeButton: UIButton!
    @IBOutlet var myTexView: UILabel!
    @IBOutlet var tableView: UITableView!
    
//    @IBOutlet var tableView: UITableView!
//    @IBOutlet var transcribeButton: UIButton!
//    @IBOutlet var stopButton: UIButton!
//    @IBOutlet var myTexView: UITextField!
//    @IBOutlet var contact_person: UITextField!
//    @IBOutlet var submit_button: UIButton!
    
//    @IBAction func addTask(_ sender: UIButton) {
//
//        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//
//        let task = Contacts(context : context)
//        if ((myTexView.text) != nil) && ((contact_person.text) != nil) {
//            task.tocall = myTexView.text!
//            task.phone = contact_person.text!
//            (UIApplication.shared.delegate as! AppDelegate).saveContext()
//            //navigationController!.popViewController(animated: true)
//            tableView.reloadData()
//        }else { return }
//        self.viewWillAppear(true)
//    }
    
    
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//
//        if editingStyle == .delete {
//            let task = tasks[indexPath.row]
//            context.delete(task)
//            (UIApplication.shared.delegate as! AppDelegate).saveContext()
//
//            do{
//                tasks = try context.fetch(Contacts.fetchRequest())
//            } catch {
//                print("Fetching Failed")
//            }
//            tableView.reloadData()
//        }
//    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        do {
            if editingStyle == UITableViewCell.EditingStyle.delete{
                let target = tasks[indexPath.row]
                tasks.remove(at: indexPath.row)
                let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                let fetchRequest: NSFetchRequest<Contacts> = Contacts.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "toCall == %@ && phone == %@", target.toCall!, target.phone!)
                let fetchContent = try context.fetch(fetchRequest)
                if fetchContent.count > 0{
                    context.delete(fetchContent.first!)
                    tableView.reloadData()
                    (UIApplication.shared.delegate as! AppDelegate).saveContext()
                }else{
                    print("No matched")
                }
            }
        }catch{
            print("FETCH ERROR DELETE")
        }
    }
    
    private let speechRecognizer = SFSpeechRecognizer(locale:
        Locale(identifier: "en_US"))!
    
    private var speechRecognitionRequest:
    SFSpeechAudioBufferRecognitionRequest?
    private var speechRecognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @IBAction func startTranscribing(_ sender: AnyObject) {
        transcribeButton.isEnabled = false
        try! startSession()
    }
    
    func startSession() throws {
        
        if let recognitionTask = speechRecognitionTask {
            recognitionTask.cancel()
            self.speechRecognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .videoChat)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        
        speechRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = speechRecognitionRequest else { fatalError("SFSpeechAudioBufferRecognitionRequest object creation failed") }
        
        guard let inputNode : AVAudioNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        
        recognitionRequest.shouldReportPartialResults = true
        var finished = false
        var count = 0
        speechRecognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            if let temp = result {
                let bestString = temp.bestTranscription.formattedString
                var lastString : String = ""
                for segment in temp.bestTranscription.segments {
                    let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                    lastString = bestString.substring(from: indexTo).lowercased()
                }
                self.myTexView.text = lastString
                self.checkCommand(&lastString, &finished, &count)
                recognitionRequest.endAudio()
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.speechRecognitionRequest = nil
                self.speechRecognitionTask = nil
                self.transcribeButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            
            self.speechRecognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myTexView.adjustsFontSizeToFitWidth = true
        authorizeSR()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.audioEngine.stop()
        self.speechRecognitionRequest = nil
        self.speechRecognitionTask = nil
    }
    
    func checkCommand(_ cmd: inout String,_ bool: inout Bool,_ numCount: inout Int) {
        for task in tasks{
            if task.toCall == cmd && !bool{
                if numCount < 1{
                    let url = URL(string: "tel:\(task.phone!)")
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url!)
                    } else {
                        UIApplication.shared.openURL(url!)
                    }
                    cmd = ""
                    bool = true
                }
            }
        }
        numCount += 1
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

