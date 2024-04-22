require "menu.recruit.RecruitListSegmentMenu"
require "menu.recruit.RecruitmentListMenu"

-- -----------------------------------------------
-- Recruitment List Dungeon Choice Menu
-- -----------------------------------------------
-- Menu for choosing what dungeon to visualize the recruit list of

RecruitListDungeonMenu = Class('RecruitListDungeonMenu')
RecruitListDungeonMenu.static = {}
RecruitListDungeonMenu.static.color_complete = "#FFC663"
RecruitListDungeonMenu.static.color_incomplete = "#00FFFF"

function RecruitListDungeonMenu:initialize()
    assert(self, "RecruitListDungeonMenu:initialize(): self is nil!")
    self.static = RecruitListDungeonMenu.static

    local exit_fn = function() _GAME:SE("Menu/Cancel"); _MENU:RemoveMenu() end
    self.entries = RECRUIT_LIST.getDungeonOrder()
    self.choices = self:generateOptions()
    local choices_array = luanet.make_array(RogueEssence.Menu.MenuTextChoice, self.choices)
    self.menu = RogueEssence.Menu.ScriptableMultiPageMenu(RogueElements.Loc(16,16), 144, "Dungeons", choices_array, 0, 10, exit_fn, exit_fn)
    self.menu.ChoiceChangedFunction = function() self:updateSummary() end
    self.summary = RecruitListDungeonSummary:new()
    self.menu.SummaryMenus:Add(self.summary.window)
    self:updateSummary()
end

function RecruitListDungeonMenu:generateOptions()
    local choices = {}
    for _,entry in pairs(self.entries) do
        local color = self.static.color_incomplete
        if RECRUIT_LIST.getSegmentData(entry.zone,0).completed then color = self.static.color_complete end
        local zone_name = "[color="..color.."]"..entry.name.."[color]"
        table.insert(choices, RogueEssence.Menu.MenuTextChoice(zone_name, function() self:chooseNextMenu(entry.zone) end))
    end
    return choices
end

function RecruitListDungeonMenu:updateSummary()
    local selected = self.entries[self.menu.CurrentChoiceTotal+1]
    local index = selected.zone
    local completed = RECRUIT_LIST.getSegmentData(index,0).completed
    local color = self.static.color_incomplete
    if completed then color = self.static.color_complete end
    local title = "[color="..color.."]"..selected.name.."[color]"
    self.summary:SetDungeon(title, index, completed)
end


function RecruitListDungeonMenu:chooseNextMenu(zone)
    local segments = RECRUIT_LIST.getValidSegments(zone)
    if #segments < 2 then
        local segment = segments[1]
        local max_fl = RECRUIT_LIST.getFloorsCleared(zone, segment.id)
        local color = self.static.color_complete
        local title = "[color="..color.."]"..segment.name.."[color]"
        if not segment.completed then
            color = self.static.color_incomplete
            title = "[color="..color.."]"..segment.name.." (Up to "..max_fl.."F)[color]"
        end
        _MENU:AddMenu(RecruitmentListMenu:new(title, zone, segment.id).menu, false)
    else
        local segment_menu = RecruitListSegmentMenu:new(zone, segments, self).menu
        if segment_menu.Bounds.Top < self.summary.window.Bounds.Bottom then
            local oldBounds = self.summary.window.Bounds
            local newBounds = RogueElements.Rect(oldBounds.X, self.menu.Bounds.Bottom - oldBounds.Height, oldBounds.Width, oldBounds.Height)
            self.summary.window.Bounds = newBounds
        end
        _MENU:AddMenu(segment_menu, true)
    end
end






RecruitListDungeonSummary = Class("RecruitListDungeonSummary")

function RecruitListDungeonSummary:initialize()
    self.origin = {X = 168, Y = 16}
    local GraphicsManager = RogueEssence.Content.GraphicsManager
    self.window = RogueEssence.Menu.SummaryMenu(RogueElements.Rect.FromPoints(
        RogueElements.Loc(self.origin.X, self.origin.Y), RogueElements.Loc(GraphicsManager.ScreenWidth - 8, 8 + GraphicsManager.MenuBG.TileHeight * 2 + 14 * 7)))

    self.dungeonName = RogueEssence.Menu.MenuText("", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight))
    local div = RogueEssence.Menu.MenuDivider(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight + 12), self.window.Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2)
    self.levelIndicator = RogueEssence.Menu.MenuText("", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + RogueEssence.Menu.TitledStripMenu.TITLE_OFFSET))
    self.floorIndicator = RogueEssence.Menu.MenuText("", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + RogueEssence.Menu.TitledStripMenu.TITLE_OFFSET + 14))

    self.window.Elements:Add(self.dungeonName)
    self.window.Elements:Add(div)
    self.window.Elements:Add(self.levelIndicator)
    self.window.Elements:Add(self.floorIndicator)
end


function RecruitListDungeonSummary:SetDungeon(title, index, isComplete)
    local zoneEntry = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Zone]:Get(index)
    if zoneEntry == nil then
        self.window.Visible = false;
    else
        self.dungeonName:SetText(title);

        while (self.window.Elements.Count > 4) do
            self.window.Elements:RemoveAt(4)
        end

        local rules = {}

        if zoneEntry.Level > -1 then
            if zoneEntry.LevelCap then
                self.levelIndicator:SetText(STRINGS:FormatKey("ZONE_RESTRICT_LEVEL", zoneEntry.Level))
            else
                self.levelIndicator:SetText(STRINGS:FormatKey("ZONE_EXPECT_LEVEL", zoneEntry.Level))
            end
        else
            self.levelIndicator:SetText("")
        end

        local count = "??"
        if isComplete and zoneEntry.CountedFloors > 0 then count = zoneEntry.CountedFloors end
        self.floorIndicator:SetText(STRINGS:FormatKey("MENU_DUNGEON_FLOORS", count))

        if zoneEntry.LevelCap and not zoneEntry.KeepSkills then
            table.insert(rules, RogueEssence.Menu.MenuText(STRINGS:FormatKey("ZONE_RESET_MOVESET"), RogueElements.Loc.Zero))
        end
        if zoneEntry.TeamSize > -1 then
            table.insert(rules, RogueEssence.Menu.MenuText(STRINGS:FormatKey("ZONE_RESTRICT_TEAM", zoneEntry.TeamSize), RogueElements.Loc.Zero, Color.White))
        end
        if zoneEntry.TeamRestrict then
            table.insert(rules, RogueEssence.Menu.MenuText(STRINGS:FormatKey("ZONE_RESTRICT_ALONE"), RogueElements.Loc.Zero, Color.White))
        end
        if zoneEntry.MoneyRestrict then
            table.insert(rules, RogueEssence.Menu.MenuText(STRINGS:FormatKey("ZONE_RESTRICT_MONEY"), RogueElements.Loc.Zero, Color.White))
        end
        if zoneEntry.BagRestrict > -1 then
            local text = STRINGS:FormatKey("ZONE_RESTRICT_ITEM_ALL")
            if zoneEntry.BagRestrict > 0 then text = STRINGS:FormatKey("ZONE_RESTRICT_ITEM", zoneEntry.BagRestrict) end
            table.insert(rules, RogueEssence.Menu.MenuText(text, RogueElements.Loc.Zero, Color.White))
        end

        if zoneEntry.BagSize > -1 then
            table.insert(rules, RogueEssence.Menu.MenuText(STRINGS:FormatKey("ZONE_RESTRICT_BAG", zoneEntry.BagSize), RogueElements.Loc.Zero, Color.White))
        end

        local GraphicsManager = RogueEssence.Content.GraphicsManager
        for i = 1, #rules, 1 do
            rules[i].Loc = RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + RogueEssence.Menu.TitledStripMenu.TITLE_OFFSET + 14 * (i+1))
            self.window.Elements:Add(rules[i]);
        end

        --structs are passed by copy so gotta do it like this
        local newHeight = GraphicsManager.MenuBG.TileHeight * 2 + RogueEssence.Menu.TitledStripMenu.TITLE_OFFSET + 14 * (#rules+2)
        local newBounds = RogueElements.Rect(self.origin.X, self.origin.Y, self.window.Bounds.Width, newHeight)
        self.window.Bounds = newBounds
    end
end

function RecruitListDungeonSummary:SetSegment(title, floors)
    self.dungeonName:SetText(title)
    self.floorIndicator:SetText(STRINGS:FormatKey("MENU_DUNGEON_FLOORS", floors))
end