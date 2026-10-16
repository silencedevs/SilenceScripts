from pathlib import Path
import re
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
FARMING = (ROOT / 'Scripts/MuscleLegends/Farming.luau').read_text()
LIBRARY = (ROOT / 'libraries/eleriumv2.luau').read_text()


def section(source, start, end):
    return source[source.index(start):source.index(end, source.index(start))]


SENDER = section(FARMING, 'local function sendTrainingReps', 'local function updateRuntimeLabel')
PETS = section(FARMING, 'local function applyPetLoadout', 'local function sendTrainingReps')
REBIRTH = section(FARMING, 'tabs.rebirths.updateAdaptiveSpeed = function', 'tabs.rebirths.startWorker = function')
ANTI_AFK = section(LIBRARY, 'function library:EnableAntiAFK()', 'function library:CreatePrivacyRedactor')
BASE = '''
local now, sent = 0, 0
local os = {clock = function() return now end}
math.clamp = function(value, lower, upper) return math.max(lower, math.min(upper, value)) end
local services = {muscleEvent = {FireServer = function(_, action) assert(action == 'rep'); sent = sent + 1 end}}
'''


@unittest.skipUnless(shutil.which('lua'), 'Lua is required')
class FarmingRegression(unittest.TestCase):
    def run_lua(self, source):
        result = subprocess.run(['lua', '-'], input=source, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_syntax(self):
        for source in (FARMING, LIBRARY):
            normalized = re.sub(r'([\w.]+) \+= ([^\n]+)', r'\1 = \1 + \2', source)
            self.run_lua('assert(load([====[' + normalized + ']====]))')

    def test_rep_rates_and_bursts(self):
        self.run_lua(BASE + SENDER + '''
for _, rate in ipairs({1, 50, 656}) do
 for _, fps in ipairs({30, 60, 144}) do
  now, sent = 0, 0
  local state = {LastAt = 0, Tokens = 0}
  local burst = rate == 656 and 24 or 5
  for frame = 1, fps * 10 do
   now = frame / fps
   local count = sendTrainingReps(state, rate, burst, function() return true end)
   assert(count <= burst)
  end
  assert(sent <= rate * 10 and sent >= rate * 10 - 1)
 end
end
local state = {LastAt = now, Tokens = 0}
now = now + 10
local count = sendTrainingReps(state, 50, 5, function() return true end)
assert(count == 5)
assert(sendTrainingReps(state, 50, 5, function() return false end) == 0)
''')

    def test_pet_loadout_diff_and_cancellation(self):
        self.run_lua(BASE + PETS + '''
local a, b, c = {}, {}, {}
local values = {}
local function reference(pet)
 return {Value = pet, IsA = function(_, name) return name == 'ObjectValue' end}
end
local folder = {GetChildren = function() return values end}
lp = {player = {FindFirstChild = function() return folder end}}
local calls = {}
services.replicatedstorage = {rEvents = {equipPetEvent = {FireServer = function(_, action, pet)
 table.insert(calls, {action, pet})
end}}}
local active = true
task = {wait = function() end}
values = {reference(a), reference(b)}
applyPetLoadout({a, c}, function() return active end)
assert(#calls == 2)
assert(calls[1][1] == 'unequipPet' and calls[1][2] == b)
assert(calls[2][1] == 'equipPet' and calls[2][2] == c)
calls = {}
values = {reference(a), reference(c)}
applyPetLoadout({a, c})
assert(#calls == 0)
values = {reference(a), reference(b)}
task.wait = function() active = false end
applyPetLoadout({a, c}, function() return active end)
assert(#calls == 1 and calls[1][1] == 'unequipPet')
''')

    def rebirth_setup(self):
        return BASE + SENDER + '''
local humanoid = {Health = 100}
local lp = {player = {Character = {FindFirstChildOfClass = function() return humanoid end}}}
local active, invokes, petSwitchAt = true, 0, nil
local tabs = {rebirths = {
 adaptive = {TargetSeconds = 3, MaxRate = 50, SendRate = 50},
 rebirths = {Value = 0}, strength = {Value = 0}, Status = {},
 isCurrent = function() return active end,
 equipRebirthPets = function() petSwitchAt = now end
}}
local task = {wait = function(seconds) now = now + (seconds or 1 / 60) end}
services.runservice = {Heartbeat = {Wait = function() now = now + 1 / 60; assert(now < 20) end}}
services.replicatedstorage = {rEvents = {rebirthRemote = {InvokeServer = function()
 invokes = invokes + 1
 tabs.rebirths.rebirths.Value = tabs.rebirths.rebirths.Value + 1
end}}}
local formatNumber = tostring
''' + REBIRTH

    def test_rebirth_stops_training_at_target(self):
        self.run_lua(self.rebirth_setup() + '''
services.muscleEvent.FireServer = function()
 sent = sent + 1
 tabs.rebirths.strength.Value = tabs.rebirths.strength.Value + 1000
end
tabs.rebirths.performRebirth(1)
assert(sent == 5 and invokes == 1)
assert(petSwitchAt < 0.2)
assert(tabs.rebirths.adaptive.SendRate <= 50)
''')

    def test_rebirth_cancel_and_respawn(self):
        self.run_lua(self.rebirth_setup() + '''
humanoid.Health = 0
services.runservice.Heartbeat.Wait = function()
 now = now + 1 / 60
 if now < 1 then assert(sent == 0) else active = false end
end
tabs.rebirths.performRebirth(1)
assert(sent == 0 and invokes == 0 and petSwitchAt == nil)
''')

    def test_rebirth_batches_and_rate_ceiling(self):
        self.run_lua(self.rebirth_setup() + '''
local pending = 0
services.muscleEvent.FireServer = function() sent = sent + 1; pending = pending + 100 end
services.runservice.Heartbeat.Wait = function()
 local before = math.floor(now * 2)
 now = now + 1 / 60
 if math.floor(now * 2) ~= before then
  tabs.rebirths.strength.Value = tabs.rebirths.strength.Value + pending
  pending = 0
 end
 assert(now < 6)
 assert(sent <= math.floor(now * 50 + 0.0001))
 assert(tabs.rebirths.adaptive.SendRate <= 50)
end
tabs.rebirths.performRebirth(1)
assert(invokes == 1 and petSwitchAt <= 3.6)
''')

    def test_boss_pauses_waits_and_restores_training(self):
        pause = section(FARMING, 'tabs.boss.pauseTraining = function', 'tabs.boss.hasTrainingStats = function')
        prepare = section(FARMING, 'tabs.boss.prepareForBoss = function', 'tabs.boss.needsRetraining = function')
        resume = section(FARMING, 'tabs.boss.resumeTraining = function', 'tabs.boss.getBossHeadPosition = function')
        self.run_lua("""
local tabs = {boss = {Data = {TrainingResumeGeneration = 0}}, rebirths = {running = true}, strength = {running = true}}
tabs.boss.captureTraining = function()
 tabs.boss.Data.TrainingSnapshot = {Rebirth = tabs.rebirths.running, Strength = tabs.strength.running}
end
tabs.rebirths.Switch = {Set = function(_, state) tabs.rebirths.running = state end}
tabs.strength.FastRepToggle = {Set = function(_, state) tabs.strength.running = state end}
local lp = {player = {}}
local task = {wait = function() error('unexpected wait') end}
local runtime = {Spawn = function(_, fn, ...) fn(...) end}
""" + pause + prepare + resume + """
tabs.boss.pauseTraining()
assert(not tabs.rebirths.running and not tabs.strength.running)
local boss = {Data = {Preparation = {}}, StatusLabel = {}}
for _, worker in ipairs({tabs.rebirths, tabs.strength}) do
 worker.workerActive = true
 assert(tabs.boss.prepareForBoss(boss) == false)
 assert(boss.StatusLabel.Text == 'Status: Waiting for Farming to Pause')
 worker.workerActive = false
end
tabs.boss.restoreMachine = function() return true end
tabs.boss.resumeTraining()
assert(tabs.rebirths.running and tabs.strength.running)
assert(tabs.boss.Data.TrainingSnapshot == nil and tabs.boss.Data.TrainingRestore == nil)
""")

    def test_anti_afk_replaces_listener_and_falls_back(self):
        self.run_lua('''
local library, _G = {}, {}
local runtime = {Connect = function(_, signal, callback) return signal:Connect(callback) end, AddCleanup = function() end}
local connected, disconnected, callback, fallback = 0, 0, nil, 0
local failInput, keyDown, keyUp = false, 0, 0
local game = {GetService = function(_, name)
 if name == 'Players' then
  return {LocalPlayer = {Idled = {Connect = function(_, fn)
   connected = connected + 1; callback = fn
   return {Disconnect = function() disconnected = disconnected + 1 end}
  end}}}
 elseif name == 'VirtualInputManager' then
  return {SendKeyEvent = function(_, down)
   if failInput then error('unsupported') end
   if down then keyDown = keyDown + 1 else keyUp = keyUp + 1 end
  end}
 else
  assert(name == 'VirtualUser')
  return {CaptureController = function() end, ClickButton2 = function() fallback = fallback + 1 end}
 end
end}
local Enum = {KeyCode = {Y = 'Y'}}
local Vector2 = {new = function() return {} end}
local task = {wait = function() end}
''' + ANTI_AFK + '''
library:EnableAntiAFK()
library:EnableAntiAFK()
assert(connected == 2 and disconnected == 1)
callback()
assert(keyDown == 1 and keyUp == 1 and fallback == 0)
failInput = true
callback()
assert(fallback == 1)
''')

    def test_removed_tab_and_logging(self):
        self.assertNotIn('strength2', FARMING)
        self.assertNotIn('659', FARMING)
        self.assertNotIn('Data Ping', FARMING)
        for source in (FARMING, LIBRARY, (ROOT / 'Scripts/MuscleLegends/Main.luau').read_text()):
            self.assertNotRegex(source, r'(?m)^\s*--')
            self.assertNotRegex(source, r'\b(?:print|warn)\s*\(')


if __name__ == '__main__':
    unittest.main()
