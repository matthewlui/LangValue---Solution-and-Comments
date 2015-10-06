//: [Previous](@previous)

//: ## Impletment With Enum
//: 
//: ----
//: 
//: **Please check swift version if recieve any error**
import Foundation

enum LangValueError:ErrorType{
    case LangCoercionError
}

enum LangValue{
    enum Type{
        case Integer
        case String
        case Table
    }
    case LangInteger(Int)
    case LangString(String)
    case LangTable([String:LangValue])
    
    var type:Type{
        switch self{
        case .LangInteger(_): return Type.Integer
        case .LangString(_) : return Type.String
        case .LangTable(_)  : return Type.Table
        }
    }
    
    func combine(b:LangValue) -> LangValue{
        return .LangTable([String:LangValue]())
    }
    func integerValue() throws -> Int{
        switch self{
        case let .LangInteger(value):
            return value
        case let .LangString(value):
            guard let intValue = Int(value) else {
                return 0
            }
            return intValue
        default :
            throw LangValueError.LangCoercionError
        }
    }
    func stringValue() throws -> String{
        switch self{
        case let .LangInteger(value):
            return "\(value)"
        case let .LangString(value):
            return value
        default :
            throw LangValueError.LangCoercionError
        }
    }
    func tableValue() throws -> [String:LangValue]{
        switch self{
        case let .LangTable(value):
            return value
        default :
            throw LangValueError.LangCoercionError
        }
    }
    
    mutating func setObjectForKey(object: LangValue,_ key: String) throws{
        guard case var .LangTable(value) = self else{
            throw LangValueError.LangCoercionError
        }
        value[key] = object
        self = .LangTable(value)
    }
    
    mutating func removeObjectForKey(key: String) throws{
        guard case var .LangTable(value) = self else{
            throw LangValueError.LangCoercionError
        }
        value.removeValueForKey(key)
        self = .LangTable(value)
    }
    
    func objectForKey(key: String) throws -> LangValue?{
        guard case var .LangTable(value) = self else{
            throw LangValueError.LangCoercionError
        }
        return value[key]
    }
    
    func keys() throws -> [String]{
        guard case let .LangTable(value) = self else{
            throw LangValueError.LangCoercionError
        }
        return value.map({ (E) -> String in
            return E.0
        })
    }
    func valueByAddingValue(value:LangValue) throws -> LangValue{
        guard let sum = self + value else{
            throw LangValueError.LangCoercionError
        }
        return sum
    }
}
func LangValueWithString(value:String) -> LangValue{
    return LangValue.LangString(value)
}
func LangValueWithInteger(value:Int) -> LangValue{
    return LangValue.LangInteger(value)
}
func LangValueTable()->LangValue{
    return LangValue.LangTable([String : LangValue]())
}
func + (lhsOptional:LangValue?,rhsOptional:LangValue?) -> LangValue?{
    guard let lhs = lhsOptional else{
        guard let _ = rhsOptional else{
            return nil
        }
        return nil
    }
    guard let rhs = rhsOptional else{
        return nil
    }
    switch (lhs,rhs){
    case let (.LangInteger(lValur),.LangInteger(rValue)):
        return .LangInteger(lValur + rValue)
    case (.LangString ,.LangInteger): fallthrough
    case (.LangInteger,.LangString): fallthrough
    case (.LangString,.LangString):
        return try! .LangString(lhs.stringValue() + rhs.stringValue())
    default :
        return nil
    }
    
}

//: Test provide by original [link](http://inessential.com/langvalue)
let s = LangValueWithString("This is a string")
let n = LangValueWithInteger(42)
let someValues = [s, n]

func addIntegerValuesInArray(values: [LangValue]) -> LangValue {
    return values.reduce(LangValue.LangInteger(0), combine: { (pre, current) -> LangValue in
        if case .LangInteger = current {
            guard let value = pre + current else{
                return pre
            }
            return value
        }
        return pre
    })
}
func addStringValuesInArray(values: [LangValue]) -> LangValue {
    return values.reduce(LangValue.LangString(""), combine: { (pre, current) -> LangValue in
        guard let value = pre + current else{
            return pre
        }
        return value
    })
}

let intResult = addIntegerValuesInArray(someValues)
assert(try! intResult.integerValue() == 42)

let stringResult = addStringValuesInArray(someValues)
assert(try! stringResult.stringValue() == "This is a string42")

let unknownResult = try! s.valueByAddingValue(n)
assert(unknownResult.type == .String)

var t = LangValueTable()
try! t.setObjectForKey(LangValueWithInteger(10), "SomeInt")
let someString = LangValueWithString("Some string")
try! t.setObjectForKey(someString, "SomeString")

var subtable = LangValueTable()
try! subtable.setObjectForKey(LangValueWithInteger(50), "SubtableInt")
let anotherString = LangValueWithString("Another string")
try! subtable.setObjectForKey(anotherString, "SubtableString")
try! t.setObjectForKey(subtable, "Subtable")

func == (lhs:LangValue,rhs:LangValue) -> Bool{
    if lhs.type != rhs.type {
        return false
    }
    return lhs.hashValue == rhs.hashValue
}
extension LangValue:Hashable{
    var hashValue:Int{
        switch self{
        case .LangInteger(let value):
            return value.hashValue
        case .LangString(let value):
            return value.hashValue
        case .LangTable:
            return try! self.keys().reduce("", combine: { (pre, cur) -> String in
                return pre + cur
            }).hashValue
        }
    }
}
try! t.tableValue()
func recursiveSetOfStringsInTable(table: LangValue) -> Set<LangValue> {
    // Get all LangValueType.String objects from a table and its subtables and return them as a Swift set.
    do {
        let tableValue = try table.tableValue()
        return tableValue.reduce(Set<LangValue>(), combine: { (pre, cur) -> Set<LangValue> in
            if cur.1.type == .String{
                var mutable = pre
                mutable.insert(cur.1)
                return mutable
            }
            if cur.1.type == .Table{
                let set = recursiveSetOfStringsInTable(cur.1)
                return set.union(pre)
            }
            return pre
        })
    }catch _{
        
    }
    return Set<LangValue>()
}
let setOfStrings = recursiveSetOfStringsInTable(t)
assert(setOfStrings == Set([someString,anotherString]))

