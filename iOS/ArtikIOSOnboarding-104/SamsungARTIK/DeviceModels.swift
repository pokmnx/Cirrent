//
//  DeviceModels.swift
//  SamsungARTIK
//
//  Created by Vaibhav Singh on 13/03/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import Foundation
import CoreData
import ArtikCloud

public class DeviceManifest: NSManagedObject {
    
    @NSManaged var properties: ACFieldsActions?
    
}

public class DeviceSnapshot : NSManagedObject {
    
    @NSManaged var snapshot : ACSnapshotResponse?    
}


