from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
LIBRARY = (ROOT / 'libraries/eleriumv2.luau').read_text()
RUNTIME = LIBRARY[:LIBRARY.index('local isSolara = false')]
SETUP = '''
table.clear = table.clear or function(t) for key in pairs(t) do t[key] = nil end end
local queue = {}
local task = {}
function task.spawn(thread, ...)
 local ok, message = coroutine.resume(thread, ...)
 assert(ok, message)
 return thread
end
function task.defer(thread) table.insert(queue, thread); return thread end
function task.delay(seconds, thread) table.insert(queue, thread); return thread end
function task.cancel(thread) assert(coroutine.close(thread)) end
function task.wait() coroutine.yield() end
local environment = setmetatable({task = task, _G = {}}, {__index = _G})
local create = assert(load([====[RUNTIME_SOURCE return runtime]====], 'runtime', 't', environment))
local function signal()
 local callbacks = {}
 return {
  Connect = function(_, callback)
   local connection = {Connected = true}
   function connection:Disconnect() self.Connected = false end
   callbacks[connection] = callback
   return connection
  end,
  Fire = function(_, ...)
   for connection, callback in pairs(callbacks) do
    if connection.Connected then callback(...) end
   end
  end
 }
end
'''.replace('RUNTIME_SOURCE', RUNTIME)


@unittest.skipUnless(shutil.which('lua'), 'Lua is required')
class LibraryLifecycle(unittest.TestCase):
    def run_lua(self, source):
        result = subprocess.run(['lua', '-'], input=SETUP + source, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_reexecution_cancels_old_tasks_and_event_callbacks(self):
        self.run_lua('''
local first = create()
local runs = 0
local worker = first:Spawn(function()
 while true do runs = runs + 1; task.wait() end
end)
local event = signal()
local handler = first:Connect(event, function(amount)
 runs = runs + amount
 task.wait()
 runs = runs + 1000
end)
event:Fire(3)
local deferred = first:Defer(function() runs = runs + 1000 end)
local delayed = first:Delay(60, function() runs = runs + 1000 end)
local second = create()
assert(not first.Alive and second.Alive)
assert(environment._G.SilenceRuntime == second)
assert(coroutine.status(worker) == 'dead')
assert(coroutine.status(deferred) == 'dead' and coroutine.status(delayed) == 'dead')
assert(not handler.Connected)
event:Fire(10)
assert(runs == 4)
assert(next(first.Threads) == nil and next(first.Connections) == nil)
assert(first:Spawn(function() error('old session restarted') end) == nil)
second:Destroy()
assert(environment._G.SilenceRuntime == nil)
''')

    def test_cleanup_order_idempotence_and_failures(self):
        self.run_lua('''
local runtime = create()
local order = {}
runtime:AddCleanup(function() table.insert(order, 1) end)
runtime:AddCleanup(function() error('cleanup failure') end)
runtime:AddCleanup(function()
 assert(not runtime.Alive)
 table.insert(order, 3)
 assert(runtime:Defer(function() error('cleanup restarted work') end) == nil)
end)
runtime:Destroy()
runtime:Destroy()
assert(#order == 2 and order[1] == 3 and order[2] == 1)
runtime:AddCleanup(function() table.insert(order, 4) end)
assert(#order == 3)
''')

    def test_completed_tasks_are_released_and_arguments_preserved(self):
        self.run_lua('''
local runtime = create()
local count = 0
local thread = runtime:Spawn(function(a, b, c)
 assert(a == 2 and b == nil and c == 4)
 count = count + 1
end, 2, nil, 4)
assert(coroutine.status(thread) == 'dead' and runtime.Threads[thread] == nil)
local deferred = runtime:Defer(function() count = count + 1 end)
task.spawn(table.remove(queue, 1))
assert(runtime.Threads[deferred] == nil and count == 2)
''')

    def test_switch_cleanup_and_stale_setters(self):
        start = LIBRARY.index('function tab_data:AddSwitch(')
        switch = LIBRARY[start:LIBRARY.index('function tab_data:AddTextBox(', start)]
        start = LIBRARY.index('function window_data:SetTitle(')
        setter = LIBRARY[start:LIBRARY.index('\n\tdo\n', start)]
        self.run_lua('''
local runtime = create()
local typeof = type
local function node()
 local title, image = {ZIndex = 0}, {ZIndex = 0}
 local item = {ZIndex = 0, MouseButton1Click = signal()}
 function item:FindFirstChild() return title end
 function item:GetChildren() return {image} end
 return item
end
local prefabs = {FindFirstChild = function() return {Clone = node} end}
local tab_data, new_tab, windows, options = {}, {}, 0, {}
local RS = {Heartbeat = {Wait = task.wait}}
local enabled, disabled, reps = 0, 0, 0
''' + switch + '''
local toggle = tab_data:AddSwitch('Farm', function(state)
 if state then
  enabled = enabled + 1
  runtime:Spawn(function() while true do reps = reps + 1; task.wait() end end)
 else disabled = disabled + 1 end
end)
toggle:Set(true)
assert(enabled == 1 and reps == 1)
runtime:Destroy()
assert(disabled == 1)
toggle:Set(true)
assert(enabled == 1)
local window_data = {}
local Window = {FindFirstChild = function() error('stale UI access') end}
''' + setter + '''
window_data:SetTitle('Old title timer')
''')

    def test_all_muscle_legends_work_is_scoped(self):
        for name in ('Scripts/MuscleLegends/Main.luau', 'Scripts/MuscleLegends/Farming.luau'):
            source = (ROOT / name).read_text()
            self.assertNotRegex(source, r'\btask\.(?:spawn|defer|delay)\(')
            self.assertNotRegex(source, r'(?<!runtime):Connect\(')
            self.assertIn('local runtime = library.Runtime', source)


if __name__ == '__main__':
    unittest.main()
