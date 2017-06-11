import Noise

import MaxPNG

func write_rgb_png(path:String, width:Int, height:Int, pixbuf:[UInt8])
{
    guard let properties = PNGProperties(width: width, height: height, bit_depth: 8, color: .rgb, interlaced: false)
    else
    {
        fatalError("failed to set png properties")
    }

    do
    {
        try png_encode(path: path, raw_data: pixbuf, properties: properties)
    }
    catch
    {
        print(error)
    }
}

func color_noise_png(r_noise:Noise, g_noise:Noise, b_noise:Noise,
    width:Int, height:Int, value_offset:Double, invert:Bool = false, path:String)
{
    var pixbuf:[UInt8] = []
        pixbuf.reserveCapacity(3 * width * height)
    for (r, (g, b)) in zip(r_noise.sample_area_saturated_to_u8(width: width, height: height, offset: value_offset),
                       zip(g_noise.sample_area_saturated_to_u8(width: width, height: height, offset: value_offset),
                           b_noise.sample_area_saturated_to_u8(width: width, height: height, offset: value_offset)))
    {
        if invert
        {
            pixbuf.append(UInt8.max - r)
            pixbuf.append(UInt8.max - g)
            pixbuf.append(UInt8.max - b)
        }
        else
        {
            pixbuf.append(r)
            pixbuf.append(g)
            pixbuf.append(b)
        }
    }

    write_rgb_png(path: path, width: width, height: height, pixbuf: pixbuf)
}

func banner_simplex2d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: SimplexNoise2D(amplitude: 0.5*255, frequency: 0.015, seed: seed),
                    g_noise: SimplexNoise2D(amplitude: 0.5*255, frequency: 0.0075, seed: seed + 1),
                    b_noise: SimplexNoise2D(amplitude: 0.5*255, frequency: 0.00375, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: 0.65*255,
                    path: "tests/banner_simplex2d.png")
}

func banner_supersimplex2d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: SuperSimplexNoise2D(amplitude: 0.5*255, frequency: 0.01, seed: seed),
                    g_noise: SuperSimplexNoise2D(amplitude: 0.5*255, frequency: 0.005, seed: seed + 1),
                    b_noise: SuperSimplexNoise2D(amplitude: 0.5*255, frequency: 0.0025, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: 0.65*255,
                    path: "tests/banner_supersimplex2d.png")
}

func banner_supersimplex3d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: SuperSimplexNoise3D(amplitude: 0.5*255, frequency: 0.01, seed: seed),
                    g_noise: SuperSimplexNoise3D(amplitude: 0.5*255, frequency: 0.005, seed: seed + 1),
                    b_noise: SuperSimplexNoise3D(amplitude: 0.5*255, frequency: 0.0025, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: 0.65*255,
                    path: "tests/banner_supersimplex3d.png")
}

func banner_cell2d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: CellNoise2D(amplitude: 3*255, frequency: 0.03, seed: seed),
                    g_noise: CellNoise2D(amplitude: 3*255, frequency: 0.015, seed: seed + 1),
                    b_noise: CellNoise2D(amplitude: 3*255, frequency: 0.0075, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: 0,
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
                    value_offset: 0,
                    invert: true,
                    path: "tests/banner_cell3d.png")
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
    var poisson        = DiskSampler2D(seed: seed)
    var pixbuf:[UInt8] = [UInt8](repeating: 255, count: 3 * width * height)

    let points = poisson.generate(radius: 20, width: width, height: height, k: 80)
    for point:(x:Double, y:Double) in points
    {
        circle_at(cx: point.x, cy: point.y, r: 5, width: width, height: height,
        {
            (x:Int, y:Int, v:Double) in

            let base_addr:Int = 3 * (y * width + x)
            pixbuf[base_addr + 1] = pixbuf[base_addr + 1] &- UInt8(255 * v)
        })
    }

    write_rgb_png(path: "tests/banner_disk2d.png", width: width, height: height, pixbuf: pixbuf)
}

public
func banners(width:Int, ratio:Double)
{
    let height:Int = Int(Double(width) / ratio)
    banner_simplex2d(width: width, height: height, seed: 5)
    banner_supersimplex2d(width: width, height: height, seed: 8)
    banner_supersimplex3d(width: width, height: height, seed: 0)
    banner_cell2d(width: width, height: height, seed: 0)
    banner_cell3d(width: width, height: height, seed: 0)

    banner_disk2d(width: width, height: height, seed: 0)
}
