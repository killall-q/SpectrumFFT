function Initialize()
  mFFT, grad = {}, {}
  bands = tonumber(SKIN:GetVariable('Bands')) -- number of FFT bands
  bandPct = 1 / (bands + 1)
  levelMin = tonumber(SKIN:GetVariable('LevelMin'))
  levelRange = tonumber(SKIN:GetVariable('LevelMax')) - levelMin
  scroll = 0 -- preset selection list scroll position
  isLocked = false -- lock hiding of mouseover controls
  if not SKIN:GetMeasure('mFFT1') then
    GenMeasures()
    SKIN:Bang('!Refresh')
    return
  end
  for b = 0, bands - 1 do
    mFFT[b] = SKIN:GetMeasure('mFFT'..b)
  end
  os.remove(SKIN:GetVariable('@')..'Measures.inc')
  LoadPreset()
  SetChannel(SKIN:GetVariable('Channel'))
  SetAngle(0)
  SKIN:Bang('[!SetOption AttackSlider X '..(tonumber(SKIN:GetVariable('Attack')) * 0.09)..'r][!SetOption DecaySlider X '..(tonumber(SKIN:GetVariable('Decay')) * 0.09)..'r][!SetOption LevelRange X '..(2 + levelMin * 95)..'r][!SetOption LevelRange W '..(levelRange * 95)..'][!SetOption LevelMaxSlider X '..(levelRange * 95)..'r][!SetOption SensSlider X '..(tonumber(SKIN:GetVariable('Sens')) * 0.9)..'r][!SetOption AngleSlider X '..(tonumber(SKIN:GetVariable('Angle')) / 9)..'r]')
  if SKIN:GetVariable('ShowSet') == '1' then
    ShowSettings()
    SKIN:Bang('!WriteKeyValue Variables ShowSet 0 "#@#Settings.inc"')
  end
end

function Update()
  for b = 1, bands do
    grad[b + 1] = Preset((mFFT[b - 1]:GetValue() - levelMin) / levelRange, b, bands)..';'..(bandPct * b)
  end
  SKIN:Bang('!SetOption', 'Row', 'Grad', '180|'..table.concat(grad, '|'))
end

function ShowHover()
  if SKIN:GetMeter('Handle'):GetW() > 0 then return end
  SKIN:Bang('!SetOption Hover SolidColor 80808050')
end

function ShowSettings()
  SKIN:Bang('[!SetOption Handle W '..math.max(SKIN:GetMeter('Hover'):GetW(), 270)..'][!SetOptionGroup Label X 12][!MoveMeter 12 12 PresetLabel][!MoveMeter 66 12 PresetBG][!MoveMeter 83 99 ChannelBG][!ShowMeterGroup Set][!SetOption Hover SolidColor 00000001]')
end

function HideSettings()
  if isLocked then return end
  SKIN:Bang('[!SetOptionGroup Label X -270][!MoveMeter -270 -300 PresetLabel][!MoveMeter -270 -300 PresetBG][!MoveMeter -270 -300 ChannelBG][!HideMeterGroup Set][!SetOption Hover SolidColor 00000001]')
end

function GenMeasures()
  local file = io.open(SKIN:GetVariable('@')..'Measures.inc', 'w')
  for b = 1, bands - 1 do
    file:write('[mFFT'..b..']\nMeasure=Plugin\nPlugin=AudioLevel\nParent=mFFT0\nType=Band\nBandIdx='..b..'\nGroup=mFFT\n')
  end
  file:close()
end

function LoadPreset(n)
  local file
  if n then
    file = SKIN:GetMeasure('mPreset'..n):GetStringValue()
    SKIN:Bang('[!SetOption PresetSet Text "'..file..'"][!SetVariable Preset "'..file..'"][!WriteKeyValue Variables Preset "'..file..'" "#@#Settings.inc"]')
  else
    file = SKIN:GetVariable('Preset')
  end
  -- Create function from file
  Preset = assert(loadfile(SKIN:GetVariable('@')..'Presets\\'..file..'.lua'))
  grad = {Preset(0, 0, bands)..';0', [bands + 2] = Preset(0, bands, bands)..';1'}
end

function InitScroll()
  presetCount = SKIN:GetMeasure('mPresetCount'):GetValue()
  SKIN:GetMeter('PresetScroll'):SetH(math.min(186, 1900 / presetCount - 4))
end

function ScrollList(n, m)
  if m then
    local n = m * 0.01 > (scroll + 5) / presetCount and 1 or -1
    for i = 1, 3 do
      ScrollList(n)
    end
  elseif 0 <= scroll + n and scroll + n + 10 <= presetCount then
    scroll = scroll + n
    SKIN:Bang('[!SetOption PresetScroll Y '..(190 / (presetCount - 10) * (1 - 10 / presetCount) * scroll + 2)..'r][!UpdateMeter PresetScroll][!CommandMeasure mPreset1 Index'..(n > 0 and 'Down' or 'Up')..']')
  end
end

function SetAttack(n, m)
  local attack = tonumber(SKIN:GetVariable('Attack'))
  if m then
    attack = math.floor(m * 0.11) * 100
  elseif 0 <= attack + n and attack + n <= 1000 then
    attack = math.floor((attack + n) * 0.01 + 0.5) * 100
  else return end
  SKIN:Bang('[!SetOption mFFT0 FFTAttack '..attack..'][!SetOption AttackSlider X '..(attack * 0.09)..'r][!SetOption AttackVal Text '..attack..'][!SetVariable Attack '..attack..'][!WriteKeyValue Variables Attack '..attack..' "#@#Settings.inc"]')
end

function SetDecay(n, m)
  local decay = tonumber(SKIN:GetVariable('Decay'))
  if m then
    decay = math.floor(m * 0.11) * 100
  elseif 0 <= decay + n and decay + n <= 1000 then
    decay = math.floor((decay + n) * 0.01 + 0.5) * 100
  else return end
  SKIN:Bang('[!SetOption mFFT0 FFTDecay '..decay..'][!SetOption DecaySlider X '..(decay * 0.09)..'r][!SetOption DecayVal Text '..decay..'][!SetVariable Decay '..decay..'][!WriteKeyValue Variables Decay '..decay..' "#@#Settings.inc"]')
end

function SetLevel(n, m)
  local level = { Min = levelMin, Max = levelMin + levelRange }
  local limit = m * 0.02 < level.Min + level.Max and 'Min' or 'Max'
  local val = 0
  if n == 0 then
    val = math.floor(m * 0.21) * 0.05
  elseif 0 <= level[limit] + n and level[limit] + n <= 1 then
    val = math.floor((level[limit] + n) * 20 + 0.5) * 0.05
  end
  if (limit == 'Min' and level.Max - 0.01 <= val) or (limit == 'Max' and val <= level.Min + 0.01) then return end
  if limit == 'Min' then
    levelMin = val
    levelRange = level.Max - levelMin
  else
    levelRange = val - levelMin
  end
  local range = SKIN:GetMeter('LevelRange')
  SKIN:Bang('[!SetOption LevelRange X '..(2 + levelMin * 95)..'r][!SetOption LevelRange W '..(levelRange * 95)..'][!SetOption LevelMaxSlider X '..(levelRange * 95)..'r][!SetOption Level'..limit..'Val Text '..string.format('%.2f', val)..'][!WriteKeyValue Variables Level'..limit..' '..string.format('%.2f', val)..' "#@#Settings.inc"]')
end

function SetSens(n, m)
  local sens = tonumber(SKIN:GetVariable('Sens'))
  if m then
    sens = math.floor(m * 0.11) * 10
  elseif 0 <= sens + n and sens + n <= 100 then
    sens = math.floor((sens + n) * 0.1 + 0.5) * 10
  else return end
  SKIN:Bang('[!SetOption mFFT0 Sensitivity '..sens..'][!SetOption SensSlider X '..(sens * 0.09)..'r][!SetOption SensVal Text '..sens..'][!SetVariable Sens '..sens..'][!WriteKeyValue Variables Sens '..sens..' "#@#Settings.inc"]')
end

function SetChannel(n)
  local name = {[0]='Left','Right','Center','Subwoofer','Back Left','Back Right','Side Left','Side Right'}
  if n == 'Stereo' then
    -- Split bands between L and R channels
    for b = 0, bands / 2 - 1 do
      SKIN:Bang('[!SetOption mFFT'..b..' Channel L][!SetOption mFFT'..b..' BandIdx '..(bands - b * 2 - 2)..']')
    end
    for b = bands / 2, bands - 1 do
      SKIN:Bang('[!SetOption mFFT'..b..' Channel R][!SetOption mFFT'..b..' BandIdx '..(b * 2 - bands - 2)..']')
    end
  else
    SKIN:Bang('!SetOptionGroup mFFT Channel '..n)
    for b = 0, bands - 1 do
      SKIN:Bang('!SetOption mFFT'..b..' BandIdx '..b)
    end
  end
  SKIN:Bang('[!SetOption ChannelSet Text "'..(name[tonumber(n)] or n)..'"][!SetVariable Channel '..n..'][!WriteKeyValue Variables Channel '..n..' "#@#Settings.inc"]')
end

function SetBands()
  isLocked = false
  local set = tonumber(SKIN:GetVariable('Set'))
  if not set or set < 2 then return end
  SKIN:Bang('[!WriteKeyValue Variables Bands #Set# "#@#Settings.inc"][!WriteKeyValue Variables ShowSet 1 "#@#Settings.inc"][!Refresh]')
end

function SetVar(var)
  isLocked = false
  local set = tonumber(SKIN:GetVariable('Set'))
  if not set or var ~= 'BlurH' and set <= 0 or set < 0 then return end
  SKIN:Bang('[!SetOption '..var..'Set Text "#Set# px"][!SetVariable '..var..' #Set#][!WriteKeyValue Variables '..var..' #Set# "#@#Settings.inc"]')
  SetAngle(0)
end

function SetAngle(n, m)
  local angle = tonumber(SKIN:GetVariable('Angle'))
  if m then
    angle = math.floor(m * 0.04) * 90
  elseif 0 <= angle + n and angle + n <= 270 then
    angle = math.floor((angle + n) / 90 + 0.5) * 90
  else return end
  local isVertical = angle % 180 == 90
  local offset = isVertical and '((#Height#-#Width#)/2),((#Width#-#Height#)/2)' or '0,0'
  SKIN:Bang('[!SetOption Row Shape "Rectangle 0,0,#Width#,#Height#|Fill LinearGradient Grad|StrokeWidth 0|Rotate '..angle..'|Offset '..offset..'"][!SetOption Mask Shape "Rectangle 0,0,#Width#,#Height#|Fill LinearGradient Grad|StrokeWidth 0|Rotate '..angle..'|Offset '..offset..'"][!SetOption Mask Grad 90|00000000;0|000000;(#BlurH#<#Height#/2?#BlurH#/#Height#:0.5)|000000;(#BlurH#<#Height#/2?(#Height#-#BlurH#)/#Height#:0.5)|00000000;1][!SetOption Hover W '..(isVertical and '#Height#' or '#Width#')..'][!SetOption Hover H '..(isVertical and '#Width#' or '#Height#')..'][!SetOption AngleSlider X '..(angle / 9)..'r][!SetOption AngleVal Text '..angle..'\176][!SetVariable Angle '..angle..'][!WriteKeyValue Variables Angle '..angle..' "#@#Settings.inc"]')
end
