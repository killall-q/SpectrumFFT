local v = ...

if v < 0 then
  return '255,0,0,0'
else
  -- 255,127,  0 @ 0.5
  -- 255,255,127 @ 1
  return '255,'..(v * 255)..','..((v - 0.5) * 255)..','..(v * 510)
end
