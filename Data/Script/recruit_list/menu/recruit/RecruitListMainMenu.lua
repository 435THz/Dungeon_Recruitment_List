require "recruit_list.menu.recruit.MultiPageTextMenu"
require "recruit_list.menu.recruit.RecruitListSettingsMenu"
require "recruit_list.menu.recruit.RecruitListDungeonMenu"
require "recruit_list.menu.recruit.RecruitmentListMenu"

-- -----------------------------------------------
-- Recruitment List Main Menu
-- -----------------------------------------------
-- Main menu for the Recruitment List mod.

RecruitListMainMenu = Class('RecruitListMainMenu')
RecruitListMainMenu.static = {}
RecruitListMainMenu.static.width = 70
RecruitListMainMenu.static.optionsOutOfDungeon = {"Dungeon", "Info", "Colors", "Options"}
RecruitListMainMenu.static.optionsInDungeon =    {"List", "Info", "Colors", "Options"}

function RecruitListMainMenu:initialize(x)
    assert(self, "RecruitListMainMenu:initialize(): self is nil!")
    self.static = RecruitListMainMenu.static

    self.optionsList = self:generate_options()
    self.menu = RogueEssence.Menu.ScriptableSingleStripMenu(x, 46, self.static.width, self.optionsList, 0, function() _GAME:SE("Menu/Cancel"); _MENU:RemoveMenu() end)
end

function RecruitListMainMenu:generate_options()
    local dungeonListEnabled = RECRUIT_LIST.hasVisitedValidDungeons()
    local inDungeon = RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance

    local list = {}
    local text = self.static.optionsInDungeon
    if not inDungeon then text = self.static.optionsOutOfDungeon end
    for i=1, 4, 1 do
        list[i] = {text[i], true, function() self:choose(i) end}
    end
    list[1][2] = not _DATA.Save.NoRecruiting and (inDungeon or dungeonListEnabled) -- only disable option 1 outside of dungeons
    return list
end

function RecruitListMainMenu:choose(index)
    if index == 1 then
        if RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then
            local map = RECRUIT_LIST.getCurrentMap()
            local zone = map.zone
            local segment = map.segment
            _MENU:AddMenu(RecruitmentListMenu:new("Recruitment List", zone, segment).menu, false)
        else
            _MENU:AddMenu(RecruitListDungeonMenu:new().menu, false)
        end
    elseif index == 4 then
        _MENU:AddMenu(RecruitListSettingsMenu:new(self.menu).menu, true)
    else
        _MENU:AddMenu(MultiPageTextMenu:new(index-1).menu, false)
    end
end