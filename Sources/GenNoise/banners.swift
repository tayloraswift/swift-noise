import Noise
import PNG

extension UInt8
{
    init<T>(clamping value:T) where T:BinaryFloatingPoint
    {
        self.init(Swift.max(0, Swift.min(255, value)))
    }
}

func color_noise_png(r_noise:Noise, g_noise:Noise, b_noise:Noise,
    width:Int, height:Int, value_offset:(r:Double, g:Double, b:Double), invert:Bool = false, path:String)
{
    let domain:Domain2D         = .init(samples_x: width, samples_y: height)
    let rgba:[PNG.RGBA<UInt8>]  = domain.map 
    {
        (p:SIMD2<Double>) in 
        
        let r:UInt8 = .init(clamping: r_noise.evaluate(p.x, p.y) + value_offset.r),
            g:UInt8 = .init(clamping: g_noise.evaluate(p.x, p.y) + value_offset.g),
            b:UInt8 = .init(clamping: b_noise.evaluate(p.x, p.y) + value_offset.b)
        if invert
        {
            return .init(.max - r, .max - g, .max - b)
        }
        else
        {
            return .init(r, g, b)
        }
    }
    
    do
    {
        let image:PNG.Image = .init(packing: rgba, size: (width, height),
            layout: .init(format: .rgb8(palette: [], fill: nil, key: nil)))
        try image.compress(path: path, level: 9)
    }
    catch
    {
        print(error)
    }
}

func banner_classic3d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: ClassicNoise3D(amplitude: 1.6 * 0.5*255, frequency: 0.01, seed: seed),
                    g_noise: ClassicNoise3D(amplitude: 1.6 * 0.5*255, frequency: 0.005, seed: seed + 1),
                    b_noise: ClassicNoise3D(amplitude: 1.6 * 0.5*255, frequency: 0.0025, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: (0.65*255, 0.65*255, 0.65*255),
                    path: "examples/banner_classic3d.png")
}

/*
func banner_simplex2d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: SimplexNoise2D(amplitude: 0.5*255, frequency: 0.015, seed: seed),
                    g_noise: SimplexNoise2D(amplitude: 0.5*255, frequency: 0.0075, seed: seed + 1),
                    b_noise: SimplexNoise2D(amplitude: 0.5*255, frequency: 0.00375, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: (0.65*255, 0.65*255, 0.65*255),
                    path: "tests/banner_simplex2d.png")
}
*/

func banner_supersimplex2d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: GradientNoise2D(amplitude: 0.5*255, frequency: 0.01, seed: seed),
                    g_noise: GradientNoise2D(amplitude: 0.5*255, frequency: 0.005, seed: seed + 1),
                    b_noise: GradientNoise2D(amplitude: 0.5*255, frequency: 0.0025, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: (0.65*255, 0.65*255, 0.65*255),
                    path: "examples/banner_supersimplex2d.png")
}

func banner_supersimplex3d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: GradientNoise3D(amplitude: 0.5*255, frequency: 0.01, seed: seed),
                    g_noise: GradientNoise3D(amplitude: 0.5*255, frequency: 0.005, seed: seed + 1),
                    b_noise: GradientNoise3D(amplitude: 0.5*255, frequency: 0.0025, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: (0.65*255, 0.65*255, 0.65*255),
                    path: "examples/banner_supersimplex3d.png")
}

func banner_cell2d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: CellNoise2D(amplitude: 3*255, frequency: 0.03, seed: seed),
                    g_noise: CellNoise2D(amplitude: 3*255, frequency: 0.015, seed: seed + 1),
                    b_noise: CellNoise2D(amplitude: 3*255, frequency: 0.0075, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: (0, 0, 0),
                    invert: true,
                    path: "examples/banner_cell2d.png")
}

func banner_cell3d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: CellNoise3D(amplitude: 3*255, frequency: 0.03, seed: seed),
                    g_noise: CellNoise3D(amplitude: 3*255, frequency: 0.015, seed: seed + 1),
                    b_noise: CellNoise3D(amplitude: 3*255, frequency: 0.0075, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: (0, 0, 0),
                    invert: true,
                    path: "examples/banner_cell3d.png")
}

func banner_FBM(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: FBM<CellNoise3D>    (CellNoise3D(amplitude: 10*255, frequency: 0.01, seed: seed + 2), octaves: 7, persistence: 0.75),
                    g_noise: FBM<GradientNoise3D>(GradientNoise3D(amplitude: 300, frequency: 0.005, seed: seed + 3), octaves: 7, persistence: 0.75),
                    b_noise: FBM<GradientNoise2D>(GradientNoise2D(amplitude: 300, frequency: 0.005), octaves: 7, persistence: 0.75),
                    width: width,
                    height: height,
                    value_offset: (0, 150, 150),
                    invert: false,
                    path: "examples/banner_FBM.png")
}

func circle_at(cx:Double, cy:Double, r:Double, width:Int, height:Int, _ f:(Int, Int, Double) -> ())
{
    // get bounding box
    let x1:Int = max(0         , Int(cx - r)),
        x2:Int = min(width - 1 , Int((cx + r).rounded(.up))),
        y1:Int = max(0         , Int(cy - r)),
        y2:Int = min(height - 1, Int((cy + r).rounded(.up)))

    for y in y1 ... y2
    {
        let dy:Double = Double(y) - cy
        for x in x1 ... x2
        {
            let dx:Double = Double(x) - cx,
                dr:Double = (dx*dx + dy*dy).squareRoot()

            f(x, y, min(1, max(0, 1 - dr + r - 0.5)))
        }
    }
}

func banner_disk2d(width:Int, height:Int, seed:Int)
{
    var poisson:DiskSampler2D       = .init(seed: seed)
    var rgba:[PNG.RGBA<UInt8>]    = .init(repeating: .init(.max), count: width * height)

    //let points = poisson.generate(radius: 20, width: width, height: height, k: 80)

    @inline(__always)
    func _dots(_ points:[SIMD2<Double>], color: (r:UInt8, g:UInt8, b:UInt8))
    {
        for point:(SIMD2<Double>) in points
        {
            circle_at(cx: point.x, cy: point.y, r: 10, width: width, height: height)
            {
                (x:Int, y:Int, v:Double) in

                let i:Int = y * width + x
                rgba[i].r = .init(clamping: Int(rgba[i].r) - Int(Double(color.r) * v))
                rgba[i].g = .init(clamping: Int(rgba[i].g) - Int(Double(color.g) * v))
                rgba[i].b = .init(clamping: Int(rgba[i].b) - Int(Double(color.b) * v))
            }
        }
    }

    _dots(poisson.generate(radius: 35, width: width, height: height, k: 80, seed: SIMD2<Double>(10, 10)), color: (0, 210, 70))
    _dots(poisson.generate(radius: 25, width: width, height: height, k: 80, seed: SIMD2<Double>(45, 15)), color: (0, 10, 235))
    _dots(poisson.generate(radius: 30, width: width, height: height, k: 80, seed: SIMD2<Double>(15, 45)), color: (225, 20, 0))
    
    do
    {
        let image:PNG.Image = .init(packing: rgba, size: (width, height), 
            layout: .init(format: .rgb8(palette: [], fill: nil, key: nil)))
        try image.compress(path: "examples/banner_disk2d.png", level: 9)
    }
    catch
    {
        print(error)
    }
}

func banner_voronoi2d(width:Int, height:Int, seed:Int)
{
    let voronoi:CellNoise2D = CellNoise2D(amplitude: 255, frequency: 0.025, seed: seed)

    let r:PermutationTable   = PermutationTable(seed: seed),
        g:PermutationTable   = PermutationTable(seed: seed + 1),
        b:PermutationTable   = PermutationTable(seed: seed + 2)

    let domain:Domain2D         = .init(samples_x: width, samples_y: height)
    let rgba:[PNG.RGBA<UInt8>]  = domain.map 
    {
        (p:SIMD2<Double>) in 
        
        @inline(__always)
        func _supersample(_ x:Double, _ y:Double) -> (r:UInt8, g:UInt8, b:UInt8)
        {
            let (point, _):(SIMD2<Int>, Double) = voronoi.closest_point(Double(x), Double(y))
            let r:UInt8 = r.hash(point.x, point.y),
                g:UInt8 = g.hash(point.x, point.y),
                b:UInt8 = b.hash(point.x, point.y),
                peak:UInt8 = max(r, max(g, b)),
                saturate:Double = .init(UInt8.max) / .init(peak)
            return (.init(.init(r) * saturate), .init(.init(g) * saturate), .init(.init(b) * saturate))
        }

        var r:Int = 0,
            g:Int = 0,
            b:Int = 0
        let supersamples:[(Double, Double)] = [(0, 0), (0, 0.4), (0.4, 0), (-0.4, 0), (0, -0.4),
                                               (-0.25, -0.25), (0.25, 0.25), (-0.25, 0.25), (0.25, -0.25)]
        for (dx, dy):(Double, Double) in supersamples
        {
            let contribution:(r:UInt8, g:UInt8, b:UInt8) = _supersample(p.x + dx, p.y + dy)
            r += .init(contribution.r)
            g += .init(contribution.g)
            b += .init(contribution.b)
        }
        
        return .init(   .init(r / supersamples.count), 
                        .init(g / supersamples.count), 
                        .init(b / supersamples.count))
    }
    
    do
    {
        let image:PNG.Image = .init(packing: rgba, size: (width, height),
            layout: .init(format: .rgb8(palette: [], fill: nil, key: nil)))
        try image.compress(path: "examples/banner_voronoi2d.png", level: 9)
    }
    catch
    {
        print(error)
    }
}

public
func banners(width:Int, ratio:Double)
{
    let height:Int = Int(Double(width) / ratio)
    print("banner_classic3d")
    banner_classic3d     (width: width, height: height, seed: 6)
    //print("banner_simplex2d")
    //banner_simplex2d     (width: width, height: height, seed: 6)
    print("banner_supersimplex2d")
    banner_supersimplex2d(width: width, height: height, seed: 8)
    print("banner_supersimplex3d")
    banner_supersimplex3d(width: width, height: height, seed: 2)
    print("banner_cell2d")
    banner_cell2d        (width: width, height: height, seed: 0)
    print("banner_cell3d")
    banner_cell3d        (width: width, height: height, seed: 0)
    print("banner_voronoi2d")
    banner_voronoi2d     (width: width, height: height, seed: 3)
    print("banner_FBM")
    banner_FBM           (width: width, height: height, seed: 2)
    print("banner_disk2d")
    banner_disk2d        (width: width, height: height, seed: 0)
}
