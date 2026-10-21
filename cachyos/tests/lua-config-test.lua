-- Validate the personal Hyprland Lua layer without a running compositor.
--
-- Hyprland's Lua API is not available outside the compositor, so this test
-- installs a recording stub for `hl` and then loads the real modules from
-- cachyos/hypr/. It asserts the keybindings, the input layout and the
-- window rules, which is exactly what a typo in those files would break.
--
-- Usage: lua cachyos/tests/lua-config-test.lua [repo-root]
--
-- Exits non-zero on the first failed assertion.

local repo = (arg and arg[1]) or "."

local binds, unbinds, configs, rules = {}, {}, {}, {}

hl = {
  bind = function(key, ...)
    binds[#binds + 1] = { key = key, args = { ... } }
  end,
  unbind = function(key)
    unbinds[#unbinds + 1] = key
  end,
  config = function(cfg)
    configs[#configs + 1] = cfg
  end,
  window_rule = function(rule)
    rules[#rules + 1] = rule
  end,
  dsp = {
    focus = function(a)
      return { dispatcher = "focus", args = a }
    end,
    exec_cmd = function(a)
      return { dispatcher = "exec_cmd", args = a }
    end,
  },
}

local failures = 0
local function ok(cond, msg)
  if cond then
    print("PASS: " .. msg)
  else
    failures = failures + 1
    print("FAIL: " .. msg)
  end
end

local function load_module(rel)
  local path = repo .. "/" .. rel
  local chunk, err = loadfile(path)
  if not chunk then
    print("FAIL: cannot load " .. path .. ": " .. tostring(err))
    failures = failures + 1
    return
  end
  local okrun, runerr = pcall(chunk)
  if not okrun then
    print("FAIL: error while running " .. path .. ": " .. tostring(runerr))
    failures = failures + 1
  end
end

load_module("cachyos/hypr/input.lua")
load_module("cachyos/hypr/bindings.lua")

-- --- input layout: us, ir, de cycled with Alt+Shift
local input_cfg
for _, cfg in ipairs(configs) do
  if cfg.input then
    input_cfg = cfg.input
  end
end
ok(input_cfg ~= nil, "input configuration present")
if input_cfg then
  ok(input_cfg.kb_layout == "us,ir,de", "kb_layout is us,ir,de (got " .. tostring(input_cfg.kb_layout) .. ")")
  ok(
    type(input_cfg.kb_options) == "string" and input_cfg.kb_options:find("grp:alt_shift_toggle") ~= nil,
    "kb_options cycles the layout with alt_shift_toggle"
  )
end

-- --- workspace bindings: SUPER+code:10..19 focus workspaces 1..10
local by_key = {}
for _, b in ipairs(binds) do
  by_key[b.key] = b
end

local workspace_ok = true
for workspace = 1, 10 do
  local digit = workspace % 10
  local code = (digit == 0) and 19 or (9 + digit)
  local key = "SUPER + code:" .. code
  local b = by_key[key]
  local args = b and b.args[1]
  if not (b and args and args.dispatcher == "focus" and args.args.workspace == workspace) then
    workspace_ok = false
    print("   missing or wrong: " .. key .. " -> workspace " .. workspace)
  end
end
ok(workspace_ok, "SUPER+code:10..19 focus workspaces 1..10")

-- --- the old digit variants must be unbound, or they would shadow the
-- --- workspace shortcuts
local unbound = {}
for _, key in ipairs(unbinds) do
  unbound[key] = true
end
local shadow_ok = true
for digit = 1, 9 do
  if not unbound["SUPER + " .. digit] then
    shadow_ok = false
    print("   not unbound: SUPER + " .. digit)
  end
end
for workspace = 1, 10 do
  local digit = workspace % 10
  local code = (digit == 0) and 19 or (9 + digit)
  if not unbound["SUPER + code:" .. code] then
    shadow_ok = false
    print("   not unbound: SUPER + code:" .. code)
  end
end
ok(shadow_ok, "the stock monitor/workspace shortcuts are unbound")

-- --- theme toggle and Speedy launcher
local function is_exec(b, needle)
  if not b or not b.args[1] or b.args[1].dispatcher ~= "exec_cmd" then
    return false
  end
  local cmd = b.args[1].args
  return type(cmd) == "string" and cmd:find(needle, 1, true) ~= nil
end

ok(is_exec(by_key["SUPER + SHIFT + T"], "mydotfiles-theme-toggle"), "SUPER+SHIFT+T runs the theme toggle")
ok(is_exec(by_key["SUPER + SHIFT + I"], "mydotfiles-speedy"), "SUPER+SHIFT+I runs the Speedy helper")

-- --- Notes PWA window rules
local class_rule, title_rule
for _, rule in ipairs(rules) do
  if rule.match and rule.match.class == "^(NotesApp)$" then
    class_rule = rule
  end
  if rule.match and type(rule.match.title) == "string" and rule.match.title:find("amirahmadzadeh", 1, true) then
    title_rule = rule
  end
end
ok(class_rule ~= nil, "a window rule matches the NotesApp class")
ok(title_rule ~= nil, "a window rule matches the Notes URL in the title")
for _, rule in ipairs({ class_rule, title_rule }) do
  if rule then
    ok(rule.float == true, "the Notes rule floats the window")
    ok(rule.center == true, "the Notes rule centers the window")
    ok(type(rule.size) == "table" and rule.size[1] == "1200" and rule.size[2] == "800", "the Notes rule sizes the window 1200x800")
  end
end

if failures > 0 then
  print(string.format("Result: %d failed", failures))
  os.exit(1)
end
print("Result: all Hyprland Lua config checks passed")
