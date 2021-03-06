//
//  SuccessSchema.swift
//  Niceter
//
//  Created by uuttff8 on 3/29/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import Foundation

@frozen
public struct SuccessSchema: Codable {
    let success: Bool
}

@frozen
public struct ErrorSchema: Codable {
    let error: String
}
