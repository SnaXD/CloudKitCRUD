//
//  CloudkitUser.swift
//  CloudKitTesting
//
//  Created by Jonathan T. Nielsen on 24/03/2022.
//

import SwiftUI
import CloudKit

class CloudkitUserViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var error = ""
    @Published var userName = ""
    @Published var permissionStatus = false
    init(){
        getiCloudStatus()
        requestPermission()
        fetchIcloudUserRecordId()
    }
    private func getiCloudStatus(){
        CKContainer.default().accountStatus { returnedStatus, returnedError in
            DispatchQueue.main.async {
                switch returnedStatus {
                case .couldNotDetermine:
                    self.error = "could not dertermine"
                case .available:
                    self.isSignedIn.toggle()
                    self.error = "it is available lul"
                case .restricted:
                    self.error = "restriced"
                case .noAccount:
                    self.error = "no account"
                case .temporarilyUnavailable:
                    self.error = "temporarly unavailable"
                default:
                    self.error = "icloud unknown"
                }
            }
        }
    }
    func requestPermission(){
        CKContainer.default().requestApplicationPermission([.userDiscoverability]) { returnedStatus, returnedError in
            DispatchQueue.main.async {
                if returnedStatus == .granted{
                    self.permissionStatus = true
                }
            }
        }
    }
    func fetchIcloudUserRecordId(){
        CKContainer.default().fetchUserRecordID { returnedId, returnedError in
            if let id = returnedId {
                self.discoveriCloudUser(id: id)
            }
        }
    }
    func discoveriCloudUser(id: CKRecord.ID) {
        CKContainer.default().discoverUserIdentity(withUserRecordID: id) { returnedIdentitiy, returnedError in
            if let name = returnedIdentitiy?.nameComponents?.givenName {
                self.userName = name
            }
        }
    }
}

struct CloudkitUser: View {
    @StateObject private var vm = CloudkitUserViewModel()
    var body: some View {
        VStack{
            Text("is signed in: \(vm.isSignedIn.description)")
            Text(vm.error)
            Text("permission: \(String(vm.permissionStatus))")
            Text("name: \(vm.userName)")
        }
    }
}

struct CloudkitUser_Previews: PreviewProvider {
    static var previews: some View {
        CloudkitUser()
    }
}
