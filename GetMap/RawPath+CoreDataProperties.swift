//
//  RawPath+CoreDataProperties.swift
//  GetMap
//
//  Created by wanruuu on 7/11/2020.
//
//

import Foundation
import CoreData
import CoreLocation

extension RawPath {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RawPath> {
        return NSFetchRequest<RawPath>(entityName: "RawPath")
    }

    @NSManaged public var locations: [CLLocation]

}

extension RawPath : Identifiable {

}
