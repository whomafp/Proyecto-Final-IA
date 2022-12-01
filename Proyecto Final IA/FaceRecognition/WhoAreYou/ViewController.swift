//
//  ViewController.swift
//  WhoAreYou
//
//  Created by Miguel Ángel Fonseca Pérez.
//  Copyright © 2022 Joysoft. All rights reserved.
//

import UIKit
import AVKit
import Vision
import ARKit
import CoreML
import SceneKit

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, ARSessionDelegate {
    
    let sceneView = ARSCNView(frame: UIScreen.main.bounds)
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 18)
        return label
    }()
    let semesterLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    let majorLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    let idLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    var recognizedStudents = Set<Student>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
        self.setARConfig()
        self.setStudents()
    }
    

    private func setStudents(){
        let firstStudent = Student(name: "Luis Fernando Garnica Luna", major: "ISC", currentSemester: "9", id: 18240022)
        let secondStudent = Student(name: "Miguel Ángel Fonseca Pérez", major: "ISC", currentSemester: "9", id: 18240659)
        let thirdStudent = Student(name: "Juan Pedro Gamiño Muñoz", major: "ISC", currentSemester: "9", id: 18240885)
        let fourthStudent = Student(name: "Gaytán Ramirez Jesús", major: "ISC", currentSemester: "9", id: 18240458)
        
        recognizedStudents.insert(firstStudent)
        recognizedStudents.insert(secondStudent)
        recognizedStudents.insert(thirdStudent)
        recognizedStudents.insert(fourthStudent)
    }
    private func setARConfig(){
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    private func setupView(){
        self.view.addSubview(sceneView)
        sceneView.addSubview(stackView)
        let subviews = [nameLabel, idLabel, majorLabel, semesterLabel]
        self.configureConstraints()
        subviews.forEach({
            $0.adjustsFontSizeToFitWidth = true
            stackView.addArrangedSubview($0)
        })
        
    }
    private func configureConstraints(){
        let margins = sceneView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            stackView.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -10),
            stackView.leadingAnchor.constraint(equalTo: sceneView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: sceneView.trailingAnchor),
            stackView.heightAnchor.constraint(equalTo: sceneView.heightAnchor, multiplier: 0.1)
        ])
    }

}

extension ViewController: StudentRecognition{
    
    func showCurrentRecognizedStudent(with id: Int){
        guard let recognizedStudent = recognizedStudents.first(where: {$0.id == id}) else {
            debugPrint("DEBUG: STUDENT NOT FOUND!")
            self.unknownStudent()
            return}
        
        debugPrint("DEBUG: Current student: \(recognizedStudent)")
        self.nameLabel.text = "Name: \(recognizedStudent.name)"
        self.majorLabel.text = "Major: \(recognizedStudent.major)"
        self.semesterLabel.text = "Semester: \(recognizedStudent.currentSemester)"
        self.idLabel.text = "Student ID: \(recognizedStudent.id)"
        
        stackView.arrangedSubviews.forEach({
            $0.isHidden = false
            if let label = $0 as? UILabel{
                label.textAlignment = .center
                label.backgroundColor = .systemBlue
                label.textColor = .white
                label.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 18)
            }
        })
    }
    
    func unknownStudent(){
        self.nameLabel.text = "STUDENT NOT FOUND"
        self.nameLabel.backgroundColor = .black
        self.nameLabel.textColor = .white
        self.majorLabel.isHidden = true
        self.semesterLabel.isHidden = true
        self.idLabel.isHidden = true
    }
    
}


extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        guard let device = sceneView.device else {
            return nil
        }
        
        let faceGeometry = ARSCNFaceGeometry(device: device)
        
        let node = SCNNode(geometry: faceGeometry)
        
        node.geometry?.firstMaterial?.fillMode = .lines
        
        return node
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        stackView.isHidden =  faceAnchor.isTracked == true ? false : true
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
                return
        }
        
        faceGeometry.update(from: faceAnchor.geometry)
        
        let config = MLModelConfiguration()
        guard let coreMLModel = try? FinalTest_1(configuration: config),
              let visionModel = try? VNCoreMLModel(for: coreMLModel.model) else {
            fatalError("Unable to load model")
        }
        
        let coreMlRequest = VNCoreMLRequest(model: visionModel) {[weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first
                else {
                    fatalError("Unexpected results")
            }
            
            let id = Int(topResult.identifier) ?? 0
            DispatchQueue.main.async {[weak self] in
                self?.showCurrentRecognizedStudent(with: id)
            }
        }
        
        guard let pixelBuffer = self.sceneView.session.currentFrame?.capturedImage else { return }
        
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        DispatchQueue.global().async {
            do {
                try handler.perform([coreMlRequest])
            } catch {
                print(error)
            }
        }
    }
    
}
