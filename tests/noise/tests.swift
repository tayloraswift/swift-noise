import Noise
import MaxPNG

func write_png(path:String, width:Int, height:Int, pixbytes:UnsafeBufferPointer<UInt8>, color:PNGProperties.ColorFormat)
{
    guard let properties = PNGProperties(width: width, height: height, bit_depth: 8, color: color, interlaced: false)
    else
    {
        fatalError("failed to set png properties")
    }

    do
    {
        try png_encode( path: path,
                        raw_data: pixbytes,
                        properties: properties)
    }
    catch
    {
        print(error)
    }
}

extension UInt8
{
    init<T>(clamping value:T) where T:FloatingPoint
    {
        self.init(Swift.max(0, Swift.min(255, value)))
    }
}

func color_noise_png(r_noise:Noise, g_noise:Noise, b_noise:Noise,
    width:Int, height:Int, value_offset:(r:Double, g:Double, b:Double), invert:Bool = false, path:String)
{
    let byte_count:Int = 3 * width * height
    let pixbytes = UnsafeMutableBufferPointer<UInt8>(start: UnsafeMutablePointer<UInt8>.allocate(capacity: byte_count), count: byte_count)
    defer
    {
        pixbytes.baseAddress?.deallocate(capacity: pixbytes.count)
    }

    var i:Int = 0
    for (x, y):(Double, Double) in Domain2D(samples_x: width, samples_y: height)
    {
        let r:UInt8 = UInt8(clamping: r_noise.evaluate(x, y) + value_offset.r),
            g:UInt8 = UInt8(clamping: g_noise.evaluate(x, y) + value_offset.g),
            b:UInt8 = UInt8(clamping: b_noise.evaluate(x, y) + value_offset.b)
        if invert
        {
            pixbytes[i    ] = UInt8.max - r
            pixbytes[i + 1] = UInt8.max - g
            pixbytes[i + 2] = UInt8.max - b
        }
        else
        {
            pixbytes[i    ] = r
            pixbytes[i + 1] = g
            pixbytes[i + 2] = b
        }

        i += 3
    }

    write_png(  path: path,
                width: width,
                height: height,
                pixbytes: UnsafeBufferPointer<UInt8>(start: pixbytes.baseAddress, count: pixbytes.count),
                color: .rgb)
}

func banner_classic3d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: ClassicNoise3D(amplitude: 1.6 * 0.5*255, frequency: 0.01, seed: seed),
                    g_noise: ClassicNoise3D(amplitude: 1.6 * 0.5*255, frequency: 0.005, seed: seed + 1),
                    b_noise: ClassicNoise3D(amplitude: 1.6 * 0.5*255, frequency: 0.0025, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: (0.65*255, 0.65*255, 0.65*255),
                    path: "tests/banner_classic3d.png")
}

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

func banner_supersimplex2d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: GradientNoise2D(amplitude: 0.5*255, frequency: 0.01, seed: seed),
                    g_noise: GradientNoise2D(amplitude: 0.5*255, frequency: 0.005, seed: seed + 1),
                    b_noise: GradientNoise2D(amplitude: 0.5*255, frequency: 0.0025, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: (0.65*255, 0.65*255, 0.65*255),
                    path: "tests/banner_supersimplex2d.png")
}

func banner_supersimplex3d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: GradientNoise3D(amplitude: 0.5*255, frequency: 0.01, seed: seed),
                    g_noise: GradientNoise3D(amplitude: 0.5*255, frequency: 0.005, seed: seed + 1),
                    b_noise: GradientNoise3D(amplitude: 0.5*255, frequency: 0.0025, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: (0.65*255, 0.65*255, 0.65*255),
                    path: "tests/banner_supersimplex3d.png")
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
                    path: "tests/banner_cell2d.png")
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
                    path: "tests/banner_cell3d.png")
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
                    path: "tests/banner_FBM.png")
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
    var poisson          = DiskSampler2D(seed: seed)
    var pixbytes:[UInt8] = [UInt8](repeating: 255, count: 3 * width * height)

    let points = poisson.generate(radius: 20, width: width, height: height, k: 80)

    @inline(__always)
    func _dots(_ points:[(x:Double, y:Double)], color: (r:UInt8, g:UInt8, b:UInt8))
    {
        for point:(x:Double, y:Double) in points
        {
            circle_at(cx: point.x, cy: point.y, r: 10, width: width, height: height,
            {
                (x:Int, y:Int, v:Double) in

                let base_addr:Int = 3 * (y * width + x)
                pixbytes[base_addr    ] = UInt8(clamping: Int(pixbytes[base_addr    ]) - Int(Double(color.r) * v))
                pixbytes[base_addr + 1] = UInt8(clamping: Int(pixbytes[base_addr + 1]) - Int(Double(color.g) * v))
                pixbytes[base_addr + 2] = UInt8(clamping: Int(pixbytes[base_addr + 2]) - Int(Double(color.b) * v))
            })
        }
    }

    _dots(poisson.generate(radius: 35, width: width, height: height, k: 80, seed: (10, 10)), color: (0, 210, 70))
    _dots(poisson.generate(radius: 25, width: width, height: height, k: 80, seed: (45, 15)), color: (0, 10, 235))
    _dots(poisson.generate(radius: 30, width: width, height: height, k: 80, seed: (15, 45)), color: (225, 20, 0))

    pixbytes.withUnsafeBufferPointer
    {
        write_png(path: "tests/banner_disk2d.png", width: width, height: height, pixbytes: $0, color: .rgb)
    }
}

func banner_voronoi2d(width:Int, height:Int, seed:Int)
{
    let voronoi:CellNoise2D = CellNoise2D(amplitude: 255, frequency: 0.025, seed: seed)
    var pixbytes:[UInt8] = [UInt8](repeating: 0, count: 3 * width * height)

    let r:PermutationTable   = PermutationTable(seed: seed),
        g:PermutationTable   = PermutationTable(seed: seed + 1),
        b:PermutationTable   = PermutationTable(seed: seed + 2)

    var base_addr:Int = 0
    for y in 0 ..< height
    {
        for x in 0 ..< width
        {
            @inline(__always)
            func _supersample(_ x:Double, _ y:Double) -> (r:UInt8, g:UInt8, b:UInt8)
            {
                let (point, _):((Int, Int), Double) = voronoi.closest_point(Double(x), Double(y))
                let r:UInt8 = r.hash(point.0, point.1),
                    g:UInt8 = g.hash(point.0, point.1),
                    b:UInt8 = b.hash(point.0, point.1),
                    peak:UInt8 = max(r, max(g, b)),
                    saturate:Double = Double(UInt8.max) / Double(peak)
                return (UInt8(Double(r) * saturate), UInt8(Double(g) * saturate), UInt8(Double(b) * saturate))
            }

            var r:Int = 0,
                g:Int = 0,
                b:Int = 0
            let supersamples:[(Double, Double)] = [(0, 0), (0, 0.4), (0.4, 0), (-0.4, 0), (0, -0.4),
                                                   (-0.25, -0.25), (0.25, 0.25), (-0.25, 0.25), (0.25, -0.25)]
            for (dx, dy) in supersamples
            {
                let contribution:(r:UInt8, g:UInt8, b:UInt8) = _supersample(Double(x) + dx, Double(y) + dy)
                r += Int(contribution.r)
                g += Int(contribution.g)
                b += Int(contribution.b)
            }
            pixbytes[base_addr    ] = UInt8(r / supersamples.count)
            pixbytes[base_addr + 1] = UInt8(g / supersamples.count)
            pixbytes[base_addr + 2] = UInt8(b / supersamples.count)

            base_addr += 3
        }
    }

    pixbytes.withUnsafeBufferPointer
    {
        write_png(path: "tests/banner_voronoi2d.png", width: width, height: height, pixbytes: $0, color: .rgb)
    }
}

public
func banners(width:Int, ratio:Double)
{
    let height:Int = Int(Double(width) / ratio)
    banner_classic3d     (width: width, height: height, seed: 6)
    banner_simplex2d     (width: width, height: height, seed: 6)
    banner_supersimplex2d(width: width, height: height, seed: 8)
    banner_supersimplex3d(width: width, height: height, seed: 2)
    banner_cell2d        (width: width, height: height, seed: 0)
    banner_cell3d        (width: width, height: height, seed: 0)
    banner_voronoi2d     (width: width, height: height, seed: 3)

    banner_FBM           (width: width, height: height, seed: 2)

    banner_disk2d        (width: width, height: height, seed: 0)
}
