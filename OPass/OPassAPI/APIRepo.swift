//
//  APIRepo.swift
//  OPass
//
//  Created by secminhr on 2022/3/4.
//  2022 OPass.
//

import Foundation
import SwiftDate
import OSLog

final class APIRepo {
    private static let logger = Logger(subsystem: "app.opass.ccip", category: "APIRepo")
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
}

// MARK: - Opass APIs
extension APIRepo {
    static func loadEventList() async throws -> [EventTitleModel] {
        guard let url = URL(.eventList) else {
            logger.error("Invalid EventList URL: \(URLs.eventList.getString())")
            throw LoadError.invalidURL(url: .eventList)
        }
        
        do {
            return try await URLSession.shared.jsonData(from: url)
        } catch {
            logger.error("EventList Data Error: \(error.localizedDescription)")
            throw LoadError.dataFetchingFailed(cause: error)
        }
    }
    
    static func loadEventSettings(id: String) async throws -> SettingsModel {
        guard let settingsUrl = URL(.settings(id)) else {
            logger.error("Invalid Settings URL: \(URLs.settings(id).getString())")
            throw LoadError.invalidURL(url: .settings(id))
        }
        
        do {
            return try await URLSession.shared.jsonData(from: settingsUrl)
        } catch {
            logger.error("Settings Data Error: \(error.localizedDescription)")
            throw LoadError.dataFetchingFailed(cause: error)
        }
    }
}

// MARK: - Event APIs
extension APIRepo {
    static func load(@Feature(.fastpass) scenarioUseFrom feature: FeatureModel, scenario: String, token: String) async throws -> ScenarioStatusModel {
        guard let baseURL = feature.url?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            logger.error("Couldn't find URL in feature: \(feature.feature.rawValue)")
            throw LoadError.missingURL(feature: feature)
        }
        
        guard let url = URL(.scenarioUse(baseURL, scenario, token)) else {
            logger.error("Invalid ScenarioUse URL: \(URLs.scenarioUse(baseURL, scenario, token).getString())")
            throw LoadError.invalidURL(url: .scenarioUse(baseURL, scenario, token))
        }
        
        do {
            return try await URLSession.shared.jsonData(from: url)
        } catch {
            logger.error("Invaild ScenarioUse or AccessToken Error: \(error.localizedDescription)")
            throw LoadError.dataFetchingFailed(cause: error)
        }
    }
    
    static func load(@Feature(.fastpass) scenarioStatusFrom feature: FeatureModel,token: String) async throws -> ScenarioStatusModel {
        guard let baseURL = feature.url?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            logger.error("Couldn't find URL in feature: \(feature.feature.rawValue)")
            throw LoadError.missingURL(feature: feature)
        }
        
        guard let url = URL(.scenarioStatus(baseURL, token)) else {
            logger.error("Invalid ScenarioStatus URL: \(URLs.scenarioStatus(baseURL, token).getString())")
            throw LoadError.invalidURL(url: .scenarioStatus(baseURL, token))
        }
        
        do {
            return try await URLSession.shared.jsonData(from: url)
        } catch {
            logger.error("ScenarioStatus Data or AccessToken Error: \(error.localizedDescription)")
            throw LoadError.dataFetchingFailed(cause: error)
        }
    }
    
    static func loadLogo(from url: String) async throws -> Data {
        guard let urlString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let logoUrl = URL(string: urlString) else {
            logger.error("Invalid Logo URL: \(url)")
            throw LoadError.invalidURL(url: .raw(url))
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: logoUrl)
            return data
        } catch {
            logger.error("Logo Data Error: \(error.localizedDescription)")
            throw LoadError.dataFetchingFailed(cause: error)
        }
    }
    
    static func load(@Feature(.schedule) scheduleFrom schedule: FeatureModel) async throws -> ScheduleModel {
        guard let baseURL = schedule.url?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            logger.error("Couldn't find URL in feature: \(schedule.feature.rawValue)")
            throw LoadError.missingURL(feature: schedule)
        }
        
        guard let url = URL(string: baseURL) else {
            logger.error("Invalid Schedule URL: \(baseURL)")
            throw LoadError.invalidURL(url: .raw(baseURL))
        }
        
        do {
            return try await URLSession.shared.jsonData(from: url)
        } catch {
            logger.error("Schedule Data Error: \(error.localizedDescription)")
            throw LoadError.dataFetchingFailed(cause: error)
        }
    }
    
    static func load(@Feature(.announcement) announcementFrom feature: FeatureModel, token: String) async throws -> [AnnouncementModel] {
        guard let baseURL = feature.url?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            logger.error("Couldn't find URL in feature: \(feature.feature.rawValue)")
            throw LoadError.missingURL(feature: feature)
        }
        
        guard let url = URL(.announcements(baseURL, token)) else {
            logger.error("Invalid Announcements URL: \(URLs.announcements(baseURL, token).getString())")
            throw LoadError.invalidURL(url: .announcements(baseURL, token))
        }
        
        do {
            return try await URLSession.shared.jsonData(from: url)
        } catch {
            logger.error("Announcement Data Error: \(error.localizedDescription)")
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
        decoder.userInfo[.needTransform] = true
        return try decoder.decode(T.self, from: data)
    }
}

extension CodingUserInfoKey {
    static let needTransform = CodingUserInfoKey(rawValue: "needTransform")!
}
