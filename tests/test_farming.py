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

    def test_pet_loadout_switches_both_phases_and_cancels(self):
        self.run_lua(BASE + PETS + """
local farmingPet, rebirthPet = {}, {}
local folder = {IsA = function(_, name) return name == 'Folder' end,
 GetChildren = function() return {farmingPet, rebirthPet} end}
lp = {player = {petsFolder = {GetChildren = function() return {folder} end}}}
local calls = {}
services.replicatedstorage = {rEvents = {equipPetEvent = {FireServer = function(_, action, pet)
 table.insert(calls, {action, pet})
end}}}
local active = true
task = {wait = function() end}
assert(applyPetLoadout({farmingPet}, function() return active end))
assert(#calls == 3)
assert(calls[1][1] == 'unequipPet' and calls[2][1] == 'unequipPet')
assert(calls[3][1] == 'equipPet' and calls[3][2] == farmingPet)
calls = {}
assert(applyPetLoadout({rebirthPet}, function() return active end))
assert(#calls == 3 and calls[3][1] == 'equipPet' and calls[3][2] == rebirthPet)
calls = {}
task.wait = function() active = false end
assert(not applyPetLoadout({farmingPet}, function() return active end))
assert(#calls == 2)
calls = {}
assert(not applyPetLoadout({rebirthPet}, function() return active end))
assert(#calls == 0)
""")

    def test_runtime_and_average_exclude_pauses(self):
        helpers = section(FARMING, 'local function getElapsed', 'local function getOwnedConfiguredPets')
        rebirth_average = section(FARMING, 'tabs.rebirths.updateAverage = function', 'tabs.rebirths.isCurrent = function')
        strength_average = section(FARMING, 'tabs.strength.updateAverage = function', 'tabs.strength.updateAdaptiveRate = function')
        self.run_lua(BASE + helpers + """
local tab = {running = false, timerStarted = false, totalElapsed = 0, startedAt = 0,
 Runtime = {}, statSamples = {Strength = 100}, statGains = {Strength = 0}}
setTimerRunning(tab, true)
tab.running = true
for second = 1, 5 do
 now = second
 updateRuntimeLabel(tab)
 assert(tab.Runtime.Text == 'Runtime: 0d 0h 0m ' .. second .. 's')
end
recordStatGain(tab, 'Strength', 150)
assert(tab.statGains.Strength == 50)
setTimerRunning(tab, false)
tab.running = false
now = 50
recordStatGain(tab, 'Strength', 200)
assert(tab.statGains.Strength == 50 and getElapsed(tab) == 5)
setTimerRunning(tab, true)
tab.running = true
now = 55
recordStatGain(tab, 'Strength', 250)
assert(getElapsed(tab) == 10 and tab.statGains.Strength == 100)
recordStatGain(tab, 'Strength', 0)
assert(tab.statGains.Strength == 100)
local tabs = {strength = tab, rebirths = {totalElapsed = 10, timerStarted = false,
 statGains = {Rebirths = 1}, AverageRate = {}}}
tab.statGains.Durability = 200
tab.StrengthAverage, tab.DurabilityAverage = {}, {}
local formatNumber = tostring
local formatRate = function(rate) return string.format('%.2f', rate) end
""" + rebirth_average + strength_average + """
tabs.rebirths.updateAverage()
tabs.strength.updateAverage()
assert(tab.StrengthAverage.Text == 'Str Ø: 10.00')
assert(tab.DurabilityAverage.Text == 'Dura Ø: 20.00')
assert(tabs.rebirths.AverageRate.Text == 'Average: 360.0 / Hour | 8640.0 / Day | 60480.0 / Week')
""")

    def rebirth_setup(self):
        return BASE + SENDER + '''
local humanoid = {Health = 100}
local lp = {player = {Character = {FindFirstChildOfClass = function() return humanoid end}}}
local active, invokes, petSwitchAt = true, 0, nil
local tabs = {rebirths = {
 adaptive = {TargetSeconds = 3, MaxRate = 50, SendRate = 50},
 nextRequestAt = 0, cooldown = 6, recordRebirth = function() end,
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

    def test_rebirth_waits_for_six_second_deadline(self):
        self.run_lua(self.rebirth_setup() + """
tabs.rebirths.strength.Value = 5000
tabs.rebirths.nextRequestAt = 6
local invokedAt
services.replicatedstorage.rEvents.rebirthRemote.InvokeServer = function()
 invokedAt = now
 tabs.rebirths.rebirths.Value = 16
end
tabs.rebirths.performRebirth(1)
assert(math.abs(invokedAt - 6) < 0.000001)
""")

    def test_rebirth_first_is_baseline_then_total_average(self):
        helpers = section(FARMING, 'local function getElapsed', 'local function getOwnedConfiguredPets')
        average = section(FARMING, 'tabs.rebirths.updateAverage = function', 'tabs.rebirths.isCurrent = function')
        record = section(FARMING, 'tabs.rebirths.recordRebirth = function', 'runtime:Connect(tabs.rebirths.rebirths:GetPropertyChangedSignal')
        self.run_lua(BASE + helpers + """
local tabs = {rebirths = {running = true, timerStarted = false, totalElapsed = 0,
 statSamples = {Rebirths = 0}, statGains = {Rebirths = 0}, rebirths = {Value = 0},
 cooldown = 6, measuredCycles = 0, AverageRate = {}, updateStats = function() end}}
local rate
local formatNumber = function(value) rate = rate or value; return tostring(value) end
""" + average + record + """
now = 5
tabs.rebirths.rebirths.Value = 16
tabs.rebirths.recordRebirth()
assert(tabs.rebirths.statGains.Rebirths == 0 and getElapsed(tabs.rebirths) == 0)
assert(tabs.rebirths.nextRequestAt == 11 and rate == nil)
now = 11
tabs.rebirths.rebirths.Value = 32
tabs.rebirths.recordRebirth()
assert(tabs.rebirths.statGains.Rebirths == 16 and getElapsed(tabs.rebirths) == 6)
assert(rate == nil)
now = 17
tabs.rebirths.rebirths.Value = 48
tabs.rebirths.recordRebirth()
assert(tabs.rebirths.statGains.Rebirths == 32 and getElapsed(tabs.rebirths) == 12)
assert(rate == 32 / 12 * 3600)
rate = nil
now = 23
tabs.rebirths.rebirths.Value = 64
tabs.rebirths.recordRebirth()
assert(tabs.rebirths.statGains.Rebirths == 48 and getElapsed(tabs.rebirths) == 18)
assert(rate == 48 / 18 * 3600)
""")

    def test_strength_only_measures_from_configured_top_speed(self):
        helpers = section(FARMING, 'local function getElapsed', 'local function getOwnedConfiguredPets')
        measurement = section(FARMING, 'tabs.strength.startMeasurement = function', 'tabs.strength.updateAdaptiveRate = function')
        self.run_lua(BASE + helpers + """
local tabs = {strength = {running = true, timerStarted = false, totalElapsed = 0,
 updateStats = function() end, sendRate = 200, maxSendRate = 700, strength = {Value = 100}, durability = {Value = 100},
 statSamples = {Strength = 100, Durability = 100}, statGains = {Strength = 0, Durability = 0}}}
""" + measurement + """
now = 4
tabs.strength.strength.Value = 500
recordStatGain(tabs.strength, 'Strength', 500)
tabs.strength.startMeasurement()
assert(not tabs.strength.timerStarted and tabs.strength.statGains.Strength == 0)
now = 8
tabs.strength.sendRate = 700
tabs.strength.startMeasurement()
assert(tabs.strength.timerStarted and getElapsed(tabs.strength) == 0)
assert(tabs.strength.nextAverageElapsed == 10)
now = 18
recordStatGain(tabs.strength, 'Strength', 800)
assert(tabs.strength.statGains.Strength == 300 and getElapsed(tabs.strength) == 10)
now = 28
recordStatGain(tabs.strength, 'Strength', 1000)
assert(tabs.strength.statGains.Strength == 500 and getElapsed(tabs.strength) == 20)
""")

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
