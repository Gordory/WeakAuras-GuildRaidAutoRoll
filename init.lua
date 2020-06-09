aura_env.nothing = 1
aura_env.pass = 2
aura_env.greed = 3
aura_env.need = 4

aura_env.requiredPercentKey = "requiredPercent"
aura_env.guildMembersPercent = 2.5

aura_env.chooseRoll = function(rollId)
    local _,_,_,_,bindOnPickUp,canNeed,canGreed,canDis = GetLootRollItemInfo(rollId)
    local itemLink = GetLootRollItemLink(rollId)
    local itemId = select(3, strfind(itemLink, "item:(%d+)"))
    local name,_,quality,_,_,type,subType,_,_,_,_ = GetItemInfo(itemLink)

    local exceptionalRoll = aura_env.getExceptionalRoll(itemId, name)
    if exceptionalRoll then
        return aura_env.mapRoll(exceptionalRoll)
    end
    
    local innerRoll = nil
    if bindOnPickUp then
        innerRoll = aura_env.getBopConfigRoll(type, subType, quality)
    else
        innerRoll = aura_env.getBoeConfigRoll(type, subType, quality)
    end
    
    if innerRoll == aura_env.need or innerRoll == aura_env.greed then
        if bindOnPickUp then
            return nil
        end
        return aura_env.mapRoll(innerRoll)
    else -- pass or nothing
        return aura_env.mapRoll(innerRoll)
    end
end

aura_env.getExceptionalRoll = function(itemId, name)
    local exceptions = aura_env.config.exceptions
    if not exceptions then
        return nil
    end
    
    for i, v in ipairs(exceptions) do
        if v and v.value and (v.value == itemId or v.value == name) then
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
    
    if innerRoll == aura_env.need 
    or innerRoll == aura_env.greed then
        return aura_env.nothing
    end
    
    return innerRoll
end

aura_env.getConfigRoll = function(settings, type, subType, quality)
    if subType then
        local subTypeWithQualityRoll = settings[type .." ".. subType .." ".. quality]
        if subTypeWithQualityRoll then
            return subTypeWithQualityRoll
        end
        
        local subTypeRoll = settings[type .." ".. subType]
        if subTypeRoll then
            return subTypeRoll
        end
    end
    
    local commonTypeWithQualityRoll = settings[type .." ".. quality]
    if commonTypeWithQualityRoll then 
        return commonTypeWithQualityRoll
    end
    
    local commonTypeRoll = settings[type]
    if commonTypeRoll then
        return commonTypeRoll
    end    
    
    return aura_env.nothing
end

aura_env.mapRoll = function(innerRoll)
    if innerRoll == aura_env.nothing then
        return nil
    end
    if innerRoll == aura_env.pass then
        return 0
    end
    if innerRoll == aura_env.need then
        return 1
    end
    if innerRoll == aura_env.greed then
        return 2
    end
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

aura_env.onRosterUpdate()