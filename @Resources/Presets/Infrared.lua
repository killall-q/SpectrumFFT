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
