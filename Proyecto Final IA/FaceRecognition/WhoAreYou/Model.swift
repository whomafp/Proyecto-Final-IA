//
//  Model.swift
//  WhoAreYou
//
//  Created by Miguel Angel Fonseca Perez on 25/11/22.
//  Copyright © 2022 M'haimdat omar. All rights reserved.
//

import Foundation

struct Student: Hashable{
    var name, major, currentSemester: String
    var id: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
   
}

protocol StudentRecognition{
    func showCurrentRecognizedStudent(with id: Int)
    func unknownStudent()
}
