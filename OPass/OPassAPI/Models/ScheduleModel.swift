//
//  ScheduleModel.swift
//  OPass
//
//  Created by 張智堯 on 2022/3/2.
//  2022 OPass.
//

import Foundation
import SwiftDate

struct ScheduleModel: Hashable, Decodable {
    //The transform() function in below Array extension will be used automatically when decoding json
    @TransformWith<SessionModelsTransform> var sessions = []
    @TransformWith<SpeakerTransform> var speakers = [:]
    @TransformWith<Id_Name_DescriptionTransform> var session_types = [:]
    @TransformWith<Id_Name_DescriptionTransform> var rooms = [:]
    @TransformWith<Id_Name_DescriptionTransform> var tags = [:]
}

struct SessionModelsTransform: TransformFunction {
    static func transform(_ sessions: [SessionDataModel]) -> [SessionModel] {
        let preProcessData = sessions
            .sorted { $0.start < $1.start || $0.end <= $1.end } //sort by time
            .reduce(into: [], { (sessionsAcrossDays: inout [[SessionDataModel]], currentSession) in
                if !sessionsAcrossDays.isEmpty && sessionsAcrossDays.last![0].onSameDay(as: currentSession) {
                    sessionsAcrossDays[sessionsAcrossDays.count-1].append(currentSession)
                } else {
                    sessionsAcrossDays.append([currentSession])
                }
            }) //combine events on the same day into an array
        var data: [SessionModel] = []
        for index in 0 ..< preProcessData.count {
            let sessionData = Dictionary(grouping: preProcessData[index], by: { $0.start })
            let sectionID = sessionData.map({ $0.key }).sorted()
            data.append(SessionModel(sectionID: sectionID, sessionData: sessionData))
        }
        return data
    }
}

struct SessionModel: Hashable, Decodable {
    var sectionID: [DateInRegion] = []
    var sessionData: [DateInRegion : [SessionDataModel]] = [:]
}

struct SessionDataModel: Hashable, Decodable {
    var id: String = ""
    var type: String? = nil
    var room: String = ""
    var broadcast: [String]? = nil
    @TransformedFrom<String> var start = DateInRegion()
    @TransformedFrom<String> var end = DateInRegion()
    var qa: String? = nil
    var slide: String? = nil
    var live: String? = nil
    var record: String? = nil
    var pad: String? = nil
    var language: String? = nil
    var zh = Title_DescriptionModel()
    var en = Title_DescriptionModel()
    var speakers: [String] = [""]
    var tags: [String] = [""]
    
    func onSameDay(as session: SessionDataModel) -> Bool {
        //Note: we only compare its start time
        return self.start.sameDay(as: session.start)
    }
}

struct SpeakerTransform: TransformFunction {
    static func transform(_ speakers: [Id_SpeakerModel]) -> [String: SpeakerModel] {
        return Dictionary(uniqueKeysWithValues: speakers.map { element in
            (element.id, SpeakerModel(avatar: element.avatar, zh: element.zh, en: element.zh))
        })
    }
}

struct Id_Name_DescriptionTransform: TransformFunction {
    static func transform(_ array: [Id_Name_DescriptionModel]) -> [String: Name_DescriptionPair] {
        return Dictionary(uniqueKeysWithValues: array.map { element in
            (element.id, Name_DescriptionPair(zh: element.zh, en: element.en))
        })
    }
}

extension String: TransformSelf {
    static func transform(_ dateString: String) -> DateInRegion {
        return dateString.toISODate()!
    }
}

extension DateInRegion {
    func sameDay(as date: DateInRegion) -> Bool {
        return self.year == date.year &&
                self.month == date.month &&
                self.day == date.day
    }
}

struct Id_SpeakerModel: Hashable, Codable {
    var id: String = ""
    var avatar: String = ""
    var zh = Name_BioModel()
    var en = Name_BioModel()
}

struct SpeakerModel: Hashable {
    var avatar: String = ""
    var avatarData: Data?
    var zh = Name_BioModel()
    var en = Name_BioModel()
}

struct Id_Name_DescriptionModel: Hashable, Codable {
    var id: String = ""
    var zh = Name_DescriptionModel()
    var en = Name_DescriptionModel()
}

struct Title_DescriptionModel: Hashable, Codable {
    var title: String = ""
    var description: String = ""
}

struct Name_BioModel: Hashable, Codable {
    var name: String = ""
    var bio: String = ""
}

struct Name_DescriptionPair: Hashable {
    var zh: Name_DescriptionModel
    var en: Name_DescriptionModel
}

struct Name_DescriptionModel: Hashable, Codable {
    var name: String = ""
    var description: String? = nil
}
