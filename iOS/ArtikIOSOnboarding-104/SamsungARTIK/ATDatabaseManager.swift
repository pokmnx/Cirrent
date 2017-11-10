//
//  DatabaseManager.swift
//  CoreDataEx2
//
//  Created by Surendra on 12/8/16.
//  Copyright © 2016 Surendra. All rights reserved.
//

import Foundation
import CoreData
import ArtikCloud

class ATDatabaseManager {
    
    static var newId = "0"
    static let moduleClassName:String = String(describing: Module.self)
    static let deviceTypeClassName:String = String(describing: DeviceType.self)
    static let manifestClassName:String = String(describing: Manifest.self)
    static let messagesClassName:String = String(describing: Messages.self)

    class func getAllModules() -> [Module] {
        let fetchRequest: NSFetchRequest<Module> = Module.fetchRequest()
         
        do {
            let searchResults = try ATCoreDataStack.getContext().fetch(fetchRequest)
            return searchResults
        }
        catch {
            print("Error = \(error)")
        }
        
        return []
    }
    
    class func storeWithAutoIncrement(moduleDict: ACDevice) {
        
        let fetchRequest: NSFetchRequest<Module> = Module.fetchRequest()
        
        let idDescriptor: NSSortDescriptor = NSSortDescriptor(key: "sno", ascending: false, selector: #selector(NSString.localizedStandardCompare(_:)))
        fetchRequest.sortDescriptors = [idDescriptor]
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try ATCoreDataStack.getContext().fetch(fetchRequest)
            
            if results.count == 1 {
                newId = String(Int(results[0].sno!)! + 1)
            } else {
                newId = String(1)
            }
        } catch {
            print("Error = \(error as NSError)")
        }
        
        //Inserting
        let module: Module = NSEntityDescription.insertNewObject(forEntityName: moduleClassName, into: ATCoreDataStack.persistentContainer.viewContext) as! Module
        module.connected = String(describing: moduleDict.connected)
        module.createdOn = String(describing: moduleDict.createdOn)
        module.dtid = moduleDict.dtid as String
        module.id = moduleDict._id as String
        module.manifestVersion = moduleDict.manifestVersion as Int32
        module.manifestVersionPolicy = moduleDict.manifestVersionPolicy
        module.name = moduleDict.name as String
        module.needProviderAuth = String(describing: moduleDict.needProviderAuth)
        module.moduleLocation = ""
        module.sno = newId as String
        
        do {
            try ATCoreDataStack.getContext().save()
            print("Saved successfully.")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        ATCoreDataStack.saveContext()
    }
    
    class func insertDevice(moduleDict: ACDevice) {
        
        //Inserting
        let module: Module = NSEntityDescription.insertNewObject(forEntityName: moduleClassName, into: ATCoreDataStack.persistentContainer.viewContext) as! Module
        module.connected = String(describing: moduleDict.connected)
        module.createdOn = String(describing: moduleDict.createdOn)
        module.dtid = moduleDict.dtid as String
        module.id = moduleDict._id as String
        module.manifestVersion = moduleDict.manifestVersion as Int32
        module.manifestVersionPolicy = moduleDict.manifestVersionPolicy
        module.name = moduleDict.name as String
        module.needProviderAuth = String(describing: moduleDict.needProviderAuth)
        module.moduleLocation = ""
        
        do {
            try ATCoreDataStack.getContext().save()
           // print("Saved successfully.")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        ATCoreDataStack.saveContext()
    }

    class func updateDevicePresence(deviceId : String, lastSeen: Int64) {

        let fetchRequest: NSFetchRequest<Module> = Module.fetchRequest()

        let predicate = NSPredicate(format: "id = %@", deviceId)
        fetchRequest.predicate = predicate

        do {
            let searchResults = try ATCoreDataStack.getContext().fetch(fetchRequest)

            if (searchResults.count == 1) {

                let module = searchResults.first
                if ((module?.lastSeen)! < lastSeen) {
                    module?.lastSeen = lastSeen
                }
            }

        }
        catch {
            print("Error = \(error)")
        }

        do {
            try ATCoreDataStack.getContext().save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }

        ATCoreDataStack.saveContext()


    }
    
    
    class func filterModulesBy(module: String) -> [Module] {
        let fetchRequest: NSFetchRequest<Module> = Module.fetchRequest()
        
        let predicate = NSPredicate(format: "dtid = %@", module)
        fetchRequest.predicate = predicate
        
        do {
            let searchResults = try ATCoreDataStack.getContext().fetch(fetchRequest)
            return searchResults
        }
        catch {
            print("Error = \(error)")
        }
        return []
    }
    
    class func truncateEntity() -> Void {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Module.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        let deviceTypeFetchRequest: NSFetchRequest<NSFetchRequestResult> = DeviceType.fetchRequest()
        let deviceTypeDeleteRequest = NSBatchDeleteRequest(fetchRequest: deviceTypeFetchRequest)
        
        do {
            try ATCoreDataStack.getContext().execute(deleteRequest)
            try ATCoreDataStack.getContext().execute(deviceTypeDeleteRequest)
        }
        catch {
            print("Error = \(error)")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "table_truncated_notification"), object: nil)
    }
    
    class func deleteModulewith(id: String) -> Void {
        let managedContext = ATCoreDataStack.getContext()
        let fetchRequest: NSFetchRequest<Module> = Module.fetchRequest()
        
        let predicate = NSPredicate(format: "id = %@", id)
        fetchRequest.predicate = predicate
        
        if let result = try? managedContext.fetch(fetchRequest) {
            for object in result {
                managedContext.delete(object)
            }
        }
        
        do {
            try managedContext.save()
        } catch {
            print("Error = \(error)")
        }
    }
    
    class func insertDeviceType(deviceType : ACDeviceType) {
        
        let dtype: DeviceType = NSEntityDescription.insertNewObject(forEntityName: deviceTypeClassName, into: ATCoreDataStack.persistentContainer.viewContext) as! DeviceType
        //Inserting
        dtype.dtid = deviceType._id
        dtype.describe = deviceType._description
        dtype.name = deviceType.name
        dtype.cloudConnector = deviceType.hasCloudConnector.int16Value as Int16
        
        do {
            try ATCoreDataStack.getContext().save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        ATCoreDataStack.saveContext()
    
    }
    
    class func insertDeviceManifest(deviceTypeId: String, version: String, deviceManifest : ACManifestProperties) {
        
        let dManifest: Manifest = NSEntityDescription.insertNewObject(forEntityName: manifestClassName, into: ATCoreDataStack.persistentContainer.viewContext) as! Manifest
        //Inserting
        dManifest.dtid = deviceTypeId + "-" + version
        dManifest.version = version
        let properties = deviceManifest.properties.copy() as! ACFieldsActions
        dManifest.properties = properties
        //print("Actions Count \(properties.actions.count)")

        //print("Adding Device Manifest \(dManifest.dtid) with Actions Count \(properties.actions.count)")
        
        do {
            try ATCoreDataStack.getContext().save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        ATCoreDataStack.saveContext()
        
    }
    
    class func insertDeviceSnapshot(snapshotResponse : ACSnapshotResponse) {
        
        
        let fetchRequest: NSFetchRequest<Module> = Module.fetchRequest()
        
        let predicate = NSPredicate(format: "id = %@", snapshotResponse.sdid)
        fetchRequest.predicate = predicate
        
        do {
            let searchResults = try ATCoreDataStack.getContext().fetch(fetchRequest)
            
            if (searchResults.count == 1) {

                let module = searchResults.first
                module?.snapshot = snapshotResponse
            }
            
        }
        catch {
            print("Error = \(error)")
        }
        
        do {
            try ATCoreDataStack.getContext().save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        ATCoreDataStack.saveContext()
        
    }

    class func insertLastNormalizedMessage(response : ACNormalizedMessage) {


        let fetchRequest: NSFetchRequest<Messages> = Messages.fetchRequest()

        let predicate = NSPredicate(format: "mid = %@", response.mid)
        fetchRequest.predicate = predicate

        do {
            let searchResults = try ATCoreDataStack.getContext().fetch(fetchRequest)

            if (searchResults.count == 0) {
                let message: Messages = NSEntityDescription.insertNewObject(forEntityName: messagesClassName, into: ATCoreDataStack.persistentContainer.viewContext) as! Messages
                //Inserting
                message.mid = response.mid
                message.sdid = response.sdid
                message.ts = response.ts.int64Value as Int64
                message.data = response as AnyObject

            //   print("Message added for \(message.sdid) with mid as \(message.mid)")
            }
        }
        catch {
            print("Error = \(error)")
        }

        do {
            try ATCoreDataStack.getContext().save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }

        ATCoreDataStack.saveContext()
        
    }

    class func getLastNormalizedMessages(deviceId : String) -> [ACNormalizedMessage] {


        var messages = [ACNormalizedMessage]()
        let fetchRequest: NSFetchRequest<Messages> = Messages.fetchRequest()

        let sortDescriptor = NSSortDescriptor(key: "ts", ascending: false,
                                              selector: #selector(NSString.localizedStandardCompare(_:)))

        fetchRequest.sortDescriptors = [sortDescriptor]

        let predicate = NSPredicate(format: "sdid = %@", deviceId)
        fetchRequest.predicate = predicate

        do {
            let searchResults = try ATCoreDataStack.getContext().fetch(fetchRequest)

            for searchResult in searchResults {
                messages.append(searchResult.data as! ACNormalizedMessage)
            }

        }
        catch {
            print("Error = \(error)")
        }
        
        return messages
    }

    class func getDevice(deviceId : String) -> Module? {

        let fetchRequest: NSFetchRequest<Module> = Module.fetchRequest()

        let predicate = NSPredicate(format: "id = %@", deviceId)
        fetchRequest.predicate = predicate

        do {
            let searchResults = try ATCoreDataStack.getContext().fetch(fetchRequest)

            if (searchResults.count == 1) {
                return (searchResults.first)
            }
        }
        catch {
            print("Error = \(error)")
        }

        return nil
    }

    
    class func doesExistDeviceTypeInfo(deviceTypeId: String) -> Bool {
        let fetchRequest: NSFetchRequest<DeviceType> = DeviceType.fetchRequest()
        
        let predicate = NSPredicate(format: "dtid = %@", deviceTypeId)
        fetchRequest.predicate = predicate
        
        do {
            let searchResults = try ATCoreDataStack.getContext().fetch(fetchRequest)
            return searchResults.count > 0
        }
        catch {
            print("Error = \(error)")
        }
        return false
    }
    
    class func doesExistDeviceManifestInfo(deviceTypeId: String, version: String) -> Bool {
        let fetchRequest: NSFetchRequest<Manifest> = Manifest.fetchRequest()
        
        let dtid = deviceTypeId + "-" + version
        
        let predicate = NSPredicate(format: "dtid = %@", dtid)
        fetchRequest.predicate = predicate
        
        do {
            let searchResults = try ATCoreDataStack.getContext().fetch(fetchRequest)
            return searchResults.count > 0
        }
        catch {
            print("Error = \(error)")
        }
        return false
    }
    
    class func getDeviceManifest(deviceTypeId: String, version : String) -> ACFieldsActions? {
        let manifestId = deviceTypeId + "-" + version
        
        let fetchRequest: NSFetchRequest<Manifest> = Manifest.fetchRequest()
        
        let predicate = NSPredicate(format: "dtid = %@", manifestId)
        fetchRequest.predicate = predicate
        
        do {
            let searchResults = try ATCoreDataStack.getContext().fetch(fetchRequest)

            if (searchResults.count == 1) {
                return (searchResults.first?.properties as! ACFieldsActions?)
            }

        }
        catch {
            print("Error = \(error)")
        }
        return nil
        
    }

    class func getDeviceSnapshot(deviceId: String) -> ACSnapshotResponse? {

        let fetchRequest: NSFetchRequest<Module> = Module.fetchRequest()

        let predicate = NSPredicate(format: "id = %@", deviceId)
        fetchRequest.predicate = predicate

        do {
            let searchResults = try ATCoreDataStack.getContext().fetch(fetchRequest)

            if (searchResults.count == 1) {
                return (searchResults.first?.snapshot as! ACSnapshotResponse?)
            }
        }
        catch {
            print("Error = \(error)")
        }
        return nil
        
    }


    
    class func getAllDeviceType() -> [DeviceType] {
        
        let fetchRequest: NSFetchRequest<DeviceType> = DeviceType.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true,
                                              selector: #selector(NSString.caseInsensitiveCompare))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let searchResults = try ATCoreDataStack.getContext().fetch(fetchRequest)
            return searchResults
        }
        catch {
            print("Error = \(error)")
        }
        
        return []
    }
    
    class func getAllDeviceManifest() -> [Manifest] {
        
        let fetchRequest: NSFetchRequest<Manifest> = Manifest.fetchRequest()
        
        do {
            let searchResults = try ATCoreDataStack.getContext().fetch(fetchRequest)
            return searchResults
        }
        catch {
            print("Error = \(error)")
        }
        
        return []
    }
    

    
    class func getDeviceCount() -> Int{
        
        let fetchRequest: NSFetchRequest<Module> = Module.fetchRequest()
        
        do {
            let searchResults = try ATCoreDataStack.getContext().fetch(fetchRequest)
            return searchResults.count
        }
        catch {
            print("Error = \(error)")
        }
        return 0
    
    }
    
}
