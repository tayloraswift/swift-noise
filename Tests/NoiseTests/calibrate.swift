import Noise
import PNG

func grayscale_noise_png(noise:Noise, width:Int, height:Int, value_offset:Double, path:String)
{
    let domain:Domain2D = .init(-2 ... 2, -2 ... 2, samples_x: width, samples_y: height)
    let v:[UInt8]       = domain.enumerated().map 
    {
        (element:(Int, (x:Double, y:Double))) in
        
        return .init(clamping: noise.evaluate(element.1.x, element.1.y) + value_offset)
    }

    do
    {
        let image:PNG.Image = .init(packing: v, size: (width, height), 
            layout: .init(format: .v8(fill: nil, key: nil)))
        try image.compress(path: path, level: 9)
    }
    catch
    {
        print(error)
    }
}

public
func calibrate_noise(width:Int, height:Int, seed:Int = 0)
{
    grayscale_noise_png(noise: DistortedNoise(FBM(ClassicNoise3D(amplitude: 0.5*255, frequency: 2, seed: seed), octaves: 4), strength: 0.003),
                        width: width,
                        height: height,
                        value_offset: 0.5*255,
                        path: "tests/calibrate_classic-distortion.png")

    grayscale_noise_png(noise: GradientNoise2D(amplitude: 0.5*255, frequency: 4, seed: seed),
                        width: width,
                        height: height,
                        value_offset: 0.5*255,
                        path: "tests/calibrate_gradient2d.png")

    grayscale_noise_png(noise: GradientNoise3D(amplitude: 0.5*255, frequency: 4, seed: seed),
                        width: width,
                        height: height,
                        value_offset: 0.5*255,
                        path: "tests/calibrate_gradient3d.png")

    grayscale_noise_png(noise: CellNoise2D(amplitude: 255, frequency: 4, seed: seed),
                        width: width,
                        height: height,
                        value_offset: 0,
                        path: "tests/calibrate_cell2d.png")

    grayscale_noise_png(noise: CellNoise3D(amplitude: 255, frequency: 4, seed: seed),
                        width: width,
                        height: height,
                        value_offset: 0,
                        path: "tests/calibrate_cell3d.png")
}
