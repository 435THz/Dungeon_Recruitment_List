-- -----------------------------------------------
-- Recruit Summary Learnset Window
-- -----------------------------------------------
-- Pages 3 and onwards of the Recruit Summary Menu. They display the Pokémon's levelup moves.

RecruitSummaryLearnsetWindow = Class('RecruitSummaryLearnsetWindow')

function RecruitSummaryLearnsetWindow:initialize(spawns, index, page, selected)
    self.page = page
    self.index = math.max(1, math.min(index or 1, #spawns))
    self.entries = spawns
    self.selected = selected or 1
    self.hovered = 0
    RecruitSummaryMenu.updateMenuData(self)

    self.menu = RogueEssence.Menu.ScriptableMenu(16, 16, 288, 32 + 14 * RecruitSummaryMenu.SLOTS_PER_PAGE, function(input) self:Update(input) end)
    local GraphicsManager = RogueEssence.Content.GraphicsManager
    local Bounds = self.menu.Bounds
    local VERT_SPACE = 14
    local LINE_HEIGHT = 12

    self.title = RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_TEAM_LEARNSET", "Pokémon"), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth + 8, GraphicsManager.MenuBG.TileHeight))
    self.menu.Elements:Add(self.title)
    self.menu.Elements:Add(RogueEssence.Menu.MenuText("("..self.page.."/"..self.totalPages..")", RogueElements.Loc(Bounds.Width - GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight), RogueElements.DirH.Right))
    self.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth, GraphicsManager.MenuBG.TileHeight + 12), Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2))

    self.cursor = RogueEssence.Menu.MenuCursor(self.menu)
    self.menu.Elements:Add(self.cursor)

    self.summaryMenu = RogueEssence.Menu.SkillSummary(RogueElements.Rect.FromPoints(RogueElements.Loc(16, GraphicsManager.ScreenHeight - 8 - GraphicsManager.MenuBG.TileHeight * 2 - LINE_HEIGHT * 2 - VERT_SPACE * 4), RogueElements.Loc(GraphicsManager.ScreenWidth - 16, GraphicsManager.ScreenHeight - 8)))
    self.menu.SummaryMenus:Add(self.summaryMenu)
    self:DrawMenu()
end

function RecruitSummaryLearnsetWindow:Choose(i)
    self:select(i)
end

function RecruitSummaryLearnsetWindow:select(i)
    _GAME:SE("Menu/Skip")
    self.selected = i
    self:DrawMenu()
end

function RecruitSummaryLearnsetWindow:DrawMenu()
    RecruitSummaryMenu.updateMenuData(self)

    local name = self.entryData.speciesName
    self.title:SetText(STRINGS:FormatKey("MENU_TEAM_LEARNSET", name))

    self:loadSkills()
    self.summaryMenu:SetSkill(self.skillIds[self.selected])
end

function RecruitSummaryLearnsetWindow:loadSkills()
    local GraphicsManager = RogueEssence.Content.GraphicsManager
    local TITLE_OFFSET = RogueEssence.Menu.TitledStripMenu.TITLE_OFFSET
    local Bounds = self.menu.Bounds
    local VERT_SPACE = 14
    while self.menu.Elements.Count>4 do
        self.menu.Elements:RemoveAt(4)
    end

    self.skillIds = {}
    self.choices = {}
    local skills = self.formEntry.LevelSkills
    local start = (self.page-3)*RecruitSummaryMenu.SLOTS_PER_PAGE
    local slot = 1
    local i = start
    while i < skills.Count and slot <= RecruitSummaryMenu.SLOTS_PER_PAGE do
        local skill = skills[i]
        local skillEntry = _DATA:GetSkill(skill.Skill)
        if skillEntry.Released then
            local skillText =   RogueEssence.Menu.MenuText(skillEntry:GetIconName(), RogueElements.Loc(1, 1), Color.White);
            local levelLabel =  RogueEssence.Menu.MenuText(STRINGS:FormatKey("MENU_TEAM_LEVEL_SHORT"), RogueElements.Loc(GraphicsManager.ScreenWidth - 88, 1), RogueElements.DirH.Right);
            local levelNumber = RogueEssence.Menu.MenuText(tostring(skill.Level), RogueElements.Loc(GraphicsManager.ScreenWidth - 88 + GraphicsManager.TextFont:SubstringWidth(tostring(_DATA.Start.MaxLevel)), 1), RogueElements.DirH.Right);
            local choice = RogueEssence.Menu.MenuElementChoice(function() self:choose(slot) end, true, levelLabel, levelNumber, skillText)
            choice.Bounds = RogueElements.Rect(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth + 16 - 5, GraphicsManager.MenuBG.TileHeight + TITLE_OFFSET + VERT_SPACE * (slot-1) - 1), RogueElements.Loc(Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2 - 16 + 5 - 4, VERT_SPACE - 2));
            table.insert(self.skillIds, skill.Skill)
            table.insert(self.choices, choice)
            self.menu.Elements:Add(choice)
            slot = slot+1
        end
        i = i+1
    end
    self.selected = math.min(self.selected, #self.skillIds)
    self.cursor.Loc = RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2 - 7, GraphicsManager.MenuBG.TileHeight + (self.selected-1) * VERT_SPACE + TITLE_OFFSET)
    self.cursor:ResetTimeOffset()
end

function RecruitSummaryLearnsetWindow:Update(input)
    self:UpdateMouse(input)

    local changed = false
    if RogueEssence.Menu.InteractableMenu.IsInputting(input, RogueElements.Dir8.Up) then
        if self.selected > 1 then
            self:select(self.selected-1)
            changed = true
        else
            self:select(RecruitSummaryMenu.SLOTS_PER_PAGE)
        end
    elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, RogueElements.Dir8.Down) then
        if self.selected < #self.skillIds then
            self:select(self.selected+1)
            changed = true
        else
            self:select(1)
        end
    end
    if not changed then
        RecruitSummaryMenu.Update(self, input, "Menu/Skip")
    end
end

function RecruitSummaryLearnsetWindow:UpdateMouse(input)
    --when moused down on a selection, change currentchoice to that choice
    --find the choice it's hovered over
    local newHover = self:FindHoveredMenuChoice(input)
    if self.hovered ~= newHover then
        if self.hovered > 0 and self.hovered <= #self.choices then
            self.choices[self.hovered]:OnHoverChanged(false)
        end
        if newHover > 0 then
            self.choices[newHover]:OnHoverChanged(true)
        end
        self.hovered = newHover
    end
    if input:JustPressed(RogueEssence.FrameInput.InputType.LeftMouse) then
        if newHover > 0 then
            self:select(newHover)
            self.clicking = true
        end
        for _, choice in ipairs(self.choices) do
            choice:OnMouseState(true)
        end
    elseif input:JustReleased(RogueEssence.FrameInput.InputType.LeftMouse) then
        self.clicking = false
        for _, choice in ipairs(self.choices) do
            choice:OnMouseState(false)
        end
    end
end


function RecruitSummaryLearnsetWindow:FindHoveredMenuChoice(input)
    local GraphicsManager = RogueEssence.Content.GraphicsManager
    local loc = RogueElements.Loc(input.MouseLoc.X // GraphicsManager.WindowZoom - self.menu.Bounds.Start.X,
                                  input.MouseLoc.Y // GraphicsManager.WindowZoom - self.menu.Bounds.Start.Y)
    for i = #self.choices, 1, -1 do
        if RogueElements.Collision.InBounds(self.choices[i].Bounds, loc) then return i end
    end
    return 0
end



