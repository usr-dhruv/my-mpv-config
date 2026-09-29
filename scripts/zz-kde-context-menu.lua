-- KDE-style dense context menu for mpv 0.41.x
--
-- mpv 0.41 introduced context_menu.lua. The menu renderer consumes the
-- read/write `menu-data` property; it does NOT read menu.conf as a menu
-- definition. This script owns menu-data and the global RMB binding.
--
-- UI/integration only: it deliberately does not alter video/audio quality.

local mp = require 'mp'
local msg = require 'mp.msg'

local function state(name)
    return { name }
end

local function checked(v)
    return v and state('checked') or nil
end

local function disabled(v)
    return v and state('disabled') or nil
end

local function item(title, cmd, item_state)
    local t = { title = title }
    if cmd then t.cmd = cmd end
    if item_state then t.state = item_state end
    return t
end

local function separator()
    return { type = 'separator' }
end

local function submenu(title, items, item_state)
    local t = { type = 'submenu', title = title, submenu = items }
    if item_state then t.state = item_state end
    return t
end

local function prop_bool(name, default)
    local v = mp.get_property_native(name)
    if v == nil then return default end
    return not not v
end

local function prop_num(name, default)
    local v = mp.get_property_number(name)
    return v == nil and default or v
end

local function current_track_counts()
    local counts = { audio = 0, video = 0, sub = 0 }
    local tracks = mp.get_property_native('track-list') or {}
    for _, t in ipairs(tracks) do
        if counts[t.type] ~= nil then
            counts[t.type] = counts[t.type] + 1
        end
    end
    return counts
end

local function build_menu()
    local counts = current_track_counts()
    local playlist_count = mp.get_property_number('playlist-count', 0) or 0
    local chapter_count = #(mp.get_property_native('chapter-list') or {})
    local edition_count = #(mp.get_property_native('edition-list') or {})

    local paused = prop_bool('pause', false)
    local muted = prop_bool('mute', false)
    local fullscreen = prop_bool('fullscreen', false)
    local ontop = prop_bool('ontop', false)
    local loop_file = mp.get_property('loop-file') == 'inf'
    local loop_playlist = mp.get_property('loop-playlist') == 'inf'
    local speed = prop_num('speed', 1)
    local volume = prop_num('volume', 100)
    local sub_visible = prop_bool('sub-visibility', true)
    local secondary_sub_visible = prop_bool('secondary-sub-visibility', false)
    local duration = mp.get_property_number('duration', 0) or 0

    local menu = {
        item(paused and 'Play' or 'Pause', 'cycle pause'),
        item('Stop and return to idle', 'stop'),
        separator(),

        submenu('Playback', {
            submenu('Speed', {
                item('25%', 'set speed 0.25', checked(math.abs(speed - 0.25) < 0.001)),
                item('50%', 'set speed 0.5', checked(math.abs(speed - 0.5) < 0.001)),
                item('75%', 'set speed 0.75', checked(math.abs(speed - 0.75) < 0.001)),
                item('100%', 'set speed 1', checked(math.abs(speed - 1) < 0.001)),
                item('125%', 'set speed 1.25', checked(math.abs(speed - 1.25) < 0.001)),
                item('150%', 'set speed 1.5', checked(math.abs(speed - 1.5) < 0.001)),
                item('175%', 'set speed 1.75', checked(math.abs(speed - 1.75) < 0.001)),
                item('200%', 'set speed 2', checked(math.abs(speed - 2) < 0.001)),
                item('400%', 'set speed 4', checked(math.abs(speed - 4) < 0.001)),
                separator(),
                item('Slower 10%', 'multiply speed 1/1.1'),
                item('Faster 10%', 'multiply speed 1.1'),
                item('Reset to 100%', 'set speed 1'),
            }),
            submenu('Seek', {
                item('−5 seconds', 'seek -5 exact'),
                item('+5 seconds', 'seek 5 exact'),
                item('−30 seconds', 'seek -30 exact'),
                item('+30 seconds', 'seek 30 exact'),
                item('−5 minutes', 'seek -300 exact'),
                item('+5 minutes', 'seek 300 exact'),
                item('−10 minutes', 'seek -600 exact'),
                item('+10 minutes', 'seek 600 exact'),
                item('Beginning', 'seek 0 absolute'),
                item('End', 'seek 100 absolute-percent'),
            }),
            submenu('Loop', {
                item(loop_file and 'Loop file: ON' or 'Loop file: OFF', 'cycle-values loop-file inf no', checked(loop_file)),
                item(loop_playlist and 'Loop playlist: ON' or 'Loop playlist: OFF', 'cycle-values loop-playlist inf no', checked(loop_playlist)),
                item('Set / clear A-B loop', 'ab-loop'),
            }),
            item('Next file', 'playlist-next', disabled(playlist_count < 2)),
            item('Previous file', 'playlist-prev', disabled(playlist_count < 2)),
            item('Next chapter', 'add chapter 1', disabled(chapter_count == 0)),
            item('Previous chapter', 'add chapter -1', disabled(chapter_count == 0)),
            item('Shuffle playlist', 'playlist-shuffle', disabled(playlist_count < 2)),
        }),

        submenu('Video', {
            submenu('Tracks', {
                item('Select video track…', 'script-binding select/select-vid', disabled(counts.video < 1)),
                item('Cycle video track', 'cycle video', disabled(counts.video < 2)),
            }),
            submenu('Aspect ratio', {
                item('Default', 'set video-aspect-override no'),
                item('16:9', 'set video-aspect-override 16:9'),
                item('4:3', 'set video-aspect-override 4:3'),
                item('2.35:1', 'set video-aspect-override 2.35:1'),
            }),
            submenu('Zoom', {
                item('Zoom in 10%', 'add video-zoom 0.1'),
                item('Zoom out 10%', 'add video-zoom -0.1'),
                item('Reset zoom', 'set video-zoom 0'),
            }),
            submenu('Pan', {
                item('Left', 'add video-pan-x -0.05'),
                item('Right', 'add video-pan-x 0.05'),
                item('Up', 'add video-pan-y -0.05'),
                item('Down', 'add video-pan-y 0.05'),
                item('Reset position', 'set video-pan-x 0; set video-pan-y 0; set video-align-x 0; set video-align-y 0'),
            }),
            submenu('Rotation', {
                item('Rotate −90°', 'add video-rotate -90'),
                item('Rotate +90°', 'add video-rotate 90'),
                item('Reset rotation', 'set video-rotate 0'),
            }),
            item('Crop / panscan +10%', 'add panscan 0.1'),
            item('Crop / panscan −10%', 'add panscan -0.1'),
            item('Toggle deinterlacing', 'cycle deinterlace'),
            item('Toggle debanding', 'cycle deband'),
            item('Screenshot', 'screenshot'),
            item('Screenshot without subtitles', 'screenshot video'),
        }),

        submenu('Audio', {
            item('Select audio track…', 'script-binding select/select-aid', disabled(counts.audio < 1)),
            item('Cycle audio track', 'cycle audio', disabled(counts.audio < 2)),
            item('Select audio device…', 'script-binding select/select-audio-device', disabled(counts.audio < 1)),
            separator(),
            item('Volume +5', 'add volume 5'),
            item('Volume −5', 'add volume -5'),
            item(string.format('Volume: %d%%', math.floor(volume + 0.5)), nil, state('disabled')),
            item(muted and 'Unmute' or 'Mute', 'cycle mute', checked(muted)),
            item('Audio delay +100 ms', 'add audio-delay 0.1'),
            item('Audio delay −100 ms', 'add audio-delay -0.1'),
            submenu('Channels', {
                item('Auto-safe', 'set audio-channels auto-safe'),
                item('Stereo', 'set audio-channels stereo'),
                item('Mono', 'set audio-channels mono'),
            }),
        }, disabled(counts.audio < 1)),

        submenu('Subtitles', {
            item('Select subtitle track…', 'script-binding select/select-sid', disabled(counts.sub < 1)),
            item(sub_visible and 'Hide subtitles' or 'Show subtitles', 'cycle sub-visibility', checked(sub_visible)),
            item('Cycle subtitle track', 'cycle sub', disabled(counts.sub < 2)),
            item('Select subtitle line…', 'script-binding select/select-subtitle-line', disabled(not sub_visible)),
            item('Subtitle delay +100 ms', 'add sub-delay 0.1'),
            item('Subtitle delay −100 ms', 'add sub-delay -0.1'),
            item('Subtitle size +10%', 'add sub-scale 0.1'),
            item('Subtitle size −10%', 'add sub-scale -0.1'),
            submenu('Secondary subtitle', {
                item('Select track…', 'script-binding select/select-secondary-sid', disabled(counts.sub < 2)),
                item(secondary_sub_visible and 'Hide secondary subtitle' or 'Show secondary subtitle', 'cycle secondary-sub-visibility', checked(secondary_sub_visible)),
                item('Cycle track', 'cycle secondary-sub', disabled(counts.sub < 2)),
                item('Delay +100 ms', 'add secondary-sub-delay 0.1'),
                item('Delay −100 ms', 'add secondary-sub-delay -0.1'),
            }, disabled(counts.sub < 2)),
        }, disabled(counts.sub < 1)),

        submenu('Playlist', {
            item('Playlist…', 'script-binding select/select-playlist', disabled(playlist_count < 1)),
            item('Previous file', 'playlist-prev', disabled(playlist_count < 2)),
            item('Next file', 'playlist-next', disabled(playlist_count < 2)),
            item('Shuffle playlist', 'playlist-shuffle', disabled(playlist_count < 2)),
            item('Clear playlist', 'playlist-clear', disabled(playlist_count < 2)),
        }),

        submenu('Chapters & Editions', {
            item('Select chapter…', 'script-binding select/select-chapter', disabled(chapter_count == 0)),
            item('Previous chapter', 'add chapter -1', disabled(chapter_count == 0)),
            item('Next chapter', 'add chapter 1', disabled(chapter_count == 0)),
            item('Select edition / title…', 'script-binding select/select-edition', disabled(edition_count < 2)),
        }),

        submenu('Window', {
            item(fullscreen and 'Exit fullscreen' or 'Enter fullscreen', 'cycle fullscreen', checked(fullscreen)),
            item(ontop and 'Unpin window' or 'Pin window', 'cycle ontop', checked(ontop)),
            submenu('Scale', {
                item('50%', 'set window-scale 0.5'),
                item('75%', 'set window-scale 0.75'),
                item('100%', 'set window-scale 1'),
                item('125%', 'set window-scale 1.25'),
                item('150%', 'set window-scale 1.5'),
                item('200%', 'set window-scale 2'),
            }),
            item('Maximize / restore', 'cycle window-maximized'),
        }),

        submenu('ModernZ', {
            item('Cycle interface visibility', 'script-binding modernz/visibility'),
            item('Show interface', 'script-message-to modernz osc-show'),
            item('Hide interface', 'script-message-to modernz osc-hide'),
            item('Toggle persistent progress line', 'script-binding modernz/progress-toggle'),
            item('Toggle idle screen', 'script-message-to modernz osc-idlescreen'),
            item('Show playback statistics', 'script-binding stats/display-page-1-toggle'),
            item('Show file information', 'script-binding stats/display-page-5-toggle'),
        }),

        submenu('Information & Tools', {
            item('Playback statistics', 'script-binding stats/display-page-1-toggle'),
            item('File information', 'script-binding stats/display-page-5-toggle'),
            item('Show key bindings', 'script-binding stats/display-page-4-toggle'),
            item('Select a binding…', 'script-binding select/select-binding'),
            item('Inspect a property…', 'script-binding select/show-properties'),
            item('Open mpv console', 'script-binding commands/open'),
            item('Edit mpv.conf', 'script-binding select/edit-config-file'),
            item('Edit input.conf', 'script-binding select/edit-input-conf'),
            item('Open mpv documentation', 'script-binding select/open-docs'),
        }),

        separator(),
        item('Quit and save position', 'quit-watch-later'),
        item('Quit', 'quit'),
    }

    -- Avoid an unused local warning while making the menu data useful for
    -- future extensions that want to display file duration.
    if duration < 0 then msg.debug('unreachable') end

    return menu
end

local function update_menu()
    local ok, menu = pcall(build_menu)
    if not ok then
        msg.error('Failed to build KDE context menu: ' .. tostring(menu))
        return
    end
    mp.set_property_native('menu-data', menu)
end

-- Context menu button must beat ModernZ's forced RMB handler, so this script
-- intentionally uses a forced binding as well. The built-in context menu then
-- installs its own temporary forced bindings while it is open.
mp.add_forced_key_binding('MBTN_RIGHT', 'kde-context-menu', function()
    mp.command('script-message-to context_menu open')
end, { repeatable = false })
mp.add_forced_key_binding('MENU', 'kde-context-menu-menu', function()
    mp.command('script-message-to context_menu open')
end, { repeatable = false })
mp.add_forced_key_binding('Shift+F10', 'kde-context-menu-f10', function()
    mp.command('script-message-to context_menu open')
end, { repeatable = false })

-- Keep the menu's checked/disabled state current without polling.
local observed = {
    'pause', 'mute', 'volume', 'speed', 'fullscreen', 'ontop',
    'loop-file', 'loop-playlist', 'playlist-count', 'track-list',
    'chapter-list', 'chapter', 'edition-list', 'sub-visibility',
    'secondary-sub-visibility', 'aid', 'sid', 'vid', 'filename',
}
for _, property in ipairs(observed) do
    mp.observe_property(property, 'native', update_menu)
end

mp.register_event('start-file', update_menu)
mp.register_event('file-loaded', update_menu)
mp.register_event('end-file', update_menu)
mp.register_event('shutdown', function()
    pcall(mp.set_property_native, 'menu-data', {})
end)

update_menu()
