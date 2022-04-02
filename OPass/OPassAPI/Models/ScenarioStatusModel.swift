//
//  ScenarioStatusModel.swift
//  OPass
//
//  Created by 張智堯 on 2022/3/5.
//

import Foundation

struct ScenarioStatusModel: Hashable, Decodable {
    var event_id: String = ""
    var token: String = ""
    var user_id: String = ""
    var attr = AttrModel()
    var first_use: Int = 0
    var role: String = ""
    @TransformWith<ScenarioModelsTransform> var scenarios = [ScenarioModel()]
}

struct ScenarioModelsTransform: TransformFunction {
    static func transform(_ scenarios: [ScenarioModel]) -> [ScenarioModel] {
        return scenarios
            .sorted { $0.order < $1.order } //sort by order
    }
}

struct AttrModel: Hashable, Codable {
    var diet: String? = nil
}

struct ScenarioModel: Hashable, Codable {
    var order: Int = 0
    var display_text = DisplayTextModel_CountryCode()
    var available_time: Int = 0
    var expire_time: Int = 0
    var disable: String? = nil
    var countdown: Int = 0
    var attr = AttrModel()
    var used: Int? = nil
    var id: String = ""
}
