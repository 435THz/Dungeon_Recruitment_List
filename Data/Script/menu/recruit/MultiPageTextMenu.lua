-- -----------------------------------------------
-- Multi Page Text Menu
-- -----------------------------------------------
-- Shows text and divides it in multiple pages
MultiPageTextMenu = Class('MultiPageTextMenu')
MultiPageTextMenu.static = {{}, {}}

-- Info menu content
MultiPageTextMenu.static[1].title = "Recruitment List Info"
MultiPageTextMenu.static[1].content = {
    -- page 1
    "The [color=#00FFFF]Recruitment List[color], as the name suggests, " ..
            "shows the list of Pokémon that can be "..
            "recruited in a dungeon. If a Pokémon has not " ..
            "been registered yet, it will be listed as a \"???\".\n" ..
            "\n" ..
            "The [color=#00FFFF]Recruitment List[color] works differently " ..
            "depending on where you are: If you're inside a " ..
            "[color=#FFC060]Dungeon[color], it will show you the list of recruitable " ..
            "Pokémon on the current floor. If not, it will " ..
            "show the list of all Pokémon in a [color=#FFC060]Dungeon[color] of " ..
            "your choice instead.",
    -- page 2
    "When inside a [color=#FFC060]Dungeon[color], the current floor will " ..
            "be scanned, and the List will not only contain all " ..
            "species that can spawn naturally inside of it, " ..
            "but also all Pokémon that are currently on the " ..
            "floor but are not supposed to appear normally.",--[[.." If a" ..]] --TODO we just keep this for the future
    --        "Pokémon is marked with an \"*\", that means it can" ..
    --        "spawn on the floor but it is not guaranteed to," ..
    --        "and it will not respawn upon defeat."
    -- page 3
    "Be careful: if on the current floor there's a " ..
            "Pokémon you never met before and that " ..
            "Pokémon is not part of the floor's natural " ..
            "spawn list, it will not appear in the [color=#00FFFF]Recruitment " ..
            "List[color] regardless of whether or not it can be " ..
            "recruited.",
    -- page 4
    "When not in a [color=#FFC060]Dungeon[color], you have the option to " ..
            "choose any [color=#FFC060]Dungeon[color] you have ever visited. " ..
            "Doing so will open a detailed list of all Pokémon " ..
            "available in the portion of that [color=#FFC060]Dungeon[color] that you " ..
            "have already explored, complete with the floor " ..
            "ranges at which they can appear.\n" ..
            "You will only see the natural spawn list of the " ..
            "[color=#FFC060]Dungeon[color] in question, as explained in the Color " ..
            "list.\n" ..
            "[color=#FF0000]WARNING[color]: The bigger dungeons can take a few " ..
            "seconds to load.",
    -- page 5
    "This mod comes with an [color=#FFFF00]Scanner Mode[color] that " ..
            "allows you to view any spawn entry's [color=#00FFFF]Summary[color], " ..
            "provided you already befriended the species in " ..
            "question at least once.\n" ..
            "\n" ..
            "There is also an accessibility option, active by " ..
            "default, that uses icons on top of coloring the " ..
            "various entries of the list.\n" ..
            "\n" ..
            "You can toggle these modes from the Options " ..
            "menu at any time.",
    -- page 6
    "The title of [color=#FFA0FF]Guildmaster[color] grants you the ability " ..
            "to see which of the [color=#FFC060]Dungeons[color] you found still " ..
            "contain unexplored sections. These entries will "..
            "be marked in [color=#FF0000]red[color] and you will not be able to " ..
            "open their [color=#00FFFF]Recruitment List[color] until you enter "..
            "them.",
    -- page 7
    {
        -- icon mode
        "[color=#FFA0FF]DEV MODE ONLY[color]:\n" ..
                "Being in [color=#FFA0FF]Dev Mode[color] grants you the ability to see " ..
                "even Pokémon that are in a [color=#FFC060]Dungeon[color]'s spawn " ..
                "list but cannot be recruited. These Pokémon " ..
                "will appear \u{E10B}[color=#989898]greyed out[color] in the [color=#00FFFF]Recruitment List[color].\n" ..
                "You will also be able to read any spawn entry's "..
                "[color=#00FFFF]Summary[color] as long you met that species at least " ..
                "once.",
        -- no icon mode
        "[color=#FFA0FF]DEV MODE ONLY[color]:\n" ..
                "Being in [color=#FFA0FF]Dev Mode[color] grants you the ability to see " ..
                "even Pokémon that are in a [color=#FFC060]Dungeon[color]'s spawn " ..
                "list but cannot be recruited. These Pokémon " ..
                "will appear [color=#989898]greyed out[color] in the [color=#00FFFF]Recruitment List[color].\n" ..
                "You will also be able to read any spawn entry's " ..
                "[color=#00FFFF]Summary[color] as long you met that species at least " ..
                "once."
    }
}
MultiPageTextMenu.static[1].content_filter = function(page)
    if page == 6 then return RECRUIT_LIST.gameCompleted() end
    if page == 7 then return RECRUIT_LIST.showUnrecruitable() end
    return true
end

-- Colors menu content
MultiPageTextMenu.static[2].title = "Recruitment List Colors"
MultiPageTextMenu.static[2].content = {
    -- page 1
    {
        -- icon mode
        "Colors used for Pokémon that keep appearing " ..
                "as long as you stay in this Dungeon:\n" ..
                "\n" ..
                "???(White): You have never met this Pokémon.\n" ..
                "White: You have never recruited this Pokémon.\n" ..
                "[color=#FFFF00]Yellow[color]\u{E10C}: You have recruited this Pokémon.\n" ..
                "[color=#FFA500]Orange[color]\u{E10D}: You have recruited this Pokémon, but " ..
                "it has multiple forms and the Recruitment List " ..
                "cannot tell which ones nor how many you have.",
        -- no icon mode
        "Colors used for Pokémon that keep appearing\n" ..
                "as long as you stay in this Dungeon:\n" ..
                "\n" ..
                "???(White): You have never met this Pokémon.\n" ..
                "White: You have never recruited this Pokémon.\n" ..
                "[color=#FFFF00]Yellow[color]: You have recruited this Pokémon.\n" ..
                "[color=#FFA500]Orange[color]: You have recruited this Pokémon, but it " ..
                "has multiple forms and the Recruitment List " ..
                "cannot tell which ones nor how many you have."
    },
    -- page 2
    {
        -- icon mode
        "Colors used for Pokémon that appeared in " ..
                "special circumstances (only shown in floor):\n" ..
                "\n" ..
                "\u{E111}[color=#00FFFF]Cyan[color]: You have never recruited this Pokémon.\n" ..
                "\u{E111}[color=#FFFFA0]Faded Yellow[color]\u{E10C}: You have recruited this " ..
                "Pokémon.\n" ..
                "\u{E111}[color=#FFE0A0]Faded Orange[color]\u{E10D}: You have recruited this " ..
                "Pokémon, but it has multiple forms and the " ..
                "Recruitment List cannot tell which ones nor how " ..
                "many you have.",

        -- no icon mode
        "Colors used for Pokémon that appeared in " ..
                "special circumstances (only shown in floor):\n" ..
                "\n" ..
                "[color=#00FFFF]Cyan[color]: You have never recruited this Pokémon.\n" ..
                "[color=#FFFFA0]Faded Yellow[color]: You have recruited this Pokémon.\n" ..
                "[color=#FFE0A0]Faded Orange[color]: You have recruited this Pokémon, " ..
                "but it has multiple forms and the Recruitment " ..
                "List cannot tell which ones nor how many you " ..
                "have."
    }
}
MultiPageTextMenu.static[2].content_filter = function(_) return true end

function MultiPageTextMenu:initialize(content_index)
    assert(self, "MultiPageTextMenu:initialize(): self is nil!")
    self.static = MultiPageTextMenu.static

    self.menu = RogueEssence.Menu.ScriptableMenu(32, 32, 256, 176, function(input) self:Update(input) end)
    self.dirPressed = false
    self.page = 1

    self.title = self.static[content_index].title
    self.pages = self:generatePages(content_index)
    self.PAGE_MAX = #self.pages

    local GraphicsManager = RogueEssence.Content.GraphicsManager
    self.page_num = RogueEssence.Menu.MenuText("", RogueElements.Loc(self.menu.Bounds.Width - 8, 8),RogueElements.DirH.Right)
    self.page_text = RogueEssence.Menu.DialogueText("", RogueElements.Rect(RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + 14 + 4),
        RogueElements.Loc(self.menu.Bounds.Width - GraphicsManager.MenuBG.TileWidth * 4, self.menu.Bounds.Height - GraphicsManager.MenuBG.TileHeight * 4)), 12)
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(self.title, RogueElements.Loc(16, 8)))
    self.menu.MenuElements:Add(self.page_num)
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, 8 + 12), self.menu.Bounds.Width - 8 * 2))
    self.menu.MenuElements:Add(self.page_text)

    self:UpdateMenu()
end

function MultiPageTextMenu:generatePages(index)
    local content = self.static[index].content
    local mode_index = 1
    if not RECRUIT_LIST.iconMode() then mode_index = 2 end

    local list = {}
    for page =1, #content, 1 do
        if(self.static[index].content_filter(page)) then --check if we should include this page
            if type(content[page]) == "table" then          --check if the page has modes
                table.insert(list, content[page][mode_index])  -- pick the right mode if so
            else
                table.insert(list, content[page])
            end
        end
    end
    return list
end

function MultiPageTextMenu:UpdateMenu()
    --Update page number if it has more than one
    if self.PAGE_MAX > 1 then
        local page_num = "("..tostring(self.page).."/"..tostring(self.PAGE_MAX)..")"
        self.page_num:SetText(page_num)
    end

    self.page_text:SetAndFormatText(self.pages[self.page])
end

function MultiPageTextMenu:Update(input)
    if input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
    elseif input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
    elseif input.Direction == RogueElements.Dir8.Right then
        if not self.dirPressed then
            if self.PAGE_MAX == 1 then
                _GAME:SE("Menu/Cancel")
                self.page = 1
            else
                local p_index = self.page-1
                self.page = ((p_index+1) % (self.PAGE_MAX))+1
                _GAME:SE("Menu/Skip")
                self:UpdateMenu()
                self.dirPressed = true
            end
        end
    elseif input.Direction == RogueElements.Dir8.Left then
        if not self.dirPressed then
            if self.PAGE_MAX == 1 then
                _GAME:SE("Menu/Cancel")
                self.page = 1
            else
                local p_index = self.page-1
                self.page = ((p_index-1) % (self.PAGE_MAX))+1
                _GAME:SE("Menu/Skip")
                self:UpdateMenu()
                self.dirPressed = true
            end
        end
    elseif input.Direction == RogueElements.Dir8.None then
        self.dirPressed = false
    end
end