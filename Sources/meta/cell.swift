//struct Point3D:CustomStringConvertible
//{
//    let x:Double,
//        y:Double,
//        z:Double
//
//    var r2:Double
//    {
//        return self.x*self.x + self.y*self.y + self.z*self.z
//    }
//
//    var description:String
//    {
//        guard let xb:Int = Int(exactly: self.x),
//              let yb:Int = Int(exactly: self.y),
//              let zb:Int = Int(exactly: self.z)
//        else
//        {
//            return "(\(self.x), \(self.y), \(self.z))"
//        }
//
//        return "(\(xb), \(yb), \(zb))"
//    }
//
//    init(_ x:Double, _ y:Double, _ z:Double)
//    {
//        self.x = x
//        self.y = y
//        self.z = z
//    }
//
//    init(_ x:Int, _ y:Int, _ z:Int)
//    {
//        self.x = Double(x)
//        self.y = Double(y)
//        self.z = Double(z)
//    }
//
//    static
//    func + (_ a:Point3D, _ b:Double) -> Point3D
//    {
//        return Point3D(a.x + b, a.y + b, a.z + b)
//    }
//
//    static
//    func + (_ a:Point3D, _ b:Point3D) -> Point3D
//    {
//        return Point3D(a.x + b.x, a.y + b.y, a.z + b.z)
//    }
//
//    static
//    prefix func - (_ a:Point3D) -> Point3D
//    {
//        return Point3D(-a.x, -a.y, -a.z)
//    }
//}
//
//struct Cell3D
//{
//    let root:Point3D
//
//    var min:Point3D
//    {
//        return self.root
//    }
//
//    var max:Point3D
//    {
//        return self.root + 1
//    }
//
//    init(_ point:Point3D)
//    {
//        self.root = point
//    }
//
//    func distance_squared(from point:Point3D) -> Double
//    {
//        let v:Point3D = Point3D(Swift.max(self.min.x - point.x, 0, point.x - self.max.x),
//                                Swift.max(self.min.y - point.y, 0, point.y - self.max.y),
//                                Swift.max(self.min.z - point.z, 0, point.z - self.max.z))
//        return v.r2
//    }
//}
//
//enum Colors
//{
//    static
//    let bold = "\u{001B}[1m",
//        green = "\u{001B}[0;32m",
//        green_bold = "\u{001B}[1;32m",
//
//        light_green = "\u{001B}[92m",
//        light_green_bold = "\u{001B}[1;92m",
//
//        light_cyan = "\u{001B}[96m",
//        light_cyan_bold = "\u{001B}[1;96m",
//
//        red = "\u{001B}[0;31m",
//        red_bold = "\u{001B}[1;31m",
//
//        pink_bold = "\u{001B}[1m\u{001B}[38;5;204m",
//
//        off = "\u{001B}[0m"
//}
//
//
//func kernel3d()
//{
//    let near:Point3D = Point3D(0.5, 0.5, 0.5)
//
//    var cell_classes:[Double: [Cell3D]] = [:]
//
//    for k in -3 ..< 3
//    {
//        for j in -3 ..< 3
//        {
//            for i in -3 ..< 3
//            {
//                let cell = Cell3D(Point3D(i, j, k))
//
//                var r2:Double = cell.distance_squared(from: near)
//                for point in [  Point3D(0, near.y, near.z),
//                                Point3D(near.x, 0, near.z),
//                                Point3D(near.x, near.y, 0),
//                                Point3D(0, 0, near.z),
//                                Point3D(near.x, 0, 0),
//                                Point3D(0, near.y, 0),
//                                Point3D(0, 0, 0)]
//                {
//                    r2 = min(r2, cell.distance_squared(from: point))
//                }
//
//                if cell_classes[r2]?.append(cell) == nil
//                {
//                    cell_classes[r2] = [cell]
//                }
//
//                var output:String = pad(String(r2), to: 5)
//
//                if r2 < 3
//                {
//                    output = Colors.red_bold + output + Colors.off
//                }
//
//                print(output, terminator: " ")
//            }
//            print()
//        }
//        print()
//    }
//
//    for r2:Double in cell_classes.keys.sorted()
//    {
//        let cells:[Cell3D] = cell_classes[r2]!
//        let class_vector:String = cells.reversed().map{ String(describing: $0.root) }.joined(separator: ", ")
//        //print("\(Colors.bold)\(pad(String(r2), to: 5))\(Colors.off): \(pad(String(cells.count), to: 2)) cells [\(class_vector)]")
//        print("(\(Colors.bold)\(pad(String(r2), to: 5))\(Colors.off), [\(class_vector)]),")
//    }
//}
//
//func pad(_ str:String, to n:Int) -> String
//{
//    return str + String(repeating: " ", count: max(0, n - str.count))
//}
//
//kernel3d()
