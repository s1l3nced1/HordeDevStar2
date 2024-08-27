local utils = require "core.utils"
local enums = require "data.enums"
local tracker = require "core.tracker"
local open_chests_task = require "tasks.open_chests"

local function reset_chest_flags()
    open_chests_task:reset()
    tracker.finished_looting_start_time = nil
    console.print("Chest flags reset for new dungeon run")
end

local function use_dungeon_sigil()
    local local_player = get_local_player()
    local inventory = local_player:get_consumable_items()
    for _, item in pairs(inventory) do
        local item_info = utils.get_consumable_info(item)
        if item_info and item_info.name == "S05_DungeonSigil_BSK" then
            console.print("Found Dungeon Sigil. Attempting to use it.")
            local success, error = pcall(use_item, item)
            if success then
                console.print("Successfully used Dungeon Sigil.")
                tracker.horde_opened = true
                tracker.first_run = true
                tracker.force_horde_start = false  -- Reset the force start flag
                return true
            else
                console.print("Failed to use Dungeon Sigil: " .. tostring(error))
                return false
            end
        end
    end
    console.print("Dungeon Sigil not found in inventory.")
    return false
end

local start_dungeon_task = {
    name = "Start Dungeon",
    start_attempt_time = nil,

    shouldExecute = function()
        return utils.player_in_zone("Kehj_Caldeum") 
            and (not tracker.horde_opened or tracker.force_horde_start)
    end,

    Execute = function(self)
        local current_time = get_time_since_inject()
        
        if not self.start_attempt_time then
            self.start_attempt_time = current_time
            console.print("Preparing to start a new horde")
        end

        local elapsed_time = current_time - self.start_attempt_time
        if elapsed_time >= 5 then
            console.print("Attempting to use Dungeon Sigil")
            reset_chest_flags() -- Reset chest flags at the start of the dungeon
            if use_dungeon_sigil() then
                -- Additional resets if needed
                tracker.wave_start_time = 0
                self.start_attempt_time = nil
                -- Any other task-specific resets can be added here
            else
                console.print("Failed to start new horde. Will retry in 10 seconds.")
                self.start_attempt_time = current_time + 5  -- Set next attempt time
            end
        else
            console.print(string.format("Waiting before using Dungeon Sigil... %.2f seconds remaining.", 5 - elapsed_time))
        end
    end
}

return start_dungeon_task
