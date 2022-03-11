//
//  EventViewModel.swift
//  OPass
//
//  Created by 張智堯 on 2022/3/3.
//

import Foundation
import KeychainAccess

//Endpoint hold by each Event Organization or hold by OPass Official but switch by Event Organization.
class EventAPIViewModel: ObservableObject, Decodable {
    //Conform to Codable
    enum CodingKeys: CodingKey {
        case event_id, display_name, logo_url
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        event_id = try container.decode(String.self, forKey: .event_id)
        display_name = try container.decode(DisplayTextModel.self, forKey: .display_name)
        logo_url = try container.decode(String.self, forKey: .logo_url)
    }
    
    @Published var event_id: String = ""
    @Published var display_name = DisplayTextModel()
    @Published var logo_url: String = ""
    //End of Codable
    @Published var eventSettings: SettingsModel? = nil
    @Published var eventLogo: Data? = nil
    @Published var eventSchedule: ScheduleModel? = nil
    @Published var eventAnnouncements: [AnnouncementModel] = []
    @Published var eventScenarioStatus: ScenarioStatusModel? = nil
    @Published var isLogin: Bool = false
    
    private let keychain = Keychain(service: "app.opass.ccip") //Service key value match App Bundle ID
    var accessToken: String? { //Try not to use this for view update beacuse of it's not published. Use isLogin.
        get {
            return try? keychain.get(self.event_id + "_token") //Key sample: SITCON_2020_token
        }
        set {
            if let accessToken = newValue {
                do {
                    try keychain.remove(self.event_id + "_token")
                    try keychain.set(accessToken, key: self.event_id + "_token")
                } catch {
                    print("Save accessToken faild")
                }
            } else {
                print("No accessToken import")
            }
        }
    }
    
    func useScenario(scenario: String) async -> Bool{ //Scenario switch by scenario ID. Return true/false for view update
        guard let fastpassFeature = eventSettings?.features[ofType: .fastpass] else {
            print("FastPass feature is not included")
            return false
        }
        
        guard let token = accessToken else {
            print("No accessToken included")
            return false
        }
        
        if let eventScenarioUseStatus = try? await APIRepo.load(scenarioUseFrom: fastpassFeature, scenario: scenario, token: token) {
            DispatchQueue.main.async {
                self.eventScenarioStatus = eventScenarioUseStatus
            }
            return true
        }
        return false
    }
    
    func redeemToken(token: String) async { //Save token after token check
        let token = token.tirm()
        let nonAllowedCharacters = CharacterSet
                                    .alphanumerics
                                    .union(CharacterSet(charactersIn: "-_"))
                                    .inverted
        if (token.isEmpty || token.containsAny(nonAllowedCharacters)) {
            print("Invalid accessToken")
            return
        }
        
        self.isLogin = false
        
        guard let fastpassFeature = eventSettings?.features[ofType: .fastpass] else {
            print("FastPass feature is not included")
            return
        }
        
        if let eventScenarioStatus = try? await APIRepo.load(scenarioStatusFrom: fastpassFeature, token: token) {
            DispatchQueue.main.async {
                self.eventScenarioStatus = eventScenarioStatus
                self.accessToken = token
                self.isLogin = true
            }
        }
    }
    
    func loadScenarioStatus() async {
        guard let fastpassFeature = eventSettings?.features[ofType: .fastpass] else {
            print("FastPass feature is not included")
            return
        }
        
        guard let token = accessToken else {
            print("No accessToken included")
            return
        }
        
        if let eventScenarioStatus = try? await APIRepo.load(scenarioStatusFrom: fastpassFeature, token: token) {
            DispatchQueue.main.async {
                self.eventScenarioStatus = eventScenarioStatus
                self.isLogin = true
            }
        }
    }
    
    func loadSettings_Logo() async {
        guard let eventSettings = try? await APIRepo.loadSettings(ofEvent: event_id) else {
            return
        }
        
        DispatchQueue.main.async {
            self.eventSettings = eventSettings
        }

        if let logo = try? await APIRepo.loadLogo(from: eventSettings.logo_url) {
            DispatchQueue.main.async {
                self.eventLogo = logo
            }
        }
    }
    
    func loadSchedule() async {
        guard let scheduleFeature = eventSettings?.features[ofType: .schedule] else {
            print("Schedule feature is not included")
            return
        }
        
        if let schedule = try? await APIRepo.load(scheduleFrom: scheduleFeature) {
            DispatchQueue.main.async {
                self.eventSchedule = schedule
            }
        }
    }
    
    func loadAnnouncements() async {
        guard let announcementFeature = eventSettings?.features[ofType: .announcement] else {
            print("Announcement feature is not included")
            return
        }
        
        guard let token = accessToken else {
            print("No accessToken included")
            return
        }
        
        if let announcements = try? await APIRepo.load(announcementFrom: announcementFeature, token: token) {
            DispatchQueue.main.async {
                self.eventAnnouncements = announcements
            }
        } else {
            DispatchQueue.main.async {
                self.eventAnnouncements = []
            }
        }
    }
}

extension Array where Element == FeatureModel {
    fileprivate subscript(ofType type: FeatureType) -> Element? {
        return self.first { $0.feature == type }
    }
}

extension String {
    func tirm() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    func containsAny(_ characterSet: CharacterSet) -> Bool {
        return rangeOfCharacter(from: characterSet) != nil
    }
}
