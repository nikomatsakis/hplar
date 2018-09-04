//
//  main.swift
//  hplar
//
//  Created by Nicholas Matsakis on 9/2/18.
//  Copyright © 2018 Nicholas Matsakis. All rights reserved.
//

import Foundation

let f: Formula<String> = Formula.False.and(Formula.True)
let g = f.map_atoms({ Formula.Atom($0) })
print(f)
print(g)

