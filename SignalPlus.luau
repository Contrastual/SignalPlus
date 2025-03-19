--!optimize 2
--!native

--[[

           +++                                                                                      
       ++++++++   ===                                                                               
    ++++++++++   ====                                                  ====                         
     ++++++                                                            ====                         
       +++++     ====     ====== ====+  ==== ======+      ========     ====        ====             
        +++++    ====    ============+  =============    ===========   ====        ====             
         ++++    ====   ====     ====+  =====    ====           ====   ====        ====             
         ++++    ====   ====     ====+  =====    ====     ==========   ====    =============        
         ++++    ====   ====     ====+  =====    ====   ======  ====   ====    ++++====++++=        
       ++++++    ====   =====   =====+  =====    ====  ====     ====   ====        ====    +++++++++
   ++++++++++    ====    ============+  =====    ====   ============   ====   ++++ ==== ++++++++++++
  +++++++        ====            ====+  ====     ====   + ====  ====   ==== ++++++++  +++++++*      
 +++++                  ====+    ==== +++++++++++++++++++++++++++++++++++++++++++++++++++++         
 ++++        +++++++++++ =========== +++++++++++++++++++++++++++++++++++++++      ++++++            
++++++++*++++++++++++++++++                                                         +               
 +++++++++++++++++++++++++                                                                          
      *++++                                                                                         

A super fast, memory efficient, open-source script signal module
for Roblox, with all features of RBXScriptSignals and even more.


GitHub:
https://github.com/AlexanderLindholt/SignalPlus

Devforum:
https://devforum.roblox.com/t/signal%EF%BD%9Csuper-fast-featureful-script-signal/3552231


--------------------------------------------------------------------------------
MIT License

Copyright (c) 2025 AlexanderLindholt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--------------------------------------------------------------------------------

]]--

-- Types.
export type Connection = {
	Disconnect: (connection: Connection) -> (),
	Connected: boolean
}
export type Signal = {
	Connect: (signal: Signal, callback: () -> ()) -> Connection,
	Once: (signal: Signal, callback: () -> ()) -> Connection,
	Wait: (signal: Signal) -> (),
	
	Fire: (signal: Signal, ...any) -> (),
	
	DisconnectAll: (signal: Signal) -> (),
	Destroy: (signal: Signal) -> ()
}
type CreateSignal = () -> Signal

-- Cache frequently used functions.
local running = coroutine.running
local resume = coroutine.resume
local yield = coroutine.yield

-- Thread recycling.
local freeThread = nil
local function runCallbackInFreeThread(callback, ...)
	local thread = freeThread
	freeThread = nil
	callback(...)
	freeThread = thread
end
local function createFreeThread()
	while true do
		runCallbackInFreeThread(yield())
	end
end
freeThread = coroutine.create(createFreeThread)
resume(freeThread)

-- Connection class.
local connectionClass = table.freeze({__index = table.freeze({
	Disconnect = function(connection)
		-- Remove from linked list.
		local previous = connection[2]
		local next = connection[3]
		if previous then
			previous[3] = next
		else
			connection[1][1] = next
		end
		if next then
			next[2] = previous
		end
		-- Set connected boolean.
		connection.Connected = false
		-- Clear values.
		connection[1] = nil
		connection[2] = nil
		connection[3] = nil
		connection[4] = nil
		-- Unlink class methods.
		setmetatable(connection, nil)
	end
})})

-- Signal class.
local signalClass = table.freeze({__index = table.freeze({
	Connect = function(signal, callback)
		-- Setup connection.
		local connection = nil
		connection = setmetatable({
			[1] = signal,
			[2] = nil, -- Previous.
			[3] = signal[1], -- Next.
			
			Connected = true,
			[4] = callback
		}, connectionClass)
		signal[1] = connection
		
		-- Return connection.
		return connection
	end,
	Once = function(signal, callback)
		-- Setup connection.
		local connection = nil
		connection = setmetatable({
			[1] = signal,
			[2] = nil, -- Previous.
			[3] = signal[1], -- Next.
			
			Connected = true,
			[4] = function() -- Callback.
				-- Disconnect.
				local previous = connection[2]
				local next = connection[3]
				if previous then
					previous[3] = next
				else
					signal[1] = next
				end
				if next then
					next[2] = previous
				end
				connection.Connected = false
				
				-- Fire callback.
				callback()
			end
		}, connectionClass)
		signal[1] = connection
		
		-- Return connection.
		return connection
	end,
	Wait = function(signal)
		-- Setup connection.
		local thread = running()
		
		local connection = nil
		connection = setmetatable({
			[1] = signal,
			[2] = nil, -- Previous.
			[3] = signal[1], -- Next.
			
			Connected = false,
			[4] = function() -- Callback.
				-- Disconnect.
				local previous = connection[2]
				local next = connection[3]
				if previous then
					previous[3] = next
				else
					signal[1] = next
				end
				if next then
					next[2] = previous
				end
				connection.Connected = false
				
				-- Resume the thread.
				resume(thread)
			end
		}, connectionClass)
		signal[1] = connection
		
		-- Yield (pause) the current thread.
		yield()
	end,
	
	Fire = function(signal, ...)
		-- Fire to listeners.
		local node = signal[1]
		while node do
			if not freeThread then
				freeThread = coroutine.create(createFreeThread)
				resume(freeThread)
			end
			task.spawn(freeThread, node[4], ...)
			
			node = node[3]
		end
	end,
	
	DisconnectAll = function(signal)
		local node = signal[1]
		while node do
			local next = node[3]
			node[1] = nil
			node[3] = nil
			node.Connected = false
			node = next
		end
		signal[1] = nil
	end,
	Destroy = function(signal)
		-- Disconnect all.
		local node = signal[1]
		while node do
			local next = node[3]
			node[1] = nil
			node[3] = nil
			node.Connected = false
			node = next
		end
		signal[1] = nil
		-- Unlink class methods.
		setmetatable(signal, nil)
	end
})})

-- Return signal create function.
return function()
	return setmetatable({}, signalClass)
end :: CreateSignal
