--!optimize 2

--[[

           +++                                                                                      
       ++++++++   ===                                                                               
    ++++++++++   ====                                                  ====                         
     ++++++                                                            ====                         
       +++++     ====     ====== =====  ==== =======      ========     ====        ====             
        +++++    ====    =============  =============    ===========   ====        ====             
         ++++    ====   ====     =====  =====    ====           ====   ====        ====             
         ++++    ====   ====     =====  =====    ====     ==========   ====    =============        
         ++++    ====   ====     =====  =====    ====   ======  ====   ====    =============        
       ++++++    ====   =====   ======  =====    ====  ====     ====   ====        ====    +++++++++
   ++++++++++    ====    =============  =====    ====   ============   ====   ++++ ==== ++++++++++++
  +++++++        ====            =====  ====     ====   + ====  ====   ==== ++++++++  ++++++++      
 +++++                  ==== +++ ==== +++++++++++++++++++++++++++++++++++++++++++++++++++++         
 ++++        +++++++++++ =========== +++++++++++++++++++++++++++++++++++++++      ++++++            
+++++++++++++++++++++++++++                                                         +               
 +++++++++++++++++++++++++                                                                          
      +++++                                                                                         

v3.2.0

An insanely fast, lightweight, fully typed and documented
open-source signal module for Roblox, with dynamic types.


GitHub:
https://github.com/AlexanderLindholt/SignalPlus

Devforum:
https://devforum.roblox.com/t/3552231


--------------------------------------------------------------------------------
MIT License

Copyright (c) 2025 Alexander Lindholt

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
	Disconnect: typeof(
		-- Disconnects the connection.
		-- To reconnect, make a new connection.
		function(connection: Connection) end
	),
}
export type Signal<Parameters...> = {
	Connect: typeof(
		-- Connects the given function.
		function(signal: Signal<Parameters...>, callback: (Parameters...) -> ()): Connection end
	),
	Once: typeof(
		-- Connects the given function, but disconnects after first fire.
		function(signal: Signal<Parameters...>, callback: (Parameters...) -> ()): Connection end
	),
	Wait: typeof(
		-- Yields the current thread until the next fire.
		function(signal: Signal<Parameters...>): Parameters... end
	),
	
	Fire: typeof(
		-- Fires all callbacks and resumes all waiting threads.
		function(signal: Signal<Parameters...>, ...: Parameters...) end
	),
	
	DisconnectAll: typeof(
		-- Disconnects all connections.
		function(signal: Signal<Parameters...>) end
	),
	Destroy: typeof(
		-- Disconnects all connections, and makes the signal unusable.
		function(signal: Signal<Parameters...>) end
	),
}
type CreateSignal = typeof(
	-- Creates a new signal.
	function(): Signal end
)

-- Setup thread recycling.
local threads = {}
local function reusableThreadCall(callback, thread, ...)
	callback(...)
	table.insert(threads, thread)
end
local function reusableThread()
	while true do
		reusableThreadCall(coroutine.yield())
	end
end

-- Connection functions.
local Connection = {}
Connection.__index = Connection

Connection.Disconnect = function(connection)
	-- Verify connection.
	if not connection.Index then return end
	
	-- Remove connection.
	local signal = connection.Signal
	local lastIndex = #signal
	local index = connection.Index
	if index == lastIndex then
		signal[lastIndex] = nil
	else
		local last = signal[lastIndex]
		last.Index = index
		signal[index] = last
		signal[lastIndex] = nil
	end
end

-- Signal functions.
local Signal = {}
Signal.__index = Signal

Signal.Connect = function(signal, callback)
	-- Create connection.
	local connection = {
		Signal = signal,
		Index = #signal + 1,
		Callback = callback
	}
	
	-- Add connection.
	table.insert(signal, connection)
	
	-- Return connection.
	return setmetatable(connection, Connection)
end
Signal.Once = function(signal, callback)
	-- Create connection.
	local connection = nil
	connection = {
		Signal = signal,
		Index = #signal + 1,
		Callback = function(...)
			-- Remove callback.
			connection.Index = nil
			-- Remove connection.
			local lastIndex = #signal
			local index = connection.Index
			if index == lastIndex then
				signal[lastIndex] = nil
			else
				local last = signal[lastIndex]
				last.Index = index
				signal[index] = last
				signal[lastIndex] = nil
			end
			
			-- Fire callback.
			callback(...)
		end
	}
	
	-- Add connection.
	table.insert(signal, connection)
	
	-- Return connection.
	return setmetatable(connection, Connection)
end
Signal.Wait = function(signal)
	-- Save this thread to resume later.
	local thread = coroutine.running()
	
	-- Create connection.
	local connection = nil
	connection = {
		Signal = signal,
		Index = #signal + 1,
		Callback = function(...)
			-- Remove callback.
			connection.Index = nil
			-- Remove connection.
			local lastIndex = #signal
			local index = connection.Index
			if index == lastIndex then
				signal[lastIndex] = nil
			else
				local last = signal[lastIndex]
				last.Index = index
				signal[index] = last
				signal[lastIndex] = nil
			end
			
			-- Resume the thread.
			if coroutine.status(thread) == "suspended" then -- To avoid errors.
				local _, err = coroutine.resume(thread, ...)
				if err then error(err, 2) end
			end
		end
	}
	
	-- Add connection.
	table.insert(signal, connection)
	
	-- Yield until the next fire, and return the arguments on resume.
	return coroutine.yield()
end

Signal.Fire = function(signal, ...)
	-- Resume all callback threads.
	for index = #signal, 1, -1 do
		-- Find or create a thread, and run the callback in it.
		local length = #threads
		if length == 0 then
			local thread = coroutine.create(reusableThread)
			coroutine.resume(thread)
			task.spawn(thread, signal[index].Callback, thread, ...)
		else
			local thread = threads[length]
			threads[length] = nil -- Remove from free threads list.
			task.spawn(thread, signal[index].Callback, thread, ...)
		end
	end
end

Signal.DisconnectAll = function(signal)
	table.clear(signal)
end
Signal.Destroy = function(signal)
	-- Disconnect all connections.
	table.clear(signal)
	
	-- Unlink methods.
	setmetatable(signal, nil)
end

-- Return signal creation function.
return function()
	return setmetatable({}, Signal)
end :: CreateSignal
