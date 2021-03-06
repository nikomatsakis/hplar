//
//  propositional_logic.swift
//  hplar
//
//  Created by Nicholas Matsakis on 9/2/18.
//  Copyright © 2018 Nicholas Matsakis. All rights reserved.
//

import Foundation

indirect enum Formula<A: Equatable>: CustomStringConvertible {
    case False
    case True
    case Atom(A)
    case Not(Formula<A>)
    case Binary(Operator, Formula<A>, Formula<A>)
    case Quantified(Quantifier, Name, Formula<A>)
    
    func map_atoms<B>(_ f: (A) -> Formula<B>) -> Formula<B> {
        switch self {
        case .False:
            return Formula<B>.False
        case .True:
            return Formula<B>.True
        case .Atom(let a):
            return f(a)
        case .Not(let formula):
            return Formula<B>.Not(formula.map_atoms(f))
        case .Binary(let op, let left, let right):
            return Formula<B>.Binary(op, left.map_atoms(f), right.map_atoms(f))
        case .Quantified(let q, let n, let formula):
            return Formula<B>.Quantified(q, n, formula.map_atoms(f))
        }
    }
    
    static func t() -> Formula<A> {
        return Formula.True
    }

    static func f() -> Formula<A> {
        return Formula.False
    }

    static func atom(_ a: A) -> Formula<A> {
        return Formula.Atom(a)
    }
    
    func not() -> Formula<A> {
        return Formula.Not(self)
    }
    
    func negate() -> Formula<A> {
        switch self {
        case .Not(let f):
            return f
        default:
            return Formula.Not(self)
        }
    }
    
    func with(_ op: Operator, _ rhs: Formula<A>) -> Formula<A> {
        return Formula.Binary(op, self, rhs)
    }

    func and(_ rhs: Formula<A>) -> Formula<A> {
        return self.with(Operator.And, rhs)
    }
    
    func or(_ rhs: Formula<A>) -> Formula<A> {
        return self.with(Operator.Or, rhs)
    }
    
    func implies(_ rhs: Formula<A>) -> Formula<A> {
        return self.with(Operator.Implies, rhs)
    }
    
    func iff(_ rhs: Formula<A>) -> Formula<A> {
        return self.with(Operator.Iff, rhs)
    }
    
    func eval(_ valuation: (A) -> Bool) -> Bool {
        switch self {
        case .False:
            return false
        case .True:
            return true
        case .Atom(let a):
            return valuation(a)
        case .Not(let f):
            return !f.eval(valuation)
        case .Binary(let op, let left, let right):
            return op.eval({ () in left.eval(valuation) }, { () in right.eval(valuation) })
        case .Quantified(_, _, _):
            fatalError("unimplemented")
        }
    }
    
    func fold_atoms<B>(_ value: B, _ f: (B, A) -> B) -> B {
        switch self {
        case .False, .True:
            return value
        case .Atom(let a):
            return f(value, a)
        case.Not(let formula):
            return formula.fold_atoms(value, f)
        case .Quantified(_, _, let subformula):
            return subformula.fold_atoms(value, f)
        case .Binary(_, let left, let right):
            let value1 = left.fold_atoms(value, f)
            return right.fold_atoms(value1, f)
        }
    }
    
    func bottom_up(_ op: (Formula<A>) -> Formula<A>) -> Formula<A> {
        switch self {
        case .Not(let formula):
            return op(.Not(formula.bottom_up(op)))
        case .Binary(let oper, let left, let right):
            return op(.Binary(oper, left.bottom_up(op), right.bottom_up(op)))
        case .Quantified(let q, let name, let formula):
            return op(.Quantified(q, name, formula))
        case .Atom(_), .False, .True:
            return op(self)
        }
    }
    
    func psimplify1() -> Formula<A> {
        switch self {
        case .Not(.False):
            return Formula.True
        case .Not(.True):
            return Formula.False
        case .Not(.Not(let p)):
            return p
        case .Binary(Operator.And, _, .False),
             .Binary(Operator.And, .False, _):
            return Formula.False
        case .Binary(Operator.Or, _, .True),
             .Binary(Operator.Or, .True, _):
            return Formula.True
        case .Binary(Operator.Or, let p, .False),
             .Binary(Operator.Or, .False, let p),
             .Binary(Operator.And, let p, .True),
             .Binary(Operator.And, .True, let p):
            return p
        case .Binary(Operator.Implies, .False, _),
             .Binary(Operator.Implies, _, .True):
            return Formula.True
        case .Binary(Operator.Implies, .True, let p):
            return p
        case .Binary(Operator.Iff, let p, .True),
             .Binary(Operator.Iff, .True, let p):
            return p
        case .Binary(Operator.Iff, .False, let p),
             .Binary(Operator.Iff, let p, .False):
            return p.not()
        default:
            return self
        }
    }
    
    func psimplify() -> Formula {
        return self.bottom_up({ $0.psimplify1() })
    }
    
    func eq_true() -> Bool {
        switch self {
        case .True: return true
        default: return false
        }
    }
    
    private func nnf1() -> Formula<A> {
        switch self {
        case .Binary(.And, let p, let q):
            return p.nnf1().and(q.nnf1())
        case .Binary(.Or, let p, let q):
            return p.nnf1().or(q.nnf1())
        case .Binary(.Implies, let p, let q):
            return p.not().nnf1().or(q.nnf1())
        case .Binary(.Iff, let p, let q):
            return p.nnf1().and(q.nnf1()).or(p.not().nnf1().and(q.not().nnf1()))
        case .Not(.Not(let p)):
            return p.nnf1()
        case .Not(.Binary(.And, let p, let q)):
            return p.not().nnf1().or(q.not().nnf1())
        case .Not(.Binary(.Or, let p, let q)):
            return p.not().nnf1().and(q.not().nnf1())
        case .Not(.Binary(.Implies, let p, let q)):
            return p.nnf1().and(q.not().nnf1())
        case .Not(.Binary(.Iff, let p, let q)):
            return p.nnf1().and(q.not().nnf1()).or(p.not().nnf1().and(q.nnf1()))
        default:
            return self
        }
    }
    
    func nnf() -> Formula<A> {
        return self.psimplify().nnf1()
    }
    
    func to_string(_ precedence: Int) -> String {
        switch self {
        case .False:
            return "false"
        case .True:
            return "true"
        case .Atom(let a):
            return "\(a)"
        case .Not(let formula):
            return "~\(formula.to_string(precedence))"
        case .Binary(let op, let left, let right):
            let op_precedence = op.precedence();
            let s = "\(left.to_string(op_precedence)) \(op) \(right.to_string(op_precedence))";
            if op_precedence < precedence {
                return "(\(s))"
            }
            return s
        case .Quantified(let q, let n, let formula):
            return "\(q)<\(n)> \(formula.to_string(100))"
        }
    }
    
    var description: String {
        return self.to_string(0)
    }
}

enum Operator: CustomStringConvertible {
    case And
    case Or
    case Implies
    case Iff
    
    func combine<A>(_ lhs: Formula<A>, _ rhs: Formula<A>) -> Formula<A> {
        return lhs.with(self, rhs)
    }
    
    func eval(_ lhs: () -> Bool, _ rhs: () -> Bool) -> Bool {
        return false
    }
    
    var description: String {
        switch self {
        case .And: return "&&"
        case .Or: return "||"
        case .Implies: return "==>"
        case .Iff: return "<=>"
        }
    }
    
    func precedence() -> Int {
        switch self {
        case .And: return 1
        case .Or: return 0
        case .Implies: return 1
        case .Iff: return 1
        }
    }
}

enum Quantifier: CustomStringConvertible {
    case ForAll
    case Exists
    
    var description: String {
        switch self {
        case .ForAll: return "forall"
        case .Exists: return "exists"
        }
    }
}

struct Name {
    let name: String
}

struct Debruijn {
    let depth: Int
    
    /// Shifts this index "in" through a set of binders
    /// (hence incrementing it).
    func shifted_in() -> Debruijn {
        return Debruijn(depth: self.depth + 1)
    }

    /// Shifts this index "out" through a set of binders
    /// (hence decrementing it) -- not legal if this index
    /// represents the innermost set of binders.
    func shifted_out() -> Debruijn {
        assert(self.depth > 0)
        return Debruijn(depth: self.depth - 1)
    }
}
