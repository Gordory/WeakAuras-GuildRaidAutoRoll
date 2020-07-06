function(event, ...)
    aura_env.debug("Event: ".. event)

    if event == "START_LOOT_ROLL" then
        local rollId = select(1, ...)

        if quality == 0 -- poor
        or quality == 1 -- common
        or quality == 5 -- legendary (!) this WA will NOT auto roll legendary items
        or quality == 6 -- artifact
        or quality == 7 -- heirloom
        or quality == 8 then -- wow token
            return -- no roll for this quality
        end

        if not aura_env.isGuildRoster() then
            aura_env.debug("Not working in PUG raids")
            return -- not working in PUGs
        end

        local rollType = aura_env.chooseRoll(rollId)
        if not rollType then
            return
        end

        RollOnLoot(rollId, rollType)
    elseif event == "GROUP_ROSTER_UPDATE" then
        aura_env.onRosterUpdate()
    elseif event == "TEST" then
        aura_env.chooseRollForItem(22637)
    end

    return true
end