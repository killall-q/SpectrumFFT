# SpectrumFFT
###### for [Rainmeter](https://www.rainmeter.net/)
Displays audio FFT as blended color bands.

Choose from 18 preset color schemes or create your own.

---

## Creating Your Own Color Schemes

### Overview

SpectrumFFT displays the volume level of each audio frequency as a color from a color scheme function of your choosing. A color scheme function takes a volume level value between 0 and 1, and outputs a color. When designing a color scheme, think of it as a set of color stops, e.g. transparent at 0% volume to red at 100% volume, and the blending between those color stops.

If a color scheme you make is interesting and unique enough, I'll include it as a default preset in SpectrumFFT!

If you have cannot understand how to create a color scheme function, you can give me a list of color stops and their percentage positions, and I can create it for you.

### Getting Started

Go to this directory:

    Documents\Rainmeter\Skins\SpectrumFFT\@Resources\Presets\

Duplicate the file of an existing preset, and open it in your favorite text editor.

### Function Outline

A basic visualization function (Red.lua is shown) looks like this:
```lua
local v = ...

return '255,0,0,'..(v^3 * 255)
```
SpectrumFFT will convert the above into this function:
```lua
function Preset(v, b, bands)
    return '255,0,0,'..(v^3 * 255)
end
```
Which will then be used like so:
```lua
SKIN:Bang('!SetVariable Color'..b..' '..Preset((mFFT[b]:GetValue() - levelMin) / levelRange, b, bands))
```

Functions are restricted to the use of these input variables:

* __v__  
value of FFT at current band and row, ranging from 0 to 1
* __b__  
number of current band, ranging from 0 to (bands - 1), usually unused
* __bands__  
total number of bands, usually unused

Additionally, you can use any built-in [Lua 5.1 functions](http://www.lua.org/manual/5.1/#index). Global variables and external Lua libraries cannot be used. Rainmeter [variables](https://docs.rainmeter.net/manual/lua-scripting/#GetVariable) and measure values are allowed.

Functions must return a valid color in RGB, RGBA (meaning Red, Green, Blue, Alpha transparency), or hex color format.

### Color Blending

Here is a color scheme with multiple color stops (Infrared.lua):
```lua
local v = ...

if v < 0 then
    return '0,0,0,0'
elseif v < 0.4 then
    --   0,  0,255 @ 0.4
    return '0,0,'..(v * 638)..','..(v * 638)
else
    -- 255,  0,  0 @ 0.8
    -- 255,255,  0 @ 1
    return ((v - 0.4) * 638)..','..((v - 0.8) * 1275)..','..((v - 0.8) * -638)
end
```
It is easier to understand in the non-compact form:
```lua
local v = ...

if v < 0 then
    return '0,0,0,0'
elseif v < 0.4 then
    --   0,  0,255 @ 0.4
    return '0,0,'..(v * 638)..','..(v * 638)
elseif v < 0.8 then
    -- 255,  0,  0 @ 0.8
    return ((v - 0.4) * 638)..',0,'..((v - 0.4) * -638 + 255)
else
    -- 255,255,  0 @ 1
    return '255,'..((v - 0.8) * 1275)..',0'
end
```
It consists of the following color stops:
* ```'0,0,0,0'``` at ```v = 0```
* ```'0,0,255,255'``` at ```v = 0.4```
* ```'255,0,0,255'``` at ```v = 0.8```
* ```'255,255,0,255'``` at ```v = 1```

An RGBA color has 4 color channels. The general formula for smoothly blending a color channel between 2 color stops is:
```
(v - range min of v) * ((change in color channel value) / (range of v)) + (color channel value at range min of v) = output color channel value
```
For example, to blend the red channel from 0 to 255 for range of v = 0.4 to v = 0.8, the formula is:
```
(v - 0.4) * (255 / 0.4) + 0 = (v - 0.4) * 638
```
This formula only covers linear blending. For smoother blending curves, adapt formulas from HoloFFT's tutorial. However, in my experience, linear blending is often sufficient.

Color channel values below 0 are equivalent to 0 and values above 255 are equivalent to 255, so functions don't need to attempt to clamp values to the valid range.
