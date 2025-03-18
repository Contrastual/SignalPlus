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
https://devforum.roblox.com/t/signal%EF%BD%9Cinsanely-fast-simple-script-signal/3552231


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
type CreateSignal = () -> ()

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
		runCallbackInFreeThread(coroutine.yield())
	end
end

-- Connection class.
local connectionClass = {__index = {
	Disconnect = function(connection)
		if connection[2] then
			connection[2][3] = connection[3]
		else
			connection[1][2] = connection[3]
		end
		if connection[3] then
			connection[3][2] = connection[2]
		else
			connection[1][1] = connection[2]
		end
		
		table.clear(connection)
		setmetatable(connection, nil)
	end
}}

-- Signal class.
local signalClass = {__index = {
	Connect = function(signal, callback)
		-- Connect callback.
		local connection = nil
		connection = setmetatable({
			[1] = signal,
			[2] = signal[1], -- Previous.
			[3] = nil, -- Next.
			
			Connected = false,
			[5] = callback
		}, connectionClass)
		if signal[1] then
			signal[1][3] = connection
		else
			signal[2] = connection
		end
		signal[1] = connection
		
		-- Create and return connection.
		return connection
	end,
	Once = function(signal, callback)
		-- Connect callback.
		local connection = nil
		connection = setmetatable({
			[1] = signal,
			[2] = signal[1], -- Previous.
			[3] = nil, -- Next.
			
			Connected = false,
			[5] = function() -- Callback.
				-- Disconnect.
				if connection[2] then
					connection[2][3] = connection[3]
				else
					signal[2] = connection[3]
				end
				if connection[3] then
					connection[3][2] = connection[2]
				else
					signal[1] = connection[2]
				end
				connection.Connected = false
				
				-- Fire callback.
				callback()
			end
		}, connectionClass)
		if signal[1] then
			signal[1][3] = connection
		else
			signal[2] = connection
		end
		signal[1] = connection
		
		-- Create and return connection.
		return connection
	end,
	Wait = function(signal)
		-- Connect callback.
		local thread = coroutine.running()
		
		-- Connect callback.
		local connection = nil
		connection = setmetatable({
			[1] = signal,
			[2] = signal[1], -- Previous.
			[3] = nil, -- Next.
			
			Connected = false,
			[5] = function() -- Callback.
				-- Disconnect.
				if connection[2] then
					connection[2][3] = connection[3]
				else
					signal[2] = connection[3]
				end
				if connection[3] then
					connection[3][2] = connection[2]
				else
					signal[1] = connection[2]
				end
				connection.Connected = false
				
				-- Resume the thread.
				coroutine.resume(thread)
			end
		}, connectionClass)
		if signal[1] then
			signal[1][3] = connection
		else
			signal[2] = connection
		end
		signal[1] = connection
		
		-- Yield (pause) the current thread.
		coroutine.yield()
	end,
	
	Fire = function(signal, ...)
		-- Fire to listeners.
		local node = signal[2]
		while node do
			if not freeThread then
				freeThread = coroutine.create(createFreeThread)
				coroutine.resume(freeThread)
			end
			task.spawn(freeThread, node[5], ...)
			
			node = node[3]
		end
	end,
	
	DisconnectAll = function(signal)
		-- Clear linked list.
		signal[1] = nil
		signal[2] = nil
	end,
	Destroy = function(signal)
		-- Clear linked list.
		signal[1] = nil
		signal[2] = nil
		-- Unlink class methods.
		setmetatable(signal, nil)
	end
}}

-- Return signal create function.
return function()
	return setmetatable({}, signalClass)
end :: CreateSignal
