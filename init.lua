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
    
    --debug
    print(name.." : "..itemId)
    if not subType then 
        print(type .."->".. quality)
    else 
        print(type .."->".. quality .."->".. subType)
    end
    
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
            print("Trying to need or greed BoP item. Did nothing.")
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
        print("exceptions nil")
        return nil
    end
    
    for i, v in ipairs(exceptions) do
        if v and v.value and (v.value == itemId or v.value == name) then
            print("found at exceptions list")
            return v.roll
        end
    end
    
    print("not found at exceptions list")
    return nil
end

aura_env.getBoeConfigRoll = function(type, subType, quality)
    return aura_env.getConfigRoll(aura_env.config.settingsBoE, type, subType, quality)
end

aura_env.getBopConfigRoll = function(type, subType, quality)
    local innerRoll = aura_env.getConfigRoll(aura_env.config.settingsBoP, type, subType, quality)
    
    if innerRoll == aura_env.need 
    or innerRoll == aura_env.greed then
        print("BoP configs for raiders should not contain need or greed options")
        return aura_env.nothing
    end
    
    return innerRoll
end

aura_env.getConfigRoll = function(settings, type, subType, quality)
    if not subType then
        print("subType nil")
    end
    
    if subType then
        local subTypeWithQualityRoll = settings[type .." ".. subType .." ".. quality]
        if subTypeWithQualityRoll then
            print("subtype with quality")
            return subTypeWithQualityRoll
        end
        
        local subTypeRoll = settings[type .." ".. subType]
        if subTypeRoll then
            print("subtype")
            return subTypeRoll
        end
    end
    
    local commonTypeWithQualityRoll = settings[type .." ".. quality]
    if commonTypeWithQualityRoll then 
        print("common type with quality")
        return commonTypeWithQualityRoll
    end
    
    local commonTypeRoll = settings[type]
    if commonTypeRoll then
        print("common type")
        return commonTypeRoll
    end    
    
    print("not found inner roll")
    return aura_env.nothing
end

aura_env.mapRoll = function(innerRoll)
    if innerRoll == aura_env.nothing then
        print("nothing")
        return nil
    end
    if innerRoll == aura_env.pass then
        print("pass")
        return 0
    end
    if innerRoll == aura_env.need then
        print("need")
        return 1
    end
    if innerRoll == aura_env.greed then
        print("greed")
        return 2
    end
    print("InnerRoll value was out of range")
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