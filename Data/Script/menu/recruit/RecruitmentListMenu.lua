require "menu.recruit.summary.RecruitSummaryMenu"
-- -----------------------------------------------
-- Recruitment List Menu
-- -----------------------------------------------
-- Menu that displays the recruitment list to the player
RecruitmentListMenu = Class('RecruitmentListMenu')
RecruitmentListMenu.static = {}
RecruitmentListMenu.static.listMode = 0
RecruitmentListMenu.static.scannerMode = 1
-- {pattern, spacing, color, show_always}
RecruitmentListMenu.static.patternList = {
    {        '\u{E10B}???', 10, '#989898', false},
    {                '???',  0, '#FFFFFF', false},
    {        '\u{E10B}{t}', 10, '#989898', false},
    {                '{t}',  0, '#FFFFFF', false},
    {        '\u{E111}{t}', 10, '#00FFFF', false},
    {        '{t}\u{E10C}',  0, '#FFFF00', false},
    {'\u{E111}{t}\u{E10C}', 10, '#FFFFA0', false},
    {        '{t}\u{E10D}',  0, '#FFA500', false},
    {'\u{E111}{t}\u{E10D}', 10, '#FFE0A0', false}
}
RecruitmentListMenu.static.colorError = '#FF0000'

function RecruitmentListMenu:initialize(title, zone, segment)
    assert(self, "RecruitmentListMenu:initialize(): self is nil!")
    self.static = RecruitmentListMenu.static

    self.fullDungeon = not (RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance)
    self.mode = self.static.listMode
    self.maxFloor = RECRUIT_LIST.getFloorsCleared(zone, segment)

    self.ENTRY_LINES = 10
    self.ENTRY_COLUMNS = 2
    self.ENTRY_LIMIT = self.ENTRY_LINES * self.ENTRY_COLUMNS

    self.list = self:loadEntries(zone, segment)
    self.page = 0
    self.selected = {1, 1}

    self.PAGE_MAX = math.max(0, (#self.list-1)//self.ENTRY_LIMIT)
    self.ENTRY_COUNT_LAST_PAGE = ((#self.list - 1) % self.ENTRY_LIMIT) + 1
    self.ENTRY_COLUMNS_LAST_PAGE = ((self.ENTRY_COUNT_LAST_PAGE - 1) // self.ENTRY_LINES) + 1
    self.ENTRY_ROWS_LAST_COLUMN = ((#self.list - 1) % self.ENTRY_LINES) + 1

    self.menu = RogueEssence.Menu.ScriptableMenu(32, 32, 256, 176, function(input) self:Update(input) end)
    self.dirPressed = false

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(title, RogueElements.Loc(20, 8)))
    self.page_num = RogueEssence.Menu.MenuText("", RogueElements.Loc(self.menu.Bounds.Width - 8, 8),RogueElements.DirH.Right)
    if self.PAGE_MAX>0 then
        self.menu.MenuElements:Add(self.page_num)
    end

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, 8 + 12), self.menu.Bounds.Width - 8 * 2))

    self.positions = {}
    self.slots = {}
    for i=1, self.ENTRY_LIMIT, 1 do
        -- positional parameters
        local ii = i-1
        local line = ii % self.ENTRY_LINES
        local col = ii // self.ENTRY_LINES
        local x_pad = 20
        local y_pad = 24
        local x_dist = ((self.menu.Bounds.Width - x_pad)//self.ENTRY_COLUMNS)
        local y_dist = 14

        local x = x_pad + x_dist * col
        local y = y_pad + y_dist * line
        local loc = RogueElements.Loc(x, y)
        self.positions[i] = loc
        self.slots[i] = RogueEssence.Menu.MenuText("", loc)
        self.menu.MenuElements:Add(self.slots[i])
    end

    self.cursor = RogueEssence.Menu.MenuCursor(self.menu)
    self.menu.MenuElements:Add(self.cursor)
    self:DrawMenu()
end

function RecruitmentListMenu:loadEntries(zone, segment)
    if self.fullDungeon then return RECRUIT_LIST.compileFullDungeonList(zone, segment)
    else return RECRUIT_LIST.compileFloorList()
    end
end

function RecruitmentListMenu:DrawMenu()
    -- add a special message if there are no entries
    if #self.list<1 then
        self.slots[1]:SetText("No recruits available")
        return
    end

    local page_num = "("..tostring(self.page+1).."/"..tostring(self.PAGE_MAX+1)..")"
    self.page_num:SetText(page_num)

    local start_pos = self.page * self.ENTRY_LIMIT
    for slot=1, self.ENTRY_LIMIT, 1 do
        local i = start_pos + slot

        local text = ""
        local x_adjust = 0
        if i <= #self.list then
            text, x_adjust = self:formatName(self.list[i].species, self.list[i].mode)
            if self.fullDungeon then
                local text_fl = tostring(self.list[i].min)
                if self.list[i].min ~= self.list[i].max then
                    text_fl = text_fl.."-"
                    if self.list[i].max > self.maxFloor then
                        text_fl = text_fl.."??"
                    else
                        text_fl = text_fl..tostring(self.list[i].max).."F"
                    end
                else
                    text_fl = text_fl.."F  "
                    if self.list[i].min > 9 then text_fl = text_fl.."  " end
                end
                text = text_fl.." "..text
            end
        end
        self.slots[slot]:SetText(text)
        self.slots[slot].Loc = RogueElements.Loc(self.positions[slot].X - x_adjust, self.positions[slot].Y)
    end

    local x = -100
    local y = -100
    if self.mode == self.static.scannerMode then
        local slot = ((self.selected[1] - 1) * 10) + self.selected[2]
        x = self.positions[slot].X - 10
        y = self.positions[slot].Y
    end
    self.cursor.Loc = RogueElements.Loc(x, y)
end

function RecruitmentListMenu:formatName(monster, mode)
    local use_icon = RECRUIT_LIST.iconMode()
    local name = _DATA:GetMonster(monster).Name:ToLocal()

    local pattern = self.static.patternList[4]
    local color = self.static.colorError
    local spacing = 0

    if mode > 0 then
        pattern = self.static.patternList[mode]
        color = pattern[3]
    end
    if pattern[4] or use_icon then
        name = string.gsub(pattern[1], "{t}", name)
        if not self.fullDungeon  then spacing = pattern[2] end
    end

    return '[color='..color..']'..name..'[color]', spacing
end

function RecruitmentListMenu:Update(input)
    local change = {0, 0}
    if input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
        self:confirmButton()
    elseif input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) or
            input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
        self:cancelButton()
    elseif self:directionHold(input, RogueElements.Dir8.Up)       then change[2] = change[2] - 1
    elseif self:directionHold(input, RogueElements.Dir8.Down)     then change[2] = change[2] + 1
    elseif self:directionPressed(input, RogueElements.Dir8.Left)  then change[1] = change[1] - 1
    elseif self:directionPressed(input, RogueElements.Dir8.Right) then change[1] = change[1] + 1
    elseif self:dirsNotPressed(input, RogueElements.Dir8.Left, RogueElements.Dir8.Right) then self.dirPressed = false end
    self:updateSelection(change[1], change[2])
end

function RecruitmentListMenu:confirmButton()
    if self.mode == self.static.listMode and RECRUIT_LIST.scannerMode() and #self.list>0 then
        _GAME:SE("Menu/Skip")
        self.mode = self.static.scannerMode
        self:DrawMenu()
    elseif self.mode == self.static.scannerMode then
        local states = RogueEssence.Data.GameProgress.UnlockState
        local index = self.page*self.ENTRY_LIMIT + (self.selected[1]-1)*self.ENTRY_LINES + self.selected[2]
        local element = self.list[index]
        local enabled = element.state == states.Completed or (RogueEssence.DiagManager.Instance.DevMode and element.state == states.Discovered)
        if enabled then
            _GAME:SE("Menu/Confirm")
            RecruitSummaryMenu.run(element)
        else
            _GAME:SE("Menu/Cancel")
        end
    else
        self.mode = self.static.listMode
        self:DrawMenu()
    end
end

function RecruitmentListMenu:cancelButton()
    _GAME:SE("Menu/Cancel")
    if self.mode == self.static.listMode then _MENU:RemoveMenu()
    else
        self.mode = self.static.listMode
        self.selected = {1, 1}
        self:DrawMenu()
    end
end

function RecruitmentListMenu:directionHold(input, direction)
    local INPUT_WAIT = 30
    local INPUT_GAP = 6

    local new_dir = false
    local old_dir = false
    if input.Direction == direction then new_dir = true end
    if input.PrevDirection == direction then old_dir = true end

    local repeat_time = false
    if input.InputTime >= INPUT_WAIT and input.InputTime % INPUT_GAP == 0 then
        repeat_time = true
    end
    return new_dir and (not old_dir or repeat_time)
end

function RecruitmentListMenu:directionPressed(input, direction)
    local pressed = input.Direction == direction and not self.dirPressed
    if pressed then self.dirPressed = true end
    return pressed
end

function RecruitmentListMenu:dirsNotPressed(input, ...)
    local arg = { select(1, ...) }
    for _, dir in ipairs(arg) do if input.Direction == dir then return false end end
    return true
end

function RecruitmentListMenu:updateSelection(x, y)
    local start_pos = {self.page, self.selected[1], self.selected[2], self.mode}
    local change
    if self.mode == self.static.listMode then
        change = self:changePage(x)
        if y~=0 then
            self.mode = self.static.scannerMode
        end
    else change = self:changeSelection(x, y) end

    if change then
        if self.page == start_pos[1] and self.selected[1] == start_pos[2] and self.selected[2] == start_pos[3] and self.mode == start_pos[4] then
            if self.mode == self.static.scannerMode then _GAME:SE("Menu/Cancel") end
        else
            _GAME:SE("Menu/Skip")
            self:DrawMenu()
        end
    end
end

function RecruitmentListMenu:changePage(x)
    if x == 0 then return false end
    self.page = (self.page+x) % (self.PAGE_MAX+1)
    return true
end

function RecruitmentListMenu:changeSelection(x, y)
    if x==0 and y==0 then return false end

    self.selected[1] = math.max(0,math.min(self.selected[1] + x, self.ENTRY_COLUMNS+1))
    self.selected[2] = ((self.selected[2] + y - 1) % self.ENTRY_LINES) + 1

    if self.selected[1] == 0 then
        local new_page = (self.page-1) % (self.PAGE_MAX+1)
        self.selected[1] = self:getPageMaxColumns(new_page)
        self.page = new_page
    elseif self.selected[1] > self:getPageMaxColumns(self.page) then
        local new_page = (self.page+1) % (self.PAGE_MAX+1)
        self.selected[1] = 1
        self.page = new_page
    end
    if self.page == self.PAGE_MAX and self.selected[1] == self.ENTRY_COLUMNS_LAST_PAGE and self.selected[2] > self.ENTRY_ROWS_LAST_COLUMN then
        if y == 0 then
            self.selected[2] = self.ENTRY_ROWS_LAST_COLUMN
        else
            self.selected[2] = 1
        end
    end
    return true
end

function RecruitmentListMenu:getPageMaxColumns(page)
    if page >= self.PAGE_MAX then return self.ENTRY_COLUMNS_LAST_PAGE end
    return self.ENTRY_COLUMNS
end