//: [Previous](@previous)

//: ## Conclusion of this funny experiment

//: No doubt, implement by enum is so quickly, thanks to the powerful Swift Enum type. But when you think of the future (if it's a real case =_=), the grow of the scale of LangValue, you may think it will eventually be a mess. I guess this is why most of us will come to the protocol solution.
//:
//: ----
//:
//: I should admit that the first time I tried to construct my protocol solution made me a little frustrated. That time I had only a protocol **LangValue** and made it conform by **Int**, **String**, **Dictionary**. When I come to the last line of the test code, I saw, oh I need a **Set** of type **LangValue** but **LangValue** isn't conform to **Hashable**. So I try to put the **Hashable** to the **LangValue** like a flash. Then the whole problem began. We knew that a protocol has an associate type is not a typical type anymore. There are so many limitation there. You can't use it directly as a constraint type in anywhere, you might want a generic function to use it. In most of the other cases, like what we do everyday, it works well, but if we haven't pepared at the very begining, the changging of it's behavior will increase so many work load. So sometime it acts not so convenience to us. Especially in the LangValue case, it communicate with the protocol type self a lot, if we want it to be the the central of our type system, if it fail to be used as a type constraint in many case, it matter.

//: Example:
//:
//: ----
//:
//: In many case, you may like to have the following protocol
protocol Languages{
    var words:String {get set}
    var name: String {get}
    func translate(from words:Languages) -> String
    init(str:String)
}

//: You will like to use it in every language you declare:
struct English:Languages{
    var words:String
    let name: String = "English"
    init(str:String){
        self.words = str
    }
    func translate(from words: Languages) -> String{
        // some translation code
        return words.words
    }
}
struct Japanese:Languages {
    var words:String
    let name: String = "Japanese"
    init(str:String){
        self.words = str
    }
    func translate(from words: Languages) -> String {
        // some translation code
        return words.words
    }

}
//: And some how you think compare the languages with other is a good idea:

protocol ComparableLanguages:Languages,Equatable{
    static func Languages<T:ComparableLanguages>(words:String) -> T
}

func == <T:ComparableLanguages>(lhs:T,rhs:T) -> Bool{
    return lhs.words == rhs.words
}

extension English:ComparableLanguages{
    static func Languages<T:ComparableLanguages>(words:String) -> T{
        return English(str: words) as! T
    }
}
extension Japanese:ComparableLanguages{
    static func Languages<T:ComparableLanguages>(words:String) -> T{
        return Japanese(str: words) as! T
    }
}

//: Not a big deal, hah.
//:
//: ----
//:
//: Ok, let's dig deeper. First in-comment the following code.

//extension Languages{
//    func join(words:Languages) -> Languages{
//        return words
//    }
//}
//
//var a = English(str: "Hello")
//var b = Japanese(str: "Ohayo")
//a.join(b) == a.join(b)

//: You might say, because we declare **Equatable** only on **ComparableLanguages** , so the return type of the function *wordsFrom(_:)->Languages* can't be compared is so obviously. You are right, let's do it again.

extension ComparableLanguages{
    func join<T:ComparableLanguages>(words:T) -> T{
        return words
    }
}
var a = English(str: "Hello")
var b = Japanese(str: "Ohayo")
a.join(b) == a.join(b)

//: It works! But what if...

//extension ComparableLanguages{
//    static func wordsInLanguage(of number:Int) -> Self{
//        return Self(str: "\(number)")
//    }
//}
//
//var c = English.wordsInLanguage(of: 42)
//var d = Japanese.wordsInLanguage(of: 94)
//c == d

//: You might think the following code will do the magic:
//extension ComparableLanguages{
//    static func wordsInLanguage<T:ComparableLanguages>(of number:Int) -> T{
//        return T(str: "\(number)")
//    }
//}
//
//var c = English.wordsInLanguage(of: 42)
//var d = Japanese.wordsInLanguage(of: 94)
//c == d
//: But it doesn't.

//: Not even this will work:

//extension ComparableLanguages{
//    static func wordsInLanguage<T:ComparableLanguages>(of number:Int,t:T.Type) -> T{
//        return T.Languages("\(number)")
//    }
//}
//
//var c = English.wordsInLanguage(of: 42,t:English.self)
//var d = Japanese.wordsInLanguage(of: 94,t:Japanese.self)
//c == d

//: Once you need a associate type in a protocol, thing get more complicated.
//:
//: ----
//:
//: What I have to say is, it's not actually a big deal. To me, protocol is used for put limitation in my code, and to make possible everything is under control(At less we wish...). If it works as what it is, solid.
//:
//: ----
//:
//: We should realise when a *protocol* has it's own associate type, it acts liked a generic type indeed. And the type refer to the implement type itself should be treat as a generic type also. An implementation of the protocol in a type, it's the type itself. This is the fact.
//:
//: ----
//:
//: That's why the protocol solution of this question is to declare a protocol to tell what it can do and for responsibility of the type management, it pass to a struct to do. Although, the author had said in his other post that he doesn't like the solution with a type system like this because it will make the hierarchy tree more complicate, but I will still like to say, 'no,it doesn't.' You can still extend your functionality in the protocol, just don't touch the final struct if you would like to keep it simple.
//:
//: ----
//:
//: Just remember the protocol system in Swift is strong enough I guess, but it's still just a protocol...

protocol AlientLanguages:Equatable{
    var words:String {get set}
    var planet:String {get}
    func translate(from words:Languages) -> String
    init(str:String,planet:String)
}

extension AlientLanguages{
    func voice(of words:Self) {
        //bababa
    }
}

func == <T:AlientLanguages>(lhs:T,rhs:T) -> Bool{
    return lhs.words == rhs.words
}

extension AlientLanguages{
    func join<T:AlientLanguages>(words:T) -> T{
        return words
    }
}
struct TheAlientLanguage:AlientLanguages{
    var words:String
    let planet:String
    init(str:String,planet:String){
        self.words = str
        self.planet = planet
    }
    func translate(from words:Languages) -> String{
        return words.words
    }
}

var human = TheAlientLanguage(str: "Hello", planet: "Earth")
var alient = TheAlientLanguage(str: "#%@#$%^", planet: "D7689")

//: [Next](@next)
