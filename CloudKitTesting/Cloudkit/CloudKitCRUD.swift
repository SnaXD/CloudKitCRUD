//
//  CloudKitCRUD.swift
//  CloudKitTesting
//
//  Created by Jonathan T. Nielsen on 25/03/2022.
//

import SwiftUI
import CloudKit

struct fruitModel: Hashable{
    let name: String
    let imageURL: URL?
    let record: CKRecord
}

class cloudkitCRUDViewModel: ObservableObject{
    @Published var text: String = ""
    @Published var fruits: [fruitModel] = []
    
    init(){
        fetchItems()
    }
    
    func addButtonPressed(){
        guard !text.isEmpty else { return }
        addItem(name: text)
    }
    func addItem(name: String){
        let newFruit = CKRecord(recordType: "Fruits")
        newFruit["name"] = name
        
        guard let image = UIImage(named: "251239997_10226265072154641_4626950811026994616_n"), let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("fruitImage.jgp"), let data = image.jpegData(compressionQuality: 1.0) else {return }
        
        do {
            try data.write(to: url)
            let asset = CKAsset(fileURL: url)
             newFruit["image"] = asset
            
            saveItem(record: newFruit)
        } catch let error {
            print(error)
        }
       
        
    }
    func fetchItems(){
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Fruits", predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        var returnedItems: [fruitModel] = []
        queryOperation.queryResultBlock = { returnedResult in
            print("Returned result \(returnedResult)")
            DispatchQueue.main.async {
                self.fruits = returnedItems
            }
        }
        queryOperation.recordMatchedBlock = {(returnedRecordID, returnedResult) in
            switch returnedResult{
            case .success(let record):
                guard let name = record["name"] as? String else { return }
                let imageAsset = record["image"] as? CKAsset
                let imageURL = imageAsset?.fileURL
                returnedItems.append(fruitModel(name: name, imageURL: imageURL, record: record))
            case .failure(let error):
                print("error: \(error)")
            }
        }
        addOperation(operation: queryOperation)
    }
    
    func addOperation(operation: CKDatabaseOperation){
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    
    private func saveItem(record: CKRecord){
        CKContainer.default().publicCloudDatabase.save(record) { returnedRecord, returnedError in
            print("returned record: \(returnedRecord)")
            print("returned error: \(returnedError)")
            DispatchQueue.main.async {
                self.text = ""
                self.fetchItems()
            }
        }
    }
    func updateItems(fruit: fruitModel){
        let record = fruit.record
        record["name"] = fruit.name + " !"
        saveItem(record: record)
    }
    func deleteItem(indexSet: IndexSet){
        guard let index = indexSet.first else { return }
        let fruit = fruits[index]
        let record = fruit.record
        CKContainer.default().publicCloudDatabase.delete(withRecordID: record.recordID) { returnedRecordId, returnedError in
            DispatchQueue.main.async {
                self.fruits.remove(at: index)
            }
        }
    }
}

struct CloudKitCRUD: View {
    
    @ObservedObject var vm = cloudkitCRUDViewModel()
    
    var body: some View {
        VStack{
            TextField("tekst", text: $vm.text)
            Button {
                vm.addButtonPressed()
            } label: {
                Text("Add")
            }
            List{
                ForEach(vm.fruits, id: \.self) { fruit in
                    HStack{
                    Text(fruit.name)
                        if let url = fruit.imageURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 50, height: 50)
                        }
                    }
                        .onTapGesture {
                            vm.updateItems(fruit: fruit)
                        }
                }.onDelete(perform: vm.deleteItem)
            }
        }
    }
}

struct CloudKitCRUD_Previews: PreviewProvider {
    static var previews: some View {
        CloudKitCRUD()
    }
}
