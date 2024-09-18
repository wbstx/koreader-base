--[[--
Generic blitbuffer/GFX stuff that works on memory buffers

@module ffi.blitbuffer
--]]

local bit = require("bit")
local ffi = require("ffi")
local util = require("ffi/util")
local C = ffi.C

-- we will use this extensively
local floor = math.floor
local ceil = math.ceil
local min = math.min
local max = math.max
local function round(x)
    return math.floor(x + 0.5)
end
local rshift = bit.rshift
local lshift = bit.lshift
local band = bit.band
local bnot = bit.bnot
local bor = bit.bor
local bxor = bit.bxor

local uint32pt = ffi.typeof("uint32_t*")
local uint16pt = ffi.typeof("uint16_t*")
local uint8pt = ffi.typeof("uint8_t*")
local uint8pt_rodata = ffi.typeof("const uint8_t*")
require("ffi/posix_h")

-- the following definitions are redundant.
-- they need to be since only this way we can set
-- different metatables for them.
ffi.cdef[[
typedef struct Color4L {
    uint8_t a;
} Color4L;
typedef struct Color4U {
    uint8_t a;
} Color4U;
typedef struct Color8 {
    uint8_t a;
} Color8;
typedef struct Color8A {
    uint8_t a;
    uint8_t alpha;
} Color8A;
typedef struct ColorRGB16 {
    uint16_t v;
} ColorRGB16;
typedef struct ColorRGB24 {
    uint8_t r;
    uint8_t g;
    uint8_t b;
} ColorRGB24;
typedef struct ColorRGB32 {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t alpha;
} ColorRGB32;

typedef struct BlitBuffer {
    unsigned int w;
    unsigned int pixel_stride;  // nb of pixels from the start of a line to the start of next line
    unsigned int h;
    size_t stride;              // nb of bytes from the start of a line to the start of next line
    uint8_t * restrict data;
    uint8_t config;
} BlitBuffer;
typedef struct BlitBuffer4 {
    unsigned int w;
    unsigned int pixel_stride;
    unsigned int h;
    size_t stride;
    uint8_t *data;
    uint8_t config;
} BlitBuffer4;
typedef struct BlitBuffer8 {
    unsigned int w;
    unsigned int pixel_stride;
    unsigned int h;
    size_t stride;
    Color8 * restrict data;
    uint8_t config;
} BlitBuffer8;
typedef struct BlitBuffer8A {
    unsigned int w;
    unsigned int pixel_stride;
    unsigned int h;
    size_t stride;
    Color8A * restrict data;
    uint8_t config;
} BlitBuffer8A;
typedef struct BlitBufferRGB16 {
    unsigned int w;
    unsigned int pixel_stride;
    unsigned int h;
    size_t stride;
    ColorRGB16 * restrict data;
    uint8_t config;
} BlitBufferRGB16;

typedef struct BlitBufferRGB24 {
    unsigned int w;
    unsigned int pixel_stride;
    unsigned int h;
    size_t stride;
    ColorRGB24 * restrict data;
    uint8_t config;
} BlitBufferRGB24;

typedef struct BlitBufferRGB32 {
    unsigned int w;
    unsigned int pixel_stride;
    unsigned int h;
    size_t stride;
    ColorRGB32 * restrict data;
    uint8_t config;
} BlitBufferRGB32;

void BB_fill(BlitBuffer * restrict bb, uint8_t v);
void BB_fill_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, uint8_t v);
void BB_fill_rect_RGB32(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const ColorRGB32 * restrict color);
void BB_blend_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const Color8A * restrict color);
void BB_blend_RGB32_over_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const ColorRGB32 * restrict color);
void BB_blend_RGB_multiply_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const ColorRGB24 * restrict color);
void BB_blend_RGB32_multiply_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const ColorRGB32 * restrict color);
void BB_invert_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h);
void BB_hatch_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, unsigned int stripe_width, const Color8 * restrict color, uint8_t alpha);
void BB_blit_to(const BlitBuffer * restrict source, BlitBuffer * restrict dest, unsigned int dest_x, unsigned int dest_y,
                unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
void BB_dither_blit_to(const BlitBuffer * restrict source, BlitBuffer * restrict dest, unsigned int dest_x, unsigned int dest_y,
                unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
void BB_add_blit_from(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                      unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h, uint8_t alpha);
void BB_alpha_blit_from(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                        unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
void BB_dither_alpha_blit_from(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                        unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
void BB_pmulalpha_blit_from(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                        unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
void BB_dither_pmulalpha_blit_from(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                        unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
void BB_invert_blit_from(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                         unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
void BB_color_blit_from(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                        unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h, const Color8A * restrict color);
void BB_color_blit_from_RGB32(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                        unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h, const ColorRGB32 * restrict color);
void BB_paint_rounded_corner(BlitBuffer * restrict bb, unsigned int off_x, unsigned int off_y, unsigned int w, unsigned int h,
                        unsigned int bw, unsigned int r, uint8_t c, int anti_alias);
]]

-- We'll load it later
local cblitbuffer
local use_cblitbuffer

-- color value types
local Color4U = ffi.typeof("Color4U")
local Color4L = ffi.typeof("Color4L")
local Color8 = ffi.typeof("Color8")
local Color8A = ffi.typeof("Color8A")
local ColorRGB16 = ffi.typeof("ColorRGB16")
local ColorRGB24 = ffi.typeof("ColorRGB24")
local ColorRGB32 = ffi.typeof("ColorRGB32")

-- color value pointer types
local P_Color4U = ffi.typeof("Color4U*")
local P_Color4L = ffi.typeof("Color4L*")
local P_Color8 = ffi.typeof("Color8*") -- luacheck: ignore 211
local P_Color8A = ffi.typeof("Color8A*") -- luacheck: ignore 211
local P_ColorRGB16 = ffi.typeof("ColorRGB16*") -- luacheck: ignore 211
local P_ColorRGB24 = ffi.typeof("ColorRGB24*") -- luacheck: ignore 211
local P_ColorRGB32 = ffi.typeof("ColorRGB32*") -- luacheck: ignore 211

-- blitbuffer struct types (pointers)
local P_BlitBuffer = ffi.typeof("BlitBuffer*")
local P_BlitBuffer_ROData = ffi.typeof("const BlitBuffer*")

-- metatables for color types:
local Color4L_mt = {__index={}}
local Color4U_mt = {__index={}}
local Color8_mt = {__index={}}
local Color8A_mt = {__index={}}
local ColorRGB16_mt = {__index={}}
local ColorRGB24_mt = {__index={}}
local ColorRGB32_mt = {__index={}}

-- color setting
function Color4L_mt.__index:set(color)
    self.a = bor(band(0xF0, self.a), color:getColor4L().a)
end
function Color4U_mt.__index:set(color)
    self.a = bor(band(0x0F, self.a), color:getColor4U().a)
end
function Color8_mt.__index:set(color)
    self.a = color:getColor8().a
end
function Color8A_mt.__index:set(color)
    local c = color:getColor8A()
    self.a = c.a
    self.alpha = c.alpha
end
function ColorRGB16_mt.__index:set(color)
    self.v = color:getColorRGB16().v
end
function ColorRGB24_mt.__index:set(color)
    local c = color:getColorRGB24()
    self.r = c.r
    self.g = c.g
    self.b = c.b
end
function ColorRGB32_mt.__index:set(color)
    local c = color:getColorRGB32()
    self.r = c.r
    self.g = c.g
    self.b = c.b
    self.alpha = c.alpha
end

-- Fast integer only divisions used for quantum scaling
local function div255(value)
    local v = value + 128
    return rshift((rshift(v, 8) + v), 8)
end
local function div4080(value)
    return rshift(value + 0x01 + rshift(value, 8), 12)
end

-- Quantize an 8-bit color value down to a palette of 16 evenly spaced colors, using an ordered 8x8 dithering pattern.
-- With a grayscale input, this happens to match the eInk palette perfectly ;).
-- If the input is not grayscale, and the output fb is not grayscale either,
-- this usually still happens to match the eInk palette after the EPDC's own quantization pass.
-- c.f., https://en.wikipedia.org/wiki/Ordered_dithering
-- & https://github.com/ImageMagick/ImageMagick/blob/ecfeac404e75f304004f0566557848c53030bad6/MagickCore/threshold.c#L1627
-- NOTE: As the references imply, this is straight from ImageMagick,
--       with only minor simplifications to enforce Q8 & avoid fp maths.
-- c.f., https://github.com/ImageMagick/ImageMagick/blob/ecfeac404e75f304004f0566557848c53030bad6/config/thresholds.xml#L107
local threshold_map_o8x8 = ffi.new("uint8_t[64]", { [0]=1,  49, 13, 61, 4,  52, 16, 64, 33, 17, 45, 29, 36, 20, 48, 32,
                                                    9,  57, 5,  53, 12, 60, 8,  56, 41, 25, 37, 21, 44, 28, 40, 24,
                                                    3,  51, 15, 63, 2,  50, 14, 62, 35, 19, 47, 31, 34, 18, 46, 30,
                                                    11, 59, 7,  55, 10, 58, 6,  54, 43, 27, 39, 23, 42, 26, 38, 22 })
local function dither_o8x8(x, y, v)
    -- Constants:
    -- Quantum = 8; Levels = 16; map Divisor = 65
    -- QuantumRange = 0xFF
    -- QuantumScale = 1.0 / QuantumRange
    --
    -- threshold = QuantumScale * v * ((L-1) * (D-1) + 1)
    -- NOTE: The initial computation of t (specifically, what we pass to DIV255) would overflow an uint8_t.
    --       So jump to shorts, and do it signed to be extra careful, although I don't *think* we can ever underflow here.
    local t = div255(v * (lshift(15, 6) + 1))
    -- level = t / (D-1);
    local l = rshift(t, 6)
    -- t -= l * (D-1);
    t = t - lshift(l, 6)

    -- map width & height = 8
    -- c = ClampToQuantum((l+(t >= map[(x % mw) + mw * (y % mh)])) * QuantumRange / (L-1));
    local q = (l + (t >= threshold_map_o8x8[band(x, 7) + (8 * band(y, 7))] and 1 or 0)) * 17
    -- NOTE: For some arcane reason, on ARM (at least), this is noticeably faster than Pillow's CLIP8 macro.
    --       Following this logic with ternary operators yields similar results,
    --       so I'm guessing it's the < 256 part of Pillow's macro that doesn't agree with GCC/ARM...
    if (q > 0xFF) then
        return 0xFF
    elseif (q < 0) then
        return 0
    else
        return q
    end
end

-- Straight alpha blending (8bit alpha value)
function Color4L_mt.__index:blend(color, coverage)
    local alpha = coverage or color:getAlpha()
    -- simplified: we expect a 8bit grayscale "color" as parameter
    local value = div4080(band(self.a, 0x0F) * 0x11 * bxor(alpha, 0xFF) + color:getR() * alpha)
    self:set(Color4L(value))
end
function Color4U_mt.__index:blend(color, coverage)
    local alpha = coverage or color:getAlpha()
    local orig = band(self.a, 0xF0)
    -- simplified: we expect a 8bit grayscale "color" as parameter
    local value = div255((orig + rshift(orig, 4)) * bxor(alpha, 0xFF) + color:getR() * alpha)
    self:set(Color4U(value))
end
function Color8_mt.__index:blend(color, coverage)
    local alpha = coverage or color:getAlpha()
    -- simplified: we expect a 8bit grayscale "color" as parameter
    local value = div255(self.a * bxor(alpha, 0xFF) + color:getR() * alpha)
    self:set(Color8(value))
end
function Color8A_mt.__index:blend(color, coverage)
    local alpha = coverage or color:getAlpha()
    -- simplified: we expect a 8bit grayscale "color" as parameter
    local value = div255(self.a * bxor(alpha, 0xFF) + color:getR() * alpha)
    self:set(Color8A(value, self:getAlpha()))
end
function ColorRGB16_mt.__index:blend(color, coverage)
    local alpha = coverage or color:getAlpha()
    local ainv = bxor(alpha, 0xFF)
    local r = div255(self:getR() * ainv + color:getR() * alpha)
    local g = div255(self:getG() * ainv + color:getG() * alpha)
    local b = div255(self:getB() * ainv + color:getB() * alpha)
    self:set(ColorRGB24(r, g, b))
end
ColorRGB24_mt.__index.blend = ColorRGB16_mt.__index.blend
function ColorRGB32_mt.__index:blend(color, coverage)
    local alpha = coverage or color:getAlpha()
    local ainv = bxor(alpha, 0xFF)
    local r = div255(self:getR() * ainv + color:getR() * alpha)
    local g = div255(self:getG() * ainv + color:getG() * alpha)
    local b = div255(self:getB() * ainv + color:getB() * alpha)
    self:set(ColorRGB32(r, g, b, self:getAlpha()))
end
-- And the BB8 version of the same that dithers the result...
function Color8_mt.__index:ditherblend(x, y, color)
    local alpha = color:getAlpha()
    -- simplified: we expect a 8bit grayscale "color" as parameter
    local value = div255(self.a * bxor(alpha, 0xFF) + color:getR() * alpha)
    value = dither_o8x8(x, y, value)
    self:set(Color8(value))
end
-- Alpha blending with a premultiplied input (i.e., color OVER self, w/ color being premultiplied)
function Color4L_mt.__index:pmulblend(color)
    local alpha = color:getAlpha()
    -- simplified: we expect a 8bit grayscale "color" as parameter
    local value = div4080(band(self.a, 0x0F) * 0x11 * bxor(alpha, 0xFF) + color:getR() * 0xFF)
    self:set(Color4L(value))
end
function Color4U_mt.__index:pmulblend(color)
    local alpha = color:getAlpha()
    local orig = band(self.a, 0xF0)
    -- simplified: we expect a 8bit grayscale "color" as parameter
    local value = div255((orig + rshift(orig, 4)) * bxor(alpha, 0xFF) + color:getR() * 0xFF)
    self:set(Color4U(value))
end
function Color8_mt.__index:pmulblend(color)
    local alpha = color:getAlpha()
    -- simplified: we expect a 8bit grayscale "color" as parameter
    local value = div255(self.a * bxor(alpha, 0xFF) + color:getR() * 0xFF)
    self:set(Color8(value))
end
function Color8A_mt.__index:pmulblend(color)
    local alpha = color:getAlpha()
    -- simplified: we expect a 8bit grayscale "color" as parameter
    local value = div255(self.a * bxor(alpha, 0xFF) + color:getR() * 0xFF)
    self:set(Color8A(value, self:getAlpha()))
end
function ColorRGB16_mt.__index:pmulblend(color)
    local alpha = color:getAlpha()
    local ainv = bxor(alpha, 0xFF)
    local r = div255(self:getR() * ainv + color:getR() * 0xFF)
    local g = div255(self:getG() * ainv + color:getG() * 0xFF)
    local b = div255(self:getB() * ainv + color:getB() * 0xFF)
    self:set(ColorRGB24(r, g, b))
end
ColorRGB24_mt.__index.pmulblend = ColorRGB16_mt.__index.pmulblend
function ColorRGB32_mt.__index:pmulblend(color)
    local alpha = color:getAlpha()
    local ainv = bxor(alpha, 0xFF)
    local r = div255(self:getR() * ainv + color:getR() * 0xFF)
    local g = div255(self:getG() * ainv + color:getG() * 0xFF)
    local b = div255(self:getB() * ainv + color:getB() * 0xFF)
    self:set(ColorRGB32(r, g, b, self:getAlpha()))
end
-- And the BB8 version of the same that dithers the result...
function Color8_mt.__index:ditherpmulblend(x, y, color)
    local alpha = color:getAlpha()
    -- simplified: we expect a 8bit grayscale "color" as parameter
    local value = div255(self.a * bxor(alpha, 0xFF) + color:getR() * 0xFF)
    value = dither_o8x8(x, y, value)
    self:set(Color8(value))
end
-- Dumb multiply blending with an RGB24 color (will be grayscaled when targeting grayscale BBs)
function Color4L_mt.__index:mul(color)
    local value = div255(self:getColor8().a * color:getColor8().a)
    self:set(Color4L(value))
end
function Color4U_mt.__index:mul(color)
local value = div255(self:getColor8().a * color:getColor8().a)
    self:set(Color4U(value))
end
function Color8_mt.__index:mul(color)
    local value = div255(self.a * color:getColor8().a)
    self:set(Color8(value))
end
function Color8A_mt.__index:mul(color)
    local value = div255(self.a * color:getColor8().a)
    self:set(Color8A(value, self:getAlpha()))
end
function ColorRGB16_mt.__index:mul(color)
    local r = div255(self:getR() * color:getR())
    local g = div255(self:getG() * color:getG())
    local b = div255(self:getB() * color:getB())
    self:set(ColorRGB24(r, g, b))
end
ColorRGB24_mt.__index.mul = ColorRGB16_mt.__index.mul
function ColorRGB32_mt.__index:mul(color)
    local r = div255(self:getR() * color:getR())
    local g = div255(self:getG() * color:getG())
    local b = div255(self:getB() * color:getB())
    self:set(ColorRGB32(r, g, b, self:getAlpha()))
end

-- color conversions:
-- NOTE: These *always* return a new Color? object, even when no conversion is needed.
--       This ensures that, we you work on this new object, you won't potentially affect the source reference!
-- to Color4L:
function Color4L_mt.__index:getColor4L() return Color4L(band(0x0F, self.a)) end
function Color4U_mt.__index:getColor4L() return Color4L(rshift(self.a, 4)) end
function Color8_mt.__index:getColor4L() return Color4L(rshift(self.a, 4)) end
function Color8A_mt.__index:getColor4L() return Color4L(rshift(self.a, 4)) end
--[[
Uses luminance match for approximating the human perception of colour, as per
http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale

L = 0.299*Red + 0.587*Green + 0.114*Blue
--]]
function ColorRGB16_mt.__index:getColor4L()
    local r = rshift(self.v, 11)
    local g = band(rshift(self.v, 5), 0x3F)
    local b = band(self.v, 0x001F)
    return Color4L(rshift(39919*r + 39185*g + 15220*b, 18))
end
function ColorRGB24_mt.__index:getColor4L()
    return Color4L(rshift(4898*self.r + 9618*self.g + 1869*self.b, 18))
end
ColorRGB32_mt.__index.getColor4L = ColorRGB24_mt.__index.getColor4L

-- to Color4U:
function Color4L_mt.__index:getColor4U() return Color4U(lshift(self.a, 4)) end
function Color4U_mt.__index:getColor4U() return Color4U(band(0xF0, self.a)) end
function Color8_mt.__index:getColor4U() return Color4U(band(0xF0, self.a)) end
function Color8A_mt.__index:getColor4U() return Color4U(band(0xF0, self.a)) end
function ColorRGB16_mt.__index:getColor4U()
    local r = rshift(self.v, 11)
    local g = band(rshift(self.v, 5), 0x3F)
    local b = band(self.v, 0x001F)
    return Color4U(band(0xF0, rshift(39919*r + 39185*g + 15220*b, 14)))
end
function ColorRGB24_mt.__index:getColor4U()
    return Color4U(band(0xF0, rshift(4898*self.r + 9618*self.g + 1869*self.b, 14)))
end
ColorRGB32_mt.__index.getColor4U = ColorRGB24_mt.__index.getColor4U

-- to Color8:
function Color4L_mt.__index:getColor8()
    local v = band(0x0F, self.a)
    return Color8(v*0x11)
end
function Color4U_mt.__index:getColor8()
    local v = band(0xF0, self.a)
    return Color8(bor(rshift(v, 4), v))
end
function Color8_mt.__index:getColor8() return Color8(self.a) end
Color8A_mt.__index.getColor8 = Color8_mt.__index.getColor8
function ColorRGB16_mt.__index:getColor8()
    local r = rshift(self.v, 11)
    local g = band(rshift(self.v, 5), 0x3F)
    local b = band(self.v, 0x001F)
    return Color8(rshift(39919*r + 39185*g + 15220*b, 14))
end
function ColorRGB24_mt.__index:getColor8()
    return Color8(rshift(4898*self:getR() + 9618*self:getG() + 1869*self:getB(), 14))
end
ColorRGB32_mt.__index.getColor8 = ColorRGB24_mt.__index.getColor8

-- to Color8A:
function Color4L_mt.__index:getColor8A()
    local v = band(0x0F, self.a)
    return Color8A(v*0x11, 0xFF)
end
function Color4U_mt.__index:getColor8A()
    local v = band(0xF0, self.a)
    return Color8A(bor(rshift(v, 4), v), 0xFF)
end
function Color8_mt.__index:getColor8A() return Color8A(self.a, 0xFF) end
function Color8A_mt.__index:getColor8A() return Color8A(self.a, self.alpha) end
function ColorRGB16_mt.__index:getColor8A()
    local r = rshift(self.v, 11)
    local g = band(rshift(self.v, 5), 0x3F)
    local b = band(self.v, 0x001F)
    return Color8A(rshift(39919*r + 39185*g + 15220*b, 14), 0xFF)
end
function ColorRGB24_mt.__index:getColor8A()
    return Color8A(rshift(4898*self:getR() + 9618*self:getG() + 1869*self:getB(), 14), 0xFF)
end
function ColorRGB32_mt.__index:getColor8A()
    return Color8A(rshift(4898*self:getR() + 9618*self:getG() + 1869*self:getB(), 14), self:getAlpha())
end

-- to ColorRGB16:
function Color4L_mt.__index:getColorRGB16()
    local v = self:getColor8().a
    local v5bit = rshift(v, 3)
    return ColorRGB16(lshift(v5bit, 11) + lshift(band(v, 0xFC), 3) + v5bit)
end
Color4U_mt.__index.getColorRGB16 = Color4L_mt.__index.getColorRGB16
function Color8_mt.__index:getColorRGB16()
    local v = self.a
    local v5bit = rshift(v, 3)
    return ColorRGB16(lshift(v5bit, 11) + lshift(band(v, 0xFC), 3) + v5bit)
end
Color8A_mt.__index.getColorRGB16 = Color8_mt.__index.getColorRGB16
function ColorRGB16_mt.__index:getColorRGB16() return ColorRGB16(self.v) end
function ColorRGB24_mt.__index:getColorRGB16()
    return ColorRGB16(lshift(band(self.r, 0xF8), 8) + lshift(band(self.g, 0xFC), 3)  + rshift(self.b, 3))
end
ColorRGB32_mt.__index.getColorRGB16 = ColorRGB24_mt.__index.getColorRGB16

-- to ColorRGB24:
function Color4L_mt.__index:getColorRGB24()
    local v = self:getColor8()
    return ColorRGB24(v.a, v.a, v.a)
end
Color4U_mt.__index.getColorRGB24 = Color4L_mt.__index.getColorRGB24
function Color8_mt.__index:getColorRGB24() return ColorRGB24(self.a, self.a, self.a) end
Color8A_mt.__index.getColorRGB24 = Color8_mt.__index.getColorRGB24
function ColorRGB16_mt.__index:getColorRGB24()
    local r = rshift(self.v, 11)
    local g = band(rshift(self.v, 5), 0x3F)
    local b = band(self.v, 0x001F)
    return ColorRGB24(lshift(r, 3) + rshift(r, 2), lshift(g, 2) + rshift(g, 4), lshift(b, 3) + rshift(b, 2))
end
function ColorRGB24_mt.__index:getColorRGB24() return ColorRGB24(self.r, self.g, self.b) end
ColorRGB32_mt.__index.getColorRGB24 = ColorRGB24_mt.__index.getColorRGB24

-- to ColorRGB32:
function Color4L_mt.__index:getColorRGB32()
    local v = self:getColor8()
    return ColorRGB32(v.a, v.a, v.a, 0xFF)
end
Color4U_mt.__index.getColorRGB32 = Color4L_mt.__index.getColorRGB32
function Color8_mt.__index:getColorRGB32() return ColorRGB32(self.a, self.a, self.a, 0xFF) end
function Color8A_mt.__index:getColorRGB32() return ColorRGB32(self.a, self.a, self.a, self.alpha) end
function ColorRGB16_mt.__index:getColorRGB32()
    local r = rshift(self.v, 11)
    local g = band(rshift(self.v, 5), 0x3F)
    local b = band(self.v, 0x001F)
    return ColorRGB32(lshift(r, 3) + rshift(r, 2), lshift(g, 2) + rshift(g, 4), lshift(b, 3) + rshift(b, 2), 0xFF)
end
function ColorRGB24_mt.__index:getColorRGB32() return ColorRGB32(self.r, self.g, self.b, 0xFF) end
function ColorRGB32_mt.__index:getColorRGB32() return ColorRGB32(self.r, self.g, self.b, self.alpha) end

-- RGB getters (with the necessary trickery for non-RGB color types)
function Color4L_mt.__index:getR() return self:getColor8().a end
Color4L_mt.__index.getG = Color4L_mt.__index.getR
Color4L_mt.__index.getB = Color4L_mt.__index.getR
function Color4L_mt.__index:getAlpha() return 0xFF end
Color4U_mt.__index.getR = Color4L_mt.__index.getR
Color4U_mt.__index.getG = Color4L_mt.__index.getR
Color4U_mt.__index.getB = Color4L_mt.__index.getR
Color4U_mt.__index.getAlpha = Color4L_mt.__index.getAlpha
function Color8_mt.__index:getR() return self.a end
Color8_mt.__index.getG = Color8_mt.__index.getR
Color8_mt.__index.getB = Color8_mt.__index.getR
Color8_mt.__index.getAlpha = Color4L_mt.__index.getAlpha
Color8A_mt.__index.getR = Color8_mt.__index.getR
Color8A_mt.__index.getG = Color8_mt.__index.getR
Color8A_mt.__index.getB = Color8_mt.__index.getR
function Color8A_mt.__index:getAlpha() return self.alpha end
function ColorRGB16_mt.__index:getR()
    local r = rshift(self.v, 11)
    return lshift(r, 3) + rshift(r, 2)
end
function ColorRGB16_mt.__index:getG()
    local g = band(rshift(self.v, 5), 0x3F)
    return lshift(g, 2) + rshift(g, 4)
end
function ColorRGB16_mt.__index:getB()
    local b = band(self.v, 0x001F)
    return lshift(b, 3) + rshift(b, 2)
end
ColorRGB16_mt.__index.getAlpha = Color4L_mt.__index.getAlpha
function ColorRGB24_mt.__index:getR() return self.r end
function ColorRGB24_mt.__index:getG() return self.g end
function ColorRGB24_mt.__index:getB() return self.b end
ColorRGB24_mt.__index.getAlpha = Color4L_mt.__index.getAlpha
ColorRGB32_mt.__index.getR = ColorRGB24_mt.__index.getR
ColorRGB32_mt.__index.getG = ColorRGB24_mt.__index.getG
ColorRGB32_mt.__index.getB = ColorRGB24_mt.__index.getB
ColorRGB32_mt.__index.getAlpha = Color8A_mt.__index.getAlpha

-- modifications:
-- inversion:
function Color4L_mt.__index:invert() return Color4L(bxor(self.a, 0x0F)) end
function Color4U_mt.__index:invert() return Color4U(bxor(self.a, 0xF0)) end
function Color8_mt.__index:invert() return Color8(bxor(self.a, 0xFF)) end
function Color8A_mt.__index:invert() return Color8A(bxor(self.a, 0xFF), self.alpha) end
function ColorRGB16_mt.__index:invert() return ColorRGB16(bxor(self.v, 0xFFFF)) end
function ColorRGB24_mt.__index:invert()
    return ColorRGB24(bxor(self.r, 0xFF), bxor(self.g, 0xFF), bxor(self.b, 0xFF))
end
function ColorRGB32_mt.__index:invert()
    return ColorRGB32(bxor(self.r, 0xFF), bxor(self.g, 0xFF), bxor(self.b, 0xFF), self.alpha)
end

-- comparison:
function ColorRGB32_mt:__eq(color)
    local c = color:getColorRGB32()
    return (self:getR() == c:getR())
    and (self:getG() == c:getG())
    and (self:getB() == c:getB())
    and (self:getAlpha() == c:getAlpha())
end
Color4L_mt.__eq = ColorRGB32_mt.__eq
Color4U_mt.__eq = ColorRGB32_mt.__eq
Color8_mt.__eq = ColorRGB32_mt.__eq
Color8A_mt.__eq = ColorRGB32_mt.__eq
ColorRGB16_mt.__eq = ColorRGB32_mt.__eq
ColorRGB24_mt.__eq = ColorRGB32_mt.__eq

-- pretty printing
function Color4L_mt:__tostring()
    return "Color4L("..band(self.a, 0x0F)..")"
end
function Color4U_mt:__tostring()
    return "Color4U("..rshift(band(self.a, 0xF0),4)..")"
end
function Color8_mt:__tostring()
    return "Color8("..self.a..")"
end
function Color8A_mt:__tostring()
    return "Color8A("..self.a ..", "..self.alpha..")"
end
function ColorRGB16_mt:__tostring()
    return "ColorRGB16("..self:getR()..", "..self:getG()..", "..self:getB()..")"
end
function ColorRGB24_mt:__tostring()
    return "ColorRGB24("..self:getR()..", "..self:getG()..", "..self:getB()..")"
end
function ColorRGB32_mt:__tostring()
    return "ColorRGB32("..self:getR()..", "..self:getG()..", "..self:getB()..", "..self:getAlpha()..")"
end

local MASK_ALLOCATED = 0x01
local SHIFT_ALLOCATED = 0
local MASK_INVERSE = 0x02
local SHIFT_INVERSE = 1
local MASK_ROTATED = 0x0C
local SHIFT_ROTATED = 2
local MASK_TYPE = 0xF0
local SHIFT_TYPE = 4

local TYPE_BB4 = 0
local TYPE_BB8 = 1
local TYPE_BB8A = 2
local TYPE_BBRGB16 = 3
local TYPE_BBRGB24 = 4
local TYPE_BBRGB32 = 5

local BB = {}

-- metatables for BlitBuffer objects:
local BB4_mt = {__index={}}
local BB8_mt = {__index={}}
local BB8A_mt = {__index={}}
local BBRGB16_mt = {__index={}}
local BBRGB24_mt = {__index={}}
local BBRGB32_mt = {__index={}}

-- this is like a metatable for the others,
-- but we don't make it a metatable because LuaJIT
-- doesn't cope well with ctype metatables with
-- metatables on them
-- we just replicate what's in the following table
-- when we set the other metatables for their types
local BB_mt = {__index={}}

function BB_mt.__index:getRotation()
    return rshift(band(MASK_ROTATED, self.config), SHIFT_ROTATED)
end
function BB_mt.__index:setRotation(rotation_mode)
    self.config = bor(band(self.config, bxor(MASK_ROTATED, 0xFF)), lshift(rotation_mode, SHIFT_ROTATED))
end
function BB_mt.__index:rotateAbsolute(degree)
    local mode = (degree % 360) / 90
    self:setRotation(mode)
    return self
end
function BB_mt.__index:rotate(degree)
    degree = degree + self:getRotation()*90
    return self:rotateAbsolute(degree)
end
function BB_mt.__index:getInverse()
    return rshift(band(MASK_INVERSE, self.config), SHIFT_INVERSE)
end
function BB_mt.__index:setInverse(inverse)
    self.config = bor(band(self.config, bxor(MASK_INVERSE, 0xFF)), lshift(inverse, SHIFT_INVERSE))
end
function BB_mt.__index:invert()
    self:setInverse(band(self:getInverse() + 1, 1))
    return self
end
function BB_mt.__index:getAllocated()
    return rshift(band(MASK_ALLOCATED, self.config), SHIFT_ALLOCATED)
end
function BB_mt.__index:setAllocated(allocated)
    self.config = bor(band(self.config, bxor(MASK_ALLOCATED, 0xFF)), lshift(allocated, SHIFT_ALLOCATED))
    if allocated == 1 then
        ffi.gc(self, BB.gc)
    else
        ffi.gc(self, nil)
    end
end
function BB_mt.__index:getType()
    return rshift(band(MASK_TYPE, self.config), SHIFT_TYPE)
end

-- NOTE: On Android, we want to *avoid* the Lua blitter at all costs, *especially* pixel loops,
--       in order to save precious mcode memory!
--       c.f., https://github.com/koreader/koreader-base/pull/1263 & co.
function BB:getUseCBB()
   return use_cblitbuffer
end

-- In practice, that means that we overload the C BB checks to always return true
-- (because use_cblitbuffer will be true on Android).
-- This means that the invert flag is effectively ignored, as it's not supported by the C blitter.
-- So, how do we handle nightmode, if we can't rely on the Lua fallback?
-- Well, the flag may be ignored by the blitter, but it's still there:
-- so, when flipping the buffer for Android's window, ffi/framebuffer_android.lua
-- just does an invertblitFrom instead of a blitFrom if the screen bb is flagged as inverted,
-- as the only way this could happen is with nightmode enabled.
if os.getenv("IS_ANDROID") then
    BB_mt.__index.canUseCbbTogether = BB.getUseCBB
    BB_mt.__index.canUseCbb = BB.getUseCBB
else
    -- Determine if a pair of buffers can use CBB in relation to each other, or whether CBB is used at all.
    -- Used to skip unsupported modes such as unrelated inverses.
    -- TODO: Possibly some RGB24/32 stuff too?
    function BB_mt.__index:canUseCbbTogether(other)
        return use_cblitbuffer and self:getInverse() == other:getInverse()
    end

    -- The C blitter doesn't honor the invert flag, in which case we fall back to Lua.
    function BB_mt.__index:canUseCbb()
        return use_cblitbuffer and self:getInverse() == 0
    end
end

-- Bits per pixel
function BB4_mt.__index:getBpp() return 4 end
function BB8_mt.__index:getBpp() return 8 end
function BB8A_mt.__index:getBpp() return 16 end
function BBRGB16_mt.__index:getBpp() return 16 end
function BBRGB24_mt.__index:getBpp() return 24 end
function BBRGB32_mt.__index:getBpp() return 32 end
-- Or, generally more useful, bytes per pixel
function BB4_mt.__index:getBytesPerPixel() return 0.5 end
function BB8_mt.__index:getBytesPerPixel() return 1 end
function BB8A_mt.__index:getBytesPerPixel() return 2 end
function BBRGB16_mt.__index:getBytesPerPixel() return 2 end
function BBRGB24_mt.__index:getBytesPerPixel() return 3 end
function BBRGB32_mt.__index:getBytesPerPixel() return 4 end
function BB_mt.__index:isRGB()
    local bb_type = self:getType()
    if bb_type == TYPE_BBRGB16
        or bb_type == TYPE_BBRGB24
        or bb_type == TYPE_BBRGB32 then
        return true
    end
    return false
end
function BB_mt.__index:setType(type_id)
    self.config = bor(band(self.config, bxor(MASK_TYPE, 0xFF)), lshift(type_id, SHIFT_TYPE))
end
function BB_mt.__index:getPhysicalCoordinates(x, y)
    local rotation = self:getRotation()
    if rotation == 0 then
        return              x,              y
    elseif rotation == 1 then
        return self.w - y - 1,              x
    elseif rotation == 2 then
        return self.w - x - 1, self.h - y - 1
    elseif rotation == 3 then
        return              y, self.h - x - 1
    end
end
function BB_mt.__index:getPhysicalRect(x, y, w, h)
    local rotation = self:getRotation()
    if rotation == 0 then
        return                x,                y, w, h
    elseif rotation == 1 then
        return self.w - (y + h),                x, h, w
    elseif rotation == 2 then
        return self.w - (x + w), self.h - (y + h), w, h
    elseif rotation == 3 then
        return                y, self.h - (x + w), h, w
    end
end

-- physical coordinate checking
function BB_mt.__index:checkCoordinates(x, y)
    assert(x >= 0, "x coordinate >= 0")
    assert(y >= 0, "y coordinate >= 0")
    assert(x < self:getWidth(), "x coordinate < width")
    assert(y < self:getHeight(), "y coordinate < height")
end

-- getPixelP (pointer) routines, working on physical coordinates
function BB_mt.__index:getPixelP(x, y)
    --self:checkCoordinates(x, y)
    return ffi.cast(self.data, ffi.cast(uint8pt, self.data) + self.stride*y) + x
end
function BB4_mt.__index:getPixelP(x, y)
    --self:checkCoordinates(x, y)
    local p = self.data + self.stride*y + rshift(x, 1)
    if band(x, 1) == 0 then
        return ffi.cast(P_Color4U, p)
    else
        return ffi.cast(P_Color4L, p)
    end
end

-- Do *NOT* write to the returned pointer!
-- If you want an actual write pointer, use getPixelP
function BB_mt.__index:getPixel(x, y)
    local px, py = self:getPhysicalCoordinates(x, y)
    local color = self:getPixelP(px, py)[0]
    if self:getInverse() == 1 then
        return color:invert()
    else
        return color
    end
end

-- blitbuffer specific color conversions
function BB4_mt.__index.getMyColor(color) return color:getColor4L() end
function BB8_mt.__index.getMyColor(color) return color:getColor8() end
function BB8A_mt.__index.getMyColor(color) return color:getColor8A() end
function BBRGB16_mt.__index.getMyColor(color) return color:getColorRGB16() end
function BBRGB24_mt.__index.getMyColor(color) return color:getColorRGB24() end
function BBRGB32_mt.__index.getMyColor(color) return color:getColorRGB32() end

-- set pixel values
function BB_mt.__index:setPixel(x, y, color)
    local px, py = self:getPhysicalCoordinates(x, y)
    if self:getInverse() == 1 then
        self:getPixelP(px, py)[0]:set(color:invert())
    else
        self:getPixelP(px, py)[0]:set(color)
    end
end
-- Dithering (BB8 only)
function BB8_mt.__index:setPixelDither(x, y, color, na, o_x, o_y)
    local px, py = self:getPhysicalCoordinates(x, y)
    local c = color:getColor8()
    if self:getInverse() == 1 then c = c:invert() end
    c.a = dither_o8x8(o_x, o_y, c.a)
    self:getPixelP(px, py)[0]:set(c)
end
BB_mt.__index.setPixelDither = BB_mt.__index.setPixel
-- Add
function BB_mt.__index:setPixelAdd(x, y, color, alpha)
    -- fast path:
    if alpha == 0 then
        return
    elseif alpha == 0xFF then
        return self:setPixel(x, y, color)
    end
    -- this method works with a grayscale value
    local px, py = self:getPhysicalCoordinates(x, y)
    local c = color:getColor8A()
    if self:getInverse() == 1 then c = c:invert() end
    c.alpha = alpha
    self:getPixelP(px, py)[0]:blend(c)
end
function BBRGB16_mt.__index:setPixelAdd(x, y, color, alpha)
    -- fast path:
    if alpha == 0 then
        return
    elseif alpha == 0xFF then
        return self:setPixel(x, y, color)
    end
    -- this method uses an RGB color value
    local px, py = self:getPhysicalCoordinates(x, y)
    local c = color:getColorRGB32()
    if self:getInverse() == 1 then c = c:invert() end
    c.alpha = alpha
    self:getPixelP(px, py)[0]:blend(c)
end
BBRGB24_mt.__index.setPixelAdd = BBRGB16_mt.__index.setPixelAdd
BBRGB32_mt.__index.setPixelAdd = BBRGB16_mt.__index.setPixelAdd
-- Multiply
function BB_mt.__index:setPixelMultiply(x, y, color)
    -- this method uses an RGB24 color value
    local px, py = self:getPhysicalCoordinates(x, y)
    local c = color:getColorRGB24()
    if self:getInverse() == 1 then c = c:invert() end
    self:getPixelP(px, py)[0]:mul(c)
end
-- Straight alpha blending
function BB_mt.__index:setPixelBlend(x, y, color)
    -- fast path:
    local alpha = color:getAlpha()
    if alpha == 0 then
        return
    elseif alpha == 0xFF then
        return self:setPixel(x, y, color)
    end
    -- The blend method for these types of target BB assumes a grayscale input
    local px, py = self:getPhysicalCoordinates(x, y)
    local c = color:getColor8A()
    if self:getInverse() == 1 then c = c:invert() end
    self:getPixelP(px, py)[0]:blend(c)
end
function BBRGB16_mt.__index:setPixelBlend(x, y, color)
    -- fast path:
    local alpha = color:getAlpha()
    if alpha == 0 then
        return
    elseif alpha == 0xFF then
        return self:setPixel(x, y, color)
    end
    local px, py = self:getPhysicalCoordinates(x, y)
    if self:getInverse() == 1 then
        self:getPixelP(px, py)[0]:blend(color:invert())
    else
        self:getPixelP(px, py)[0]:blend(color)
    end
end
BBRGB24_mt.__index.setPixelBlend = BBRGB16_mt.__index.setPixelBlend
BBRGB32_mt.__index.setPixelBlend = BBRGB16_mt.__index.setPixelBlend
-- Straight alpha blending + dithering (dithering applied on BB8 only)
function BB8_mt.__index:setPixelDitherBlend(x, y, color, na, o_x, o_y)
    -- fast path:
    local alpha = color:getAlpha()
    if alpha == 0 then
        return
    elseif alpha == 0xFF then
        return self:setPixelDither(x, y, color, na, o_x, o_y)
    end
    -- The blend method for these types of target BB assumes a grayscale input
    local px, py = self:getPhysicalCoordinates(x, y)
    local c = color:getColor8A()
    if self:getInverse() == 1 then c = c:invert() end
    self:getPixelP(px, py)[0]:ditherblend(o_x, o_y, c)
end
BB_mt.__index.setPixelDitherBlend = BB_mt.__index.setPixelBlend
-- Premultiplied alpha blending
function BB_mt.__index:setPixelPmulBlend(x, y, color)
    -- fast path:
    local alpha = color:getAlpha()
    if alpha == 0 then
        return
    elseif alpha == 0xFF then
        return self:setPixel(x, y, color)
    end
    -- The pmulblend method for these types of target BB assumes a grayscale input
    local px, py = self:getPhysicalCoordinates(x, y)
    local c = color:getColor8A()
    if self:getInverse() == 1 then c = c:invert() end
    self:getPixelP(px, py)[0]:pmulblend(c)
end
function BBRGB16_mt.__index:setPixelPmulBlend(x, y, color)
    -- fast path:
    local alpha = color:getAlpha()
    if alpha == 0 then
        return
    elseif alpha == 0xFF then
        return self:setPixel(x, y, color)
    end
    local px, py = self:getPhysicalCoordinates(x, y)
    if self:getInverse() == 1 then
        self:getPixelP(px, py)[0]:pmulblend(color:invert())
    else
        self:getPixelP(px, py)[0]:pmulblend(color)
    end
end
BBRGB24_mt.__index.setPixelPmulBlend = BBRGB16_mt.__index.setPixelPmulBlend
BBRGB32_mt.__index.setPixelPmulBlend = BBRGB16_mt.__index.setPixelPmulBlend
-- Premultiplied alpha blending + dithering (dithering applied on BB8 only)
function BB8_mt.__index:setPixelDitherPmulBlend(x, y, color, na, o_x, o_y)
    -- fast path:
    local alpha = color:getAlpha()
    if alpha == 0 then
        return
    elseif alpha == 0xFF then
        return self:setPixelDither(x, y, color, na, o_x, o_y)
    end
    -- The pmulblend method for these types of target BB assumes a grayscale input
    local px, py = self:getPhysicalCoordinates(x, y)
    local c = color:getColor8A()
    if self:getInverse() == 1 then c = c:invert() end
    self:getPixelP(px, py)[0]:ditherpmulblend(o_x, o_y, c)
end
BB_mt.__index.setPixelDitherPmulBlend = BB_mt.__index.setPixelPmulBlend
-- Colorize (NOTE: colorblitFrom has already handled inversion for us)
function BB_mt.__index:setPixelColorize(x, y, mask, color)
    -- use 8bit grayscale pixel value as alpha for blitting
    local alpha = mask:getColor8().a
    -- fast path:
    if alpha == 0 then
        return
    end
    local px, py = self:getPhysicalCoordinates(x, y)
    if alpha == 0xFF then
        self:getPixelP(px, py)[0]:set(color)
    else
        -- NOTE: We're using an alpha mask, not color's actual alpha value, which we don't want to mess with,
        --       as that's a pointer to our set_param...
        --       Avoids screwing with alpha when blitting to 8A or RGB32 bbs (c.f., #3949).
        self:getPixelP(px, py)[0]:blend(color, alpha)
    end
end
-- Colorize in an RGB32 color (NOTE: colorblitFrom has already handled inversion for us)
function BB_mt.__index:setPixelColorizeRGB32(x, y, mask, color)
    -- use 8bit grayscale pixel value as alpha for blitting
    local alpha = mask:getColor8().a
    -- fast path:
    if alpha == 0 then
        return
    end
    local px, py = self:getPhysicalCoordinates(x, y)
    -- Grayscale the input color
    local c = color:getColor8()
    if alpha == 0xFF then
        self:getPixelP(px, py)[0]:set(c)
    else
        -- NOTE: We're using an alpha mask, not color's actual alpha value, which we don't want to mess with,
        --       as that's a pointer to our set_param...
        --       Avoids screwing with alpha when blitting to 8A or RGB32 bbs (c.f., #3949).
        self:getPixelP(px, py)[0]:blend(c, alpha)
    end
end
function BBRGB16_mt.__index:setPixelColorizeRGB32(x, y, mask, color)
    local alpha = mask:getColor8().a
    if alpha == 0 then
        return
    end
    local px, py = self:getPhysicalCoordinates(x, y)
    -- We keep the input ColorRGB32 color as-is
    if alpha == 0xFF then
        self:getPixelP(px, py)[0]:set(color)
    else
        self:getPixelP(px, py)[0]:blend(color, alpha)
    end
end
BBRGB24_mt.__index.setPixelColorizeRGB32 = BBRGB16_mt.__index.setPixelColorizeRGB32
BBRGB32_mt.__index.setPixelColorizeRGB32 = BBRGB16_mt.__index.setPixelColorizeRGB32
-- Invert
function BB_mt.__index:setPixelInverted(x, y, color)
    self:setPixel(x, y, color:invert())
end

-- checked Pixel setting:
function BB_mt.__index:setPixelClamped(x, y, color)
    if x >= 0 and x < self:getWidth() and y >= 0 and y < self:getHeight() then
        self:setPixel(x, y, color)
    end
end

function BB_mt.__index:setPixelClampedAA(x, y, color, weight)
    local blend_color = color:getColor8A()
    blend_color.alpha = min(255, max(0, weight))
    if x >= 0 and x < self:getWidth() and y >= 0 and y < self:getHeight() then
        self:setPixelBlend(x, y, blend_color)
    end
end

-- functions for accessing dimensions
function BB_mt.__index:getWidth()
    if 0 == band(1, self:getRotation()) then
        return self.w
    else
        return self.h
    end
end

function BB_mt.__index:getHeight()
    if 0 == band(1, self:getRotation()) then
        return self.h
    else
        return self.w
    end
end

-- names of optimized blitting routines
BB_mt.__index.blitfunc = "blitDefault" -- not optimized
BB4_mt.__index.blitfunc = "blitTo4"
BB8_mt.__index.blitfunc = "blitTo8"
BB8A_mt.__index.blitfunc = "blitTo8A"
BBRGB16_mt.__index.blitfunc = "blitToRGB16"
BBRGB24_mt.__index.blitfunc = "blitToRGB24"
BBRGB32_mt.__index.blitfunc = "blitToRGB32"

--[[
generic boundary check for copy operations

@param length length of copy operation
@param target_offset where to place part into target
@param source_offset where to take part from in source
@param target_size length of target buffer
@param source_size length of source buffer

@return adapted length that actually fits
@return adapted target offset, guaranteed within range 0..(target_size-1)
@return adapted source offset, guaranteed within range 0..(source_size-1)
--]]
function BB.checkBounds(length, target_offset, source_offset, target_size, source_size)
    -- deal with negative offsets
    if target_offset < 0 then
        length = length + target_offset
        source_offset = source_offset - target_offset
        target_offset = 0
    end
    if source_offset < 0 then
        length = length + source_offset
        target_offset = target_offset - source_offset
        source_offset = 0
    end
    -- calculate maximum lengths (size left starting at offset)
    local target_left = target_size - target_offset
    local source_left = source_size - source_offset
    -- return corresponding values
    if target_left <= 0 or source_left <= 0 then
        return 0, 0, 0
    elseif length <= target_left and length <= source_left then
        -- length is the smallest value
        return floor(length), floor(target_offset), floor(source_offset)
    elseif target_left < length and target_left < source_left then
        -- target_left is the smallest value
        return floor(target_left), floor(target_offset), floor(source_offset)
    else
        -- source_left must be the smallest value
        return floor(source_left), floor(target_offset), floor(source_offset)
    end
end

-- A couple helper functions to compute aligned values...
-- c.f., <linux/kernel.h> & ffi/framebuffer_linux.lua
local function ALIGN_DOWN(x, a)
    -- x & ~(a-1)
    local mask = a - 1
    return band(x, bnot(mask))
end

local function ALIGN_UP(x, a)
    -- (x + (a-1)) & ~(a-1)
    local mask = a - 1
    return band(x + mask, bnot(mask))
end

--[[
More specific checkBounds variant that will return the specified rect bounded inside the blitbuffer.
i.e., make sure that x & y don't go OOB on either side, and that x+w & y+h don't go over their respective dimensions.

@param x coordinate
@param y coordinate
@param w dimension
@param h dimension
@param alignment *optional* alignment constraint, if not nil, *must* be > 0 and a power of two!

@return rect strictly bounded inside the bb
--]]
function BB_mt.__index:getBoundedRect(x, y, w, h, alignment)
    local max_w = self:getWidth()
    local max_h = self:getHeight()

    -- Deal with OOB coordinates
    if x >= max_w then
        x = 0
        w = 0
    end
    if y >= max_h then
        y = 0
        h = 0
    end

    -- Deal with negative coordinates
    if x < 0 then
        w = w + x
        x = 0
    end
    if y < 0 then
        h = h + y
        y = 0
    end

    -- Align to pixel grid
    x = floor(x)
    y = floor(y)
    w = ceil(w)
    h = ceil(h)

    -- Honor alignment constraints, if any.
    -- coordinates can only go down, but never below 0, so there's no risk of it invalidating our previous OOB checks.
    -- NOTE: c.f., dithering comments in framebuffer_mxcfb for a potential use-case
    if alignment then
        local x_orig = x
        x = ALIGN_DOWN(x_orig, alignment)
        local x_fixup = x_orig - x
        w = ALIGN_UP(w + x_fixup, alignment)
        local y_orig = y
        y = ALIGN_DOWN(y_orig, alignment)
        local y_fixup = y_orig - y
        h = ALIGN_UP(h + y_fixup, alignment)
    end

    -- Make sure the rect fits strictly inside the bb
    if x + w > max_w then
        w = max_w - x
    end
    if y + h > max_h then
        h = max_h - y
    end

    return x, y, w, h
end

function BB_mt.__index:blitDefault(dest, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
    -- slow default variant:
    local o_y = offs_y
    for y = dest_y, dest_y+height-1 do
        local o_x = offs_x
        for x = dest_x, dest_x+width-1 do
            setter(dest, x, y, self:getPixel(o_x, o_y), set_param, o_x, o_y)
            o_x = o_x + 1
        end
        o_y = o_y + 1
    end
end
-- no optimized blitting by default:
BB_mt.__index.blitTo4 = BB_mt.__index.blitDefault
BB_mt.__index.blitTo8 = BB_mt.__index.blitDefault
BB_mt.__index.blitTo8A = BB_mt.__index.blitDefault
BB_mt.__index.blitToRGB16 = BB_mt.__index.blitDefault
BB_mt.__index.blitToRGB24 = BB_mt.__index.blitDefault
BB_mt.__index.blitToRGB32 = BB_mt.__index.blitDefault

-- Same to same fast blitting
function BB8_mt.__index:blitTo8(dest, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
    -- We can only do fast copy for simple blitting with no processing (setPixel, no rota, no invert)
    if setter ~= self.setPixel or self:getRotation() ~= 0 or dest:getRotation() ~= 0 or (self:getInverse() ~= dest:getInverse()) then
        return self:blitDefault(dest, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
    end

    -- Perform block copies only in the simple case of the blit width being equal to width of both buffers of same stride.
    if offs_x == 0 and dest_x == 0 and width == self.w and width == dest.w and dest.stride == self.stride then
        -- Single step for contiguous scanlines (on both sides)
        --print("BB8 to BB8 full copy")
        -- BB8 is 1 byte per pixel
        local srcp = self.data + self.stride*offs_y
        local dstp = dest.data + dest.stride*dest_y
        ffi.copy(dstp, srcp, width*height)
    else
        -- Scanline per scanline copy
        --print("BB8 to BB8 scanline copy")
        local o_y = offs_y
        for y = dest_y, dest_y+height-1 do
            -- BB8 is 1 byte per pixel
            local srcp = self.data + self.stride*o_y + offs_x
            local dstp = dest.data + dest.stride*y + dest_x
            ffi.copy(dstp, srcp, width)
            o_y = o_y + 1
        end
    end
end
function BBRGB32_mt.__index:blitToRGB32(dest, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
    -- We can only do fast copy for simple blitting with no processing (setPixel, no rota, no invert)
    if setter ~= self.setPixel or self:getRotation() ~= 0 or dest:getRotation() ~= 0 or (self:getInverse() ~= dest:getInverse()) then
        return self:blitDefault(dest, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
    end

    -- Perform block copies only in the simple case of the blit width being equal to width of both buffers of same stride.
    if offs_x == 0 and dest_x == 0 and width == self.w and width == dest.w and dest.stride == self.stride then
        -- Single step for contiguous scanlines (on both sides)
        --print("BBRGB32 to BBRGB32 full copy")
        -- BBRGB32 is 4 bytes per pixel
        local srcp = ffi.cast(uint8pt_rodata, self.data) + self.stride*offs_y
        local dstp = ffi.cast(uint8pt, dest.data) + dest.stride*dest_y
        ffi.copy(dstp, srcp, lshift(width, 2)*height)
    else
        -- Scanline per scanline copy
        --print("BBRGB32 to BBRGB32 scanline copy")
        local o_y = offs_y
        for y = dest_y, dest_y+height-1 do
            -- BBRGB32 is 4 bytes per pixel
            local srcp = ffi.cast(uint8pt_rodata, self.data) + self.stride*o_y + lshift(offs_x, 2)
            local dstp = ffi.cast(uint8pt, dest.data) + dest.stride*y + lshift(dest_x, 2)
            ffi.copy(dstp, srcp, lshift(width, 2))
            o_y = o_y + 1
        end
    end
end

function BB_mt.__index:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
    width, height = width or source:getWidth(), height or source:getHeight()
    -- NOTE: If we convince CRe to render to a padded buffer (to match pixel_stride and allow us single-copy blitting),
    --       change the self:get* calls to self:getPhysical* ones ;).
    --       c.f., https://github.com/koreader/koreader-base/pull/878#issuecomment-476312508
    width, dest_x, offs_x = BB.checkBounds(width, dest_x or 0, offs_x or 0, self:getWidth(), source:getWidth())
    height, dest_y, offs_y = BB.checkBounds(height, dest_y or 0, offs_y or 0, self:getHeight(), source:getHeight())
    if width <= 0 or height <= 0 then return end

    if not setter then setter = self.setPixel end
    if self:canUseCbbTogether(source) and setter == self.setPixel then
        cblitbuffer.BB_blit_to(ffi.cast(P_BlitBuffer_ROData, source),
            ffi.cast(P_BlitBuffer, self),
            dest_x, dest_y, offs_x, offs_y, width, height)
    else
        source[self.blitfunc](source, self, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
    end
end
BB_mt.__index.blitFullFrom = BB_mt.__index.blitFrom

-- blitting with a per-blit alpha value
function BB_mt.__index:addblitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, intensity)
    if self:canUseCbbTogether(source) then
        width, height = width or source:getWidth(), height or source:getHeight()
        width, dest_x, offs_x = BB.checkBounds(width, dest_x or 0, offs_x or 0, self:getWidth(), source:getWidth())
        height, dest_y, offs_y = BB.checkBounds(height, dest_y or 0, offs_y or 0, self:getHeight(), source:getHeight())
        if width <= 0 or height <= 0 then return end
        cblitbuffer.BB_add_blit_from(ffi.cast(P_BlitBuffer, self),
            ffi.cast(P_BlitBuffer_ROData, source),
            dest_x, dest_y, offs_x, offs_y, width, height, intensity*0xFF)
    else
        self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixelAdd, intensity*0xFF)
    end
end

-- alpha-pane aware blitting
-- straight alpha
function BB_mt.__index:alphablitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height)
    if self:canUseCbbTogether(source) then
        width, height = width or source:getWidth(), height or source:getHeight()
        width, dest_x, offs_x = BB.checkBounds(width, dest_x or 0, offs_x or 0, self:getWidth(), source:getWidth())
        height, dest_y, offs_y = BB.checkBounds(height, dest_y or 0, offs_y or 0, self:getHeight(), source:getHeight())
        if width <= 0 or height <= 0 then return end
        cblitbuffer.BB_alpha_blit_from(ffi.cast(P_BlitBuffer, self),
            ffi.cast(P_BlitBuffer_ROData, source),
            dest_x, dest_y, offs_x, offs_y, width, height)
    else
        self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixelBlend)
    end
end
-- straight alpha w/ dithering (dithering only if target is BB8)
function BB_mt.__index:ditheralphablitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height)
    if self:canUseCbbTogether(source) then
        width, height = width or source:getWidth(), height or source:getHeight()
        width, dest_x, offs_x = BB.checkBounds(width, dest_x or 0, offs_x or 0, self:getWidth(), source:getWidth())
        height, dest_y, offs_y = BB.checkBounds(height, dest_y or 0, offs_y or 0, self:getHeight(), source:getHeight())
        if width <= 0 or height <= 0 then return end
        cblitbuffer.BB_dither_alpha_blit_from(ffi.cast(P_BlitBuffer, self),
            ffi.cast(P_BlitBuffer_ROData, source),
            dest_x, dest_y, offs_x, offs_y, width, height)
    else
        self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixelDitherBlend)
    end
end
-- premultiplied alpha
function BB_mt.__index:pmulalphablitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height)
    if self:canUseCbbTogether(source) then
        width, height = width or source:getWidth(), height or source:getHeight()
        width, dest_x, offs_x = BB.checkBounds(width, dest_x or 0, offs_x or 0, self:getWidth(), source:getWidth())
        height, dest_y, offs_y = BB.checkBounds(height, dest_y or 0, offs_y or 0, self:getHeight(), source:getHeight())
        if width <= 0 or height <= 0 then return end
        cblitbuffer.BB_pmulalpha_blit_from(ffi.cast(P_BlitBuffer, self),
            ffi.cast(P_BlitBuffer_ROData, source),
            dest_x, dest_y, offs_x, offs_y, width, height)
    else
        self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixelPmulBlend)
    end
end
-- premultiplied alpha w/ dithering (dithering only if target is BB8)
function BB_mt.__index:ditherpmulalphablitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height)
    if self:canUseCbbTogether(source) then
        width, height = width or source:getWidth(), height or source:getHeight()
        width, dest_x, offs_x = BB.checkBounds(width, dest_x or 0, offs_x or 0, self:getWidth(), source:getWidth())
        height, dest_y, offs_y = BB.checkBounds(height, dest_y or 0, offs_y or 0, self:getHeight(), source:getHeight())
        if width <= 0 or height <= 0 then return end
        cblitbuffer.BB_dither_pmulalpha_blit_from(ffi.cast(P_BlitBuffer, self),
            ffi.cast(P_BlitBuffer_ROData, source),
            dest_x, dest_y, offs_x, offs_y, width, height)
    else
        self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixelDitherPmulBlend)
    end
end

-- simple blitting w/ dithering (dithering only if target is BB8)
function BB_mt.__index:ditherblitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height)
    if self:canUseCbbTogether(source) then
        width, height = width or source:getWidth(), height or source:getHeight()
        width, dest_x, offs_x = BB.checkBounds(width, dest_x or 0, offs_x or 0, self:getWidth(), source:getWidth())
        height, dest_y, offs_y = BB.checkBounds(height, dest_y or 0, offs_y or 0, self:getHeight(), source:getHeight())
        if width <= 0 or height <= 0 then return end
        cblitbuffer.BB_dither_blit_to(ffi.cast(P_BlitBuffer_ROData, source),
            ffi.cast(P_BlitBuffer, self),
            dest_x, dest_y, offs_x, offs_y, width, height)
    else
        self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixelDither)
    end
end

-- invert blitting
function BB_mt.__index:invertblitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height)
    if self:canUseCbbTogether(source) then
        width, height = width or source:getWidth(), height or source:getHeight()
        width, dest_x, offs_x = BB.checkBounds(width, dest_x or 0, offs_x or 0, self:getWidth(), source:getWidth())
        height, dest_y, offs_y = BB.checkBounds(height, dest_y or 0, offs_y or 0, self:getHeight(), source:getHeight())
        if width <= 0 or height <= 0 then return end
        cblitbuffer.BB_invert_blit_from(ffi.cast(P_BlitBuffer, self),
            ffi.cast(P_BlitBuffer_ROData, source),
            dest_x, dest_y, offs_x, offs_y, width, height)
    else
        self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixelInverted)
    end
end

-- colorize area using source blitbuffer as a alpha-map
function BB_mt.__index:colorblitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, color)
    -- we need color with alpha later:
    local c = color:getColor8A()
    if self:canUseCbbTogether(source) then
        width, height = width or source:getWidth(), height or source:getHeight()
        width, dest_x, offs_x = BB.checkBounds(width, dest_x or 0, offs_x or 0, self:getWidth(), source:getWidth())
        height, dest_y, offs_y = BB.checkBounds(height, dest_y or 0, offs_y or 0, self:getHeight(), source:getHeight())
        if width <= 0 or height <= 0 then return end
        cblitbuffer.BB_color_blit_from(ffi.cast(P_BlitBuffer, self),
            ffi.cast(P_BlitBuffer_ROData, source),
            dest_x, dest_y, offs_x, offs_y, width, height, c)
    else
        if self:getInverse() == 1 then c = c:invert() end
        self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixelColorize, c)
    end
end

function BB_mt.__index:colorblitFromRGB32(source, dest_x, dest_y, offs_x, offs_y, width, height, color)
    -- Enforce type coercion for safety (plus, we might need a copy for inversion anyway)
    local c = color:getColorRGB32()
    if self:canUseCbbTogether(source) then
        width, height = width or source:getWidth(), height or source:getHeight()
        width, dest_x, offs_x = BB.checkBounds(width, dest_x or 0, offs_x or 0, self:getWidth(), source:getWidth())
        height, dest_y, offs_y = BB.checkBounds(height, dest_y or 0, offs_y or 0, self:getHeight(), source:getHeight())
        if width <= 0 or height <= 0 then return end
        cblitbuffer.BB_color_blit_from_RGB32(ffi.cast(P_BlitBuffer, self),
            ffi.cast(P_BlitBuffer_ROData, source),
            dest_x, dest_y, offs_x, offs_y, width, height, c)
    else
        if self:getInverse() == 1 then c = c:invert() end
        self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixelColorizeRGB32, c)
    end
end

-- scale method does not modify the original blitbuffer, instead, it allocates
-- and returns a new scaled blitbuffer.
function BB_mt.__index:scale(new_width, new_height)
    local self_w, self_h = self:getWidth(), self:getHeight()
    local scaled_bb = BB.new(new_width, new_height, self:getType())
    -- uses very simple nearest neighbour scaling
    for y=0, new_height-1 do
        for x=0, new_width-1 do
            scaled_bb:setPixel(x, y,
            self:getPixel(util.idiv(x*self_w, new_width),
                          util.idiv(y*self_h, new_height)))
        end
    end
    return scaled_bb
end

-- rotatedCopy method, unlike rotate method, does not modify the original
-- blitbuffer, instead, it allocates and returns a new rotated blitbuffer.
function BB_mt.__index:rotatedCopy(degree)
    self:rotate(degree) -- rotate in-place
    local rot_w, rot_h = self:getWidth(), self:getHeight()
    local rot_bb = BB.new(rot_w, rot_h, self:getType())
    rot_bb:blitFrom(self, 0, 0, 0, 0, rot_w, rot_h)
    self:rotate(-degree) -- revert in-place rotation
    return rot_bb
end

--[[
explicit unset

will free resources immediately
this is also called upon garbage collection
--]]
function BB_mt.__index:free()
    if band(lshift(1, SHIFT_ALLOCATED), self.config) ~= 0 then
        self.config = band(self.config, bxor(0xFF, lshift(1, SHIFT_ALLOCATED)))
        C.free(self.data)
        ffi.gc(self, nil)
    end
end

--[[
memory management, via an explicit FFI cdata finalizer, since the __gc metamethod only runs on userdata in Lua 5.1/LuaJIT,
not on tables. LuaJIT *does* support the __gc metamethod for (struct/union) ctypes *if* a metatable was associated to it via ffi.metatype.
(e.g., lj-sqlite3 goes that route).
Here, relying on that is a bit tricky because of the whole BB_mt not-being-a-real-metatable hack:
Previous attempts at this mistakenly declared a BB_mt.__index.__gc function,
which made the BB_mt shenanigans below assign this to ctype_mt.__index.__gc, instead of ctype_mt.__gc!
We'd instead need to handle each separately, like we do for __eq & __tostring.
So, prefer doing it explicitly ourselves, as it turns out to be slightly less convoluted to grok anyway,
and makes perfect sense in the context of setAllocated, since *a few* BBs do not actually need a finalizer
(.e.g, a linuxfb screen bb is mmap'ed and its lifetime handled by the linuxfb module),
and/or that state can change at runtime, via setAllocated ;).
c.f., BB_mt.__index:setAllocated()
--]]
function BB.gc(bb)
    bb:free()
end


--[[
PAINTING
--]]

--[[
fill the whole blitbuffer with a given (grayscale) value
--]]
function BB_mt.__index:fill(value)
    if self:canUseCbb() then
        cblitbuffer.BB_fill(ffi.cast(P_BlitBuffer, self),
            value:getColor8().a)
    else
        -- While we could use a plain ffi.fill, there are a few BB types where we do not want to stomp on the alpha byte...
        local bbtype = self:getType()

        -- Handle invert...
        local v = value:getColor8()
        if self:getInverse() == 1 then v = v:invert() end

        --print("fill")
        if bbtype == TYPE_BBRGB32 then
            local src = v:getColorRGB32()
            local p = ffi.cast(P_ColorRGB32, self.data)
            for i = 1, self.pixel_stride*self.h do
                p[0] = src
                -- Pointer arithmetics magic: +1 on an uint32_t* means +4 bytes (i.e., next pixel) ;).
                p = p+1
            end
        elseif bbtype == TYPE_BBRGB16 then
            local src = v:getColorRGB16()
            local p = ffi.cast(P_ColorRGB16, self.data)
            for i = 1, self.pixel_stride*self.h do
                p[0] = src
                p = p+1
            end
        elseif bbtype == TYPE_BB8A then
            local src = v:getColor8A()
            local p = ffi.cast(P_Color8A, self.data)
            for i = 1, self.pixel_stride*self.h do
                p[0] = src
                p = p+1
            end
        else
            -- Should only be BBRGB24 & BB8 left, where we can use ffi.fill ;)
            local p = ffi.cast(uint8pt, self.data)
            ffi.fill(p, self.stride*self.h, v.a)
        end
    end
end

function BB4_mt.__index:fill(value)
    -- Handle invert...
    local v = value:getColor8()
    if self:getInverse() == 1 then v = v:invert() end

    v = v:getColor4L().a
    v = bor(lshift(v, 4), v)
    ffi.fill(self.data, self.stride*self.h, v)
end

--[[
invert a rectangle within the buffer

@param x X coordinate
@param y Y coordinate
@param w width
@param h height
--]]
function BB_mt.__index:invertRect(x, y, w, h)
    x, y, w, h = self:getBoundedRect(x, y, w, h)
    if w <= 0 or h <= 0 then return end
    if self:canUseCbb() then
        cblitbuffer.BB_invert_rect(ffi.cast(P_BlitBuffer, self),
            x, y, w, h)
    else
        -- Handle rotation...
        x, y, w, h = self:getPhysicalRect(x, y, w, h)
        -- Handle any target stride properly (i.e., fetch the amount of bytes taken per pixel)...
        local bpp = self:getBytesPerPixel()
        -- If we know the native data type of a pixel, we can use that instead of doing it byte-per-byte...
        local bbtype = self:getType()

        -- We check against the BB's unrotated coordinates (i.e., self.w and not self:getWidth()),
        -- as our memory region has a fixed layout, too!
        if x == 0 and w == self.w then
            -- Single step for contiguous scanlines
            --print("Full invertRect")
            if bbtype == TYPE_BBRGB32 then
                local p = ffi.cast(uint32pt, ffi.cast(uint8pt, self.data) + self.stride*y)
                -- Account for potentially off-screen scanline bits by using self.pixel_stride instead of w,
                -- as we've just assured ourselves that the requested w matches self.w ;).
                for i = 1, self.pixel_stride*h do
                    p[0] = bxor(p[0], 0x00FFFFFF)
                    -- Pointer arithmetics magic: +1 on an uint32_t* means +4 bytes (i.e., next pixel) ;).
                    p = p+1
                end
            elseif bbtype == TYPE_BBRGB16 then
                local p = ffi.cast(uint16pt, ffi.cast(uint8pt, self.data) + self.stride*y)
                for i = 1, self.pixel_stride*h do
                    p[0] = bxor(p[0], 0xFFFF)
                    p = p+1
                end
            elseif bbtype == TYPE_BB8A then
                local p = ffi.cast(uint16pt, ffi.cast(uint8pt, self.data) + self.stride*y)
                for i = 1, self.pixel_stride*h do
                    p[0] = bxor(p[0], 0x00FF)
                    p = p+1
                end
            else
                -- Should only be BBRGB24 & BB8 left
                local p = ffi.cast(uint8pt, self.data) + self.stride*y
                for i = 1, self.stride*h do
                    p[0] = bxor(p[0], 0xFF)
                    p = p+1
                end
            end
        else
            -- Pixel per pixel
            --print("Pixel invertRect")
            if bbtype == TYPE_BBRGB32 then
                for j = y, y+h-1 do
                    local p = ffi.cast(uint32pt, ffi.cast(uint8pt, self.data) + self.stride*j) + x
                    for i = 0, w-1 do
                        p[0] = bxor(p[0], 0x00FFFFFF)
                        p = p+1
                    end
                end
            elseif bbtype == TYPE_BBRGB16 then
                for j = y, y+h-1 do
                    local p = ffi.cast(uint16pt, ffi.cast(uint8pt, self.data) + self.stride*j) + x
                    for i = 0, w-1 do
                        p[0] = bxor(p[0], 0xFFFF)
                        p = p+1
                    end
                end
            elseif bbtype == TYPE_BB8A then
                for j = y, y+h-1 do
                    local p = ffi.cast(uint16pt, ffi.cast(uint8pt, self.data) + self.stride*j) + x
                    for i = 0, w-1 do
                        p[0] = bxor(p[0], 0x00FF)
                        p = p+1
                    end
                end
            else
                -- Honor bpp because of BBRGB24...
                for j = y, y+h-1 do
                    local p = ffi.cast(uint8pt, self.data) + self.stride*j + bpp*x
                    for i = 0, bpp*(w-1) do
                        p[0] = bxor(p[0], 0xFF)
                        p = p+1
                    end
                end
            end
        end
    end
end

-- No fast paths for BB4
function BB4_mt.__index:invertRect(x, y, w, h)
    self:invertblitFrom(self, x, y, x, y, w, h)
end

--[[
paint a rectangle onto this buffer

@param x X coordinate
@param y Y coordinate
@param w width
@param h height
@param value color value
@param setter function used to set pixels (defaults to normal setPixel)
--]]
function BB_mt.__index:paintRect(x, y, w, h, value, setter)
    setter = setter or self.setPixel
    value = value or Color8(0)
    x, y, w, h = self:getBoundedRect(x, y, w, h)
    if w <= 0 or h <= 0 then return end
    if self:canUseCbb() and setter == self.setPixel then
        cblitbuffer.BB_fill_rect(ffi.cast(P_BlitBuffer, self),
            x, y, w, h, value:getColor8().a)
    else
        -- We can only do fast filling when there's no complex processing involved (i.e., simple setPixel only)
        if setter == self.setPixel then
            -- Handle rotation...
            x, y, w, h = self:getPhysicalRect(x, y, w, h)

            -- While we could use a plain ffi.fill, there are a few BB types where we do not want to stomp on the alpha byte...
            local bbtype = self:getType()

            -- Handle invert...
            local v = value:getColor8()
            if self:getInverse() == 1 then v = v:invert() end

            -- We check against the BB's unrotated coordinates (i.e., self.w and not self:getWidth()),
            -- as our memory region has a fixed layout, too!
            if x == 0 and w == self.w then
                -- Single step for contiguous scanlines
                --print("Single fill paintRect")
                if bbtype == TYPE_BBRGB32 then
                    local src = v:getColorRGB32()
                    local p = ffi.cast(P_ColorRGB32, ffi.cast(uint8pt, self.data) + self.stride*y)
                    for i = 1, self.pixel_stride*h do
                        p[0] = src
                        p = p+1
                    end
                elseif bbtype == TYPE_BBRGB16 then
                    local src = v:getColorRGB16()
                    local p = ffi.cast(P_ColorRGB16, ffi.cast(uint8pt, self.data) + self.stride*y)
                    for i = 1, self.pixel_stride*h do
                        p[0] = src
                        p = p+1
                    end
                elseif bbtype == TYPE_BB8A then
                    local src = v:getColor8A()
                    local p = ffi.cast(P_Color8A, ffi.cast(uint8pt, self.data) + self.stride*y)
                    for i = 1, self.pixel_stride*h do
                        p[0] = src
                        p = p+1
                    end
                else
                    -- BBRGB24 & BB8, where we can just use ffi.fill
                    local p = ffi.cast(uint8pt, self.data) + self.stride*y
                    ffi.fill(p, self.stride*h, v.a)
                end
            else
                -- Scanline per scanline fill
                --print("Scanline fill paintRect")
                if bbtype == TYPE_BBRGB32 then
                    local src = v:getColorRGB32()
                    for j = y, y+h-1 do
                        local p = ffi.cast(P_ColorRGB32, ffi.cast(uint8pt, self.data) + self.stride*j) + x
                        for i = 0, w-1 do
                            p[0] = src
                            p = p+1
                        end
                    end
                elseif bbtype == TYPE_BBRGB24 then
                    for j = y, y+h-1 do
                        local p = ffi.cast(uint8pt, self.data) + self.stride*j + (x * 3)
                        ffi.fill(p, w * 3, v.a)
                    end
                elseif bbtype == TYPE_BBRGB16 then
                    local src = v:getColorRGB16()
                    for j = y, y+h-1 do
                        local p = ffi.cast(P_ColorRGB16, ffi.cast(uint8pt, self.data) + self.stride*j) + x
                        for i = 0, w-1 do
                            p[0] = src
                            p = p+1
                        end
                    end
                elseif bbtype == TYPE_BB8A then
                    local src = v:getColor8A()
                    for j = y, y+h-1 do
                        local p = ffi.cast(P_Color8A, ffi.cast(uint8pt, self.data) + self.stride*j) + x
                        for i = 0, w-1 do
                            p[0] = src
                            p = p+1
                        end
                    end
                else
                    -- BB8
                    for j = y, y+h-1 do
                        local p = ffi.cast(uint8pt, self.data) + self.stride*j + x
                        ffi.fill(p, w, v.a)
                    end
                end
            end
        else
            --print("Old-style paintRect pixel loop")
            for tmp_y = y, y+h-1 do
                for tmp_x = x, x+w-1 do
                    setter(self, tmp_x, tmp_y, value)
                end
            end
        end
    end
end

-- BB4 version, identical if not for the lack of fast filling, because nibbles aren't addressable...
-- Also, no cbb branch, as cbb doesn't handle 4bpp targets at all.
function BB4_mt.__index:paintRect(x, y, w, h, value, setter)
    setter = setter or self.setPixel
    value = value or Color8(0)
    x, y, w, h = self:getBoundedRect(x, y, w, h)
    if w <= 0 or h <= 0 then return end
    for tmp_y = y, y+h-1 do
        for tmp_x = x, x+w-1 do
            setter(self, tmp_x, tmp_y, value)
        end
    end
end

--[[
paintRect variant that takes a ColorRGB32 instead of a luminance value
--]]
function BB_mt.__index:paintRectRGB32(x, y, w, h, color, setter)
    setter = setter or self.setPixel
    x, y, w, h = self:getBoundedRect(x, y, w, h)
    if w <= 0 or h <= 0 then return end
    -- Type coercion for safety
    local c = color and color:getColorRGB32() or ColorRGB32(0x80, 0x80, 0x80, 0xFF)
    if self:canUseCbb() and setter == self.setPixel then
        cblitbuffer.BB_fill_rect_RGB32(ffi.cast(P_BlitBuffer, self),
            x, y, w, h, c)
    else
        -- We can only do fast filling when there's no complex processing involved (i.e., simple setPixel only)
        local bbtype = self:getType()
        if setter == self.setPixel and bbtype ~= TYPE_BBRGB24 then
            -- Handle rotation...
            x, y, w, h = self:getPhysicalRect(x, y, w, h)

            if self:getInverse() == 1 then c = c:invert() end

            -- We check against the BB's unrotated coordinates (i.e., self.w and not self:getWidth()),
            -- as our memory region has a fixed layout, too!
            if x == 0 and w == self.w then
                -- Single step for contiguous scanlines
                --print("Single fill paintRect")
                if bbtype == TYPE_BBRGB32 then
                    local src = c
                    local p = ffi.cast(P_ColorRGB32, ffi.cast(uint8pt, self.data) + self.stride*y)
                    for i = 1, self.pixel_stride*h do
                        p[0] = src
                        p = p+1
                    end
                elseif bbtype == TYPE_BBRGB16 then
                    local src = c:getColorRGB16()
                    local p = ffi.cast(P_ColorRGB16, ffi.cast(uint8pt, self.data) + self.stride*y)
                    for i = 1, self.pixel_stride*h do
                        p[0] = src
                        p = p+1
                    end
                elseif bbtype == TYPE_BB8A then
                    local src = c:getColor8A()
                    local p = ffi.cast(P_Color8A, ffi.cast(uint8pt, self.data) + self.stride*y)
                    for i = 1, self.pixel_stride*h do
                        p[0] = src
                        p = p+1
                    end
                else
                    -- BB8, where we can just use ffi.fill
                    local p = ffi.cast(uint8pt, self.data) + self.stride*y
                    ffi.fill(p, self.stride*h, c:getColor8().a)
                end
            else
                -- Scanline per scanline fill
                --print("Scanline fill paintRect")
                if bbtype == TYPE_BBRGB32 then
                    local src = c
                    for j = y, y+h-1 do
                        local p = ffi.cast(P_ColorRGB32, ffi.cast(uint8pt, self.data) + self.stride*j) + x
                        for i = 0, w-1 do
                            p[0] = src
                            p = p+1
                        end
                    end
                elseif bbtype == TYPE_BBRGB16 then
                    local src = c:getColorRGB16()
                    for j = y, y+h-1 do
                        local p = ffi.cast(P_ColorRGB16, ffi.cast(uint8pt, self.data) + self.stride*j) + x
                        for i = 0, w-1 do
                            p[0] = src
                            p = p+1
                        end
                    end
                elseif bbtype == TYPE_BB8A then
                    local src = c:getColor8A()
                    for j = y, y+h-1 do
                        local p = ffi.cast(P_Color8A, ffi.cast(uint8pt, self.data) + self.stride*j) + x
                        for i = 0, w-1 do
                            p[0] = src
                            p = p+1
                        end
                    end
                else
                    -- BB8
                    for j = y, y+h-1 do
                        local p = ffi.cast(uint8pt, self.data) + self.stride*j + x
                        ffi.fill(p, w, c:getColor8().a)
                    end
                end
            end
        else
            --print("Old-style paintRect pixel loop")
            for tmp_y = y, y+h-1 do
                for tmp_x = x, x+w-1 do
                    setter(self, tmp_x, tmp_y, color)
                end
            end
        end
    end
end

-- BB4 version, identical if not for the lack of fast filling, because nibbles aren't addressable...
-- Also, no cbb branch, as cbb doesn't handle 4bpp targets at all.
function BB4_mt.__index:paintRectRGB32(x, y, w, h, color, setter)
    setter = setter or self.setPixel
    color = color and color:getColor8() or Color8(0x80)
    x, y, w, h = self:getBoundedRect(x, y, w, h)
    if w <= 0 or h <= 0 then return end
    for tmp_y = y, y+h-1 do
        for tmp_x = x, x+w-1 do
            setter(self, tmp_x, tmp_y, color)
        end
    end
end

--[[
paint a circle onto this buffer

@param x1 X coordinate of the circle's center
@param y1 Y coordinate of the circle's center
@param r radius
@param c color value (defaults to black)
@param w width of line (defaults to radius)
--]]
function BB_mt.__index:paintCircle(center_x, center_y, r, c, w)
    c = c or Color8(0)
    if r == 0 then return end
    if w == nil then w = r end
    if w > r then w = r end

    -- for outer circle
    local x = 0
    local y = r
    local delta = 5/4 - r

    -- for inner circle
    local r2 = r - w
    local x2 = 0
    local y2 = r2
    local delta2 = 5/4 - r

    -- draw two axles
    for tmp_y = r, r2+1, -1 do
        self:setPixelClamped(center_x+0, center_y+tmp_y, c)
        self:setPixelClamped(center_x-0, center_y-tmp_y, c)
        self:setPixelClamped(center_x+tmp_y, center_y+0, c)
        self:setPixelClamped(center_x-tmp_y, center_y-0, c)
    end

    while x < y do
        -- decrease y if we are out of circle
        x = x + 1;
        if delta > 0 then
            y = y - 1
            delta = delta + 2*x - 2*y + 2
        else
            delta = delta + 2*x + 1
        end

        -- inner circle finished drawing, increase y linearly for filling
        if x2 > y2 then
            y2 = y2 + 1
            x2 = x2 + 1
        else
            x2 = x2 + 1
            if delta2 > 0 then
                y2 = y2 - 1
                delta2 = delta2 + 2*x2 - 2*y2 + 2
            else
                delta2 = delta2 + 2*x2 + 1
            end
        end

        for tmp_y = y, y2+1, -1 do
            self:setPixelClamped(center_x+x, center_y+tmp_y, c)
            self:setPixelClamped(center_x+tmp_y, center_y+x, c)

            self:setPixelClamped(center_x+tmp_y, center_y-x, c)
            self:setPixelClamped(center_x+x, center_y-tmp_y, c)

            self:setPixelClamped(center_x-x, center_y-tmp_y, c)
            self:setPixelClamped(center_x-tmp_y, center_y-x, c)

            self:setPixelClamped(center_x-tmp_y, center_y+x, c)
            self:setPixelClamped(center_x-x, center_y+tmp_y, c)
        end
    end
    if r == w then
        self:setPixelClamped(center_x, center_y, c)
    end
end

-- function plotCircleAA(xm, ym, r)
--     {                     /* draw a black anti-aliased circle on white background */
--        var x = r, y = 0;            /* II. quadrant from bottom left to top right */
--        var i, x2, e2, err = 2-2*r;                             /* error of 1.step */
--        r = 1-err;
--        for ( ; ; ) {
--           i = 255*Math.abs(err+2*(x+y)-2)/r;          /* get blend value of pixel */
--           setPixelAA(xm+x, ym-y, i);                             /*   I. Quadrant */
--           setPixelAA(xm+y, ym+x, i);                             /*  II. Quadrant */
--           setPixelAA(xm-x, ym+y, i);                             /* III. Quadrant */
--           setPixelAA(xm-y, ym-x, i);                             /*  IV. Quadrant */
--           if (x == 0) break;
--           e2 = err; x2 = x;                                    /* remember values */
--           if (err > y) {                                                /* x step */
--              i = 255*(err+2*x-1)/r;                              /* outward pixel */
--              if (i < 255) {
--                 setPixelAA(xm+x, ym-y+1, i);
--                 setPixelAA(xm+y-1, ym+x, i);
--                 setPixelAA(xm-x, ym+y-1, i);
--                 setPixelAA(xm-y+1, ym-x, i);
--              }  
--              err -= --x*2-1; 
--           } 
--           if (e2 <= x2--) {                                             /* y step */
--              i = 255*(1-2*y-e2)/r;                                /* inward pixel */
--              if (i < 255) {
--                 setPixelAA(xm+x2, ym-y, i);
--                 setPixelAA(xm+y, ym+x2, i);
--                 setPixelAA(xm-x2, ym+y, i);
--                 setPixelAA(xm-y, ym-x2, i);
--              }  
--              err -= --y*2-1; 
--           } 
--        }
--     }

-- function BB_mt.__index:paintCircleAA(center_x, center_y, r, c)
--     local x, y = r, 0
--     local i, x2, e2
--     local err = 2-2*r
--     r = 1-err
--     while true do
--         i = 255*math.abs(err+2*(x+y)-2)/r
--         self:setPixelClampedAA(center_x+x, center_y-y, c, 255-i)
--         self:setPixelClampedAA(center_x+y, center_y+x, c, 255-i)
--         self:setPixelClampedAA(center_x-x, center_y+y, c, 255-i)
--         self:setPixelClampedAA(center_x-y, center_y-x, c, 255-i)
--         if x == 0 then break end
--         e2, x2 = err, x
--         if err > y then
--             i = 255*(err+2*x-1)/r
--             if i < 255 then
--                 self:setPixelClampedAA(center_x+x, center_y-y+1, c, 255-i)
--                 self:setPixelClampedAA(center_x+y-1, center_y+x, c, 255-i)
--                 self:setPixelClampedAA(center_x-x, center_y+y-1, c, 255-i)
--                 self:setPixelClampedAA(center_x-y+1, center_y-x, c, 255-i)
--             end
--             x = x - 1
--             err = err - (x*2-1)
--         end
--         local x2_temp = x2
--         x2 = x2 - 1
--         if e2 <= x2_temp then
--             i = 255*(1-2*y-e2)/r
--             if i < 255 then
--                 self:setPixelClampedAA(center_x+x2, center_y-y, c, 255-i)
--                 self:setPixelClampedAA(center_x+y, center_y+x2, c, 255-i)
--                 self:setPixelClampedAA(center_x-x2, center_y+y, c, 255-i)
--                 self:setPixelClampedAA(center_x-y, center_y-x2, c, 255-i)
--             end
--             y = y - 1
--             err = err - (y*2-1)
--         end
--     end
-- end

function BB_mt.__index:paintEllipseRectAA(x0, y0, x1, y1, c)
    x0, y0, x1, y1 = floor(x0), floor(y0), floor(x1), floor(y1)
    local a, b = math.abs(x1-x0), math.abs(y1-y0)
    local b1 = band(b, 1)
    local dx, dy = 4*(a-1)*b*b, 4*(b1+1)*a*a
    local f, ed, i
    local err = b1*a*a-dx+dy

    if a == 0 or b == 0 then
        self:paintLineAA(x0, y0, x1, y1, c)
        return
    end
    if x0 > x1 then
        x0 = x1
        x1 = x1 + a
    end
    if y0 > y1 then
        y0 = y1
    end
    y0 = y0 + rshift(b+1, 1)
    y1 = y0 - b1
    a = 8*a*a
    b1 = 8*b*b

    while true do
        i, ed = math.min(dx, dy), math.max(dx, dy)
        if y0 == y1+1 and err > dy and a > b1 then
            ed = 255*4/a
        else
            ed = 255/(ed+2*ed*i*i/(4*ed*ed+i*i))
        end
        i = ed*math.abs(err+dx-dy)
        self:setPixelClampedAA(x0, y0, c, 255-i)
        self:setPixelClampedAA(x0, y1, c, 255-i)
        self:setPixelClampedAA(x1, y0, c, 255-i)
        self:setPixelClampedAA(x1, y1, c, 255-i)
        
        f = (2*err+dy >= 0)
        if f then
            if x0 >= x1 then
                break
            end
            i = ed*(err+dx)
            if i < 256 then
                self:setPixelClampedAA(x0, y0+1, c, 255-i)
                self:setPixelClampedAA(x0, y1-1, c, 255-i)
                self:setPixelClampedAA(x1, y0+1, c, 255-i)
                self:setPixelClampedAA(x1, y1-1, c, 255-i)
            end
        end

        if 2*err <= dx then
            i = ed*(dy-err)
            if i < 256 then
                self:setPixelClampedAA(x0+1, y0, c, 255-i)
                self:setPixelClampedAA(x1-1, y0, c, 255-i)
                self:setPixelClampedAA(x0+1, y1, c, 255-i)
                self:setPixelClampedAA(x1-1, y1, c, 255-i)
            end
            y0 = y0 + 1
            y1 = y1 - 1
            dy = dy + a
            err = err + dy
        end
        
        if f then
            x0 = x0 + 1
            x1 = x1 - 1
            dx = dx - b1
            err = err - dx
        end
    end

    x0 = x0 - 1
    if x0 == x1 then
        x1 = x1 + 1
        while y0-y1 < b do
            i = 255*4*math.abs(err+dx)/b1
            y0 = y0 + 1
            self:setPixelClampedAA(x0, y0, c, 255-i)
            self:setPixelClampedAA(x1, y0, c, 255-i)
            y1 = y1 - 1
            self:setPixelClampedAA(x0, y1, c, 255-i)
            self:setPixelClampedAA(x1, y1, c, 255-i)
            dy = dy + a
            err = err + dy
        end
    end
end

function BB_mt.__index:paintCircleAA(x0, y0, r, c)
    self:paintEllipseRectAA(x0 - r, y0 - r, x0 + r, y0 + r, c)
end

function BB_mt.__index:paintCircleWidth(x0, y0, r, c, th)
    self:paintEllipseRectWidth(x0 - r, y0 - r, x0 + r, y0 + r, c, th)
end

function BB_mt.__index:paintEllipseRectWidth(x0, y0, x1, y1, c, th)
    x0, y0, x1, y1 = floor(x0), floor(y0), floor(x1), floor(y1)
    local a, b = math.abs(x1-x0), math.abs(y1-y0)
    local b1 = band(b, 1)
    local a2, b2 = a-2*th, b-2*th
    local dx, dy = 4*(a-1)*b*b, 4*(b1-1)*a*a
    local i = a+b2
    local err = b1*a*a
    local dx2, dy2, e2, ed

    if th < 1.5 then
        return self:paintEllipseRectAA(x0, y0, x1, y1, c)
    end
    if (th-1)*(2*b-th) > a*a then
        b2 = math.sqrt(a*(b-a)*i*a2)/(a-th)
    end
    if (th-1)*(2*a-th) > b*b then
        a2 = math.sqrt(b*(a-b)*i*b2)/(b-th)
        th = (a-a2)/2
    end
    if a == 0 or b == 0 then
        return self:paintLineAA(x0, y0, x1, y1, c)
    end
    if x0 > x1 then
        x0 = x1
        x1 = x1 + a
    end
    if y0 > y1 then
        y0 = y1
    end
    if b2 <= 0 then
        th = a
    end

    e2 = th-math.floor(th)
    th = x0 + th - e2
    dx2, dy2 = 4*(a2+2*e2-1)*b2*b2, 4*(b1-1)*a2*a2
    e2 = dx2*e2
    y0 = y0 + rshift(b+1, 1)
    y1 = y0 - b1
    a, b1 = 8*a*a, 8*b*b
    a2, b2 = 8*a2*a2, 8*b2*b2

    while x0 < x1 do
        while true do
            if err < 0 or x0 > x1 then
                i = x0
                break
            end
            i, ed = math.min(dx, dy), math.max(dx, dy)
            if y0 == y1+1 and 2*err > dx and a > b1 then
                ed = a/4
            else
                ed = ed + 2*ed*i*i/(4*ed*ed+i*i+1)+1
            end
            i = 255*err/ed
            self:setPixelClampedAA(x0, y0, c, 255-i)
            self:setPixelClampedAA(x0, y1, c, 255-i)
            self:setPixelClampedAA(x1, y0, c, 255-i)
            self:setPixelClampedAA(x1, y1, c, 255-i)
            if err+dy+a < dx then
                i = x0+1
                break
            end
            x0, x1 = x0+1, x1-1
            err = err - dx
            dx = dx - b1
        end

        while i < th and 2*i <= x0+x1 do
            self:setPixelClamped(i, y0, c)
            self:setPixelClamped(x0+x1-i, y0, c)
            self:setPixelClamped(i, y1, c)
            self:setPixelClamped(x0+x1-i, y1, c)
            i = i + 1
        end

        while e2 > 0 and x0+x1 >= 2*th do
            i, ed = math.min(dx2, dy2), math.max(dx2, dy2)
            if y0 == y1+1 and 2*e2 > dx2 and a2 > b2 then
                ed = a2/4
            else
                ed = ed + 2*ed*i*i/(4*ed*ed+i*i)
            end
            i = 255-255*e2/ed
            self:setPixelClampedAA(th, y0, c, 255-i)
            self:setPixelClampedAA(x0+x1-th, y0, c, 255-i)
            self:setPixelClampedAA(th, y1, c, 255-i)
            self:setPixelClampedAA(x0+x1-th, y1, c, 255-i)
            if e2+dy2+a2 < dx2 then
                break
            end
            th = th + 1
            e2 = e2 - dx2
            dx2 = dx2 - b2
        end
        dy2 = dy2 + a2
        e2 = e2 + dy2
        y0, y1 = y0+1, y1-1
        dy = dy + a
        err = err + dy
    end

    if y0-y1 <= b then
        if err > dy+a then
            y0, y1 = y0-1, y1+1
            dy = dy - a
            err = err - dy
        end
        while y0-y1 <= b do
            i = 255*4*err/b1
            self:setPixelClampedAA(x0, y0, c, 255-i)
            self:setPixelClampedAA(x1, y0, c, 255-i)
            y0 = y0 + 1
            self:setPixelClampedAA(x0, y1, c, 255-i)
            self:setPixelClampedAA(x1, y1, c, 255-i)
            y1 = y1 - 1
            dy = dy + a
            err = err + dy
        end
    end
end

function BB_mt.__index:paintRoundedCorner(off_x, off_y, w, h, bw, r, c, anti_alias)
    if 2*r > h or 2*r > w or r == 0 then
        -- no operation
        return
    end

    if self:canUseCbb() then
        cblitbuffer.BB_paint_rounded_corner(ffi.cast(P_BlitBuffer, self),
            off_x, off_y, w, h, bw, r, c:getColor8().a, anti_alias or 0)
    else
        -- Could be optimized like in 'blitbuffer.c'
        r = min(r, h, w)
        if bw > r then
            bw = r
        end

        -- for outer circle
        local x = 0
        local y = r
        local delta = 5/4 - r

        -- for inner circle
        local r2 = r - bw
        local x2 = 0
        local y2 = r2
        local delta2 = 5/4 - r

        while x < y do
            -- decrease y if we are out of circle
            x = x + 1
            if delta > 0 then
                y = y - 1
                delta = delta + 2*x - 2*y + 2
            else
                delta = delta + 2*x + 1
            end

            -- inner circle finished drawing, increase y linearly for filling
            if x2 > y2 then
                y2 = y2 + 1
                x2 = x2 + 1
            else
                x2 = x2 + 1
                if delta2 > 0 then
                    y2 = y2 - 1
                    delta2 = delta2 + 2*x2 - 2*y2 + 2
                else
                    delta2 = delta2 + 2*x2 + 1
                end
            end

            for tmp_y = y, y2+1, -1 do
                self:setPixelClamped((w-r)+off_x+x-1, (h-r)+off_y+tmp_y-1, c)
                self:setPixelClamped((w-r)+off_x+tmp_y-1, (h-r)+off_y+x-1, c)

                self:setPixelClamped((w-r)+off_x+tmp_y-1, (r)+off_y-x, c)
                self:setPixelClamped((w-r)+off_x+x-1, (r)+off_y-tmp_y, c)

                self:setPixelClamped((r)+off_x-x, (r)+off_y-tmp_y, c)
                self:setPixelClamped((r)+off_x-tmp_y, (r)+off_y-x, c)

                self:setPixelClamped((r)+off_x-tmp_y, (h-r)+off_y+x-1, c)
                self:setPixelClamped((r)+off_x-x, (h-r)+off_y+tmp_y-1, c)
            end
        end
    end
end

--[[
Draw a border

@x:  start position in x axis
@y:  start position in y axis
@w:  width of the border
@h:  height of the border
@bw: line width of the border
@c:  color for loading bar
@r:  radius of for border's corner (nil or 0 means right corner border)
--]]
function BB_mt.__index:paintBorder(x, y, w, h, bw, c, r, anti_alias)
    x, y = ceil(x), ceil(y)
    h, w = ceil(h), ceil(w)
    if not r or r == 0 then
        self:paintRect(x, y, w, bw, c)
        self:paintRect(x, y+h-bw, w, bw, c)
        self:paintRect(x, y+bw, bw, h - 2*bw, c)
        self:paintRect(x+w-bw, y+bw, bw, h - 2*bw, c)
    else
        if h < 2*r then r = floor(h/2) end
        if w < 2*r then r = floor(w/2) end
        self:paintRoundedCorner(x, y, w, h, bw, r, c, anti_alias or 0)
        self:paintRect(r+x, y, w-2*r, bw, c)
        self:paintRect(r+x, y+h-bw, w-2*r, bw, c)
        self:paintRect(x, r+y, bw, h-2*r, c)
        self:paintRect(x+w-bw, r+y, bw, h-2*r, c)
    end
end

--[[
Draw an inner border

@x:  start position in x axis
@y:  start position in y axis
@w:  width of the border
@h:  height of the border
@bw: line width of the border
@c:  color for loading bar
@r:  radius of for border's corner (nil or 0 means right corner border) [FIXME? UNSUPPORTED]
--]]
function BB_mt.__index:paintInnerBorder(x, y, w, h, bw, c, r)
    x, y = ceil(x), ceil(y)
    h, w = ceil(h), ceil(w)
    -- T -> B -> L -> R
    self:paintRect(x, y, w, bw, c)
    self:paintRect(x, y+h-bw, w, bw, c)
    self:paintRect(x, y, bw, h, c)
    self:paintRect(x+w-bw, y, bw, h, c)
end


--[[
Fill a rounded corner rectangular area

@x:  start position in x axis
@y:  start position in y axis
@w:  width of the area
@h:  height of the area
@c:  color used to fill the area
@r:  radius of for four corners
--]]
function BB_mt.__index:paintRoundedRect(x, y, w, h, c, r)
    x, y = ceil(x), ceil(y)
    h, w = ceil(h), ceil(w)
    if not r or r == 0 then
        self:paintRect(x, y, w, h, c)
    else
        if h < 2*r then r = floor(h/2) end
        if w < 2*r then r = floor(w/2) end
        self:paintBorder(x, y, w, h, r, c, r)
        self:paintRect(x+r, y+r, w-2*r, h-2*r, c)
    end
end

function BB_mt.__index:paintLinePerp(x, y, dx, dy, c, width, x_step, y_step, einit, winit)
    local steep = math.abs(dy) > math.abs(dx)
    if steep then
        x, y = y, x
        dx, dy = dy, dx
    end

    local thres = dx - 2 * dy
    local e_diag = -2 * dx
    local e_square = 2 * dy
    local wthr = 2 * width * math.sqrt(dx * dx + dy * dy)

    local tmp_x, tmp_y = x, y
    local error = einit
    local tk = dx + dy - winit
    
    while tk <= wthr do
        if steep then
            self:setPixelClamped(tmp_y, tmp_x, c)
        else
            self:setPixelClamped(tmp_x, tmp_y, c)
        end

        if error > thres then
            tmp_x = tmp_x + x_step
            error = error + e_diag
            tk = tk + 2 * dy
        end
        error = error + e_square
        tmp_y = tmp_y + y_step
        tk = tk + 2 * dx
    end

    tmp_x, tmp_y = x, y
    error = -einit
    tk = dx + dy + winit

    while tk <= wthr do
        if steep then
            self:setPixelClamped(tmp_y, tmp_x, c)
        else
            self:setPixelClamped(tmp_x, tmp_y, c)
        end

        if error > thres then
            tmp_x = tmp_x - x_step
            error = error + e_diag
            tk = tk + 2 * dy
        end
        error = error + e_square
        tmp_y = tmp_y - y_step
        tk = tk + 2 * dx
    end

end

--[[
Bresenham‘s line algorithm to Draw a line with thickness
Reference: https://zingl.github.io/bresenham.html & http://kt8216.unixcab.org/murphy/index.html

@x1:  start point in x axis
@y1:  start point in y axis
@x2:  end point in x axis
@y2:  end point in y axis
@c:   color of the line
@width:   thickness of the line
--]]
function BB_mt.__index:paintLineDirty(x1, y1, x2, y2, c, width)
    x1, y1 = ceil(x1), ceil(y1)
    x2, y2 = ceil(x2), ceil(y2)

    local steep = math.abs(y2 - y1) > math.abs(x2 - x1)
    if steep then
        x1, y1 = y1, x1
        x2, y2 = y2, x2
    end

    if x1 > x2 then
        x1, x2 = x2, x1
        y1, y2 = y2, y1
    end

    local dx = x2 - x1
    local dy = y2 - y1

    local y_step = 1
    if dy < 0 then
        y_step = -1
        dy = -dy
    end

    local error = 0
    local thres = dx - 2 * dy
    local e_diag = -2 * dx
    local e_square = 2 * dy

    local px_step = -1
    local py_step = -1
    if y_step < 0 then
        py_step = -1
    else
        py_step = 1
    end

    local p_error = 0
    local tmp_y = y1
    for tmp_x=x1, x2+1, 1 do
        if steep then
            self:setPixelClamped(tmp_y, tmp_x, c)
            if width > 1 then
                self:paintLinePerp(tmp_y, tmp_x, dy, dx, c, width, px_step, py_step, p_error, error)
            end
        else
            self:setPixelClamped(tmp_x, tmp_y, c)
            if width > 1 then
                self:paintLinePerp(tmp_x, tmp_y, dx, dy, c, width, px_step, py_step, p_error, error)
            end
        end

        if error >= thres then
            tmp_y = tmp_y + y_step
            error = error + e_diag
            if width > 1 then
                if p_error > thres then
                    if steep then
                        self:paintLinePerp(tmp_y, tmp_x, dy, dx, c, width, px_step, py_step, p_error+e_diag+e_square, error)
                    else
                        self:paintLinePerp(tmp_x, tmp_y, dx, dy, c, width, px_step, py_step, p_error+e_diag+e_square, error)
                    end
                    p_error = p_error + e_diag
                end
                p_error = p_error + e_square
            end
        end
            error = error + e_square
        tmp_x = tmp_x + 1
    end
end

function BB_mt.__index:paintLine(x0, y0, x1, y1, c)
    x0, y0, x1, y1 = round(x0), round(y0), round(x1), round(y1)
    local dx = math.abs(x1-x0)
    local sx = x0<x1 and 1 or -1
    local dy = -math.abs(y1-y0)
    local sy = y0<y1 and 1 or -1
    local err = dx+dy
    local e2
    while true do
        self:setPixelClamped(x0, y0, c)
        if x0 == x1 and y0 == y1 then break end
        e2 = 2*err
        if e2 >= dy then
            err = err + dy
            x0 = x0 + sx
        end
        if e2 <= dx then
            err = err + dx
            y0 = y0 + sy
        end
    end
end

function BB_mt.__index:paintLineAA(x0, y0, x1, y1, c)
    x0, y0, x1, y1 = round(x0), round(y0), round(x1), round(y1)
    local dx = math.abs(x1-x0)
    local sx = x0 < x1 and 1 or -1
    local dy = math.abs(y1-y0)
    local sy = y0 < y1 and 1 or -1
    local err = dx-dy
    local e2, x2
    local ed = dx+dy == 0 and 1 or math.sqrt(dx*dx+dy*dy)

    while true do
        self:setPixelClampedAA(x0, y0, c, 255-255*math.abs(err-dx+dy)/ed)
        e2 = err
        x2 = x0
        if 2*e2 >= -dx then
            if x0 == x1 then break end
            if e2+dy < ed then
                self:setPixelClampedAA(x0, y0+sy, c, 255-255*(e2+dy)/ed)
            end
            err = err - dy
            x0 = x0 + sx
        end
        if 2*e2 <= dy then
            if y0 == y1 then break end
            if dx-e2 < ed then
                self:setPixelClampedAA(x2+sx, y0, c, 255-255*(dx-e2)/ed)
            end
            err = err + dx
            y0 = y0 + sy
        end
    end
end

function BB_mt.__index:paintLineWidth(x0, y0, x1, y1, c, w)
    x0, y0, x1, y1 = round(x0), round(y0), round(x1), round(y1)
    local dx = math.abs(x1-x0)
    local sx = x0 < x1 and 1 or -1
    local dy = math.abs(y1-y0)
    local sy = y0 < y1 and 1 or -1
    local err
    local e2 = math.sqrt(dx*dx+dy*dy)

    print(w, e2)
    if w <= 1 or e2 == 0 then
        self:paintLineAA(x0, y0, x1, y1, c)
        return
    end

    dx = dx * 255 / e2
    dy = dy * 255 / e2
    w = 255 * (w - 1)

    if dx < dy then
        x1 = round((e2+w/2)/dy)
        err = x1 * dy - w/2
        x0 = x0 - x1 * sx
        while true do
            x1 = x0
            self:setPixelClampedAA(x1, y0, c, 255-err)
            e2 = dy - err - w
            while e2 + dy < 255 do
                x1 = x1 + sx
                self:setPixelClamped(x1, y0, c)
                e2 = e2 + dy
            end
            self:setPixelClampedAA(x1+sx, y0, c, 255-e2)
            if y0 == y1 then break end
            err = err + dx
            if err > 255 then
                err = err - dy
                x0 = x0 + sx
            end
            y0 = y0 + sy
        end
    else
        y1 = round((e2+w/2)/dx)
        err = y1 * dx - w/2
        y0 = y0 - y1 * sy
        while true do
            y1 = y0
            self:setPixelClampedAA(x0, y1, c, 255-err)
            e2 = dx - err - w
            while e2 + dx < 255 do
                y1 = y1 + sy
                self:setPixelClamped(x0, y1, c)
                e2 = e2 + dx
            end
            self:setPixelClampedAA(x0, y1+sy, c, 255-e2)
            if x0 == x1 then break end
            err = err + dy
            if err > 255 then
                err = err - dx
                y0 = y0 + sy
            end
            x0 = x0 + sx
        end
    end
end

function BB_mt.__index:paintQuadRationalBezierWidthSeg(x0, y0, x1, y1, x2, y2, c, weight, width)
    x0, y0, x1, y1, x2, y2 = round(x0), round(y0), round(x1), round(y1), round(x2), round(y2)
    local sx, sy = x2-x1, y2-y1
    local dx, dy = x0-x2, y0-y2
    local xx, yy = x0-x1, y0-y1
    local xy = xx*sy+yy*sx
    local cur = xx*sy-yy*sx
    local err, e2, ed
    if xx*sx > 0 or yy*sy > 0 then return end
    local direct_return = false

    if cur ~= 0 and weight > 0 then
        if sx*sx+sy*sy > xx*xx+yy*yy then
            x2 = x0
            x0 = x0 - dx
            y2 = y0
            y0 = y0 - dy
            cur = -cur
        end
        xx = 2*(4*weight*sx*xx+dx*dx)
        yy = 2*(4*weight*sy*yy+dy*dy)
        sx = x0 < x2 and 1 or -1
        sy = y0 < y2 and 1 or -1
        xy = -2*sx*sy*(2*weight*xy+dx*dy)

        if cur*sx*sy < 0 then
            xx, yy, cur, xy = -xx, -yy, -cur, -xy
        end
        dx = 4*weight*(x1-x0)*sy*cur+xx/2
        dy = 4*weight*(y0-y1)*sx*cur+yy/2

        if weight < 0.5 and (dx+xx <= 0 or dy+yy >= 0) then
            cur = (weight+1)/2
            weight = math.sqrt(weight)
            xy = 1/(weight+1)
            sx = math.floor((x0+2*weight*x1+x2)*xy/2+0.5)
            sy = math.floor((y0+2*weight*y1+y2)*xy/2+0.5)
            dx = math.floor((weight*x1+x0)*xy+0.5)
            dy = math.floor((y1*weight+y0)*xy+0.5)
            self:paintQuadRationalBezierWidthSeg(x0, y0, dx, dy, sx, sy, c, weight, width)
            dx = math.floor((weight*x1+x2)*xy+0.5)
            dy = math.floor((y1*weight+y2)*xy+0.5)
            self:paintQuadRationalBezierWidthSeg(sx, sy, dx, dy, x2, y2, c, weight, width)
            return
        end

        local function paintLoop()
            err = 0
            while dy+2*yy < 0 and dx+2*xx > 0 do
                if dx+dy+xy < 0 then
                    while dx+dy+xy < 0 do
                        ed = -dy-2*dy*dx*dx/(4*dy*dy+dx*dx)
                        weight = (width-1)*ed
                        x1 = math.floor((err-ed-weight/2)/dy)
                        e2 = err-x1*dy-weight/2
                        x1 = x0-x1*sx
                        -- self:setPixelClamped(x1, y0, anti_alias_color_white(c, 1.-e2/ed))
                        self:setPixelClampedAA(x1, y0, c, 255*(1.-e2/ed))
                        e2 = -weight-dy-e2
                        while e2-dy < ed do
                            x1 = x1 + sx
                            self:setPixelClamped(x1, y0, c)
                            e2 = e2 - dy
                        end
                        -- self:setPixelClamped(x1+sx, y0, anti_alias_color_white(c, 1.-e2/ed))
                        self:setPixelClampedAA(x1+sx, y0, c, 255*(1.-e2/ed))
                        if y0 == y2 then return true end
                        y0 = y0 + sy
                        dy = dy + xy
                        err = err + dx
                        dx = dx + xx
                        if 2*err+dy > 0 then
                            x0 = x0 + sx
                            dx = dx + xy
                            err = err + dy
                            dy = dy + yy
                        end
                        if x0 ~= x2 and (dx+2*xx <= 0 or dy+2*yy >= 0) then
                            if math.abs(y2-y0) > math.abs(x2-x0) then 
                                return false
                            else
                                break
                            end
                        end
                    end

                    cur = err-dy-weight/2
                    y1 = y0
                    while cur < ed do
                        e2 = cur
                        x1 = x0
                        while e2-dy < ed do
                            x1 = x1 - sx
                            self:setPixelClamped(x1, y1, c)
                            e2 = e2 - dy
                        end
                        -- self:setPixelClamped(x1-sx, y1, anti_alias_color_white(c, 1.-e2/ed))
                        self:setPixelClampedAA(x1-sx, y1, c, 255*(1.-e2/ed))
                        y1 = y1 + sy
                        cur = cur + dx
                    end
                else
                    while dx + dy + xy >= 0 do
                        ed = dx + 2 * dx * dy * dy / (4 * dx * dx + dy * dy)
                        weight = (width-1) * ed
                        y1 = math.floor((err+ed+weight/2)/dx)
                        e2 = y1*dx-weight/2-err
                        y1 = y0-y1*sy
                        -- self:setPixelClamped(x0, y1, anti_alias_color_white(c, 1.-e2/ed))
                        self:setPixelClampedAA(x0, y1, c, 255*(1.-e2/ed))
                        e2 = dx-e2-weight
                        while e2+dx < ed do
                            y1 = y1 + sy
                            self:setPixelClamped(x0, y1, c)
                            e2 = e2 + dx
                        end
                        -- self:setPixelClamped(x0, y1+sy, anti_alias_color_white(c, 1.-e2/ed))
                        self:setPixelClampedAA(x0, y1+sy, c, 255*(1.-e2/ed))
                        if x0 == x2 then return true end
                        x0 = x0 + sx
                        dx = dx + xy
                        err = err + dy
                        dy = dy + yy
                        if 2*err+dx < 0 then
                            y0 = y0 + sy
                            dy = dy + xy
                            err = err + dx
                            dx = dx + xx
                        end
                        if y0 ~= y2 and (dx+2*xx <= 0 or dy+2*yy >= 0) then
                            if math.abs(y2-y0) <= math.abs(x2-x0) then
                                return false
                            else
                                break
                            end
                        end
                    end

                    cur = -err+dx-weight/2
                    x1 = x0
                    while cur < ed do
                        e2 = cur
                        y1 = y0
                        while e2+dx < ed do
                            y1 = y1 - sy
                            self:setPixelClamped(x1, y1, c)
                            e2 = e2 + dx
                        end
                        -- self:setPixelClamped(x1, y1-sy, anti_alias_color_white(c, 1.-e2/ed))
                        self:setPixelClampedAA(x1, y1-sy, c, 255*(1.-e2/ed))
                        x1 = x1 + sx
                        cur = cur - dy
                    end
                end         
            end
        end

        direct_return = paintLoop()
    end

    if not direct_return then
        self:paintLineWidth(x0, y0, x2, y2, c, width)
    end
end

function BB_mt.__index:paintQuadRationalBezierWidth(x0, y0, x1, y1, x2, y2, c, weight, width)
    x0, y0, x1, y1, x2, y2 = round(x0), round(y0), round(x1), round(y1), round(x2), round(y2)
    local x, y = x0-2*x1+x2, y0-2*y1+y2
    local xx, yy = x0-x1, y0-y1
    local ww, t, q
    if weight < 0 then return end

    if xx*(x2-x1) > 0 then
        if yy*(y2-y1) > 0 then
            if math.abs(xx*y) > math.abs(yy*x) then
                x0, x2 = x2, xx+x1
                y0, y2 = y2, yy+y1
            end
        end

        if x0 == x2 or weight == 1 then
            t = (x0-x1)/x
        else
            q = math.sqrt(4*weight*weight*(x0-x1)*(x2-x1)+(x2-x0)*(x2-x0))
            if x1 < x0 then q = -q end
            t = (2*weight*(x0-x1)-x0+x2+q)/(2*(1-weight)*(x2-x0))
        end
        q = 1/(2*t*(1-t)*(weight-1)+1)
        xx = (t*t*(x0-2*weight*x1+x2)+2*t*(weight*x1-x0)+x0)*q
        yy = (t*t*(y0-2*weight*y1+y2)+2*t*(weight*y1-y0)+y0)*q
        ww = t*(weight-1)+1
        ww = ww * ww * q
        weight = ((1-t)*(weight-1)+1)*math.sqrt(q)
        x = round(xx)
        y = round(yy)
        yy = (xx-x0)*(y1-y0)/(x1-x0)+y0
        self:paintQuadRationalBezierWidthSeg(x0, y0, x, round(yy), x, y, c, ww, width)
        yy = (xx-x2)*(y1-y2)/(x1-x2)+y2
        y1 = round(yy)
        x1 = x
        x0 = x1
        y0 = y
    end

    if (y0-y1)*(y2-y1) > 0 then
        if y0 == y2 or weight == 1 then
            t = (y0-y1)/(y0-2*y1+y2)
        else
            q = math.sqrt(4*weight*weight*(y0-y1)*(y2-y1)+(y2-y0)*(y2-y0))
            if y1 < y0 then q = -q end
            t = (2*weight*(y0-y1)-y0+y2+q)/(2*(1-weight)*(y2-y0))
        end
        q = 1/(2*t*(1-t)*(weight-1)+1)
        xx = (t*t*(x0-2*weight*x1+x2)+2*t*(weight*x1-x0)+x0)*q
        yy = (t*t*(y0-2*weight*y1+y2)+2*t*(weight*y1-y0)+y0)*q
        ww = t*(weight-1)+1
        ww = ww * ww * q
        weight = ((1-t)*(weight-1)+1)*math.sqrt(q)
        x = round(xx)
        y = round(yy)
        xx = (x1-x0)*(yy-y0)/(y1-y0)+x0
        self:paintQuadRationalBezierWidthSeg(x0, y0, round(xx), y, x, y, c, ww, width)
        xx = (x1-x2)*(yy-y2)/(y1-y2)+x2
        x1 = round(xx)
        x0 = x
        y1 = y
        y0 = y
    end

    self:paintQuadRationalBezierWidthSeg(x0, y0, x1, y1, x2, y2, c, weight*weight, width)
end

function BB_mt.__index:paintCubicBezierSegWidth(x0, y0, x1, y1, x2, y2, x3, y3, c, width)
    x0, y0, x1, y1, x2, y2, x3, y3 = round(x0), round(y0), round(x1), round(y1), round(x2), round(y2), round(x3), round(y3)
    local x = math.floor((x0+3*x1+3*x2+x3+4)/8)
    local y = math.floor((y0+3*y1+3*y2+y3+4)/8)
    self:paintQuadRationalBezierWidthSeg(x0, y0, math.floor((x0+3*x1+2)/4), math.floor((y0+3*y1+2)/4), x, y, c, 1, width)
    self:paintQuadRationalBezierWidthSeg(x, y, math.floor((3*x2+x3+2)/4), math.floor((3*y2+y3+2)/4), x3, y3, c, 1, width)
end

function BB_mt.__index:paintCubicBezierWidth(x0, y0, x1, y1, x2, y2, x3, y3, c, width)
    x0, y0, x1, y1, x2, y2, x3, y3 = round(x0), round(y0), round(x1), round(y1), round(x2), round(y2), round(x3), round(y3)
    local n, i = 1, 0
    local xc = x0+x1-x2-x3
    local xa = xc-4*(x1-x2)
    local xb = x0-x1-x2+x3
    local xd = xb+4*(x1+x2)
    local yc = y0+y1-y2-y3
    local ya = yc-4*(y1-y2)
    local yb = y0-y1-y2+y3
    local yd = yb+4*(y1+y2)
    local fx0 = x0
    local fx1, fx2, fx3
    local fy0 = y0
    local fy1, fy2, fy3
    local t1 = xb*xb-xa*xc
    local t2
    local t = {}

    if xa == 0 then
        if math.abs(xc) < 2*math.abs(xb) then
            t[n] = xc/(2.0*xb)
            n = n + 1
        end
    elseif t1 > 0 then
        t2 = math.sqrt(t1)
        t1 = (xb-t2)/xa
        if math.abs(t1) < 1.0 then
            t[n] = t1
            n = n + 1
        end
        t1 = (xb+t2)/xa
        if math.abs(t1) < 1.0 then
            t[n] = t1
            n = n + 1
        end
    end

    local t1 = yb*yb-ya*yc
    if ya == 0 then
        if math.abs(yc) < 2*math.abs(yb) then
            t[n] = yc/(2.0*yb)
            n = n + 1
        end
    elseif t1 > 0 then
        t2 = math.sqrt(t1)
        t1 = (yb-t2)/ya
        if math.abs(t1) < 1.0 then
            t[n] = t1
            n = n + 1
        end
        t1 = (yb+t2)/ya
        if math.abs(t1) < 1.0 then
            t[n] = t1
            n = n + 1
        end
    end

    t1 = 2 * (xa * yb - xb * ya)
    t2 = xa * yc - xc * ya
    i = t2 * t2 - 2 * t1 * (xb * yc - xc * yb)
    if i > 0 then
        i = math.sqrt(i)
        t[n] = (t2+i)/t1
        if math.abs(t[n]) < 1.0 then
            n = n + 1
        end
        t[n] = (t2-i)/t1
        if math.abs(t[n]) < 1.0 then
            n = n + 1
        end
    end

    for i = 2, n-1 do
        t1 = t[i-1]
        if t1 > t[i] then
            t[i-1], t[i] = t[i], t[i-1]
            i = 0
        end
    end

    t1 = -1.0
    t[n] = 1.0
    for i = 1, n do
        t2 = t[i]
        fx1 = (t1*(t1*xb-2*xc)-t2*(t1*(t1*xa-2*xb)+xc)+xd)/8-fx0
        fy1 = (t1*(t1*yb-2*yc)-t2*(t1*(t1*ya-2*yb)+yc)+yd)/8-fy0
        fx2 = (t2*(t2*xb-2*xc)-t1*(t2*(t2*xa-2*xb)+xc)+xd)/8-fx0
        fy2 = (t2*(t2*yb-2*yc)-t1*(t2*(t2*ya-2*yb)+yc)+yd)/8-fy0
        fx3 = (t2*(t2*(3*xb-t2*xa)-3*xc)+xd)/8
        fx0 = fx0 - fx3
        fy3 = (t2*(t2*(3*yb-t2*ya)-3*yc)+yd)/8
        fy0 = fy0 - fy3
        x3 = round(fx3+0.5)
        y3 = round(fy3+0.5)
        if fx0 ~= 0.0 then
            fx0 = (x0-x3)/fx0
            fx1 = fx1 * fx0
            fx2 = fx2 * fx0
        end
        if fy0 ~= 0.0 then
            fy0 = (y0-y3)/fy0
            fy1 = fy1 * fy0
            fy2 = fy2 * fy0
        end
        if x0 ~= x3 or y0 ~= y3 then
            self:paintCubicBezierSegWidth(x0, y0, x0+fx1, y0+fy1, x0+fx2, y0+fy2, x3, y3, c, width)
        end
        x0, y0, fx0, fy0, t1 = x3, y3, fx3, fy3, t2
    end
end

--[[
Bresenham‘s line algorithm to Draw a line with thickness
Reference: https://zingl.github.io/bresenham.html & http://kt8216.unixcab.org/murphy/index.html

@x1:  start point in x axis
@y1:  start point in y axis
@x2:  end point in x axis
@y2:  end point in y axis
@c:   color of the line
@width:   thickness of the line
--]]
function BB_mt.__index:paintLine2(x1, y1, x2, y2, c, width)
    x1, y1, x2, y2 = ceil(x1), ceil(y1), ceil(x2), ceil(y2)

    local dx = math.abs(x2-x1)
    local dy = math.abs(y2-y1)

    local x_step = x1 > x2 and -1 or 1
    local y_step = y1 > y2 and -1 or 1

    local error = dx - dy
    local error_temp = 0
    local x_temp, y_temp
    local ed = 1
    if dx + dy ~= 0 then
        ed = math.sqrt(dx*dx+dy*dy)
    end

    width = (width + 1) / 2
    while true do
        self:setPixelClamped(x1, y1, Color8(math.max(0, c.a * math.abs(error-dx+dy)/ed-width+1)))
        error_temp = error
        x_temp = x1
        if (2 * error_temp >= -dx) then
            y_temp = y1
            for error_temp = error_temp + dy, ed * width, dx do
                if (y1 ~= y_temp) or (dx > dy) then
                    self:setPixelClamped(x1, y_temp + y_step, Color8(math.max(0, c.a*(math.abs(error_temp)/ed-width+1))))
                    y_temp = y_temp + y_step
                else
                    break
                end
            end
            if x1 == x2 then
                break
            end
            error_temp = error
            error = error - dy
            x1 = x1 + x_step
        end

        if (2 * error_temp <= dy) then
            error_temp = dx - error_temp
            for error_temp = dx - error_temp, ed * width, dy do
                if (x1 ~= x_temp) or (dx < dy) then
                    self:setPixelClamped(x_temp + x_step, y1, Color8(math.max(0, c.a*(math.abs(error_temp)/ed-width+1))))
                    x_temp = x_temp + x_step
                else
                    break
                end
            end
            if y1 == y2 then
                break
            end
            error = error + dx
            y1 = y1 + y_step
        end
    end
end

function BB_mt.__index:paintQuadBezierSeg(x0, y0, x1, y1, x2, y2, c, w)
    local sx, sy = x2-x1, y2-y1
    local xx, yy = x0-x1, y0-y1
    local xy, dx, dy, err
    local cur = xx*sy-yy*sx

    if (xx * sx > 0) or (yy * sy > 0) then
        return
    end
    -- assert(xx*sx <= 0 and yy*sy <= 0)

    if (sx*sx + sy*sy) > (xx*xx + yy*yy) then
        x2 = x0
        x0 = sx + x1
        y2 = y0
        y0 = sy + y1
        cur = -cur
    end

    if cur ~= 0 then
        xx = xx + sx
        sx = (x0 < x2) and 1 or -1
        xx = xx * sx

        yy = yy + sy
        sy = (y0 < y2) and 1 or -1
        yy = yy * sy

        xy = 2 * xx * yy
        xx = xx * xx
        yy = yy * yy

        if cur * sx * sy < 0 then
            xx = -xx; yy = -yy; xy = -xy; cur = -cur
        end
        dx = 4.0 * sy * cur * (x1 - x0) + xx - xy
        dy = 4.0 * sx * cur * (y0 - y1) + yy - xy
        xx, yy, err = xx + xx, yy + yy, dx + dy + xy
        while dy < 0 and dx > 0 do
            self:setPixelClamped(x0, y0, c);
            if (x0 == x2) and (y0 == y2) then return end
            y1 = 2 * err < dx

            if (2 * err > dy) then
                x0 = x0 + sx; dx = dx - xy; dy = dy + yy
                err = err + dy
            end

            if y1 then
                y0 = y0 + sy; dy = dy - xy; dx = dx + xx
                err = err + dx
            end
        end
    end
    self:paintLine(x0, y0, x2, y2, c)
end

function BB_mt.__index:paintQuadBezier(x0, y0, x1, y1, x2, y2, c, w)
    x0, y0, x1, y1, x2, y2 = round(x0), round(y0), round(x1), round(y1), round(x2), round(y2)

    local x = x0-x1
    local y = y0-y1
    local t = x0-2*x1+x2
    local r

    if x * (x2 - x1) > 0 then
        if y * (y2 - y1) > 0 then
            if math.abs((y0-2*y1+y2)/t*x) > math.abs(y) then
                x0 = x2
                x2 = x+x1
                y0 = y2
                y2 = y+y1
            end
        end
        t = (x0-x1)/t
        r = (1-t)*((1-t)*y0+2.0*t*y1)+t*t*y2
        t = (x0*x2-x1*x1)*t/(x0-x1)
        x = math.floor(t+0.5); y = math.floor(r+0.5);
        r = (y1-y0)*(t-x0)/(x1-x0)+y0
        self:paintQuadBezierSeg(x0,y0, x, math.floor(r+0.5), x,y, c, w);
        r = (y1-y2)*(t-x2)/(x1-x2)+y2;
        x0 = x
        x1 = x
        y0 = y
        y1 = math.floor(r+0.5)
    end

    if ((y0-y1)*(y2-y1) > 0) then
        t = y0-2*y1+y2
        t = (y0-y1)/t
        r = (1-t)*((1-t)*x0+2.0*t*x1)+t*t*x2
        t = (y0*y2-y1*y1)*t/(y0-y1)
        x = math.floor(r+0.5); y = math.floor(t+0.5)
        r = (x1-x0)*(t-y0)/(y1-y0)+x0
        self:paintQuadBezierSeg(x0,y0, math.floor(r+0.5),y, x,y, c, w);
        r = (x1-x2)*(t-y2)/(y1-y2)+x2
        x0 = x
        x1 = math.floor(r+0.5)
        y0 = y
        y1 = y
    end

    self:paintQuadBezierSeg(x0,y0, x1,y1, x2,y2, c, w)
end

function BB_mt.__index:paintCubicBezierSeg(x0, y0, x1, y1, x2, y2, x3, y3, c, w)
    local f, fx, fy
    local leg = 1
    local sx = x0 < x3 and 1 or -1
    local sy = y0 < y3 and 1 or -1 -- step direction
    local xc = -math.abs(x0+x1-x2-x3)
    local xa, xb = xc-4*sx*(x1-x2), sx*(x0-x1-x2+x3)
    local yc = -math.abs(y0+y1-y2-y3)
    local ya, yb = yc-4*sy*(y1-y2), sy*(y0-y1-y2+y3)
    local ab, ac, bc, cb, xx, xy, yy, dx, dy, ex, pxy
    local EP = 0.01

    assert((x1-x0)*(x2-x3) < EP and ((x3-x0)*(x1-x2) < EP or xb*xb < xa*xc+EP))
    assert((y1-y0)*(y2-y3) < EP and ((y3-y0)*(y1-y2) < EP or yb*yb < ya*yc+EP))

    if xa == 0 and ya == 0 then
        self:paintQuadBezierSeg(x0, y0, (3 * x1 - x0) / 2, (3 * y1 - y0) / 2, x3, y3)
        return
    end

    x1 = (x1-x0)*(x1-x0)+(y1-y0)*(y1-y0)+1
    x2 = (x2-x3)*(x2-x3)+(y2-y3)*(y2-y3)+1

    while leg > 0 do
        ab = xa*yb-xb*ya; ac = xa*yc-xc*ya; bc = xb*yc-xc*yb;
        ex = ab*(ab+ac-3*bc)+ac*ac
        f = ex > 0 and 1 or math.floor(math.sqrt(1+1024/x1))
        ab = ab * f; ac = ac * f; bc = bc * f; ex = ex * f * f
        xy = 9*(ab+ac+bc)/8; cb = 8*(xa-ya)
        dx = 27*(8*ab*(yb*yb-ya*yc)+ex*(ya+2*yb+yc))/64-ya*ya*(xy-ya)
        dy = 27*(8*ab*(xb*xb-xa*xc)-ex*(xa+2*xb+xc))/64-xa*xa*(xy+xa)
        xx = 3*(3*ab*(3*yb*yb-ya*ya-2*ya*yc)-ya*(3*ac*(ya+yb)+ya*cb))/4;
        yy = 3*(3*ab*(3*xb*xb-xa*xa-2*xa*xc)-xa*(3*ac*(xa+xb)+xa*cb))/4;
        xy = xa*ya*(6*ab+6*ac-3*bc+cb); ac = ya*ya; cb = xa*xa;
        xy = 3*(xy+9*f*(cb*yb*yc-xb*xc*ac)-18*xb*yb*ab)/8;

        if ex < 0 then
            dx = -dx; dy = -dy; xx = -xx; yy = -yy; xy = -xy; ac = -ac; cb = -cb
        end
        ab = 6*ya*ac; ac = -6*xa*ac; bc = 6*ya*cb; cb = -6*xa*cb
        dx = dx + xy; ex = dx+dy; dy = dy + xy

        local function paintLoop()
            pxy = 0
            fx, fy = f, f
            while x0 ~= x3 and y0 ~= y3 do
                self:setPixelClamped(x0, y0, c);
                while fx > 0 and fy > 0 do
                    if pxy == 0 and (dx > xy or dy < xy) then return end
                    if pxy == 1 and (dx > 0 or dy < 0) then return end
                    y1 = 2*ex-dy
                    if (2*ex >= dx) then
                        fx = fx - 1
                        dx = dx + xx
                        ex = ex + dx
                        xy = xy + ac
                        dy = dy + xy
                        yy = yy + bc
                        xx = xx + ab
                    elseif y1 > 0 then
                        return
                    end

                    if y1 <= 0 then
                        fy = fy - 1
                        dy = dy + yy
                        ex = ex + dy
                        xy = xy + bc
                        dx = dx + xy
                        xx = xx + ac
                        yy = yy + cb
                    end
                end
                
                if (2*fx <= f) then 
                    x0 = x0 + sx
                    fx = fx + f
                end
                if (2*fy <= f) then
                    y0 = y0 + sy
                    fy = fy + f
                end 
                if (pxy == 0 and dx < 0 and dy > 0) then
                    pxy = 1
                end
            end
            xx = x0; x0 = x3; x3 = xx; sx = -sx; xb = -xb;
            yy = y0; y0 = y3; y3 = yy; sy = -sy; yb = -yb; x1 = x2;
        end

        paintLoop()
        leg = leg - 1
    end
    self:paintLine(x0, y0, x3, y3, c)
end

function BB_mt.__index:paintCubicBezier(x0, y0, x1, y1, x2, y2, x3, y3, c, w)
    x0, y0, x1, y1, x2, y2, x3, y3 = round(x0), round(y0), round(x1), round(y1), round(x2), round(y2), round(x3), round(y3)
    local n, i = 1, 0
    local xc = x0+x1-x2-x3
    local xa = xc-4*(x1-x2)
    local xb = x0-x1-x2+x3
    local xd = xb+4*(x1+x2)
    local yc = y0+y1-y2-y3
    local ya = yc-4*(y1-y2)
    local yb = y0-y1-y2+y3
    local yd = yb+4*(y1+y2)
    local fx0 = x0
    local fx1, fx2, fx3
    local fy0 = y0
    local fy1, fy2, fy3
    local t1 = xb*xb-xa*xc
    local t2
    local t = {}

    if (xa == 0) then
        if math.abs(xc) < 2 * math.abs(xb) then
            t[n] = xc / (2.0 * xb)
            n = n + 1
        end
    elseif t1 > 0.0 then
        t2 = math.sqrt(t1);
        t1 = (xb-t2)/xa
        if (math.abs(t1) < 1.0) then 
            t[n] = t1;
            n = n + 1
        end
        t1 = (xb+t2)/xa
        if (math.abs(t1) < 1.0) then 
            t[n] = t1;
            n = n + 1
        end
    end
    t1 = yb*yb-ya*yc;

    if (ya == 0) then
        if math.abs(yc) < 2*math.abs(yb) then
            t[n] = yc/(2.0*yb)
            n = n + 1
        end
    elseif t1 > 0.0 then
        t2 = math.sqrt(t1)
        t1 = (yb-t2)/ya
        if math.abs(t1) < 1.0 then
            t[n] = t1;
            n = n + 1
        end 
        t1 = (yb+t2)/ya
        if math.abs(t1) < 1.0 then
            t[n] = t1;
            n = n + 1
        end
    end

    -- bubble sort of 4 points
    for i = 2, n-1 do
        if t[i] < t[i - 1] then
            t[i - 1], t[i] = t[i], t[i - 1]
            i = 1
        end
    end

    t1 = -1.0; t[n] = 1.0;
    for i = 1, n do
        t2 = t[i]
        fx1 = (t1*(t1*xb-2*xc)-t2*(t1*(t1*xa-2*xb)+xc)+xd)/8-fx0
        fy1 = (t1*(t1*yb-2*yc)-t2*(t1*(t1*ya-2*yb)+yc)+yd)/8-fy0
        fx2 = (t2*(t2*xb-2*xc)-t1*(t2*(t2*xa-2*xb)+xc)+xd)/8-fx0
        fy2 = (t2*(t2*yb-2*yc)-t1*(t2*(t2*ya-2*yb)+yc)+yd)/8-fy0
        fx3 = (t2*(t2*(3*xb-t2*xa)-3*xc)+xd)/8
        fx0 = fx0 - fx3
        fy3 = (t2*(t2*(3*yb-t2*ya)-3*yc)+yd)/8
        fy0 = fy0 - fy3
        x3 = math.floor(fx3+0.5)
        y3 = math.floor(fy3+0.5)
        if fx0 ~= 0.0 then
            fx0 = (x0 - x3) / fx0
            fx1 = fx1 * fx0
            fx2 = fx2 * fx0
        end
        if fy0 ~= 0.0 then
            fy0 = (y0 - y3) / fy0
            fy1 = fy1 * fy0
            fy2 = fy2 * fy0
        end
        if x0 ~= x3 or y0 ~= y3 then
            self:paintCubicBezierSeg(x0, y0, x0+fx1, y0+fy1, x0+fx2, y0+fy2, x3, y3, c, w)
        end
        x0 = x3
        y0 = y3
        fx0 = fx3
        fy0 = fy3
        t1 = t2
    end
end

--[[
Paint hatches in a rectangle

@x:  start position in x axis
@y:  start position in y axis
@w:  width of the area
@h:  height of the area
@sw: stripe width
@c:  color used to fill the area
@a:  alpha
--]]
function BB_mt.__index:hatchRect(x, y, w, h, sw, c, a)
    x, y, w, h = self:getBoundedRect(x, y, w, h)
    if w <= 0 or h <= 0 then return end
    a = (a or 1)*0xFF
    if a <= 0 then return end -- fully transparent
    c = c or Color8(0)
    sw = ceil(sw)
    if self:canUseCbb() then
        cblitbuffer.BB_hatch_rect(ffi.cast(P_BlitBuffer, self), x, y, w, h, sw, c, a)
    else
        local sw2 = sw*2
        if a < 0xFF then
            for tmp_y = 0, h-1 do
                for tmp_x = 0, w-1 do
                    if (tmp_x + tmp_y) % sw2 < sw then
                        self:setPixelAdd(x+tmp_x, y+tmp_y, c, a)
                    end
                end
            end
        else
            for tmp_y = 0, h-1 do
                for tmp_x = 0, w-1 do
                    if (tmp_x + tmp_y) % sw2 < sw then
                        self:setPixel(x+tmp_x, y+tmp_y, c)
                    end
                end
            end
        end
    end
end


--[[
Draw a progress bar according to following args:

@x:  start position in x axis
@y:  start position in y axis
@w:  width for progress bar
@h:  height for progress bar
@load_m_w: width margin for loading bar
@load_m_h: height margin for loading bar
@load_percent: progress in percent
@c:  color for loading bar
--]]
function BB_mt.__index:progressBar(x, y, w, h, load_m_w, load_m_h, load_percent, c)
    if load_m_h*2 > h then
        load_m_h = h/2
    end
    self:paintBorder(x, y, w, h, 2, 15)
    self:paintRect(x+load_m_w, y+load_m_h,
    (w-2*load_m_w)*load_percent, (h-2*load_m_h), c)
end

--[[
Ligthen color values in a rectangular area
(i.e., blend pure white at the requested opacity OVER rect).
NOTE: Used to be called dimRect because it effectively makes black text dimmer.

@param x X coordinate
@param y Y coordinate
@param w width
@param h height
@param by lighten by this factor (default: 0.5)
--]]
function BB_mt.__index:lightenRect(x, y, w, h, by)
    local color = Color8A(0xFF, 0xFF*(by or 0.5))
    if self:canUseCbb() then
        x, y, w, h = self:getBoundedRect(x, y, w, h)
        if w <= 0 or h <= 0 then return end
        cblitbuffer.BB_blend_rect(ffi.cast(P_BlitBuffer, self),
            x, y, w, h, color)
    else
        self:paintRect(x, y, w, h, color, self.setPixelBlend)
    end
end

--[[
Darken color values in a rectangular area
(i.e., blend pure black at the requested opacity OVER rect).

@param x X coordinate
@param y Y coordinate
@param w width
@param h height
@param by darken by this factor (default: 0.5)
--]]
function BB_mt.__index:darkenRect(x, y, w, h, by)
    local color = Color8A(0, 0xFF*(by or 0.5))
    if self:canUseCbb() then
        x, y, w, h = self:getBoundedRect(x, y, w, h)
        if w <= 0 or h <= 0 then return end
        cblitbuffer.BB_blend_rect(ffi.cast(P_BlitBuffer, self),
            x, y, w, h, color)
    else
        self:paintRect(x, y, w, h, color, self.setPixelBlend)
    end
end

--[[
Multiply color values in a rectangular area by a given source color.
(i.e., blend color MUL rect).
Mainly used to emulate a highlighter pen over a text buffer.

@param x X coordinate
@param y Y coordinate
@param w width
@param h height
@param color source color (alpha is ignored)
--]]
function BB_mt.__index:multiplyRectRGB(x, y, w, h, color)
    -- Type coercion for safety
    local c = color and color:getColorRGB24() or ColorRGB24(0x80, 0x80, 0x80)
    if self:canUseCbb() then
        x, y, w, h = self:getBoundedRect(x, y, w, h)
        if w <= 0 or h <= 0 then return end
        cblitbuffer.BB_blend_RGB_multiply_rect(ffi.cast(P_BlitBuffer, self),
            x, y, w, h, c)
    else
        self:paintRect(x, y, w, h, c, self.setPixelMultiply)
    end
end

--[[
Blend color values in a rectangular area
(i.e., blend color OVER rect).

@param x X coordinate
@param y Y coordinate
@param w width
@param h height
@param color source color
--]]
function BB_mt.__index:blendRectRGB32(x, y, w, h, color)
    -- Type coercion for safety
    local c = color and color:getColorRGB32() or ColorRGB32(0x80, 0x80, 0x80, 0xFF)
    if self:canUseCbb() then
        x, y, w, h = self:getBoundedRect(x, y, w, h)
        if w <= 0 or h <= 0 then return end
        cblitbuffer.BB_blend_RGB32_over_rect(ffi.cast(P_BlitBuffer, self),
            x, y, w, h, c)
    else
        self:paintRect(x, y, w, h, c, self.setPixelBlend)
    end
end

--[[
make a full copy of the current buffer, with its own memory
--]]
function BB_mt.__index:copy()
    local mytype = ffi.typeof(self)
    local buffer = C.malloc(self.stride * self.h)
    assert(buffer ~= nil, "cannot allocate bb copy buffer")
    ffi.copy(buffer, self.data, self.stride * self.h)
    local copy = mytype(self.w, self.pixel_stride, self.h, self.stride, buffer, self.config)
    copy:setAllocated(1)
    return copy
end

--[[
return a new Blitbuffer object that works on a rectangular
subset of the current Blitbuffer

Note that the caller has to make sure that the underlying memory
(of the Blitbuffer this method is called on) stays in place. In other
words, a viewport does not create a new buffer with memory.
--]]
function BB_mt.__index:viewport(x, y, w, h)
    x, y, w, h = self:getPhysicalRect(x, y, w, h)
    local viewport = BB.new(w, h, self:getType(), self:getPixelP(x, y), self.stride, self.pixel_stride)
    viewport:setRotation(self:getRotation())
    viewport:setInverse(self:getInverse())
    return viewport
end

--[[
write blitbuffer contents to a PNG file (in a PNG pixel format as close as possible as the input one)

@param filename the name of the file to be created
--]]
local Png  -- lazy load ffi/png

function BB4_mt.__index:writePNG(filename)
    if not Png then Png = require("ffi/png") end

    local w, h = self:getWidth(), self:getHeight()
    -- Convert to Y8, I'm not sure how 4-bit grayscale works in PNG...
    local bbdump = BB.new(w, h, TYPE_BB8, nil, w, w)
    bbdump:blitFrom(self)

    Png.encodeToFile(filename, ffi.cast(uint8pt_rodata, bbdump.data), w, h, 1)
    bbdump:free()
end

function BB8_mt.__index:writePNG(filename)
    if not Png then Png = require("ffi/png") end

    local w, h = self:getWidth(), self:getHeight()
    -- Create a copy of the input BB, but with no padding and no soft rotation.
    -- NOTE: We've tried feeding self.data directly to LodePNG when it would be possible (i.e., rota 0, w == pixel_stride),
    --       and it turned out to be hilariously slower. Cache trashing?
    local bbdump = BB.new(w, h, TYPE_BB8, nil, w, w)
    bbdump:blitFrom(self)

    Png.encodeToFile(filename, ffi.cast(uint8pt_rodata, bbdump.data), w, h, 1)
    bbdump:free()
end

function BB8A_mt.__index:writePNG(filename)
    if not Png then Png = require("ffi/png") end

    local w, h = self:getWidth(), self:getHeight()
    -- Create a copy of the input BB, but with no padding and no soft rotation.
    local bbdump = BB.new(w, h, TYPE_BB8A, nil, w * 2, w)
    bbdump:blitFrom(self)

    Png.encodeToFile(filename, ffi.cast(uint8pt_rodata, bbdump.data), w, h, 2)
    bbdump:free()
end

function BBRGB16_mt.__index:writePNG(filename)
    if not Png then Png = require("ffi/png") end

    local w, h = self:getWidth(), self:getHeight()
    -- RGB565 is the worst, convert to RGB24
    local bbdump = BB.new(w, h, TYPE_BBRGB24, nil, w * 3, w)
    bbdump:blitFrom(self)

    Png.encodeToFile(filename, ffi.cast(uint8pt_rodata, bbdump.data), w, h, 3)
    bbdump:free()
end

function BBRGB24_mt.__index:writePNG(filename, bgr)
    -- If input is BGR, devolve straight away to the crap fallback...
    if bgr then return self:writePNGFromBGR(filename) end

    if not Png then Png = require("ffi/png") end

    local w, h = self:getWidth(), self:getHeight()
    -- Create a copy of the input BB, but with no padding and no soft rotation.
    local bbdump = BB.new(w, h, TYPE_BBRGB24, nil, w * 3, w)
    bbdump:blitFrom(self)

    Png.encodeToFile(filename, ffi.cast(uint8pt_rodata, bbdump.data), w, h, 3)
    bbdump:free()
end

function BBRGB32_mt.__index:writePNG(filename, bgr)
    -- If input is BGR, devolve straight away to the crap fallback...
    if bgr then return self:writePNGFromBGR(filename) end

    if not Png then Png = require("ffi/png") end

    local w, h = self:getWidth(), self:getHeight()
    -- Create a copy of the input BB, but with no padding and no soft rotation.
    local bbdump = BB.new(w, h, TYPE_BBRGB32, nil, w * 4, w)
    bbdump:blitFrom(self)

    Png.encodeToFile(filename, ffi.cast(uint8pt_rodata, bbdump.data), w, h, 4)
    bbdump:free()
end

-- Crap manual fallback when a have a BGR <-> RGB swap to handle...
function BB_mt.__index:writePNGFromBGR(filename)
    if not Png then Png = require("ffi/png") end
    local w, h = self:getWidth(), self:getHeight()
    local stride = w * 3
    local cdata = C.malloc(stride * h)
    local mem = ffi.cast(uint8pt, cdata)
    for y = 0, h-1 do
        local offset = stride * y
        for x = 0, w-1 do
            local c = self:getPixel(x, y):getColorRGB24()
            -- NOTE: Thankfully, this crap fallback is only ever used on BGR fbs, so, no branching here...
            mem[offset] = c.b
            mem[offset + 1] = c.g
            mem[offset + 2] = c.r
            offset = offset + 3
        end
    end
    Png.encodeToFile(filename, ffi.cast(uint8pt_rodata, mem), w, h, 3)
    C.free(cdata)
end

local Jpeg -- lazy load ffi/jpeg

function BB_mt.__index:getBufferData()
    local w, h = self:getWidth(), self:getHeight()
    local bbdump, source_ptr, stride
    if self:getType() == TYPE_BBRGB24 then
        source_ptr = ffi.cast(uint8pt, self.data)
        stride = self.stride
    else
        bbdump = BB.new(w, h, TYPE_BBRGB24, nil)
        bbdump:blitFrom(self)
        source_ptr = ffi.cast(uint8pt, bbdump.data)
        stride = bbdump.stride
    end
    return bbdump, source_ptr, w, stride, h
end

function BB_mt.__index:writeBMP(filename, grayscale)
    if not Jpeg then Jpeg = require("ffi/jpeg") end

    local bbdump, source_ptr, w, stride, h = self:getBufferData()

    Jpeg.writeBMP(filename, source_ptr, w, stride, h, grayscale)

    if bbdump then
        bbdump:free()
    end
end

function BB_mt.__index:writeJPG(filename, quality)
    if not Jpeg then Jpeg = require("ffi/jpeg") end

    local bbdump, source_ptr, w, stride, h = self:getBufferData()

    Jpeg.encodeToFile(filename, source_ptr, w, stride, h, quality) -- Colortype default, subsample default

    if bbdump then
        bbdump:free()
    end
end

function BB_mt.__index:writeToFile(filename, format, quality, grayscale)
    format = format or "jpg" -- set default format
    format = format:lower()
    if format == "png" then
        return pcall(self.writePNG, self, filename)
    elseif format == "bmp" then
        return pcall(self.writeBMP, self, filename, grayscale)
    else -- default all other extensions to jpg
        return pcall(self.writeJPG, self, filename, quality)
    end
end

-- if no special case in BB???_mt exists, use function from BB_mt
-- (we do not use BB_mt as metatable for BB???_mt since this causes
-- a major slowdown and would not get properly JIT-compiled)
for name, func in pairs(BB_mt.__index) do
    if not BB4_mt.__index[name] then BB4_mt.__index[name] = func end
    if not BB8_mt.__index[name] then BB8_mt.__index[name] = func end
    if not BB8A_mt.__index[name] then BB8A_mt.__index[name] = func end
    if not BBRGB16_mt.__index[name] then BBRGB16_mt.__index[name] = func end
    if not BBRGB24_mt.__index[name] then BBRGB24_mt.__index[name] = func end
    if not BBRGB32_mt.__index[name] then BBRGB32_mt.__index[name] = func end
end

-- set metatables for the BlitBuffer types
local BlitBuffer4 = ffi.metatype("BlitBuffer4", BB4_mt)
local BlitBuffer8 = ffi.metatype("BlitBuffer8", BB8_mt)
local BlitBuffer8A = ffi.metatype("BlitBuffer8A", BB8A_mt)
local BlitBufferRGB16 = ffi.metatype("BlitBufferRGB16", BBRGB16_mt)
local BlitBufferRGB24 = ffi.metatype("BlitBufferRGB24", BBRGB24_mt)
local BlitBufferRGB32 = ffi.metatype("BlitBufferRGB32", BBRGB32_mt)

-- set metatables for the Color types
ffi.metatype("Color4L", Color4L_mt)
ffi.metatype("Color4U", Color4U_mt)
ffi.metatype("Color8", Color8_mt)
ffi.metatype("Color8A", Color8A_mt)
ffi.metatype("ColorRGB16", ColorRGB16_mt)
ffi.metatype("ColorRGB24", ColorRGB24_mt)
ffi.metatype("ColorRGB32", ColorRGB32_mt)

function BB.new(width, height, buffertype, dataptr, stride, pixel_stride)
    local bb = nil
    buffertype = buffertype or TYPE_BB8
    local bits_per_pixel = assert(BB.TYPE_TO_BPP[tonumber(buffertype)], "unknown buffer type " .. tostring(buffertype))

    -- If no stride is given, make up one from buffer width, while ensuring that 4bpp are always aligned on a byte.
    stride = stride or rshift(width * bits_per_pixel + 7, 3)
    -- If no pixel stride is given, use byte stride * 8 / bpp
    pixel_stride = pixel_stride or (stride * 8 / bits_per_pixel)

    if buffertype == TYPE_BB4 then bb = BlitBuffer4(width, pixel_stride, height, stride, nil, 0)
    elseif buffertype == TYPE_BB8 then bb = BlitBuffer8(width, pixel_stride, height, stride, nil, 0)
    elseif buffertype == TYPE_BB8A then bb = BlitBuffer8A(width, pixel_stride, height, stride, nil, 0)
    elseif buffertype == TYPE_BBRGB16 then bb = BlitBufferRGB16(width, pixel_stride, height, stride, nil, 0)
    elseif buffertype == TYPE_BBRGB24 then bb = BlitBufferRGB24(width, pixel_stride, height, stride, nil, 0)
    elseif buffertype == TYPE_BBRGB32 then bb = BlitBufferRGB32(width, pixel_stride, height, stride, nil, 0)
    else error("unknown blitbuffer type")
    end
    bb:setType(buffertype)
    if dataptr == nil then
        dataptr = C.calloc(stride*height, 1)
        assert(dataptr ~= nil, "cannot allocate memory for new bb")
        bb:setAllocated(1)
    end
    bb.data = ffi.cast(bb.data, dataptr)
    return bb
end

function BB.compat(oldbuffer)
    return ffi.cast("BlitBuffer4*", oldbuffer)[0]
end

function BB.fromstring(width, height, buffertype, str, stride, rotation, inverse)
    local dataptr = C.malloc(#str)
    ffi.copy(dataptr, str, #str)
    local bb = BB.new(width, height, buffertype, dataptr, stride)
    bb:setAllocated(1)
    if rotation ~= nil then
        bb:setRotation(rotation)
    end
    if inverse ~= nil then
        bb:setInverse(inverse)
    end
    return bb
end

function BB.tostring(bb)
    return ffi.string(bb.data, bb.stride * bb.h)
end

--[[
return a Color value resembling a given level of blackness/gray

0 is white, 1.0 is black
--]]
function BB.gray(level)
    return Color8(bxor(floor(0xFF * level), 0xFF))
end

--[[
return a Color value resembling a given hex string (nil on failure)
--]]
function BB.colorFromString(value)
    value = value:gsub('#','')
    -- #rrggbbaa
    if(#value == 8) then
        return ColorRGB32(
            tonumber(value:sub(1, 2), 16),
            tonumber(value:sub(3, 4), 16),
            tonumber(value:sub(5, 6), 16),
            tonumber(value:sub(7, 8), 16)
        )
    -- #rrggbb
    elseif(#value == 6) then
        return ColorRGB32(
            tonumber(value:sub(1, 2), 16),
            tonumber(value:sub(3, 4), 16),
            tonumber(value:sub(5, 6), 16),
            0xFF
        )
    -- #vv
    elseif(#value == 2) then
        return ColorRGB32(
            tonumber(value:sub(1, 2), 16),
            tonumber(value:sub(1, 2), 16),
            tonumber(value:sub(1, 2), 16),
            0xFF
        )
    else
        return nil
    end
end

-- Common color names used for highlights
BB.HIGHLIGHT_COLORS = {
    ["red"]    = "#FF3300",
    ["orange"] = "#FF8800",
    ["yellow"] = "#FFFF33",
    ["green"]  = "#00AA66",
    ["olive"]  = "#88FF77",
    ["cyan"]   = "#00FFEE",
    ["blue"]   = "#0066FF",
    ["purple"] = "#EE00FF",
}
--[[
return a Color value given a common color name (nil for unknown colors)
--]]
function BB.colorFromName(name)
    if not name then return nil end
    local color_hash = BB.HIGHLIGHT_COLORS[name:lower()]
    if not color_hash then return nil end
    return BB.colorFromString(color_hash)
end

--[[
Test whether a Color is a Luminance-only type.

Technically that would mean anything <= Color8A,
but, in practice, since we only care about the constants defined below,
we only check against Color8.
--]]
function BB.isColor8(color)
    return ffi.istype(Color8, color)
end

-- the full eInk palette:
BB.COLOR_WHITE = Color8(0xFF)
BB.COLOR_GRAY_E = Color8(0xEE)
BB.COLOR_GRAY_D = Color8(0xDD)
BB.COLOR_LIGHT_GRAY = Color8(0xCC)
BB.COLOR_GRAY_B = Color8(0xBB)
BB.COLOR_GRAY = Color8(0xAA)
BB.COLOR_GRAY_9 = Color8(0x99) -- was COLOR_WEB_GRAY
BB.COLOR_DARK_GRAY = Color8(0x88)
BB.COLOR_GRAY_7 = Color8(0x77)
BB.COLOR_GRAY_6 = Color8(0x66)
BB.COLOR_GRAY_5 = Color8(0x55) -- was COLOR_DIM_GRAY
BB.COLOR_GRAY_4 = Color8(0x44)
BB.COLOR_GRAY_3 = Color8(0x33)
BB.COLOR_GRAY_2 = Color8(0x22)
BB.COLOR_GRAY_1 = Color8(0x11)
BB.COLOR_BLACK = Color8(0)

-- accessors for color types:
BB.Color4 = Color4L
BB.Color4L = Color4L
BB.Color4U = Color4U
BB.Color8 = Color8
BB.Color8A = Color8A
BB.ColorRGB16 = ColorRGB16
BB.ColorRGB24 = ColorRGB24
BB.ColorRGB32 = ColorRGB32

-- accessors for Blitbuffer types
BB.BlitBuffer4 = BlitBuffer4
BB.BlitBuffer8 = BlitBuffer8
BB.BlitBuffer8A = BlitBuffer8A
BB.BlitBufferRGB16 = BlitBufferRGB16
BB.BlitBufferRGB24 = BlitBufferRGB24
BB.BlitBufferRGB32 = BlitBufferRGB32
BB.TYPE_BB4 = TYPE_BB4
BB.TYPE_BB8 = TYPE_BB8
BB.TYPE_BB8A = TYPE_BB8A
BB.TYPE_BBRGB16 = TYPE_BBRGB16
BB.TYPE_BBRGB24 = TYPE_BBRGB24
BB.TYPE_BBRGB32 = TYPE_BBRGB32
BB.TYPE_TO_BPP = {
    [TYPE_BB4] = 4,
    [TYPE_BB8] = 8,
    [TYPE_BB8A] = 16,
    [TYPE_BBRGB16] = 16,
    [TYPE_BBRGB24] = 24,
    [TYPE_BBRGB32] = 32,
}

BB.has_cblitbuffer = false
-- Load the C blitter, and default to using it if available
BB.has_cblitbuffer, cblitbuffer = pcall(ffi.load, "blitbuffer")
if BB.has_cblitbuffer then
    -- If we can, assume we'll want to use it
    use_cblitbuffer = true
else
    use_cblitbuffer = false
end

-- Allow front to update the use_cblitbuffer flag directly, with no checks and no JIT tweaks
function BB:setUseCBB(enabled)
   use_cblitbuffer = enabled
end

-- Set the actual enable/disable CBB flag and tweak JIT opts accordingly.
-- Returns the actual state.
function BB:enableCBB(enabled)
    local old = use_cblitbuffer
    use_cblitbuffer = enabled and self.has_cblitbuffer
    if old ~= use_cblitbuffer then
        -- NOTE: This works-around a number of corner-cases which may end up with LuaJIT's optimizer blacklisting this very codepath,
        --       which'd obviously *murder* performance (to the effect of a soft-lock, essentially).
        --       c.f., koreader/koreader#4137, koreader/koreader#4752, koreader/koreader#4782,
        --       koreader/koreader#6736, #1233
        --       15 is LuaJIT's default
        local val = use_cblitbuffer and 15 or 45
        jit.opt.start("loopunroll="..tostring(val))
        jit.flush()
    end
    return use_cblitbuffer
end

-- NOTE: reader.lua will update the flag on startup, with the least amount of JIT tweaking possible.

return BB
