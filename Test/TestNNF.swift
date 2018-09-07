//
//  TestNNF.swift
//  hplar
//
//  Created by Nicholas Matsakis on 9/7/18.
//  Copyright © 2018 Nicholas Matsakis. All rights reserved.
//

import XCTest

class TestNNF: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        let p = Formula.Atom("p");
        let q = Formula.Atom("q");
        let r = Formula.Atom("r");
        let s = Formula.Atom("s");
        let fm = p.iff(q).iff(r.implies(s).not());
        let fm1 = fm.nnf();
        XCTAssertEqual(String(describing: fm1), "(p && q || ~p && ~q) && r && ~s || (p && ~q || ~p && q) && (~r || s)")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
