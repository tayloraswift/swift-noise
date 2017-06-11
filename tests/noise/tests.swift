import Noise

import MaxPNG

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

func banner_simplex2d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: SimplexNoise2D(amplitude: 0.5*255, frequency: 0.015, seed: seed),
                    g_noise: SimplexNoise2D(amplitude: 0.5*255, frequency: 0.0075, seed: seed + 1),
                    b_noise: SimplexNoise2D(amplitude: 0.5*255, frequency: 0.00375, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: 0.65*255,
                    path: "banner_simplex2d.png")
}

func banner_supersimplex2d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: SuperSimplexNoise2D(amplitude: 0.5*255, frequency: 0.01, seed: seed),
                    g_noise: SuperSimplexNoise2D(amplitude: 0.5*255, frequency: 0.005, seed: seed + 1),
                    b_noise: SuperSimplexNoise2D(amplitude: 0.5*255, frequency: 0.0025, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: 0.65*255,
                    path: "banner_supersimplex2d.png")
}

func banner_supersimplex3d(width:Int, height:Int, seed:Int)
{
    color_noise_png(r_noise: SuperSimplexNoise3D(amplitude: 0.5*255, frequency: 0.01, seed: seed),
                    g_noise: SuperSimplexNoise3D(amplitude: 0.5*255, frequency: 0.005, seed: seed + 1),
                    b_noise: SuperSimplexNoise3D(amplitude: 0.5*255, frequency: 0.0025, seed: seed + 2),
                    width: width,
                    height: height,
                    value_offset: 0.65*255,
                    path: "banner_supersimplex3d.png")
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
                    path: "banner_cell2d.png")
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
                    path: "banner_cell3d.png")
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
}
