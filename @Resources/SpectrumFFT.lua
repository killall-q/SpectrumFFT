function Initialize()
    mFFT = {}
    bands = tonumber(SKIN:GetVariable('Bands')) -- number of FFT bands
    levelMin = tonumber(SKIN:GetVariable('LevelMin'))
    levelRange = tonumber(SKIN:GetVariable('LevelMax')) - levelMin
    scroll = 0 -- preset selection list scroll position
    lock = false -- lock hiding of mouseover controls
    local showBG = tonumber(SKIN:GetVariable('ShowBG')) and true or false
    if not SKIN:GetMeter('B1') then
        GenMeasures()
        GenMeters()
        SKIN:Bang('!Refresh')
        return
    end
    for b = 0, bands - 1 do
        mFFT[b] = SKIN:GetMeasure('mFFT'..b)
    end
    os.remove(SKIN:GetVariable('@')..'Measures.inc')
    os.remove(SKIN:GetVariable('@')..'Meters.inc')
    LoadPreset()
    SetChannel(SKIN:GetVariable('Channel'))
    SetOrder(tonumber(SKIN:GetVariable('Order')), true)
    for b = 1, bands do
        SKIN:Bang('[!SetOption B'..b..' SolidColor #Color'..(b - 1)..'#][!SetOption B'..b..' SolidColor2 #Color'..b..'#]')
    end
    SKIN:Bang('[!SetOption B'..bands..' SolidColor2 0,0,0,0][!SetOption AttackSlider X '..(68 + tonumber(SKIN:GetVariable('Attack')) * 0.09)..'][!SetOption DecaySlider X '..(62 + tonumber(SKIN:GetVariable('Decay')) * 0.09)..'][!SetOption LevelRange X '..(130 + levelMin * 95)..'][!SetOption LevelRange W '..(levelRange * 95)..'][!SetOption LevelMinSlider X '..(128 + levelMin * 95)..'][!SetOption LevelMaxSlider X '..(128 + (levelMin + levelRange) * 95)..'][!SetOption SensSlider X '..(95 + tonumber(SKIN:GetVariable('Sens')) * 0.9)..'][!SetOption BG'..(showBG and 'Show' or 'Hide')..' SolidColor FF0000][!SetOption BG'..(showBG and 'Show' or 'Hide')..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"]')
    if not showBG then
        SKIN:Bang('[!HideMeterGroup Mask][!SetOption ColorLabel Y -20]')
    end
    if SKIN:GetVariable('ShowSet') ~= '' then
        ShowSettings()
        SKIN:Bang('!WriteKeyValue Variables ShowSet "" "#@#Settings.inc"')
    end
end

function Update()
    for b = 0, bands - 1 do
        SKIN:Bang('!SetVariable Color'..b..' '..Preset((mFFT[b]:GetValue() - levelMin) / levelRange, b, bands))
    end
end

function ShowHover()
    if SKIN:GetMeter('Handle'):GetW() > 0 then return end
    SKIN:Bang('!SetOption Hover SolidColor 80808050')
end

function ShowSettings()
    SKIN:Bang('[!SetOption Handle W '..math.max(SKIN:GetMeter('Hover'):GetW(), 270)..'][!MoveMeter 12 12 PresetLabel][!MoveMeter 66 12 PresetBG][!MoveMeter 83 137 ChannelBG][!ShowMeterGroup Set][!SetOption Hover SolidColor 00000001]')
end

function HideSettings()
    if lock then return end
    SKIN:Bang('[!MoveMeter 12 -300 PresetLabel][!MoveMeter 66 -300 PresetBG][!MoveMeter 83 -300 ChannelBG][!HideMeterGroup Set][!SetOption Hover SolidColor 00000001]')
end

function GenMeasures()
    local file = io.open(SKIN:GetVariable('@')..'Measures.inc', 'w')
    for b = 1, bands - 1 do
        file:write('[mFFT'..b..']\nMeasure=Plugin\nPlugin=AudioLevel\nParent=mFFT0\nType=Band\nBandIdx='..b..'\nGroup=mFFT\n')
    end
    file:close()
end

function GenMeters()
    local file = io.open(SKIN:GetVariable('@')..'Meters.inc', 'w')
    for b = 1, bands do
        file:write('[B'..b..']\nMeter=Image\nMeterStyle=B\n')
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
    elseif scroll + n >= 0 and scroll + n + 10 <= presetCount then
        scroll = scroll + n
        SKIN:Bang('[!SetOption PresetScroll Y '..(190 / (presetCount - 10) * (1 - 10 / presetCount) * scroll + 2)..'r][!UpdateMeter PresetScroll][!CommandMeasure mPreset1 Index'..(n > 0 and 'Down' or 'Up')..']')
    end
end

function SetAttack(n, m)
    local attack = tonumber(SKIN:GetVariable('Attack'))
    if m then
        attack = math.floor(m * 0.11) * 100
    elseif attack + n >= 0 and attack + n <= 1000 then
        attack = math.floor((attack + n) * 0.01 + 0.5) * 100
    else return end
    SKIN:GetMeter('AttackSlider'):SetX(68 + attack * 0.09)
    SKIN:Bang('[!SetOption mFFT0 FFTAttack '..attack..'][!SetOption AttackVal Text '..attack..'][!SetVariable Attack '..attack..'][!WriteKeyValue Variables Attack '..attack..' "#@#Settings.inc"]')
end

function SetDecay(n, m)
    local decay = tonumber(SKIN:GetVariable('Decay'))
    if m then
        decay = math.floor(m * 0.11) * 100
    elseif decay + n >= 0 and decay + n <= 1000 then
        decay = math.floor((decay + n) * 0.01 + 0.5) * 100
    else return end
    SKIN:GetMeter('DecaySlider'):SetX(62 + decay * 0.09)
    SKIN:Bang('[!SetOption mFFT0 FFTDecay '..decay..'][!SetOption DecayVal Text '..decay..'][!SetVariable Decay '..decay..'][!WriteKeyValue Variables Decay '..decay..' "#@#Settings.inc"]')
end

function SetLevel(n, m)
    local level = { Min = levelMin, Max = levelMin + levelRange }
    local limit = m * 0.02 < level.Min + level.Max and 'Min' or 'Max'
    local val = 0
    if n == 0 then
        val = math.floor(m * 0.21) * 0.05
    elseif level[limit] + n >= 0 and level[limit] + n <= 1 then
        val = math.floor((level[limit] + n) * 20 + 0.5) * 0.05
    end
    if (limit == 'Min' and level.Max - 0.01 <= val) or (limit == 'Max' and val <= level.Min + 0.01) then return end
    SKIN:GetMeter('Level'..limit..'Slider'):SetX(128 + val * 95)
    SKIN:Bang('[!SetOption Level'..limit..'Val Text '..string.format('%.2f', val)..'][!WriteKeyValue Variables Level'..limit..' '..string.format('%.2f', val)..' "#@#Settings.inc"]')
    if limit == 'Min' then
        levelMin = val
        levelRange = level.Max - levelMin
    else
        levelRange = val - levelMin
    end
    local range = SKIN:GetMeter('LevelRange')
    range:SetX(130 + levelMin * 95)
    range:SetW(levelRange * 95)
end

function SetSens(n, m)
    local sens = tonumber(SKIN:GetVariable('Sens'))
    if m then
        sens = math.floor(m * 0.11) * 10
    elseif sens + n >= 0 and sens + n <= 100 then
        sens = math.floor((sens + n) * 0.1 + 0.5) * 10
    else return end
    SKIN:GetMeter('SensSlider'):SetX(95 + sens * 0.9)
    SKIN:Bang('[!SetOption mFFT0 Sensitivity '..sens..'][!SetOption SensVal Text '..sens..'][!SetVariable Sens '..sens..'][!WriteKeyValue Variables Sens '..sens..' "#@#Settings.inc"]')
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
    lock = false
    local res = tonumber(SKIN:GetVariable('Set'))
    if res and res > 0 then
        SKIN:Bang('[!WriteKeyValue Variables Bands '..res..' "#@#Settings.inc"][!WriteKeyValue Variables ShowSet 1 "#@#Settings.inc"][!Refresh]')
    end
end

function SetOrder(n, m)
    if tonumber(n) ~= tonumber(SKIN:GetVariable('Order')) or m and n then
        for b = 0, bands / 2 - 1 do
            mFFT[b], mFFT[bands - b - 1] = mFFT[bands - b - 1], mFFT[b]
        end
    end
    SKIN:Bang('[!SetOption Order'..(n and 'Right' or 'Left')..' SolidColor 505050E0][!SetOption Order'..(n and 'Right' or 'Left')..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor 505050E0"][!SetOption Order'..(n and 'Left' or 'Right')..' SolidColor FF0000][!SetOption Order'..(n and 'Left' or 'Right')..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!SetVariable Order '..(n and 1 or '""')..'][!WriteKeyValue Variables Order '..(n and 1 or '""')..' "#@#Settings.inc"]')
end

function SetBandSize(s)
    lock = false
    local size = tonumber(SKIN:GetVariable('Set'))
    if size and size > 0 then
        SKIN:Bang('[!SetOptionGroup B '..s..' "#Set#"][!SetOption Band'..s..'Set Text "#Set#"][!SetVariable Band'..s..' "#Set#"][!WriteKeyValue Variables Band'..s..' "#Set#" "#@#Settings.inc"][!UpdateMeterGroup Mask]')
    end
end

function SetMaskH()
    lock = false
    local maskH = tonumber(SKIN:GetVariable('Set'))
    if maskH and maskH > 0 then
        SKIN:Bang('[!SetOption MaskHSet Text "#Set#"][!SetVariable MaskH "#Set#"][!WriteKeyValue Variables MaskH "#Set#" "#@#Settings.inc"][!UpdateMeterGroup Mask]')
    end
end

function SetBG(n)
    SKIN:Bang('[!'..(n and 'Show' or 'Hide')..'MeterGroup Mask][!SetOption BG'..(n and 'Hide' or 'Show')..' SolidColor 505050E0][!SetOption BG'..(n and 'Hide' or 'Show')..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor 505050E0"][!SetOption BG'..(n and 'Show' or 'Hide')..' SolidColor FF0000][!SetOption BG'..(n and 'Show' or 'Hide')..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!SetOption ColorLabel Y '..(n and '6R' or -20)..'][!WriteKeyValue Variables ShowBG '..(n or '""')..' "#@#Settings.inc"]')
end

function SetColor()
    lock = false
    if SKIN:GetVariable('Set') == '' then return end
    SKIN:Bang('[!SetOptionGroup Mask SolidColor "#Set#"][!SetOption ColorBGSet Text "#Set#"][!SetVariable ColorBG "#Set#"][!WriteKeyValue Variables ColorBG "#Set#" "#@#Settings.inc"][!UpdateMeterGroup Mask]')
end
