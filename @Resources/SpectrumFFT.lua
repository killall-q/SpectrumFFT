function Initialize()
    mFFT = {}
    bands = tonumber(SKIN:GetVariable('Bands')) -- number of FFT bands
    levelMin = tonumber(SKIN:GetVariable('LevelMin'))
    levelRange = tonumber(SKIN:GetVariable('LevelMax')) - levelMin
    lock = false -- lock hiding of mouseover controls
    if not SKIN:GetMeter('B1') then
        GenMeasures()
        GenMeters()
        SKIN:Bang('!Refresh')
        return
    end
    SKIN:Bang('[!SetOption AttackSlider X '..(68 + tonumber(SKIN:GetVariable('Attack')) * 0.09)..'][!SetOption DecaySlider X '..(62 + tonumber(SKIN:GetVariable('Decay')) * 0.09)..'][!SetOption LevelRange X '..(130 + levelMin * 95)..'][!SetOption LevelRange W '..(levelRange * 95)..'][!SetOption LevelMinSlider X '..(128 + levelMin * 95)..'][!SetOption LevelMaxSlider X '..(128 + (levelMin + levelRange) * 95)..'][!SetOption SensSlider X '..(95 + tonumber(SKIN:GetVariable('Sens')) * 0.9)..']')
    for i = 0, bands - 1 do
        mFFT[i] = SKIN:GetMeasure('mFFT'..i)
    end
    os.remove(SKIN:GetVariable('@')..'Measures.inc')
    os.remove(SKIN:GetVariable('@')..'Meters.inc')
    PrepMeters()
    SetChannel(SKIN:GetVariable('Channel'))
    if (SKIN:GetVariable('ShowSet') ~= '') then
        SKIN:Bang('[!ShowMeterGroup Set][!WriteKeyValue Variables ShowSet "" "#@#Settings.inc"]')
    else
        ToggleSet(1)
    end
end

function Update()
    local FFTMin, FFTMax = 1, 0
    for i = 0, bands - 1 do
        local FFT = (mFFT[i]:GetValue() - levelMin) / levelRange
        if FFT < 0 then
            SKIN:Bang('!SetVariable Color'..i..' 0,0,0,0')
        elseif FFT < 0.2 then
            SKIN:Bang('!SetVariable Color'..i..' '..((FFT - 0.2) * -1275)..',0,255,'..(FFT * 1275))
        elseif FFT < 0.4 then
            SKIN:Bang('!SetVariable Color'..i..' 0,'..((FFT - 0.2) * 1275)..',255')
        elseif FFT < 0.6 then
            SKIN:Bang('!SetVariable Color'..i..' 0,255,'..((FFT - 0.6) * -1275))
        elseif FFT < 0.8 then
            SKIN:Bang('!SetVariable Color'..i..' '..((FFT - 0.6) * 1275)..',255,0')
        else
            SKIN:Bang('!SetVariable Color'..i..' 255,'..((FFT - 1) * -1275)..',0')
        end
    end
end

function HideControls()
    if not lock then
        SKIN:Bang('!HideMeter Cog')
        ToggleSet(1)
    end
end

function ToggleSet(n)
    if n or SKIN:GetMeter('AttackLabel'):GetH() > 0 then
        SKIN:Bang('[!HideMeterGroup Set][!SetOption AttackLabel Y -500][!UpdateMeter AttackLabel][!MoveMeter 83 -500 ChannelBG]')
    else
        SKIN:Bang('[!ShowMeterGroup Set][!SetOption AttackLabel Y 16R][!UpdateMeter AttackLabel][!MoveMeter 83 146 ChannelBG]')
    end
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

function PrepMeters()
    for i = 1, bands do
        SKIN:Bang('[!SetOption B'..i..' SolidColor #Color'..(i - 1)..'#][!SetOption B'..i..' SolidColor2 #Color'..i..'#]')
    end
    SKIN:Bang('!SetOption B'..bands..' SolidColor2 0,0,0,0')
end

function SetAttack(n, m)
    local attack = tonumber(SKIN:GetVariable('Attack'))
    if m then
        attack = math.floor(m * 0.11) * 100
    elseif attack + n >= 0 and attack + n <= 1000 then
        attack = math.floor((attack + n) * 0.01 + 0.5) * 100
    else return end
    SKIN:GetMeter('AttackSlider'):SetX(68 + attack * 0.09)
    SKIN:Bang('[!SetOptionGroup mFFT FFTAttack '..attack..'][!SetOption AttackVal Text '..attack..'][!SetVariable Attack '..attack..'][!WriteKeyValue Variables Attack '..attack..' "#@#Settings.inc"]')
end

function SetDecay(n, m)
    local decay = tonumber(SKIN:GetVariable('Decay'))
    if m then
        decay = math.floor(m * 0.11) * 100
    elseif decay + n >= 0 and decay + n <= 1000 then
        decay = math.floor((decay + n) * 0.01 + 0.5) * 100
    else return end
    SKIN:GetMeter('DecaySlider'):SetX(62 + decay * 0.09)
    SKIN:Bang('[!SetOptionGroup mFFT FFTDecay '..decay..'][!SetOption DecayVal Text '..decay..'][!SetVariable Decay '..decay..'][!WriteKeyValue Variables Decay '..decay..' "#@#Settings.inc"]')
end

function SetLevel(n, m)
    local level = { Min = levelMin, Max = levelMin + levelRange }
    local limit = m * 0.02 < level.Min + level.Max and 'Min' or 'Max'
    local val
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
    SKIN:Bang('[!SetOptionGroup mFFT Sensitivity '..sens..'][!SetOption SensVal Text '..sens..'][!SetVariable Sens '..sens..'][!WriteKeyValue Variables Sens '..sens..' "#@#Settings.inc"]')
end

function SetChannel(n)
    local name = {[0]='Left','Right','Center','Subwoofer','Back Left','Back Right','Side Left','Side Right'}
    if n == 'Stereo' then
        -- Split bands between L and R channels
        for i = 0, bands / 2 - 1 do
            SKIN:Bang('!SetOption mFFT'..i..' Channel L')
        end
        for i = bands / 2, bands - 1 do
            SKIN:Bang('[!SetOption mFFT'..i..' Channel R][!SetOption mFFT'..i..' BandIdx '..(bands - i)..']')
        end
    else
        SKIN:Bang('!SetOptionGroup mFFT Channel '..n)
        for i = bands / 2, bands - 1 do
            SKIN:Bang('!SetOption mFFT'..i..' BandIdx '..i)
        end
    end
    SKIN:Bang('[!SetOption ChannelSet Text "'..(name[n] or n)..'"][!SetVariable Channel '..n..'][!WriteKeyValue Variables Channel '..n..' "#@#Settings.inc"]')
end

function SetBands()
    local res = tonumber(SKIN:GetVariable('Input'))
    if res and res > 0 then
        SKIN:Bang('[!WriteKeyValue Variables Bands '..res..' "#@#Settings.inc"][!WriteKeyValue Variables ShowSet 1 "#@#Settings.inc"][!Refresh]')
    else
        lock = false
    end
end

function SetBandSize(s)
    local bandSize = tonumber(SKIN:GetVariable('Input'))
    if bandSize and bandSize > 0 then
        SKIN:Bang('[!SetOptionGroup P '..(s == 'W' and 'H' or 'W')..' "#Input#"][!SetOption Band'..s..'Set Text "#Input#"][!SetVariable Band'..s..' "#Input#"][!WriteKeyValue Variables Band'..s..' "#Input#" "#@#Settings.inc"][!UpdateMeterGroup Mask]')
        lock = false
    end
end
