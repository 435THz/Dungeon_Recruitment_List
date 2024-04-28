require "menu.recruit.summary.RecruitSummaryFeaturesWindow"
-- -----------------------------------------------
-- Recruit Summary Menu
-- -----------------------------------------------
-- Menu that displays a recruit's summary to the player

RecruitSummaryMenu = {}
RecruitSummaryMenu.SLOTS_PER_PAGE = 6
RecruitSummaryMenu.pages = nil
RecruitSummaryMenu.FeatureBoost = luanet.import_type('PMDC.LevelGen.MobSpawnBoost')
RecruitSummaryMenu.FeatureLevelScale = luanet.import_type('PMDC.LevelGen.MobSpawnLevelScale')
RecruitSummaryMenu.FeatureMovesOff = luanet.import_type('PMDC.LevelGen.MobSpawnMovesOff')
RecruitSummaryMenu.FeatureScaledBoost = luanet.import_type('PMDC.LevelGen.MobSpawnScaledBoost')
RecruitSummaryMenu.FeatureUnrecruitable = luanet.import_type('PMDC.LevelGen.MobSpawnUnrecruitable')
RecruitSummaryMenu.FeatureWeak = luanet.import_type('PMDC.LevelGen.MobSpawnWeak')
RecruitSummaryMenu.pageList = {RecruitSummaryFeaturesWindow} --TODO , RecruitSummaryStatsWindow} --TODO , RecruitSummaryInfoWindow} --TODO , RecruitSummaryLearnsetWindow}

function RecruitSummaryMenu.run(entry)
    RecruitSummaryMenu.pages = nil
    local entries = RecruitSummaryMenu.loadSpawnEntries(entry)
    _MENU:AddMenu(RecruitSummaryFeaturesWindow:new(entries, 1).menu, false)
end

function RecruitSummaryMenu.loadSpawnEntries(entry)
    local list = {}
    for _, spawn in pairs(entry.spawns) do
        if RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then
            local f = RECRUIT_LIST.getCurrentMap().floor
            local lvl_list = RecruitSummaryMenu.loadSpawnLevels(spawn.data, f)
            for _, lv in pairs(lvl_list) do
                table.insert(list, {spawn = spawn.data, level = lv, floors = {{min = f, max = f}}})
            end
        else
            local levels = {}
            for f = spawn.range.min, spawn.range.max, 1 do
                local lvl_list = RecruitSummaryMenu.loadSpawnLevels(spawn.data, f)
                for _, lv in pairs(lvl_list) do
                    levels[lv] = levels[lv] or {}
                    levels[lv][f] = true
                end
            end
            for lvl, f_list in pairs(levels) do
                local element = {spawn = spawn.data, level = lvl, floors = {}}
                local floors = {}
                for n in pairs(f_list) do table.insert(floors, n) end
                table.sort(floors)

                -- fuse entries whose floors touch
                -- put final entries in output list
                local current = { min = floors[1], max = floors[1]}
                for _, f in pairs(floors) do
                    if current.max+1 >= f then
                        current.max = math.max(current.max, f)
                    else
                        table.insert(element.floors, current)
                        current = { min = f, max = f}
                    end
                end
                table.insert(element.floors, current)
                table.insert(list, element)
            end
        end
    end
    return list
end

function RecruitSummaryMenu.loadSpawnLevels(spawn, floor)
    local levelList = LUA_ENGINE:MakeList(spawn.Level:EnumerateOutcomes())
    local extraLevels = 0
    local features = spawn.SpawnFeatures
    for f = 0, features.Count-1, 1 do
        local feat = features[f]
        if LUA_ENGINE:TypeOf(feat) == luanet.ctype(RecruitSummaryMenu.FeatureLevelScale) then
            extraLevels = math.floor((floor - feat.StartFromID - 1) * feat.AddNumerator / feat.AddDenominator)
        end
    end
    local ret = {}
    for i=0, levelList.Count-1, 1 do
        table.insert(ret, levelList[i] + extraLevels)
    end
    return ret
end

function RecruitSummaryMenu.getPages(formEntry)
    if RecruitSummaryMenu.pages == nil then
        RecruitSummaryMenu.pages = 3 +  math.ceil( RecruitSummaryMenu.getEligibleSkills(formEntry) / RecruitSummaryMenu.SLOTS_PER_PAGE)
    end
    return RecruitSummaryMenu.pages
end

function RecruitSummaryMenu.getEligibleSkills(formEntry)
    local total = 0
    for levelUpSkill in luanet.each(formEntry.LevelSkills) do
        local skillEntry = _DATA:GetSkill(levelUpSkill.Skill)
        if skillEntry.Released then
            total = total +1
        end
    end
    return total
end

function RecruitSummaryMenu.GetFullFormName(form, entry, data)
    local baseForm = RecruitSummaryMenu.getBaseForm(form)
    local name = _DATA:GetMonster(baseForm.Species).Name:ToLocal()
    if not data.recruitable then
        name = "[color=#989898]"..name
    elseif _DATA.Save:GetMonsterUnlock(form.Species) == RogueEssence.Data.GameProgress.UnlockState.Completed then
        name = "[color=#00FF00]"..name else
        name = "[color=#00FFFF]"..name end

    local skinData = _DATA:GetSkin(baseForm.Skin)
    if utf8.char(skinData.Symbol).."" ~= "\0" then
        name = skinData.Symbol..name
    end
    local genderText = ''
    if     form.Gender == RogueEssence.Data.Gender.Unknown then genderText = RecruitSummaryMenu.GetPossibleGenders(entry)
    elseif form.Gender == RogueEssence.Data.Gender.Male    then genderText = '\u{2642}'
    elseif form.Gender == RogueEssence.Data.Gender.Female  then genderText = '\u{2640}'
    end
    if string.sub(name, -#genderText) ~= genderText then
        if #genderText>1 then name = name.."[color]"..genderText
        else name = name..genderText.."[color]" end
    else name = name.."[color]" end
    return name
end

function RecruitSummaryMenu.GetPossibleGenders(form)
    local genders = form:GetPossibleGenders()
    local prefix, text, suffix = "", "", ""
    if genders.Count>1 then prefix, suffix = " (", ")" end
    for i=0, genders.Count-1, 1 do
        if i>0 then text = text.."/" end
        local gender = genders[i]
        if     gender == RogueEssence.Data.Gender.Male   then text = text..'\u{2642}'
        elseif gender == RogueEssence.Data.Gender.Female then text = text..'\u{2640}'
        else
            if genders.Count>1 then text = text..'-' end
        end
    end
    return prefix..text..suffix
end

function RecruitSummaryMenu.getBaseForm(baseForm)
    local default = _DATA.DefaultMonsterID
    local skin = baseForm.Skin
    if skin == "" then skin = default.Skin end
    local gender = baseForm.Gender
    if gender == RogueEssence.Data.Gender.Unknown then gender = default.Gender end
    return RogueEssence.Dungeon.MonsterID(baseForm.Species, baseForm.Form, skin, gender)
end

function RecruitSummaryMenu.loadSpawnFeatures(spawn, level)
    local data = {
        boost = {mhp = 0, atk = 0, def = 0, sat = 0, sdf = 0, spd = 0},
        movesOff = {start = 4, remove = false},
        recruitable = true,
        weak = false
    }
    local features = spawn.SpawnFeatures
    for f = 0, features.Count-1, 1 do
        local feat = features[f]
        if LUA_ENGINE:TypeOf(feat) == luanet.ctype(RecruitSummaryMenu.FeatureBoost) then
            data.boost.mhp = data.boost.mhp + feat.MaxHPBonus
            data.boost.atk = data.boost.atk + feat.AtkBonus
            data.boost.def = data.boost.def + feat.DefBonus
            data.boost.sat = data.boost.sat + feat.SpAtkBonus
            data.boost.sdf = data.boost.sdf + feat.SpDefBonus
            data.boost.spd = data.boost.spd + feat.SpeedBonus
        elseif LUA_ENGINE:TypeOf(feat) == luanet.ctype(RecruitSummaryMenu.FeatureMovesOff) then
            data.movesOff.start = feat.StartAt
            data.movesOff.remove = feat.Remove
        elseif LUA_ENGINE:TypeOf(feat) == luanet.ctype(RecruitSummaryMenu.FeatureScaledBoost) then
            local levelMin, levelLength, levelMax = feat.LevelRange.Min, feat.LevelRange.Length, feat.LevelRange.Max
            local MAX_BOOST = PMDC.Data.MonsterFormData.MAX_STAT_BOOST
            local mhp, atk, def, sat, sdf, spd = feat.MaxHPBonus, feat.AtkBonus, feat.DefBonus, feat.SpAtkBonus, feat.SpDefBonus, feat.SpeedBonus
            local clampedLevel = math.max(levelMin, math.min(level, levelMax))
            data.boost.mhp = data.boost.mhp + math.min(mhp.Min + mhp.Length * ((clampedLevel - levelMin) // levelLength), MAX_BOOST)
            data.boost.atk = data.boost.atk + math.min(atk.Min + atk.Length * ((clampedLevel - levelMin) // levelLength), MAX_BOOST)
            data.boost.def = data.boost.def + math.min(def.Min + def.Length * ((clampedLevel - levelMin) // levelLength), MAX_BOOST)
            data.boost.sat = data.boost.sat + math.min(sat.Min + sat.Length * ((clampedLevel - levelMin) // levelLength), MAX_BOOST)
            data.boost.sdf = data.boost.sdf + math.min(sdf.Min + sdf.Length * ((clampedLevel - levelMin) // levelLength), MAX_BOOST)
            data.boost.spd = data.boost.spd + math.min(spd.Min + spd.Length * ((clampedLevel - levelMin) // levelLength), MAX_BOOST)
        elseif LUA_ENGINE:TypeOf(feat) == luanet.ctype(RecruitSummaryMenu.FeatureUnrecruitable) then
            data.recruitable = false
        elseif LUA_ENGINE:TypeOf(feat) == luanet.ctype(RecruitSummaryMenu.FeatureWeak) then
            data.weak = true
        end
    end
    return data
end


function RecruitSummaryMenu.Update(window, input)
    if input:JustPressed(RogueEssence.FrameInput.InputType.Menu) or
            input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
    elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, RogueElements.Dir8.Left) then
        _GAME:SE("Menu/Skip")
        local newPage = ((window.page-2) % window.totalPages) + 1
        local newWindow = math.min(newPage, #RecruitSummaryMenu.pageList)
        _MENU:ReplaceMenu(RecruitSummaryMenu.pageList[newWindow]:new(window.spawns, window.index, newPage).menu)
    elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, RogueElements.Dir8.Right) then
        _GAME:SE("Menu/Skip")
        local newPage = ((window.page) % window.totalPages) + 1
        local newWindow = math.min(newPage, #RecruitSummaryMenu.pageList)
        _MENU:ReplaceMenu(RecruitSummaryMenu.pageList[newWindow]:new(window.spawns, window.index, newPage).menu)
    elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, RogueElements.Dir8.Up) then
        if #window.spawns > 1 then
            _GAME:SE("Menu/Skip")
            window.index = ((window.index-2) % #window.spawns) + 1
            window:DrawMenu()
        else
            _GAME:SE("Menu/Cancel")
        end
    elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, RogueElements.Dir8.Down) then
        if #window.spawns > 1 then
            _GAME:SE("Menu/Skip")
            window.index = ((window.index) % #window.spawns) + 1
            window:DrawMenu()
        else
            _GAME:SE("Menu/Cancel")
        end
    end
end