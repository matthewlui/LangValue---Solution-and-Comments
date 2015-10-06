//: [Previous](@previous)

import Foundation

//:Convenience Extension to reduce code
extension Int{
    init<T:LangValueCore>(_ lang:T){
        switch lang.type{
        case .Integer:
            self = lang.value as! Int
        case .String:
            guard let intValue = Int(lang as! String) else{
                self = 0
                return
            }
            self = intValue
        default:
            self = 0
        }
    }
}

extension String{
    init<T:LangValueCore>(lang:T){
        switch lang.type{
        case .Integer:
            self = String(lang.value as! Int)
        case .String:
            self = String(lang.value)
        default:
            self = ""
        }
    }
}

//: Type Require by LangValue
enum LangValueError:ErrorType{
    case LangCoercionError
}

enum LangValueType{
    case String
    case Integer
    case Table
    case notValidLangValueTable
}
//: The LangValue impletmentation.
protocol LangValueCore:Hashable{
    
    var type        :LangValueType {get}
    var value       :Any {get}
    
    func integerValue() throws -> Int
    func stringValue() throws -> String
    func tableValue() throws -> [String:Self]
    
    //Basic function of LangValue
    func valueByAddingValue(value:Self) throws -> Self
    
    //Fucntionality of LangValue as a Table
    //Impletment by Type to protect internal value's imutability
    mutating func setObjectForKey(object: Self,_ key: String) throws
    //Impletment by Type to protect internal value's imutability
    mutating func removeObjectForKey(key: String) throws
    func objectForKey(key: String) throws -> Self?
    func keys() throws -> [String]

    
    init(value:String)
    init(value:Int)
    init(value:[String:Self])
    
}

extension LangValueCore{
    
    var type:LangValueType{
        if let _ = value as? Int{
            return .Integer
        }
        if let _ = value as? String{
            return .String
        }
        if let _ = value as? [String:LangValue]{
            return .Table
        }
        return LangValueType.notValidLangValueTable
    }
    
    func integerValue() throws -> Int {
        switch self.type{
        case .Integer:
            return Int(self)
        case .String:
            return Int(self)
        default:
            throw LangValueError.LangCoercionError
        }
    }
    
    func stringValue() throws -> String {
        switch self.type{
        case .Integer:
            return String(lang:self)
        case .String:
            return String(lang:self)
        default:
            throw LangValueError.LangCoercionError
        }
    }
    
    func tableValue() throws -> [String:Self]{
        switch self.type{
        case .Table:
            return self.value as! [String:Self]
        default:
            throw LangValueError.LangCoercionError
        }
    }
    
    func valueByAddingValue(value: Self) throws -> Self {
        switch (self.type,value.type){
        case (.Table,_),(.notValidLangValueTable,_):fallthrough
        case (_,.Table),(_,.notValidLangValueTable):
            throw LangValueError.LangCoercionError
        case (.Integer,.Integer):
            return try! Self(value: self.integerValue() + value.integerValue())
            
        case (.String,_): fallthrough
        case (_,.String):
            return try! Self(value: self.stringValue() + value.stringValue())
        default:
            throw LangValueError.LangCoercionError
        }
    }
    
    func objectForKey(key: String) throws -> Self?{
        if type == .Table{
            return (self.value as! [String:Self])[key]
        }
        throw LangValueError.LangCoercionError
    }
    
    func keys() throws -> [String]{
        if type == .Table{
            return (self.value as! [String:Self]).map({ (ele) -> String in
                return ele.0
            })
        }
        throw LangValueError.LangCoercionError
    }
    
}

extension LangValueCore{
    var hashValue:Int{
        switch type{
        case .Integer:
            return (value as! Int).hashValue
        case .String:
            return (value as! String).hashValue
        case .Table:
            return (self.value as! [String:Self]).keys.reduce("", combine: { (pre, cur) -> String in
                return pre + cur
            }).hashValue
        default :
            return 0
        }
    }
}

func == <T:LangValueCore>(lhs:T,rhs:T) -> Bool{
    if lhs.type != rhs.type{
        return false
    }
    return lhs.hashValue == rhs.hashValue
}

struct LangValue:LangValueCore{
    
    var value:Any {
        return _value
    }
    private var _value:Any
    static func LangWith(str:String) -> LangValue{
        return LangValue(value: str)
    }
    static func LangWith(int:Int) -> LangValue{
        return LangValue(value: int)
    }
    mutating func setObjectForKey(object: LangValue,_ key: String) throws{
        if type == .Table{
            var mutable = self.value as! [String:LangValue]
            mutable[key] = object
            return self._value = mutable
        }
        throw LangValueError.LangCoercionError
    }
    
    mutating func removeObjectForKey(key: String) throws{
        if type == .Table{
            var mutable = self.value as! [String:LangValue]
            mutable.removeValueForKey(key)
            return self._value = mutable
        }
        throw LangValueError.LangCoercionError
    }
    init(value: String) {
        self._value = value
    }
    init(value: Int) {
        self._value = value
    }
    init(value: [String : LangValue]) {
        self._value = value
    }
}

func LangValueWithString(str:String) -> LangValue{
    return LangValue(value: str)
}
func LangValueWithInteger(int:Int) -> LangValue{
    return LangValue(value: int)
}
func LangValueTable() -> LangValue{
    return LangValue(value: Dictionary<String,LangValue>())
}

let s = LangValueWithString("This is a string")
let n = LangValueWithInteger(42)
let someValues = [s, n]

func addIntegerValuesInArray(values: [LangValue]) -> LangValue {
    // Return LangValueType.Integer object
    return values.reduce(LangValue(value:0), combine: { (pre, cur) -> LangValue in
        if cur.type == .Integer {
            do {
                return try pre.valueByAddingValue(cur)
            }catch _{
                return pre
            }
        }
        return pre
    })
}

func addStringValuesInArray(values: [LangValue]) -> LangValue {
    // Return LangValueType.String object
    return values.reduce(LangValue(value:""), combine: { (pre, cur) -> LangValue in
        do {
            return try pre.valueByAddingValue(cur)
        }catch _{
            return pre
        }
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

func recursiveSetOfStringsInTable(table:LangValue) -> Set<LangValue> {
    do{
        return try table.tableValue().reduce(Set<LangValue>(), combine: { (pre, cur) -> Set<LangValue> in
            if cur.1.type == .String{
                var mutable = pre
                mutable.insert(cur.1)
                return mutable
            }
            if cur.1.type == .Table{
                return pre.union(recursiveSetOfStringsInTable(cur.1))
            }
            return pre
        })
    }catch _ {
        
    }
    return Set<LangValue>()
}

let setOfStrings = recursiveSetOfStringsInTable(t)
assert(setOfStrings == Set([someString, anotherString]))


//: [Next](@next)
