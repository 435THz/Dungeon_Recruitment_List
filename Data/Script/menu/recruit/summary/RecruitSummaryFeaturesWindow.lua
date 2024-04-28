-- -----------------------------------------------
-- Recruit Summary Features Window
-- -----------------------------------------------
-- Page 1 of the Recruit Summary Menu. Displays moves and possible abilities.

RecruitSummaryFeaturesWindow = Class('RecruitSummaryFeaturesWindow')

function RecruitSummaryFeaturesWindow:initialize(spawns, index)
    self.page = 1
    self.index = math.max(1, math.min(index or 1, #spawns))
    self.spawns = spawns
    self:updateMenuData()

    self.menu = RogueEssence.Menu.ScriptableMenu(24, 16, 272, 208, function(input) RecruitSummaryMenu.Update(self, input) end)
    local GraphicsManager = RogueEssence.Content.GraphicsManager
    local Bounds = self.menu.Bounds
    local TITLE_OFFSET = RogueEssence.Menu.TitledStripMenu.TITLE_OFFSET
    local VERT_SPACE = 14
    local LINE_HEIGHT = 12

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_TEAM_FEATURES"), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth + 8, GraphicsManager.MenuBG.TileHeight)))
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("(1/"..self.totalPages..")", RogueElements.Loc(Bounds.Width - GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight), RogueElements.DirH.Right))
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight + 12), Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2))

    self.portraitBox  = RogueEssence.Menu.SpeakerPortrait(RecruitSummaryMenu.getBaseForm(self.baseForm), RogueEssence.Content.EmoteStyle(0), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + TITLE_OFFSET), false)
    self.nameText     = RogueEssence.Menu.MenuText("Species (genders)", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 48, GraphicsManager.MenuBG.TileHeight + TITLE_OFFSET))
    self.elementsText = RogueEssence.Menu.MenuText("Type", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 48, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 1 + TITLE_OFFSET))
    self.menu.MenuElements:Add(self.portraitBox)
    self.menu.MenuElements:Add(self.nameText)
    self.menu.MenuElements:Add(self.elementsText)

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(Text.FormatKey("MENU_TEAM_LEVEL_SHORT"), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 48, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 2 + TITLE_OFFSET)))
    self.levelText    = RogueEssence.Menu.MenuText("Level", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 48 + GraphicsManager.TextFont:SubstringWidth(STRINGS:FormatKey("MENU_TEAM_LEVEL_SHORT")), GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 2 + TITLE_OFFSET), DirH.Left)
    self.menu.MenuElements:Add(self.levelText)

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_TEAM_HP"), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 3 + TITLE_OFFSET)))
    self.HPText = RogueEssence.Menu.MenuText("HP", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + GraphicsManager.TextFont:SubstringWidth(STRINGS:FormatKey("MENU_TEAM_HP")) + 4, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 3 + TITLE_OFFSET), DirH.Left)
    self.menu.MenuElements:Add(self.HPText)

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(Text.FormatKey("MENU_TEAM_HUNGER"), RogueElements.Loc((Bounds.End.X - Bounds.X) / 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 3 + TITLE_OFFSET)))
    self.bellyText = RogueEssence.Menu.MenuText("Belly/100", RogueElements.Loc((Bounds.End.X - Bounds.X) / 2 + GraphicsManager.TextFont:SubstringWidth(STRINGS:FormatKey("MENU_TEAM_HUNGER")) + 4, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 3 + TITLE_OFFSET), DirH.Left)
    self.menu.MenuElements:Add(self.bellyText)

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 5), Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2))

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(Text.FormatKey("MENU_TEAM_SKILLS"), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 4 + TITLE_OFFSET)))
    for i = 1, RogueEssence.Dungeon.CharData.MAX_SKILL_SLOTS, 1 do
        self["skillText"..i] = RogueEssence.Menu.MenuText("-----", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * (i + 4) + TITLE_OFFSET));
        self["chargesTextL"..i] = RogueEssence.Menu.MenuText("--", RogueElements.Loc(Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2 - 16 - GraphicsManager.TextFont.CharSpace, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * (i + 4) + TITLE_OFFSET), DirH.Right);
        self["chargesTextR"..i] = RogueEssence.Menu.MenuText("/--", RogueElements.Loc(Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2 - 16, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * (i + 4) + TITLE_OFFSET), DirH.Left);
        self.menu.MenuElements:Add(self["skillText"..i])
        self.menu.MenuElements:Add(self["chargesTextL"..i])
        self.menu.MenuElements:Add(self["chargesTextR"..i])
    end

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 10), Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2))

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_TEAM_INTRINSIC", ""), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 9 + TITLE_OFFSET)))
    for i = 1, 3, 1 do
        self["intrinsicText"..i] = RogueEssence.Menu.MenuText("Intrinsic"..i, RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 9 + TITLE_OFFSET + 2 + LINE_HEIGHT * i))
        self.menu.MenuElements:Add(self["intrinsicText"..i])
    end

    self:DrawMenu()
end

function RecruitSummaryFeaturesWindow:updateMenuData()
    self.current = self.spawns[self.index]
    self.spawn = self.current.spawn
    self.level = self.current.level
    self.spawnData = RecruitSummaryMenu.loadSpawnFeatures(self.spawn, self.level)

    self.baseForm = self.spawn.BaseForm
    self.formId = self.baseForm.Form

    self.speciesEntry = _DATA:GetMonster(self.baseForm.Species)
    self.formEntry = self.speciesEntry.Forms[self.formId]
    self.totalPages = RecruitSummaryMenu.getPages(self.formEntry)
end

function RecruitSummaryFeaturesWindow:DrawMenu()
    self:updateMenuData()

    self.portraitBox.Speaker = RecruitSummaryMenu.getBaseForm(self.baseForm)

    local speciesName = RecruitSummaryMenu.GetFullFormName(self.baseForm, self.formEntry, self.spawnData)
    self.nameText:SetText(speciesName)

    local element1 = _DATA:GetElement(self.formEntry.Element1)
    local element2 = _DATA:GetElement(self.formEntry.Element2)
    local typeString = element1:GetIconName();
    if self.formEntry.Element2 ~= _DATA.DefaultElement then typeString = typeString.."/"..element2:GetIconName() end
    self.elementsText:SetText(STRINGS:FormatKey("MENU_TEAM_ELEMENT", typeString))

    self.levelText:SetText(tostring(self.level))

    local hp = tostring(self.formEntry:GetStat(self.level, RogueEssence.Data.Stat.HP, 0))
    self.HPText:SetText(hp.."/"..hp)

    local hunger = 100
    if self.spawnData.weak then hunger = 35 end
    self.bellyText:SetText(hunger.."/100")

    local skills = self:loadSkills()
    for i = 1, RogueEssence.Dungeon.CharData.MAX_SKILL_SLOTS, 1 do
        self["skillText"..i]:SetText(skills[i][1])
        self["chargesTextL"..i]:SetText(skills[i][2])
        self["chargesTextR"..i]:SetText(skills[i][3])
    end

    local intrinsics = self:loadIntrinsics()
    for i = 1, 3, 1 do
        self["intrinsicText"..i]:SetText(intrinsics[i])
    end

end

function RecruitSummaryFeaturesWindow:loadSkills()
    local skillsActive = math.max(0, math.min(self.spawnData.movesOff.start, RogueEssence.Dungeon.CharData.MAX_SKILL_SLOTS))
    local skillsNumber = RogueEssence.Dungeon.CharData.MAX_SKILL_SLOTS
    if self.spawnData.movesOff.remove then skillsNumber = skillsActive end

    local skillIds = self.formEntry:RollLatestSkills(self.level, self.spawn.SpecifiedSkills)
    while skillIds.Count>skillsNumber do skillIds:RemoveAt(skillIds.Count-1) end

    local skills = {{"-----", "--", "/--"}, {"-----", "--", "/--"}, {"-----", "--", "/--"}, {"-----", "--", "/--"}}
    for i=0, skillIds.Count-1, 1 do
        if i >= #skills then break end
        if skillIds[i] and skillIds[i] ~= "" then
            local skill = _DATA:GetSkill(skillIds[i])
            local element = _DATA:GetElement(skill.Data.Element).Symbol
            local skillText = skill.Name:ToLocal()

            local charges = skill.BaseCharges
            if self.spawnData.weak then charges = math.ceil(charges/2) end
            local chargesText = tostring(charges)
            local baseChargesText = "/"..tostring(skill.BaseCharges)

            if i >= skillsActive then
                skillText = "[color=#FF0000]"..skillText.."[color]"
                chargesText = "[color=#FF0000]"..chargesText.."[color]"
                baseChargesText = "[color=#FF0000]"..baseChargesText.."[color]"
            else
                skillText = "[color=#00FF00]"..skillText.."[color]"
            end

            skills[i+1][1] = utf8.char(element).."\u{2060}"..skillText
            skills[i+1][2] = chargesText
            skills[i+1][3] = baseChargesText
        end
    end
    return skills
end

function RecruitSummaryFeaturesWindow:loadIntrinsics()
    local result = {"", "", ""}
    if self.spawn.Intrinsic == nil or self.spawn.Intrinsic == "" then
        local j=1
        local formIntrinsics = {self.formEntry.Intrinsic1, self.formEntry.Intrinsic2, self.formEntry.Intrinsic3}
        for _, id in pairs(formIntrinsics) do
            if not (id == nil or id == "" or id == "none") then
                local intrinsic = _DATA:GetIntrinsic(id)
                result[j] = intrinsic:GetColoredName()
                j = j+1
            end
        end
    else
        local intrinsic = _DATA:GetIntrinsic(self.spawn.Intrinsic)
        result[1] = intrinsic:GetColoredName()
    end
    return result
end