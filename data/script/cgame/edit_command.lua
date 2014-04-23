--- command mode ---------------------------------------------------------------

cs.edit.modes.command = {}

local command_end_callback, command_completion_func, command_completions
local command_completions_index, command_always_complete

local function command_update_completions_text()
    cs.gui_text.set_str(cs.edit.command_completions_text,
                        table.concat(command_completions, ' | '))
end
local function command_update_completions()
    local s = cs.gui_text.get_str(cs.edit.command_text)
    command_completions = command_completion_func(s)
    command_update_completions_text()
end

-- returns a completion function that uses substring search
-- case insensitive
function cs.edit.command_completion_substr(t)
    return function(s)
        local comps = {}
        s = string.lower(s)
        for k, _ in pairs(t) do
            if string.find(string.lower(k), s) then
                table.insert(comps, k)
            end
        end
        return comps
    end
end

local function run_string(s)
    local r, e = loadstring(s)
    if r then r() else error(e) end
end

function cs.edit.command_start(prompt, callback, completion_func,
                               always_complete, initial)
    cs.edit.set_mode('command')

    -- default is eval script
    prompt = prompt or 'lua: '
    command_end_callback = callback or run_string
    command_completion_func = completion_func or function () return {} end
    command_always_complete = always_complete and true or false

    initial = initial or ''
    cs.gui_text.set_str(cs.edit.command_text, initial or '')
    cs.gui_textedit.set_cursor(cs.edit.command_text, #initial)

    cs.gui_text.set_str(cs.edit.command_text_colon, prompt)
    command_update_completions()
end
function cs.edit.command_end()
    if command_always_complete then
        if #command_completions == 0 then return end -- no completions
        cs.edit.command_complete()
    end

    cs.edit.set_mode('normal')

    local s = cs.gui_text.get_str(cs.edit.command_text)
    if command_end_callback then command_end_callback(s)
    else print('no command callback for \'' .. s .. '\'') end
end
function cs.edit.command_cancel()
    cs.edit.set_mode('normal')
end

-- actually pick a completion
function cs.edit.command_complete()
    if #command_completions > 0 then
        local comp = command_completions[1]
        cs.gui_text.set_str(cs.edit.command_text, comp)
        cs.gui_textedit.set_cursor(cs.edit.command_text, #comp)
    end
end

function cs.edit.modes.command.enter()
    cs.edit.set_mode_text('command')

    cs.gui.set_visible(cs.edit.command_bar, true)

    cs.gui_text.set_str(cs.edit.command_completions_text, '')
end
function cs.edit.modes.command.exit()
    cs.gui.set_visible(cs.edit.command_bar, false)

    cs.gui.set_focus(cs.edit.command_text, false)
    command_completions = {}
end

function cs.edit.modes.command.update_all()
    -- done?
    if cs.gui.event_key_down(cs.edit.command_text) == cg.KC_ENTER then
        cs.edit.command_end()
        return
    elseif cs.gui.event_focus_exit(cs.edit.command_text) then
        cs.edit.command_cancel()
        return
    end

    if cs.gui.event_changed(cs.edit.command_text) then
        command_update_completions()
    end
    if cs.gui.event_key_down(cs.edit.command_text) == cg.KC_TAB then
        cs.edit.command_complete()
    end

    -- next/prev completion
    if cs.gui.event_key_down(cs.edit.command_text) == cg.KC_DOWN then
        table.insert(command_completions, table.remove(command_completions, 1))
        command_update_completions_text()
    elseif cs.gui.event_key_down(cs.edit.command_text) == cg.KC_UP then
        table.insert(command_completions, 1, table.remove(command_completions))
        command_update_completions_text()
    end

    cs.gui.set_focus(cs.edit.command_text, true)
end


--- built-in prompts -----------------------------------------------------------

-- asks for grid size -- first x then y
local function command_gridx(x)
    local function gridy(y)
        cs.edit.set_grid_size(cg.vec2(tonumber(x) or 0, tonumber(y) or 0))
    end
    cs.edit.command_start('grid y: ', gridy)
end
function cs.edit.command_grid()
    cs.edit.command_start('grid x: ', command_gridx)
end

-- inspects system on selected entities, or creates entity if none selected
function cs.edit.command_inspect()
    local add = cg.entity_table_empty(cs.edit.select)

    local function system(s)
        if add then
            local e = cg.entity_create()
            cs.edit_inspector.add(e, s)
            cs.edit.select[e] = true
        elseif not cg.entity_table_empty(cs.edit.select) then
            for ent, _ in pairs(cs.edit.select) do
                cs.edit_inspector.add(ent, s)
            end
        end
        cs.edit.undo_save()
    end

    -- complete to systems that have properties listed
    local syss = cs.edit_inspector.get_systems()
    local comp = cs.edit.command_completion_substr(syss)

    cs.edit.command_start(add and 'new entity: ' or 'edit system: ',
                          system, comp, true)
end

local last_save = cgame_usr_path
function cs.edit.command_save()
    local function save(s)
        print("saving group 'default' to file '" .. s .. "'")
        cs.group.set_save_filter('default', true)
        local s = cs.serializer.open_file(s)
        cs.system.save_all(s)
        cs.serializer.close(s)

        cs.edit.stop_save()

        last_save = s
    end

    cs.edit.command_start('save to file: ', save, nil, false, last_save)
end

local last_load = cgame_usr_path
function cs.edit.command_load()
    local function load(s)
        cs.group.destroy('default')

        print("loading from file '" .. s .. "'")
        local d = cs.deserializer.open_file(s)
        cs.system.load_all(d)
        cs.deserializer.close(d)

        cs.edit.stop_save()
        cs.timing.set_paused(true)
        cs.edit.stopped = true

        last_load = s
    end

    cs.edit.command_start('load from file: ', load, nil, false, last_load)
end
