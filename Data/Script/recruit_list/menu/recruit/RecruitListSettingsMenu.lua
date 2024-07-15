-- -----------------------------------------------
-- Recruitment List Options Choice
-- -----------------------------------------------
-- Small menu that allows toggling the mod's options. Accessible only in Ground maps

RecruitListSettingsMenu = Class('RecruitListSettingsMenu')

RecruitListSettingsMenu.static = {}
RecruitListSettingsMenu.static.width = 119
RecruitListSettingsMenu.static.options = {"Icon Mode",  "Scanner Mode"}
RecruitListSettingsMenu.static.states = {"[color=#FFFF00]On[color]",  "Off", "[color=#FF0000]ERROR[color]"}
RecruitListSettingsMenu.static.value = function(i)
    if i==1 then if RECRUIT_LIST.iconMode() then return 1 else return 2 end end
    if i==2 then if RECRUIT_LIST.scannerMode() then return 1 else return 2 end end
    return #RecruitListSettingsMenu.static.states
end


function RecruitListSettingsMenu:initialize(parent, starting_choice)
    assert(self, "RecruitListSettingsMenu:initialize(): self is nil!")
    self.static = RecruitListSettingsMenu.static

    self.parent = parent
    local options = self:generateOptions()
    local xx = self.parent.Bounds.Left+70
    local yy = self.parent.Bounds.Top+14*(4-#options)

    if not starting_choice then starting_choice = #options-1 end
    self.menu = RogueEssence.Menu.ScriptableSingleStripMenu(xx, yy, self.static.width, options, starting_choice, function() _GAME:SE("Menu/Cancel"); _MENU:RemoveMenu() end)
end

function RecruitListSettingsMenu:generateOptions()
    local list = {}

    local options = self.static.options
    local states = self.static.states
    local func = self.static.value
    for i=1, #options, 1 do
        local option_name = RogueEssence.Menu.MenuText(options[i]..":", RogueElements.Loc(2, 1))
        local s = func(i)
        local option_state = RogueEssence.Menu.MenuText(states[s], RogueElements.Loc(self.static.width - 8 * 4 -15 , 1))
        local option = RogueEssence.Menu.MenuElementChoice(function() self:choose(i) end, true, option_name, option_state)
        table.insert(list, option)
    end
    return list
end

function RecruitListSettingsMenu:choose(i)
    if     i==1 then RECRUIT_LIST.toggleIconMode()
    elseif i==2 then RECRUIT_LIST.toggleScannerMode() end

    --reset contents
    _MENU:RemoveMenu()
    _MENU:AddMenu(RecruitListSettingsMenu:new(self.parent, self.menu.CurrentChoice).menu, true)
end
