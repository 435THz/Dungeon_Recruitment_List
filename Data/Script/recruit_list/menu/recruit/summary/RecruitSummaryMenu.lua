require "recruit_list.menu.recruit.summary.RecruitSummaryFeaturesWindow"
require "recruit_list.menu.recruit.summary.RecruitSummaryStatsWindow"
require "recruit_list.menu.recruit.summary.RecruitSummaryLearnsetWindow"
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
RecruitSummaryMenu.pageList = {RecruitSummaryFeaturesWindow, RecruitSummaryStatsWindow, RecruitSummaryLearnsetWindow}

--- Initializes the RecruitSummaryMenu data set and then calls RecruitSummaryFeaturesWindow
---@param entry fullDungeonSpawn_entry|floorSpawn_entry
function RecruitSummaryMenu.run(entry)
    RecruitSummaryMenu.pages = nil
    local entries
    entries = RecruitSummaryMenu.loadSpawnEntries(entry)
    _MENU:AddMenu(RecruitSummaryFeaturesWindow:new(entries, 1).menu, false)
end

--- Loads the list of entries that will then be used by menus
---@param entry fullDungeonSpawn_entry|floorSpawn_entry
---@return {spawn:any|nil,char:any|nil,level:integer,dungeon:{zone:string,segment:integer},floors:{min:integer,max:integer}[]}
function RecruitSummaryMenu.loadSpawnEntries(entry)
    ---@type {spawn:any|nil,char:any|nil,level:integer,dungeon:{zone:string,segment:integer},floors:{min:integer,max:integer}[]}
    local list = {}
    for _, element in pairs(entry.elements) do
        if entry.type == "spawn" then
            if RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then
                local loc = RECRUIT_LIST.getCurrentMap()
                local f = loc.floor
                local lvl_list = RecruitSummaryMenu.loadSpawnLevels(element.data, f)
                for _, lv in pairs(lvl_list) do
                    table.insert(list, {spawn = element.data, level = lv, dungeon = {zone = loc.zone, segment = loc.segment}, floors = {{min = f, max = f}}})
                end
            else
                ---@type table<integer, table<integer, boolean>>
                local levels = {}
                for f = element.range.min, element.range.max, 1 do
                    local lvl_list = RecruitSummaryMenu.loadSpawnLevels(element.data, f)
                    for _, lv in pairs(lvl_list) do
                        levels[lv] = levels[lv] or {}
                        levels[lv][f] = true
                    end
                end
                for lvl, f_list in pairs(levels) do
                    ---@type {spawn:any,level:integer,dungeon:{zone:string,segment:integer},floors:{min:integer,max:integer}[]}
                    local elem = {spawn = element.data, level = lvl, dungeon = element.dungeon, floors = {}}
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
                            table.insert(elem.floors, current)
                            current = { min = f, max = f}
                        end
                    end
                    table.insert(elem.floors, current)
                    table.insert(list, elem)
                end
            end
        else
            local loc = RECRUIT_LIST.getCurrentMap()
            local f = loc.floor
            table.insert(list, {char = element.data, level = element.data.Level, dungeon = {zone = loc.zone, segment = loc.segment}, floors = {{min = f, max = f}}})
        end
    end
    return list
end

---@param spawn any
---@param floor integer
---@return integer[]
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

---@param window any
function RecruitSummaryMenu.updateMenuData(window)
    window.entryData = {
        monsterID = nil,
        formEntry = nil,
        level = 0,
        speciesName = "",
        speciesNameGenders = "",
        features = {} --{boost, moves, recruitable, hunger}
    }
    window.current = window.entries[window.index] --spawn entry
    window.spawnType = "spawn"
    if not window.current.spawn then window.spawnType = "char" end
    window.element = window.current[window.spawnType] --MobSpawn or Character

    window.level = window.current.level --int

    window.baseForm = window.element.BaseForm -- MonsterID
    window.formId = window.baseForm.Form -- int

    window.speciesEntry = _DATA:GetMonster(window.baseForm.Species) -- MonsterData
    window.formEntry = window.speciesEntry.Forms[window.formId] -- MonsterForm
    window.totalPages = RecruitSummaryMenu.getPages(window.formEntry) -- int

    window.entryData.monsterID = window.baseForm
    window.entryData.formEntry = window.formEntry
    window.entryData.level = window.level
    window.entryData.features = RecruitSummaryMenu.loadFeatures(window.element, window.formEntry, window.level, window.spawnType == "char") -- spawn features table
    window.entryData.speciesName = RecruitSummaryMenu.GetFullFormName(window.entryData.monsterID, window.entryData.formEntry, window.entryData.features)
    window.entryData.speciesNameGenders = RecruitSummaryMenu.GetFullFormName(window.entryData.monsterID, window.entryData.formEntry, window.entryData.features, true)
end

---@param formEntry any
---@return integer
function RecruitSummaryMenu.getPages(formEntry)
    if RecruitSummaryMenu.pages == nil then
        RecruitSummaryMenu.pages = #RecruitSummaryMenu.pageList - 1 +  math.ceil( RecruitSummaryMenu.getEligibleSkills(formEntry) / RecruitSummaryMenu.SLOTS_PER_PAGE)
    end
    return RecruitSummaryMenu.pages
end

---@param formEntry any
---@return integer
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

---@param form MonsterID
---@param entry any
---@param data {boost:{mhp:integer,atk:integer,def:integer, sat:integer, sdf:integer, spd:integer},moves:{id:string, pp:integer, enabled:boolean}[],recruitable:boolean,hunger:integer}
---@param genderInParentheses boolean?
---@return unknown
function RecruitSummaryMenu.GetFullFormName(form, entry, data, genderInParentheses)
    local baseForm = RecruitSummaryMenu.getBaseForm(form)
    local name = _DATA:GetMonster(form.Species).Name:ToLocal()
    if not data.recruitable then
        name = "[color=#989898]"..name
    elseif _DATA.Save:GetMonsterFormUnlock(form) == RogueEssence.Data.GameProgress.UnlockState.Completed then
        name = "[color=#00FF00]"..name else
        name = "[color=#00FFFF]"..name end

    local skinData = _DATA:GetSkin(baseForm.Skin)
    if utf8.char(skinData.Symbol).."" ~= "\0" then
        name = skinData.Symbol..name
    end
    local genderText = ''
    if     form.Gender == RogueEssence.Data.Gender.Unknown or genderInParentheses then genderText = RecruitSummaryMenu.GetPossibleGenders(entry)
    elseif form.Gender == RogueEssence.Data.Gender.Male    then genderText = '\u{2642}'
    elseif form.Gender == RogueEssence.Data.Gender.Female  then genderText = '\u{2640}'
    end
    if string.sub(name, -#genderText) ~= genderText then
        if #genderText>1 then name = name.."[color]"..genderText
        else name = name..genderText.."[color]" end
    else name = name.."[color]" end
    return name
end

---@param form any actually a MonsterID object
---@return string
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

---@param baseForm MonsterID
---@return MonsterID
function RecruitSummaryMenu.getBaseForm(baseForm)
    local default = _DATA.DefaultMonsterID
    local skin = baseForm.Skin
    if skin == "" then skin = default.Skin end
    local gender = baseForm.Gender
    if gender == RogueEssence.Data.Gender.Unknown then gender = default.Gender end
    return RogueEssence.Dungeon.MonsterID(baseForm.Species, baseForm.Form, skin, gender)
end

---@param element any
---@param formEntry any
---@param level integer
---@param isChar boolean
---@return {boost:{mhp:integer,atk:integer,def:integer, sat:integer, sdf:integer, spd:integer},moves:{id:string, pp:integer, enabled:boolean}[],recruitable:boolean,hunger:integer}
function RecruitSummaryMenu.loadFeatures(element, formEntry, level, isChar)
    local data = {
        boost = {mhp = 0, atk = 0, def = 0, sat = 0, sdf = 0, spd = 0},
        moves = {}, --{id = string, pp = int, enabled = bool}
        recruitable = true,
        hunger = 100
    }
    if isChar then
        data.boost = {
            mhp = element.MaxHPBonus,
            atk = element.AtkBonus,
            def = element.DefBonus,
            sat = element.MAtkBonus,
            sdf = element.MDefBonus,
            spd = element.SpeedBonus
        }
        data.recruitable = not element.Unrecruitable
        data.moves = RecruitSummaryMenu.loadCharSkills(element)
    else
        local features = element.SpawnFeatures
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
                data.moves = RecruitSummaryMenu.loadSpawnSkills(element, formEntry, level, feat.StartAt, feat.Remove)
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
                data.hunger = 35
                for _, move in ipairs(data.moves) do
                    move.pp = math.ceil(move.pp/2)
                end
            end
        end
    end
    return data
end

---@param char any
---@return {id:string, pp:integer, enabled:boolean}
function RecruitSummaryMenu.loadCharSkills(char)
    local skills = {}
    local skillList = char.BaseSkills
    for i=0, skillList.Count-1, 1 do
        if skillList[i].SkillNum ~= "" then
            skills[i+1] = {id = skillList[i].SkillNum, pp = skillList[i].Charges, enabled = char.Skills[i].Element.Enabled and not char.Skills[i].Element.Sealed}
        end
    end
    return skills
end

---@param spawn any
---@param formEntry any
---@param level integer
---@param offStart integer
---@param offRemove integer
---@return {id:string, pp:integer, enabled:boolean}[]
function RecruitSummaryMenu.loadSpawnSkills(spawn, formEntry, level, offStart, offRemove)
    local skillsActive = math.max(0, math.min(offStart, RogueEssence.Dungeon.CharData.MAX_SKILL_SLOTS))
    local skillsNumber = RogueEssence.Dungeon.CharData.MAX_SKILL_SLOTS
    if offRemove then skillsNumber = skillsActive end

    local skillIds = formEntry:RollLatestSkills(level, spawn.SpecifiedSkills)
    while skillIds.Count>skillsNumber do skillIds:RemoveAt(skillIds.Count-1) end

    local skills = {}
    for i=0, skillIds.Count-1, 1 do
        if i >= 4 then break end
        local move = {id = "", pp = 0, enabled = false}
        if skillIds[i] and skillIds[i] ~= "" then
            move = {
                id = skillIds[i],
                pp = _DATA:GetSkill(skillIds[i]).BaseCharges,
                enabled = i < skillsActive
            }
        end
        table.insert(skills, move)
    end
    return skills
end

---@param window any
---@param input any
---@param failSound string?
function RecruitSummaryMenu.Update(window, input, failSound)
    if failSound == nil then failSound = "Menu/Cancel" end
    if input:JustPressed(RogueEssence.FrameInput.InputType.Menu) or
            input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
    elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(RogueElements.Dir8, {RogueElements.Dir8.Left})) then
        _GAME:SE("Menu/Skip")
        local newPage = ((window.page-2) % window.totalPages) + 1
        local newWindow = math.min(newPage, #RecruitSummaryMenu.pageList)
        _MENU:ReplaceMenu(RecruitSummaryMenu.pageList[newWindow]:new(window.entries, window.index, newPage, window.selected).menu)
    elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(RogueElements.Dir8, {RogueElements.Dir8.Right})) then
        _GAME:SE("Menu/Skip")
        local newPage = ((window.page) % window.totalPages) + 1
        local newWindow = math.min(newPage, #RecruitSummaryMenu.pageList)
        _MENU:ReplaceMenu(RecruitSummaryMenu.pageList[newWindow]:new(window.entries, window.index, newPage, window.selected).menu)
    elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(RogueElements.Dir8, {RogueElements.Dir8.Up})) then
        if #window.entries > 1 then
            _GAME:SE("Menu/Skip")
            window.index = ((window.index-2) % #window.entries) + 1
            window:DrawMenu()
        else
            _GAME:SE(failSound)
        end
    elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(RogueElements.Dir8, {RogueElements.Dir8.Down})) then
        if #window.entries > 1 then
            _GAME:SE("Menu/Skip")
            window.index = ((window.index) % #window.entries) + 1
            window:DrawMenu()
        else
            _GAME:SE(failSound)
        end
    end
end