aura_env.nothing = 1
aura_env.pass = 2
aura_env.greed = 3
aura_env.need = 4

aura_env.requiredPercentKey = "requiredPercent"
aura_env.guildMembersPercent = 2.5

aura_env.chooseRoll = function(rollId)
    aura_env.debug("Roll id: ".. rollId)

    local _,_,_,_,_,canNeed,canGreed,canDis = GetLootRollItemInfo(rollId)
    local itemLink = GetLootRollItemLink(rollId)
    local itemId = select(3, strfind(itemLink, "item:(%d+)"))

    return aura_env.chooseRollForItem(itemId, canNeed, canGreed, canDis)
end

aura_env.chooseRollForItem = function(itemId, canNeed, canGreed, canDis)
    local name,_,quality,_,_,type,subType,_,_,_,_,_,_,bindType = GetItemInfo(itemId)
    local bindOnPickUp = (bindType == 1)

    aura_env.debug(itemId ..": ".. name)
    if subType then
        aura_env.debug(type .." ".. subType .." ".. quality)
    else
        aura_env.debug(type .." ".. quality)
    end

    local exceptionalRoll = aura_env.getExceptionalRoll(itemId, name)
    if exceptionalRoll then
        return aura_env.mapRoll(exceptionalRoll)
    end

    local innerRoll = nil
    if bindOnPickUp then
        aura_env.debug("Bind on pick up")
        innerRoll = aura_env.getBopConfigRoll(type, subType, quality)
    else
        aura_env.debug("Bind on equip or another")
        innerRoll = aura_env.getBoeConfigRoll(type, subType, quality)
    end
    
    return aura_env.mapRoll(innerRoll)
end

aura_env.getExceptionalRoll = function(itemId, name)
    local exceptions = aura_env.config.exceptions
    if not exceptions then
        return nil
    end
    
    for i, v in ipairs(exceptions) do
        if v and v.value and (v.value == itemId or v.value == name) then
            aura_env.debug("Found exceptional roll for either itemId: ".. itemId .." or name: ".. name)
            return v.roll
        end
    end
    
    return nil
end

aura_env.getBoeConfigRoll = function(type, subType, quality)
    return aura_env.getConfigRoll(aura_env.config.settingsBoE, type, subType, quality)
end

aura_env.getBopConfigRoll = function(type, subType, quality)
    local innerRoll = aura_env.getConfigRoll(aura_env.config.settingsBoP, type, subType, quality)
    
    -- Тут защита от нида БОП
    if innerRoll == aura_env.need 
    or innerRoll == aura_env.greed then
        return aura_env.nothing
    end
    
    return innerRoll
end

aura_env.getConfigRoll = function(settings, type, subType, quality)
    local key = nil
    if subType then
        key = type .." ".. subType .." ".. quality
        local subTypeWithQualityRoll = settings[key]
        if subTypeWithQualityRoll then
            aura_env.debug("Found roll with key: ".. key)
            return subTypeWithQualityRoll
        end
        
        key = type .." ".. subType
        local subTypeRoll = settings[key]
        if subTypeRoll then
            aura_env.debug("Found roll with key: ".. key)
            return subTypeRoll
        end
    end
    
    key = type .." ".. quality
    local commonTypeWithQualityRoll = settings[key]
    if commonTypeWithQualityRoll then 
        aura_env.debug("Found roll with key: ".. key)
        return commonTypeWithQualityRoll
    end
    
    key = type
    local commonTypeRoll = settings[key]
    if commonTypeRoll then
        aura_env.debug("Found roll with key: ".. key)
        return commonTypeRoll
    end    
    
    aura_env.debug("Not found any roll")
    return aura_env.nothing
end

aura_env.mapRoll = function(innerRoll)
    if innerRoll == aura_env.nothing then
        aura_env.debug("Nothing")
        return nil
    end
    if innerRoll == aura_env.pass then
        aura_env.debug("Pass")
        return 0
    end
    if innerRoll == aura_env.need then
        aura_env.debug("Need")
        return 1
    end
    if innerRoll == aura_env.greed then
        aura_env.debug("Greed")
        return 2
    end

    aura_env.debug("Inner roll was out of range")
    return nil
end

aura_env.onRosterUpdate = function()
    local playersCount = 0
    local guildMembersCount = 0
    for unit in WA_IterateGroupMembers() do
        local name, server = UnitName(unit)
        if aura_env.isInYourGuild(name) then 
            guildMembersCount = guildMembersCount + 1
        end
        playersCount = playersCount + 1
    end
    aura_env.guildMembersPercent = 100 * (guildMembersCount / playersCount)
end

aura_env.isGuildRoster = function()
    local requiredPercent = aura_env.config[aura_env.requiredPercentKey]
    aura_env.debug("Guild percent: ".. aura_env.guildMembersPercent)
    return aura_env.guildMembersPercent >= requiredPercent
end

aura_env.isInYourGuild = function(name)
    local numTotal,_,_ = GetNumGuildMembers()
    for i = 1, numTotal do
        local memberName = select(1, GetGuildRosterInfo(i))
        if string.find(memberName, name) then 
            return true
        end
    end
    return false
end

aura_env.debug = function(string)
    if aura_env.config.debug then
        print(string)
    end
end

aura_env.onRosterUpdate()