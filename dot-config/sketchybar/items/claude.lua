local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- Claude Code attention badge.
--
-- A small icon on the right that reflects the aggregate state of every running
-- Claude Code instance. State is written per-session by the `claude_status.sh`
-- hook script into ~/.local/state/sketchybar-claude/ and aggregated here:
--   * any session "waiting"  -> red   (Claude needs your input/confirmation)
--   * else any session active -> grey  (at least one is still working)
--   * else any session "done" -> green (all sessions finished, your turn)
--   * else (no sessions)      -> hidden
-- Grey wins over green so green only appears once every agent is actually done.
--
-- The hook script fires a `claude_status` event whenever state changes; we also
-- aggregate once on load so the badge is correct after a sketchybar restart.

local STATE_DIR = os.getenv("HOME") .. "/.local/state/sketchybar-claude"

-- Claude logo glyph from the sketchybar-app-font (the ":claude:" ligature).
-- It is monochrome and tinted by the icon color, so the state colours still apply.
local ICON = app_icons["Claude"]

-- Subscription usage, shown next to the badge in the same pill: the 5-hour
-- session limit on top, the weekly limit below.
--
-- The figures come from the cache ccstatusline keeps for the Claude Code status
-- line (it asks Anthropic's usage endpoint at most every 5 minutes while a
-- session is open), so nothing here touches the API or the login token. The
-- catch: the numbers only move while Claude Code is running somewhere.
--
-- Newer ccstatusline versions keep one cache per Claude config dir
-- (usage-<hash>.json) and no longer write the plain usage.json, so take
-- whichever is newest.
local USAGE_GLOB = os.getenv("HOME") .. "/.cache/ccstatusline/usage*.json"
-- A limit whose reset time has passed counts as 0 until the cache says otherwise.
local USAGE_CMD = "f=$(/bin/ls -t "
  .. USAGE_GLOB
  .. " 2>/dev/null | /usr/bin/head -n 1); "
  .. "jq -c --argjson now \"$(/bin/date +%s)\" --argjson mtime \"$(/usr/bin/stat -f %m \"$f\")\" "
  .. "'def ts: sub(\"\\\\.[0-9]+\";\"\") | sub(\"\\\\+00:00$\";\"Z\") | fromdateiso8601; "
  .. "(.sessionResetAt|ts) as $s | (.weeklyResetAt|ts) as $w | "
  .. "{session: (if $s < $now then 0 else .sessionUsage end), "
  .. "weekly: (if $w < $now then 0 else .weeklyUsage end), "
  -- Reset times in local time, rounded to the minute; empty once they have passed.
  .. "session_reset: (if $s < $now then \"\" else ($s + 30 | strflocaltime(\"%H:%M\")) end), "
  .. "weekly_reset: (if $w < $now then \"\" else ($w + 30 | strflocaltime(\"%a %H:%M\")) end), "
  .. "age: ($now - $mtime)}' "
  .. "\"$f\""
  .. " 2>/dev/null"
local DIM = 0xff7f8490

-- Two stacked lines, the same trick the network speeds used: the upper item has
-- no width, so the lower one is drawn underneath it rather than beside it.
-- `tag` is the small grey prefix ("5h"); nil leaves it out.
local function usage_line(name, tag, width, y_offset, stacked)
  return sbar.add("item", name, {
    position = "right",
    drawing = false,
    updates = "on",
    padding_left = -5,
    width = stacked and 0 or nil,
    y_offset = y_offset,
    icon = {
      drawing = tag ~= nil,
      string = tag or "",
      color = colors.grey,
      padding_right = 0,
      font = { style = settings.font.style_map["Bold"], size = 9.0 },
    },
    label = {
      string = "",
      width = width,
      align = "right",
      color = colors.grey,
      font = { family = settings.font.numbers, style = settings.font.style_map["Bold"], size = 9.0 },
    },
    click_script = "open 'https://claude.ai/settings/usage'",
  })
end

-- Right-hand items are placed right to left: first the column with the reset
-- times, then the percentages, then (below) the badge.
local reset_session = usage_line("items.claude.session.reset", nil, 50, 4, true)
local reset_weekly = usage_line("items.claude.weekly.reset", nil, 50, -4, false)
local usage_session = usage_line("items.claude.session", "5h", 28, 4, true)
local usage_weekly = usage_line("items.claude.weekly", "7d", 28, -4, false)

local claude = sbar.add("item", "items.claude", {
  position = "right",
  drawing = false,
  -- Must keep processing events even while hidden, otherwise the badge could
  -- never receive `claude_status` to un-hide itself (default is "when_shown").
  updates = "on",
  icon = {
    string = ICON,
    color = colors.grey,
    font = "sketchybar-app-font:Regular:16.0",
    padding_right = 4,
  },
  label = {
    string = "",
    drawing = false,
    color = colors.white,
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 11.0,
    },
    padding_left = 0,
  },
})

sbar.add("bracket", "items.claude.bracket", {
  reset_session.name,
  reset_weekly.name,
  usage_session.name,
  usage_weekly.name,
  claude.name,
}, {
  background = { color = colors.bg1 },
})

-- Gap to whatever sits left of the pill (Spotify, the media item).
local pill_padding = sbar.add("item", "items.claude.padding", {
  position = "right",
  width = settings.group_paddings,
})

-- The pill shows while there is something to say: a running session or usage
-- figures. With neither it disappears entirely.
local has_sessions, has_usage = false, false
local function refresh_visibility()
  claude:set({ drawing = has_sessions or has_usage })
  pill_padding:set({ drawing = has_sessions or has_usage })
  for _, line in ipairs({ usage_session, usage_weekly, reset_session, reset_weekly }) do
    line:set({ drawing = has_usage })
  end
end

local function usage_color(percent, stale)
  if stale then return colors.grey end
  if percent >= 90 then return colors.red end
  if percent >= 75 then return colors.orange end
  if percent >= 50 then return colors.yellow end
  return colors.white
end

local function update_usage()
  sbar.exec(USAGE_CMD, function(usage)
    has_usage = type(usage) == "table" and tonumber(usage.session) ~= nil and tonumber(usage.weekly) ~= nil
    if has_usage then
      -- Older than a day: nothing has refreshed it, so show it greyed out.
      local stale = (tonumber(usage.age) or 0) > 86400
      local session, weekly = math.floor(usage.session + 0.5), math.floor(usage.weekly + 0.5)
      usage_session:set({ label = { string = session .. "%", color = usage_color(session, stale) } })
      usage_weekly:set({ label = { string = weekly .. "%", color = usage_color(weekly, stale) } })
      reset_session:set({ label = { string = tostring(usage.session_reset or "") } })
      reset_weekly:set({ label = { string = tostring(usage.weekly_reset or "") } })
    end
    refresh_visibility()
  end)
end

-- Read every per-session state file, tally the statuses, and update the badge.
-- Done asynchronously via sbar.exec (rather than a blocking io.popen) so the
-- bar's event loop is never stalled, even when claude_status events arrive fast.
local function render()
  sbar.exec("/bin/cat " .. STATE_DIR .. "/* 2>/dev/null", function(result)
    local text = type(result) == "string" and result or ""
    local waiting, done, working = 0, 0, 0
    for line in text:gmatch("[^\r\n]+") do
      if line == "waiting" then
        waiting = waiting + 1
      elseif line == "done" then
        done = done + 1
      elseif line == "working" then
        working = working + 1
      end
    end
    local total = waiting + done + working

    has_sessions = total > 0
    if not has_sessions then
      -- No session running: the icon stays as the pill's label, dimmed.
      claude:set({ icon = { color = DIM }, label = { drawing = false } })
      refresh_visibility()
      return
    end

    -- Priority: red (needs input) > grey (still working) > green (all done).
    -- Grey wins over green so green only shows once every agent has finished.
    local color, attention
    if waiting > 0 then
      color = colors.red
      attention = waiting
    elseif working > 0 then
      color = colors.grey
      attention = 0
    else
      color = colors.green
      attention = done
    end

    -- Only show a count when more than one instance wants attention, to keep the
    -- badge minimal in the common single-agent case.
    local label = (attention > 1) and tostring(attention) or ""

    claude:set({
      icon = { color = color },
      label = { string = label, drawing = label ~= "" },
    })
    refresh_visibility()
  end)
end

claude:subscribe("claude_status", function()
  render()
  update_usage()
end)

-- The cache only changes every few minutes; a slow poll is plenty.
usage_session:set({ update_freq = 60 })
usage_session:subscribe("routine", update_usage)

-- Clicking the badge acknowledges finished (green) sessions so it resets;
-- "waiting" (red) sessions are left alone because they still need real action.
claude:subscribe("mouse.clicked", function()
  sbar.exec(
    "for f in " .. STATE_DIR .. "/*; do "
      .. '[ -f "$f" ] && grep -qx done "$f" && rm -f "$f"; '
      .. "done 2>/dev/null; true"
  )
  render()
end)

-- Initial state on (re)load.
render()
update_usage()
