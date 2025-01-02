-- -----------------------------------------------
-- Recruit Summary Features Window
-- -----------------------------------------------
-- Page 1 of the Recruit Summary Menu. Displays moves and possible abilities.

RecruitSummaryFeaturesWindow = Class('RecruitSummaryFeaturesWindow')

function RecruitSummaryFeaturesWindow:initialize(list, index)
    self.page = 1
    self.index = math.max(1, math.min(index or 1, #list))
    self.entries = list
    RecruitSummaryMenu.updateMenuData(self)

    self.menu = RogueEssence.Menu.ScriptableMenu(24, 16, 272, 208, function(input) RecruitSummaryMenu.Update(self, input) end)
    local GraphicsManager = RogueEssence.Content.GraphicsManager
    local Bounds = self.menu.Bounds
    local TITLE_OFFSET = RogueEssence.Menu.TitledStripMenu.TITLE_OFFSET
    local VERT_SPACE = 14
    local LINE_HEIGHT = 12

    self.menu.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_TEAM_FEATURES"), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth + 8, GraphicsManager.MenuBG.TileHeight)))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText("("..self.page.."/"..self.totalPages..")", RogueElements.Loc(Bounds.Width - GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight), RogueElements.DirH.Right))
    self.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight + 12), Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2))

    self.portraitBox  = RogueEssence.Menu.SpeakerPortrait(RecruitSummaryMenu.getBaseForm(self.entryData.monsterID), RogueEssence.Content.EmoteStyle(0), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + TITLE_OFFSET), false)
    self.nameText     = RogueEssence.Menu.MenuText("Species (genders)", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 48, GraphicsManager.MenuBG.TileHeight + TITLE_OFFSET))
    self.elementsText = RogueEssence.Menu.MenuText("Type", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 48, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 1 + TITLE_OFFSET))
    self.menu.Elements:Add(self.portraitBox)
    self.menu.Elements:Add(self.nameText)
    self.menu.Elements:Add(self.elementsText)

    self.menu.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_TEAM_LEVEL_SHORT"), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 48, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 2 + TITLE_OFFSET)))
    self.levelText    = RogueEssence.Menu.MenuText("Level", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 48 + GraphicsManager.TextFont:SubstringWidth(STRINGS:FormatKey("MENU_TEAM_LEVEL_SHORT")), GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 2 + TITLE_OFFSET), DirH.Left)
    self.menu.Elements:Add(self.levelText)

    self.menu.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_TEAM_HP"), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 3 + TITLE_OFFSET)))
    self.HPText = RogueEssence.Menu.MenuText("HP", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + GraphicsManager.TextFont:SubstringWidth(STRINGS:FormatKey("MENU_TEAM_HP")) + 4, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 3 + TITLE_OFFSET), DirH.Left)
    self.menu.Elements:Add(self.HPText)

    self.menu.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_TEAM_HUNGER"), RogueElements.Loc((Bounds.End.X - Bounds.X) / 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 3 + TITLE_OFFSET)))
    self.bellyText = RogueEssence.Menu.MenuText("Belly/100", RogueElements.Loc((Bounds.End.X - Bounds.X) / 2 + GraphicsManager.TextFont:SubstringWidth(STRINGS:FormatKey("MENU_TEAM_HUNGER")) + 4, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 3 + TITLE_OFFSET), DirH.Left)
    self.menu.Elements:Add(self.bellyText)

    self.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 5), Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2))

    self.menu.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_TEAM_SKILLS"), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 4 + TITLE_OFFSET)))
    for i = 1, RogueEssence.Dungeon.CharData.MAX_SKILL_SLOTS, 1 do
        self["skillText"..i] = RogueEssence.Menu.MenuText("-----", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * (i + 4) + TITLE_OFFSET));
        self["chargesTextL"..i] = RogueEssence.Menu.MenuText("--", RogueElements.Loc(Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2 - 16 - GraphicsManager.TextFont.CharSpace, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * (i + 4) + TITLE_OFFSET), DirH.Right);
        self["chargesTextR"..i] = RogueEssence.Menu.MenuText("/--", RogueElements.Loc(Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2 - 16, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * (i + 4) + TITLE_OFFSET), DirH.Left);
        self.menu.Elements:Add(self["skillText"..i])
        self.menu.Elements:Add(self["chargesTextL"..i])
        self.menu.Elements:Add(self["chargesTextR"..i])
    end

    self.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 10), Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2))

    self.intrinsicTextTitle = RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_TEAM_INTRINSIC", ""), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 9 + TITLE_OFFSET))
    self.menu.Elements:Add(self.intrinsicTextTitle)
    for i = 1, 3, 1 do
        self["intrinsicText"..i] = RogueEssence.Menu.MenuText("Intrinsic"..i, RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 9 + TITLE_OFFSET + 2 + LINE_HEIGHT * i))
        self.menu.Elements:Add(self["intrinsicText"..i])
    end

    self:DrawMenu()
end

function RecruitSummaryFeaturesWindow:DrawMenu()
    RecruitSummaryMenu.updateMenuData(self)

    self.portraitBox.Speaker = RecruitSummaryMenu.getBaseForm(self.entryData.monsterID)

    self.nameText:SetText(self.entryData.speciesName)

    local element1 = _DATA:GetElement(self.entryData.formEntry.Element1)
    local element2 = _DATA:GetElement(self.entryData.formEntry.Element2)
    local typeString = element1:GetIconName();
    if self.entryData.formEntry.Element2 ~= _DATA.DefaultElement then typeString = typeString.."/"..element2:GetIconName() end
    self.elementsText:SetText(STRINGS:FormatKey("MENU_TEAM_ELEMENT", typeString))

    self.levelText:SetText(tostring(self.level))

    local hp = tostring(self.formEntry:GetStat(self.entryData.level, RogueEssence.Data.Stat.HP, 0))
    self.HPText:SetText(hp)

    local hunger = self.entryData.features.hunger
    self.bellyText:SetText(hunger.."/100")

    local skills = self:loadSkills()
    for i = 1, RogueEssence.Dungeon.CharData.MAX_SKILL_SLOTS, 1 do
        self["skillText"..i]:SetText(skills[i][1])
        self["chargesTextL"..i]:SetText(skills[i][2])
        self["chargesTextR"..i]:SetText(skills[i][3])
    end

    local nIntrinsics, intrinsics = self:loadIntrinsics()
    local intrinsicTitle = STRINGS:FormatKey("MENU_TEAM_INTRINSIC", "")
    if nIntrinsics>1 then intrinsicTitle = "Possible Abilities:" end
    self.intrinsicTextTitle:SetText(intrinsicTitle)
    for i = 1, 3, 1 do
        self["intrinsicText"..i]:SetText(intrinsics[i])
    end
end

function RecruitSummaryFeaturesWindow:loadSkills()
    local skills = {{"-----", "--", "/--"}, {"-----", "--", "/--"}, {"-----", "--", "/--"}, {"-----", "--", "/--"}}
    local moves = self.entryData.features.moves

    for i=1, #skills, 1 do
        if moves[i] and moves[i].id ~= "" then
            local skill = _DATA:GetSkill(moves[i].id)
            local element = _DATA:GetElement(skill.Data.Element).Symbol
            local skillText = skill.Name:ToLocal()

            local charges = moves[i].pp
            local chargesText = tostring(charges)
            local baseChargesText = "/"..tostring(skill.BaseCharges)

            if not moves[i].enabled then
                skillText = "[color=#FF0000]"..skillText.."[color]"
                chargesText = "[color=#FF0000]"..chargesText.."[color]"
                baseChargesText = "[color=#FF0000]"..baseChargesText.."[color]"
            else
                skillText = "[color=#00FF00]"..skillText.."[color]"
            end

            skills[i][1] = utf8.char(element).."\u{2060}"..skillText
            skills[i][2] = chargesText
            skills[i][3] = baseChargesText
        end
    end
    return skills
end

function RecruitSummaryFeaturesWindow:loadIntrinsics()
    local n, result = 1, {"", "", ""}
    if self.spawnType == "char" then
        local intrinsic = _DATA:GetIntrinsic(self.element.BaseIntrinsics[0])
        result[1] = intrinsic:GetColoredName()
    else
        if self.element.Intrinsic == nil or self.element.Intrinsic == "" then
            local j=1
            local formIntrinsics = {self.entryData.formEntry.Intrinsic1, self.entryData.formEntry.Intrinsic2, self.entryData.formEntry.Intrinsic3}
            for _, id in pairs(formIntrinsics) do
                if not (id == nil or id == "" or id == "none") then
                    local intrinsic = _DATA:GetIntrinsic(id)
                    result[j] = intrinsic:GetColoredName()
                    j = j+1
                end
            end
            n = j-1
        else
            local intrinsic = _DATA:GetIntrinsic(self.element.Intrinsic)
            result[1] = intrinsic:GetColoredName()
        end
    end
    return n, result
end