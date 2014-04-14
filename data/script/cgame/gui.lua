local root = cs.gui.get_root()
cs.group.set_groups(root, 'builtin')

local old_gui_text_get_str = cg.gui_text_get_str
function cg.gui_text_get_str(ent)
    return cg.string(old_gui_text_get_str(ent))
end

--- event ----------------------------------------------------------------------

cs.gui_event = {}

local event_handlers = cg.entity_table()
local event_defaults = {}

function cs.gui_event.add()
end

local function add_event(event, default)
    event_defaults[event] = default

    cs.gui_event['set_' .. event] = function (ent, f)
        if not event_handlers[ent] then
            event_handlers[ent] = {}
        end
        event_handlers[ent][event] = f
    end
end

add_event('focus_enter', false)
add_event('focus_exit', false)
add_event('mouse_down', cg.MC_NONE)
add_event('mouse_up', cg.MC_NONE)

function cs.gui_event.update_all()
    for ent, _ in pairs(event_handlers) do
        if cs.entity.destroyed(ent) then event_handlers[ent] = nil end
    end

    for ent, handlers in pairs(event_handlers) do
        for event, f in pairs(handlers) do
            local r = cs.gui['event_' .. event](ent)
            if r ~= event_defaults[event] then
                f(ent, r)
            end
        end
    end
end


--- window ---------------------------------------------------------------------

cs.gui_window = { auto_saveload = true }

cs.gui_window.tbl = cg.entity_table()

function cs.gui_window.add(ent)
    if cs.gui_window.tbl[ent] then return end
    cs.gui_window.tbl[ent] = {}
    local window = cs.gui_window.tbl[ent]

    window.minimized = false
    window.closeable = true
    window.highlight = false

    -- add ent to gui_rect as container
    cg.add {
        ent = ent,
        gui_rect = {},
        gui = { color = cg.color(0.3, 0.3, 0.5, 0.95) },
    }

    -- titlebar containing text, minimize button
    window.titlebar = cg.add {
        transform = { parent = ent },
        gui_rect = { hfill = true },
        gui = {
            padding = cg.vec2_zero,
            color = cg.color(0.15, 0.15, 0.35, 0.95),
            valign = cg.GA_TABLE,
            halign = cg.GA_MIN,
        },
    }
    window.close_text = cg.add {
        transform = { parent = window.titlebar },
        gui = {
            color = cg.color_white,
            valign = cg.GA_MAX,
            halign = cg.GA_TABLE,
        },
        gui_text = { str = 'x' },
    }
    window.minmax_text = cg.add {
        transform = { parent = window.titlebar },
        gui = {
            color = cg.color_white,
            valign = cg.GA_MAX,
            halign = cg.GA_TABLE,
        },
        gui_text = { str = '-' },
    }
    window.title_text_area = cg.add {
        transform = { parent = window.titlebar },
        gui_rect = { hfill = true },
        gui = {
            padding = cg.vec2_zero,
            color = cg.color(0.0, 0.0, 0.0, 0.0),
            valign = cg.GA_MAX,
            halign = cg.GA_TABLE,
        },
    }
    window.title_text = cg.add {
        transform = { parent = window.title_text_area },
        gui = {
            color = cg.color_white,
            valign = cg.GA_MAX,
            halign = cg.GA_MID,
        },
        gui_text = { str = 'new window' },
    }

    -- body containing contents
    window.body = cg.add {
        transform = { parent = ent },
        gui_rect = {},
        gui = {
            padding = cg.vec2_zero,
            color = cg.color(0.0, 0.0, 0.0, 0.0),
            valign = cg.GA_TABLE,
            halign = cg.GA_MIN
        },
    }
end

function cs.gui_window.remove(ent)
    local window = cs.gui_window.tbl[ent]
    if window then cs.transform.destroy_rec(ent) end
    cs.gui_window.tbl[ent] = nil
end

function cs.gui_window.set_minimized(ent, minimized)
    local window = cs.gui_window.tbl[ent]
    if window then window.minimized = minimized end
end
function cs.gui_window.get_minimized(ent)
    local window = cs.gui_window.tbl[ent]
    if window then return window.minimized end
end

function cs.gui_window.set_highlight(ent, highlight)
    local window = cs.gui_window.tbl[ent]
    if window then window.highlight = highlight end
end
function cs.gui_window.get_highlight(ent)
    local window = cs.gui_window.tbl[ent]
    if window then return window.highlight end
end

function cs.gui_window.set_closeable(ent, closeable)
    local window = cs.gui_window.tbl[ent]
    if window then window.closeable = closeable end
end
function cs.gui_window.get_closeable(ent)
    local window = cs.gui_window.tbl[ent]
    if window then return window.closeable end
end

function cs.gui_window.set_title(ent, str)
    local window = cs.gui_window.tbl[ent]
    if window then cs.gui_text.set_str(window.title_text, str) end
end
function cs.gui_window.get_title(ent)
    local window = cs.gui_window.tbl[ent]
    if window then return cs.gui_text.get_str(window.title_text) end
end

function cs.gui_window.get_body(ent)
    local window = cs.gui_window.tbl[ent]
    if window then return window.body end
end

-- window that is being dragged
local drag_window
local mouse_prev = nil, mouse_curr

function cs.gui_window.mouse_up(mouse)
    if mouse == cg.MC_LEFT then
        drag_window = nil
    end
end

function cs.gui_window.update_all()
    -- get mouse position
    mouse_curr = cs.input.get_mouse_pos_pixels()
    if not mouse_prev then mouse_prev = mouse_curr end

    -- close button clicked?
    for ent, window in pairs(cs.gui_window.tbl) do
        if cs.gui.event_mouse_down(window.close_text) == cg.MC_LEFT
        and window.closeable then
            cs.entity.destroy(ent)
        end
    end

    -- clear destroyed
    for ent, _ in pairs(cs.gui_window.tbl) do
        if cs.entity.destroyed(ent) then cs.gui_window.remove(ent) end
    end

    -- update all
    for ent, window in pairs(cs.gui_window.tbl) do
        -- new drag motion?
        if cs.gui.event_mouse_down(window.titlebar) == cg.MC_LEFT
        and cs.gui.get_halign(ent) == cg.GA_NONE
        and cs.gui.get_valign(ent) == cg.GA_NONE then
            drag_window = ent
        end

        -- highlight?
        if window.highlight then
            cs.gui.set_color(window.title_text, cg.color(1, 1, 0.2, 1))
        else
            cs.gui.set_color(window.title_text, cg.color_white)
        end

        -- closeable?
        cs.gui.set_visible(window.close_text, window.closeable)

        -- update maximize/minimize
        if cs.gui.event_mouse_down(window.minmax_text) == cg.MC_LEFT then
            window.minimized = not window.minimized
        end
        cs.gui.set_visible(window.body, not window.minimized)
        cs.gui_text.set_str(window.minmax_text, window.minimized and '+' or '-')
    end

    -- move dragged window
    if drag_window then
        cs.transform.translate(drag_window, mouse_curr - mouse_prev)
    end

    mouse_prev = mouse_curr
end


--- textfield ---------------------------------------------------------------

cs.textfield = { auto_saveload = true }

cs.textfield.tbl = cg.entity_table()

function cs.textfield.add(ent)
    if cs.textfield.tbl[ent] then return end
    cs.textfield.tbl[ent] = {}
    local textfield = cs.textfield.tbl[ent]

    -- add ent to gui_rect as container
    cg.add {
        ent = ent,
        gui_rect = {},
        gui = { color = cg.color(0.2, 0.2, 0.4, 1) },
    }

    -- add textedit field
    textfield.textedit = cg.add {
        transform = { parent = ent },
        gui = {
            color = cg.color_white,
            valign = cg.GA_MAX,
            halign = cg.GA_MIN
        },
        gui_textedit = {},
    }
end

function cs.textfield.remove(ent)
    local textfield = cs.textfield.tbl[ent]
    if textfield then cs.transform.destroy_rec(ent) end
    cs.textfield.tbl[ent] = nil
end

function cs.textfield.get_textedit(ent)
    local textfield = cs.textfield.tbl[ent]
    if textfield then return textfield.textedit end
end

function cs.textfield.update_all()
    for ent, _ in pairs(cs.textfield.tbl) do
        if cs.entity.destroyed(ent) then cs.textfield.remove(ent) end
    end

    for ent, textfield in pairs(cs.textfield.tbl) do
        if cs.gui.event_mouse_up(ent) == cg.MC_LEFT then
            cs.gui.set_focus(textfield.textedit, true)
        end
    end
end

