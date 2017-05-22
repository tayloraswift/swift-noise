import Cairo
import func Glibc.fputs
import var Glibc.stderr

struct StandardError:TextOutputStream
{
    mutating
    func write(_ str:String)
    {
        fputs(str, stderr)
    }
}

var standard_error = StandardError()

public
enum CairoFormat
{
case argb32,
     rgb24,
     a8,
     a1,
     rgb16_565,
     rgb30

     var c_format:cairo_format_t
     {
         switch self
         {
         case .argb32:
             return CAIRO_FORMAT_ARGB32
         case .rgb24:
             return CAIRO_FORMAT_RGB24
         case .a8:
             return CAIRO_FORMAT_A8
         case .a1:
             return CAIRO_FORMAT_A1
         case .rgb16_565:
             return CAIRO_FORMAT_RGB16_565
         case .rgb30:
             return CAIRO_FORMAT_RGB30
         }
     }
}

public final
class CairoSurface
{
    private
    let surface:OpaquePointer

    private
    var owned_contexts:[CairoContext]

    private
    init?(c_surface:OpaquePointer)
    {
        let cairo_status:cairo_status_t = cairo_surface_status(c_surface)
        guard cairo_status == CAIRO_STATUS_SUCCESS
        else
        {
            print(String(cString: cairo_status_to_string(cairo_status)), to: &standard_error)
            return nil
        }

        self.surface        = c_surface
        self.owned_contexts = []
    }

    public convenience
    init?(format:CairoFormat, width:Int, height:Int)
    {
        self.init(c_surface: cairo_image_surface_create(format.c_format, CInt(width), CInt(height)))
    }

    public convenience
    init?(withoutOwningBuffer pixbuf:inout[UInt8], format:CairoFormat, width:Int, height:Int)
    {
        let image_stride:CInt = cairo_format_stride_for_width(format.c_format, CInt(width))
        self.init(c_surface: cairo_image_surface_create_for_data(&pixbuf,
                                                                 format.c_format,
                                                                 CInt(width),
                                                                 CInt(height),
                                                                 image_stride))
    }

    public convenience
    init?(withoutOwningBuffer pixbuf:inout[UInt32], format:CairoFormat, width:Int, height:Int)
    {
        let image_stride:CInt = cairo_format_stride_for_width(format.c_format, CInt(width))
        self.init(c_surface: pixbuf.withUnsafeMutableBufferPointer
        {
            bp in

            return bp.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: bp.count << 2,
            {
                return cairo_image_surface_create_for_data($0, format.c_format, CInt(width), CInt(height), image_stride)
            })
        })
    }

    public
    func create() -> CairoContext
    {
        let cr:CairoContext = CairoContext(self.surface)
        self.owned_contexts.append(cr)
        return cr
    }

    public
    var width:Int
    {
        return Int(cairo_image_surface_get_width(self.surface))
    }

    public
    var stride:Int
    {
        return Int(cairo_image_surface_get_stride(self.surface))
    }

    public
    var height:Int
    {
        return Int(cairo_image_surface_get_height(self.surface))
    }

    public
    func with_data<Result>(_ f:(UnsafeBufferPointer<UInt8>) -> Result) -> Result
    {
        return withExtendedLifetime(self,
        {
            let start:UnsafeMutablePointer<UInt8> = cairo_image_surface_get_data(self.surface)
            return f(UnsafeBufferPointer(start: start, count: self.stride * self.height))
        })
    }

    deinit
    {
        cairo_surface_destroy(self.surface)
        for cr in self.owned_contexts
        {
            cr.destroy()
        }
    }
}

public
struct CairoContext
{
    private
    let cr:OpaquePointer

    init(_ c_surface:OpaquePointer)
    {
        self.cr = cairo_create(c_surface)
    }

    public
    func move_to(_ x:Double, _ y:Double)
    {
        cairo_move_to(self.cr, x, y)
    }

    public
    func arc(x:Double, y:Double, r:Double, start:Double = 0, end:Double = 2*Double.pi)
    {
        cairo_arc(self.cr, x, y, r, start, end)
    }

    public
    func set_source_rgb(_ r:Double, _ g:Double, _ b:Double)
    {
        cairo_set_source_rgb(self.cr, r, g, b)
    }

    public
    func set_source_rgba(_ r:Double, _ g:Double, _ b:Double, _ a:Double)
    {
        cairo_set_source_rgba(self.cr, r, g, b, a)
    }

    public
    func fill()
    {
        cairo_fill(self.cr)
    }

    public
    func paint()
    {
        cairo_paint(self.cr)
    }

    public
    func select_font_face(fontname:String, slant:cairo_font_slant_t, weight:cairo_font_weight_t)
    {
        cairo_select_font_face(self.cr, fontname, slant, weight)
    }

    public
    func set_font_size(_ size:Double)
    {
        cairo_set_font_size(self.cr, size)
    }

    public
    func show_text(_ text:String)
    {
        cairo_show_text(self.cr, text)
    }

    func destroy()
    {
        cairo_destroy(self.cr)
    }
}
