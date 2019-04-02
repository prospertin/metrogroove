//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"
public class Child {
    var name:String!
}
public class example {
    var a:Int!
    public var arr:Array<Int>!
    var c:Child!
}

let v1 = example()
v1.a = 2
print(v1.a)
var xarr:Array<Int> = [1,2]
v1.arr = xarr
print(v1.arr)

xarr[1] = 3
print(xarr)
print(v1.arr)
v1.a = 9
print(v1.a)

var xc = Child()
xc.name = "Name1"
v1.c = xc
print(v1.c.name)

xc.name = "xxx"
print(v1.c.name)


func incrementAndSort(arr:Array<Int>) -> Array<Int> {
    var arr2 = Array<Int>()
    for i in 0..<arr.count {
        arr2.append(arr[i] + 1)
    }
    
    return arr2.sort(<)
}

func sort(arr:Array<Int>) -> Array<Int> {
    return arr.sort{$0<$1}
}
incrementAndSort([5,2,3,4])

var thing = "cars"

let closure = { [thing] in
    print("I love \(thing)")
}

thing = "airplanes"

let dict = ["Key" : "Hello", "Key2" : "Hello"]
print ("\(dict)")

//NSMutableDictionary()
//dict.setObject("Hello", forKey: "Key")
//dict.setObject("Hello2", forKey: "Key2")

func isBalance(parens: String) -> Bool{
    var left = 0;
    let ar = Array(parens.characters)
    for i in 0..<ar.count {
        if ar[i] == "(" {
            left += 1;
        } else if ar[i] == ")" {
            if left > 0 {
                left -= 1
            } else {
                return false
            }
        }
    }
    
    return left == 0;
}


func buildParens(size:Int, parens:String) {
    if parens.characters.count == size * 2{
        if isBalance(parens) {
            print(parens)
        }
        return;
    }
    
    buildParens(size, parens: "\(parens)(");
    buildParens(size, parens: "\(parens))");
}

buildParens(5, parens: "")

 print("Hello there")

func pp(s:String, o: Int, c: Int, n: Int){
    if(o == n && c == n) {
       print(s)
    }
    if(o < n) {
        pp( "\(s)(", o: o+1, c: c, n: n);
    }
    if(c < o) {
        pp( "\(s))", o: o, c: c+1, n: n);
    }
}

pp("", o:0, c:0, n: 5)
