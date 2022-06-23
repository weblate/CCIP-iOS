//
//  SettingView.swift
//  OPass
//
//  Created by 張智堯 on 2022/3/2.
//  2022 OPass.
//

import SwiftUI
import BetterSafariView

struct SettingView: View {
    
    @EnvironmentObject var OPassAPI: OPassAPIViewModel
    
    var body: some View {
        VStack {
            Form {
                AppIconSection()
                
                GeneralSection()
                
                AboutSection()
                
                DeveloperSection()
            }
        }
        .navigationTitle(LocalizedStringKey("Setting"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct AppIconSection: View {
    var body: some View {
        Section {
            HStack {
                Spacer()
                VStack {
                    Image("InAppIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIScreen.main.bounds.width * 0.28)
                        .clipShape(Circle())
                    Text("OPass")
                }
                .padding(5)
                Spacer()
            }
        }
    }
}

fileprivate struct GeneralSection: View {
    
    @AppStorage("appearance") var appearance: Appearance = .system
    
    var body: some View {
        Section(header: Text(LocalizedStringKey("GENERAL"))) {
            Picker(selection: $appearance) {
                Text(LocalizedStringKey("System")).tag(Appearance.system)
                Text(LocalizedStringKey("Light")).tag(Appearance.light)
                Text(LocalizedStringKey("Dark")).tag(Appearance.dark)
            } label: {
                Label { Text(LocalizedStringKey("Appearance")) } icon: {
                    Image(systemName: "circle.lefthalf.filled")
                        .padding(5)
                        .foregroundColor(.white)
                        .background(Color(red: 89/255, green: 169/255, blue: 214/255))
                        .cornerRadius(7)
                }
            }
        }
    }
}

fileprivate struct AboutSection: View {
    
    @Environment(\.colorScheme) var colorScheme
    private let CCIPWebsiteURL = URL(string: "https://opass.app")!
    private let CCIPGitHubURL = URL(string: "https://github.com/CCIP-App")!
    private let CCIPPolicyURL = URL(string: "https://opass.app/privacy-policy.html")!
    
    @State var isShowingSafari = false
    @State var url = URL(string: "https://opass.app")!
    @State var webviewTitle: String? = nil
    
    var body: some View {
        Section(header: Text(LocalizedStringKey("ABOUT"))) {
            VStack(alignment: .leading) {
                Text(LocalizedStringKey("Version"))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Text(
                    String("\(Bundle.main.infoDictionary!["CFBundleShortVersionString"]!)") +
                    String(" (Build \(Bundle.main.infoDictionary!["CFBundleVersion"]!))")
                )
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Button(action: {
                url = CCIPWebsiteURL
                isShowingSafari.toggle()
                //maybe add title? But don't know how to deal with LocalizedStringKey
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("OfficialWebsite"))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text(CCIPWebsiteURL.absoluteString)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image("external-link")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .frame(width: UIScreen.main.bounds.width * 0.045)
                }
            }
            
            Button(action: {
                url = CCIPGitHubURL
                isShowingSafari.toggle()
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("GitHub")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text(CCIPGitHubURL.absoluteString)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image("external-link")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .frame(width: UIScreen.main.bounds.width * 0.045)
                }
            }
            
            Button(action: {
                url = CCIPPolicyURL
                isShowingSafari.toggle()
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("PrivacyPolicy"))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text(CCIPPolicyURL.absoluteString)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image("external-link")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .frame(width: UIScreen.main.bounds.width * 0.045)
                }
            }
        }
        .background {
            NavigationLink(
                isActive: $isShowingSafari,
                destination: { Webview(url: url, title: webviewTitle) }
            ) {
                EmptyView()
            }.hidden()
        }
    }
}

fileprivate struct DeveloperSection: View {
    var body: some View {
        Section(header: Text("DEVELOPER")) {
            NavigationLink(destination: DeveloperOptionView()) {
                Image(systemName: "hammer")
                Text("Developer Option")
            }
        }
    }
}

fileprivate struct DeveloperOptionView: View {
    
    private var keyStore = NSUbiquitousKeyValueStore()
    @EnvironmentObject var OPassAPI: OPassAPIViewModel
    @State var isDebug = false
    
    var body: some View {
        Form {
            Button(action: {
                keyStore.synchronize()
                keyStore.removeObject(forKey: "EventAPI")
            }) {
                Label("Clear Cache Data", systemImage: "trash")
            }
        }
        .navigationTitle("Developer Option")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
#endif
