-- -----------------------------------------------
-- Recruit Summary Stats Window
-- -----------------------------------------------
-- Page 2 of the Recruit Summary Menu. Displays stats and recruit rate.

RecruitSummaryStatsWindow = Class('RecruitSummaryStatsWindow')

function RecruitSummaryStatsWindow:initialize(spawns, index)
    self.page = 2
    self.index = math.max(1, math.min(index or 1, #spawns))
    self.spawns = spawns
    RecruitSummaryMenu.updateMenuData(self)

    self.menu = RogueEssence.Menu.ScriptableMenu(24, 16, 272, 208, function(input) RecruitSummaryMenu.Update(self, input) end)
    local GraphicsManager = RogueEssence.Content.GraphicsManager
    local Bounds = self.menu.Bounds
    local TITLE_OFFSET = RogueEssence.Menu.TitledStripMenu.TITLE_OFFSET
    local VERT_SPACE = 14
    local LINE_HEIGHT = 12

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_STATS_TITLE"), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth + 8, GraphicsManager.MenuBG.TileHeight)))
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("("..self.page.."/"..self.totalPages..")", RogueElements.Loc(Bounds.Width - GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight), RogueElements.DirH.Right))
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight + 12), Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2))

    self.portraitBox  = RogueEssence.Menu.SpeakerPortrait(RecruitSummaryMenu.getBaseForm(self.baseForm), RogueEssence.Content.EmoteStyle(0), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + TITLE_OFFSET), false)
    self.nameText     = RogueEssence.Menu.MenuText("Species (genders)", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 48, GraphicsManager.MenuBG.TileHeight + TITLE_OFFSET))
    self.elementsText = RogueEssence.Menu.MenuText("Type", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 48, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 1 + TITLE_OFFSET))
    self.menu.MenuElements:Add(self.portraitBox)
    self.menu.MenuElements:Add(self.nameText)
    self.menu.MenuElements:Add(self.elementsText)

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_TEAM_LEVEL_SHORT"), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 48, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 2 + TITLE_OFFSET)))
    self.levelText    = RogueEssence.Menu.MenuText("Level", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 48 + GraphicsManager.TextFont:SubstringWidth(STRINGS:FormatKey("MENU_TEAM_LEVEL_SHORT")), GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 2 + TITLE_OFFSET), DirH.Left)
    self.menu.MenuElements:Add(self.levelText)

    self.locationText = RogueEssence.Menu.MenuText("Lives in: Location", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 3 + TITLE_OFFSET))
    self.menu.MenuElements:Add(self.locationText)

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 5), Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2))

    local Stat = RogueEssence.Data.Stat
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_TEAM_STATS"), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 4 + TITLE_OFFSET)))
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_LABEL", Stat.HP:ToLocal("tiny")), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 8, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 5 + TITLE_OFFSET)))
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_LABEL", Stat.Attack:ToLocal("tiny")), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 8, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 6 + TITLE_OFFSET)))
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_LABEL", Stat.Defense:ToLocal("tiny")), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 8, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 7 + TITLE_OFFSET)))
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_LABEL", Stat.MAtk:ToLocal("tiny")), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 8, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 8 + TITLE_OFFSET)))
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_LABEL", Stat.MDef:ToLocal("tiny")), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 8, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 9 + TITLE_OFFSET)))
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_LABEL", Stat.Speed:ToLocal("tiny")), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 8, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 10 + TITLE_OFFSET)))

    self.HPText =      RogueEssence.Menu.MenuText("MHP", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 72, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 5  + TITLE_OFFSET), RogueElements.DirH.Right)
    self.AttackText =  RogueEssence.Menu.MenuText("ATK", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 72, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 6  + TITLE_OFFSET), RogueElements.DirH.Right)
    self.DefenseText = RogueEssence.Menu.MenuText("DEF", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 72, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 7  + TITLE_OFFSET), RogueElements.DirH.Right)
    self.MAtkText =    RogueEssence.Menu.MenuText("SAT", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 72, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 8  + TITLE_OFFSET), RogueElements.DirH.Right)
    self.MDefText =    RogueEssence.Menu.MenuText("SDF", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 72, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 9  + TITLE_OFFSET), RogueElements.DirH.Right)
    self.SpeedText =   RogueEssence.Menu.MenuText("SPD", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 72, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 10 + TITLE_OFFSET), RogueElements.DirH.Right)
    self.menu.MenuElements:Add(self.HPText)
    self.menu.MenuElements:Add(self.AttackText)
    self.menu.MenuElements:Add(self.DefenseText)
    self.menu.MenuElements:Add(self.MAtkText)
    self.menu.MenuElements:Add(self.MDefText)
    self.menu.MenuElements:Add(self.SpeedText)

    self.HPBar =      RogueEssence.Menu.MenuStatBar(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 76, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 5  + TITLE_OFFSET), 1, self:calcColor(1))
    self.AttackBar =  RogueEssence.Menu.MenuStatBar(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 76, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 6  + TITLE_OFFSET), 1, self:calcColor(1))
    self.DefenseBar = RogueEssence.Menu.MenuStatBar(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 76, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 7  + TITLE_OFFSET), 1, self:calcColor(1))
    self.MAtkBar =    RogueEssence.Menu.MenuStatBar(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 76, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 8  + TITLE_OFFSET), 1, self:calcColor(1))
    self.MDefBar =    RogueEssence.Menu.MenuStatBar(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 76, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 9  + TITLE_OFFSET), 1, self:calcColor(1))
    self.SpeedBar =   RogueEssence.Menu.MenuStatBar(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 + 76, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 10 + TITLE_OFFSET), 1, self:calcColor(1))
    self.menu.MenuElements:Add(self.HPBar)
    self.menu.MenuElements:Add(self.AttackBar)
    self.menu.MenuElements:Add(self.DefenseBar)
    self.menu.MenuElements:Add(self.MAtkBar)
    self.menu.MenuElements:Add(self.MDefBar)
    self.menu.MenuElements:Add(self.SpeedBar)

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 12), Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2))

    self.recruitChanceText = RogueEssence.Menu.MenuText("Join Rate: chance%", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 11 + TITLE_OFFSET))
    self.recruitabilityText = RogueEssence.Menu.MenuText("Recruitable?", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + VERT_SPACE * 11 + TITLE_OFFSET + LINE_HEIGHT))
    self.menu.MenuElements:Add(self.recruitChanceText)
    self.menu.MenuElements:Add(self.recruitabilityText)

    self:DrawMenu()
end


function RecruitSummaryStatsWindow:DrawMenu()
    RecruitSummaryMenu.updateMenuData(self)

    self.portraitBox.Speaker = RecruitSummaryMenu.getBaseForm(self.baseForm)

    local speciesName = RecruitSummaryMenu.GetFullFormName(self.baseForm, self.formEntry, self.spawnData)
    self.nameText:SetText(speciesName)

    local element1 = _DATA:GetElement(self.formEntry.Element1)
    local element2 = _DATA:GetElement(self.formEntry.Element2)
    local typeString = element1:GetIconName();
    if self.formEntry.Element2 ~= _DATA.DefaultElement then typeString = typeString.."/"..element2:GetIconName() end
    self.elementsText:SetText(STRINGS:FormatKey("MENU_TEAM_ELEMENT", typeString))

    self.levelText:SetText(tostring(self.level))

    local location = "Lives in: "
    location = location .. "[color=#FFC663]"..self:buildLocationText().."[color]"
    self.locationText:SetText(location)

    local Stat = RogueEssence.Data.Stat
    local HP =      self.formEntry:GetStat(self.level, Stat.HP,      self.spawnData.boost.mhp)
    local Attack =  self.formEntry:GetStat(self.level, Stat.Attack,  self.spawnData.boost.atk)
    local Defense = self.formEntry:GetStat(self.level, Stat.Defense, self.spawnData.boost.def)
    local MAtk =    self.formEntry:GetStat(self.level, Stat.MAtk,    self.spawnData.boost.sat)
    local MDef =    self.formEntry:GetStat(self.level, Stat.MDef,    self.spawnData.boost.sdf)
    local Speed =   self.formEntry:GetStat(self.level, Stat.Speed,   self.spawnData.boost.spd)
    self.HPText:SetText(tostring(HP))
    self.AttackText:SetText(tostring(Attack))
    self.DefenseText:SetText(tostring(Defense))
    self.MAtkText:SetText(tostring(MAtk))
    self.MDefText:SetText(tostring(MDef))
    self.SpeedText:SetText(tostring(Speed))

    local hpLength =    self:calcLength(Stat.HP,      self.formEntry, HP,      self.level)
    local atkLength =   self:calcLength(Stat.Attack,  self.formEntry, Attack,  self.level)
    local defLength =   self:calcLength(Stat.Defense, self.formEntry, Defense, self.level)
    local mAtkLength =  self:calcLength(Stat.MAtk,    self.formEntry, MAtk,    self.level)
    local mDefLength =  self:calcLength(Stat.MDef,    self.formEntry, MDef,    self.level)
    local speedLength = self:calcLength(Stat.Speed,   self.formEntry, Speed,   self.level)
    self.HPBar.Length =      hpLength
    self.AttackBar.Length =  atkLength
    self.DefenseBar.Length = defLength
    self.MAtkBar.Length =    mAtkLength
    self.MDefBar.Length =    mDefLength
    self.SpeedBar.Length =   speedLength
    self.HPBar.Color =      self:calcColor(hpLength)
    self.AttackBar.Color =  self:calcColor(atkLength)
    self.DefenseBar.Color = self:calcColor(defLength)
    self.MAtkBar.Color =    self:calcColor(mAtkLength)
    self.MDefBar.Color =    self:calcColor(mDefLength)
    self.SpeedBar.Color =   self:calcColor(speedLength)


    local joinRate = self.speciesEntry.JoinRate
    local color = self:calcChanceColor(joinRate)
    local recruitability = ""
    if not self.spawnData.recruitable then
        color = "#989898"
        recruitability = "Unrecruitable"
    end
    self.recruitChanceText:SetText("Join Rate: [color="..color.."]"..joinRate.."%[color]")
    self.recruitabilityText:SetText("[color=#989898]"..recruitability.."[color]")
end

-- i don't like this way of doing that but that's what the game does so we'll go with it i guess
function RecruitSummaryStatsWindow:calcLength(stat, form, current, level)
    local avgLevel = 0;
    for i = 0, _DATA.Save.ActiveTeam.Players.Count - 1, 1 do
        avgLevel = avgLevel + _DATA.Save.ActiveTeam.Players[i].Level
    end

    avgLevel = avgLevel / _DATA.Save.ActiveTeam.Players.Count
    local baseStat = form:ReverseGetStat(stat, current, level)
    baseStat = baseStat * level / avgLevel
    return math.min(math.max(1, baseStat * 140 / 120), 168)
end

function RecruitSummaryStatsWindow:buildLocationText()
    local loc = self.current.dungeon
    local dungeonName = RECRUIT_LIST.getSegmentData(loc.zone, loc.segment).name
    if dungeonName == nil then
        if RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then
            return _ZONE.CurrentMap:GetColoredName()
        else return "Mysterious Location" end
    end
    local ranges = ""
    for i, range in pairs(self.current.floors) do
        if i>1 then ranges = ranges..", " end
        if range.min == range.max then
            ranges = ranges..range.min.."F"
        else
            ranges = ranges..range.min.."-"..range.max.."F"
        end
    end
    return dungeonName.." "..ranges
end

function RecruitSummaryStatsWindow:calcColor(length)
    local newColor = function(r, g, b) return Color(r/255, g/255, b/255) end

    if     length * 120 < 50  * 140 then return newColor(248, 128, 88)
    elseif length * 120 < 80  * 140 then return newColor(248, 232, 88)
    elseif length * 120 < 110 * 140 then return newColor(88, 248, 88)
    else return newColor(88, 192, 248) end
end

function RecruitSummaryStatsWindow:calcChanceColor(value)
    if     value <= -50 then return "#A00000"
    elseif value <= -35 then return "#FF0000"
    elseif value <= -30 then return "#FF303f"
    elseif value <    0 then return "#FF485f"
    elseif value <   15 then return "#FF9542"
    elseif value <   20 then return "#FFC663"
    elseif value <   50 then return "#FFFF53"
    elseif value <  100 then return "#4aff47"
    else return "#00FF00" end
end
