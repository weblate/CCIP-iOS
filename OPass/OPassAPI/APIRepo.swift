//
//  APIRepo.swift
//  OPass
//
//  Created by secminhr on 2022/3/4.
//

import Foundation
import SwiftDate

final class APIRepo {
    enum LoadError: Error {
        case invalidURL(url: URLs)
        case dataFetchingFailed(cause: Error)
        case missingURL(feature: FeatureModel)
        case invalidDateString(String)
    }
    enum URLs {
        case eventList
        case settings(String)
        case announcements(String, String)
        case scenarioStatus(String, String)
        case scenarioUse(String, String, String)
        case raw(String)
        
        func getString() -> String {
            switch self {
                case .eventList:
                    return "https://portal.opass.app/events/"
                case .settings(let id):
                    return "https://portal.opass.app/events/\(id)"
                case .announcements(let baseURL, let token):
                    return "\(baseURL)/announcement?token=\(token)"
                case .scenarioStatus(let baseURL, let token):
                    return "\(baseURL)/status?token=\(token)"
                case .scenarioUse(let baseURL, let scenario, let token):
                    return "\(baseURL)/use/\(scenario)?token=\(token)"
                case .raw(let url):
                    return url
            }
        }
    }
    
    //Opass APIs
    static func loadEventList() async throws -> [EventAPIViewModel] {
        guard let url = URL(.eventList) else {
            print("Invalid EventList URL")
            throw LoadError.invalidURL(url: .eventList)
        }
        
        do {
            return try await URLSession.shared.jsonData(from: url)
        } catch {
            print("EventList Data Error")
            throw LoadError.dataFetchingFailed(cause: error)
        }
    }
    
    static func loadEvent(id: String) async throws -> EventAPIViewModel {
        //Here we reuse settings loading to obtain an EventAPIViewModel for a specific id.
        //The reason why it works is that both EventAPIViewModel and SettingsModel have event_id, display_name, logo_url fields.
        //Therefore, the json from settings url can be converted to EventAPIViewModel safely.
        
        //Maybe we should combine loadEvent and loadSettings, since they are identical except return type.
        //However, the meaning of the function might be confusing if we make these two functions into one.
        guard let url = URL(.settings(id)) else {
            throw LoadError.invalidURL(url: .settings(id))
        }
        do {
            return try await URLSession.shared.jsonData(from: url)
        } catch {
            throw LoadError.dataFetchingFailed(cause: error)
        }
    }
    
    //Event APIs
    static func load(@Feature(.fastpass) scenarioUseFrom feature: FeatureModel, scenario: String, token: String) async throws -> ScenarioStatusModel {
        guard let baseURL = feature.url else {
            print("Couldn't find URL in feature: \(feature)")
            throw LoadError.missingURL(feature: feature)
        }
        
        guard let url = URL(.scenarioUse(baseURL, scenario, token)) else {
            print("Invalid ScenarioUse URL")
            throw LoadError.invalidURL(url: .scenarioUse(baseURL, scenario, token))
        }
        
        do {
            return try await URLSession.shared.jsonData(from: url)
        } catch {
            print("Invaild ScenarioUse or AccessToken Error")
            throw LoadError.dataFetchingFailed(cause: error)
        }
    }
    
    static func load(@Feature(.fastpass) scenarioStatusFrom feature: FeatureModel,token: String) async throws -> ScenarioStatusModel {
        guard let baseURL = feature.url else {
            print("Couldn't find URL in feature: \(feature)")
            throw LoadError.missingURL(feature: feature)
        }
        
        guard let url = URL(.scenarioStatus(baseURL, token)) else {
            print("Invalid ScenarioStatus URL")
            throw LoadError.invalidURL(url: .scenarioStatus(baseURL, token))
        }
        
        do {
            return try await URLSession.shared.jsonData(from: url)
        } catch {
            print("ScenarioStatus Data or AccessToken Error")
            throw LoadError.dataFetchingFailed(cause: error)
        }
    }
    
    static func loadSettings(ofEvent eventId: String) async throws -> SettingsModel {
        guard let SettingsUrl = URL(.settings(eventId)) else {
            print("Invalid Settings URL")
            throw LoadError.invalidURL(url: .settings(eventId))
        }
        
        do {
            return try await URLSession.shared.jsonData(from: SettingsUrl)
        } catch {
            print("Settings Data Error")
            throw LoadError.dataFetchingFailed(cause: error)
        }
    }
    
    static func loadLogo(from url: String) async throws -> Data {
        guard let logoUrl = URL(string: url) else {
            print("Invalid Logo URL")
            throw LoadError.invalidURL(url: .raw(url))
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: logoUrl)
            return data
        } catch {
            print("Logo Data Error")
            throw LoadError.dataFetchingFailed(cause: error)
        }
    }
    
    static func load(@Feature(.schedule) scheduleFrom schedule: FeatureModel) async throws -> ScheduleModel {
        guard let baseURL = schedule.url else {
            print("Couldn't find URL in feature: \(schedule)")
            throw LoadError.missingURL(feature: schedule)
        }
        
        guard let url = URL(string: baseURL) else {
            print("Invalid Schedule URL")
            throw LoadError.invalidURL(url: .raw(baseURL))
        }
        
        do {
            return try await URLSession.shared.jsonData(from: url)
        } catch {
            print("Schedule Data Errir")
            throw LoadError.dataFetchingFailed(cause: error)
        }
    }
    
    static func load(@Feature(.announcement) announcementFrom feature: FeatureModel, token: String) async throws -> [AnnouncementModel] {
        guard let baseURL = feature.url else {
            print("Couldn't find URL in feature: \(feature)")
            throw LoadError.missingURL(feature: feature)
        }
        
        guard let url = URL(.announcements(baseURL, token)) else {
            print("Invalid Announcements URL")
            throw LoadError.invalidURL(url: .announcements(baseURL, token))
        }
        
        do {
            return try await URLSession.shared.jsonData(from: url)
        } catch {
            print("Announcement Data Errir")
            throw LoadError.dataFetchingFailed(cause: error)
        }
    }
}

extension URL {
    fileprivate init?(_ urlType: APIRepo.URLs) {
        self.init(string: urlType.getString())
    }
}

extension URLSession {
    func jsonData<T: Decodable>(from url: URL) async throws -> T {
        let (data, _) = try await self.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}