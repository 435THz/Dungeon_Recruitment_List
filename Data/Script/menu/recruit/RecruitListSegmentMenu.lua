require "menu.recruit.RecruitmentListMenu"

-- -----------------------------------------------
-- Recruitment List Dungeon Segment Menu
-- -----------------------------------------------
-- Menu for choosing what segment of a specific dungeon to visualize the recruit list of
-- only shown if the chosen dungeon has more than 1 valid explored segments

RecruitListSegmentMenu = Class('RecruitListSegmentMenu')
RecruitListSegmentMenu.static.color_complete = "#FFC663"
RecruitListSegmentMenu.static.color_incomplete = "#00FFFF"
RecruitListSegmentMenu.static.color_never_seen = "#FF0000"

function RecruitListSegmentMenu:initialize(zone, segments, parent)
    assert(self, "RecruitListSegmentMenu:initialize(): self is nil!")
    self.static = RecruitListSegmentMenu.static
    self.zone = zone
    self.parent = parent
    self.segments = self:loadSegments(segments)
    table.sort(self.segments, function (a, b) return a.id < b.id end)
    self.options = self:generateOptions()

    local top_slot = math.max(0, math.min(self.parent.menu.CurrentChoice, 9 - (#self.segments-1)))

    local x = 32+14*top_slot
    self.menu = RogueEssence.Menu.ScriptableSingleStripMenu(162, x, 128, self.options, 0, function() _GAME:SE("Menu/Cancel"); _MENU:RemoveMenu(); self.parent:updateSummary() end)
    self.menu.ChoiceChangedFunction = function() self:updateSummary() end
end

function RecruitListSegmentMenu:loadSegments(segments)
    local list = {}
    for _, segment in pairs(segments) do
        local enabled = segment.floorsCleared>0
        local color = self.static.color_incomplete
        if segment.completed then color = self.static.color_complete end
        if not enabled then color = self.static.color_never_seen end
        local text = "[color="..color.."]"..segment.name
        local title = text
        local max_fl = RECRUIT_LIST.getSegmentData(self.zone, segment.id).floorsCleared
        if not segment.completed then
            title = title.." (Up to "..max_fl.."F)"
        end
        title = title.."[color]"
        text = text.."[color]"
        local entry = {
            id = segment.id,
            title = title,
            option = text,
            enabled = enabled,
            length = floors
        }
        table.insert(list, entry)
    end
    return list
end

function RecruitListSegmentMenu:generateOptions()
    local list = {}
    for i=1, #self.segments, 1 do
        local entry = self.segments[i]
        table.insert(list, RogueEssence.Menu.MenuTextChoice(entry.option, function() self:choose(i) end, entry.enabled, Color.White))
    end
    return list
end

function RecruitListSegmentMenu:updateSummary()
    local selected = self.segments[self.menu.CurrentChoice+1]
    local segData = RECRUIT_LIST.getSegmentData(self.zone, selected.id)
    local completed = segData.completed
    local floors = "??"
    if completed then floors = tostring(segData.totalFloors) end
    self.parent.summary:SetSegment(selected.option, floors)
end

function RecruitListSegmentMenu:choose(i)
    local entry = self.segments[i]
    _MENU:AddMenu(RecruitmentListMenu:new(entry.title, self.zone, entry.id).menu, false)
end
