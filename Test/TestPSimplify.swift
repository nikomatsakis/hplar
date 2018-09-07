//
//  Test.swift
//  TestPSimplify
//
//  Created by Nicholas Matsakis on 9/4/18.
//  Copyright © 2018 Nicholas Matsakis. All rights reserved.
//

import XCTest

class TestPSimplify: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let f = Formula.Atom("x").implies(Formula.Atom("y")).implies(Formula.True).or(Formula.False.not());
        let g = f.psimplify();
        XCTAssert(g.eq_true())
    }

    func testTwo() {
        // probably *should* write that dang parser after all
        let f =
            Formula.True.implies(Formula.Atom(0).iff(Formula.False)).implies(
                Formula.Not(Formula.Atom(1).or(Formula.False.and(Formula.Atom(2)))));
        let g = f.psimplify();
        let h = String(describing: g);
        
        // ~0 ==> ~1 -- clearly we need to write a better pretty printer :)
        XCTAssertEqual(h, "~0 ==> ~1")
    }
}
