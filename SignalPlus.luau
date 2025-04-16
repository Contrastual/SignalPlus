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

v2.8.0

An insanely fast, memory efficient, fully typed, featureful,
lightweight, open-source script signal module for Roblox.


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

-- Callback thread.
local function callbackThread(callback)
	while true do
		callback(coroutine.yield())
	end
end

-- Connection class.
local Connection = table.freeze({__index = table.freeze({
	Disconnect = function(connection)
		-- Remove from linked list.
		local previous = connection.Previous
		local next = connection.Next
		previous.Next = next
		if next then
			next.Previous = previous
		end
		
		-- Close callback thread.
		coroutine.close(connection.Thread)
	end
})})

-- Signal class.
local Signal = table.freeze({__index = table.freeze({
	Connect = function(signal, callback)
		-- Create connection.
		local connection = {
			Previous = signal,
			Next = signal.Next,
			Thread = task.spawn(callbackThread, callback)
		}
		
		-- Add connection.
		signal.Next = connection
		
		-- Return connection.
		return setmetatable(connection, Connection)
	end,
	Once = function(signal, callback)
		-- Create connection.
		local connection = nil
		connection = {
			Previous = signal,
			Next = signal.Next,
			Thread = task.spawn(callbackThread, function(...)
				-- Remove from linked list.
				local previous = connection.Previous
				local next = connection.Next
				previous.Next = next
				if next then
					next.Previous = previous
				end
				
				-- Fire callback.
				callback(...)
			end)
		}
		
		-- Add connection.
		signal.Next = connection
		
		-- Return connection.
		return setmetatable(connection, Connection)
	end,
	Wait = function(signal)
		-- Save this thread to resume later.
		local thread = coroutine.running()
		
		-- Create connection.
		local connection = nil
		connection = {
			Previous = signal,
			Next = signal.Next,
			Thread = task.spawn(callbackThread, function(...)
				-- Remove from linked list.
				local previous = connection.Previous
				local next = connection.Next
				previous.Next = next
				if next then
					next.Previous = previous
				end
				
				-- Resume the thread.
				if coroutine.status(thread) == "suspended" then -- To avoid errors.
					task.spawn(thread, ...)
				end
			end)
		}
		
		-- Add connection.
		signal.Next = connection
		
		-- Yield until the next fire, and return the arguments on resume.
		return coroutine.yield()
	end,
	
	Fire = function(signal, ...)
		-- Resume all callback threads.
		local connection = signal.Next
		while connection do
			-- Resume the connection's callback thread.
			task.spawn(connection.Thread, ...)
			
			-- Go to the next connection.
			connection = connection.Next
		end
	end,
	
	DisconnectAll = function(signal)
		local connection = signal.Next
		if connection then
			-- Close all callback threads.
			while true do
				-- Close callback thread.
				coroutine.close(connection.Thread)
				
				-- Go to the next connection.
				connection = connection.Next
				-- Verify connection.
				if not connection then break end
			end
			
			-- Remove linked list reference, allowing for garbage collection.
			signal.Next = nil
		end
	end,
	Destroy = function(signal)
		-- Disconnect all connections.
		local connection = signal.Next
		if connection then
			-- Close all callback threads.
			while true do
				-- Close callback thread.
				coroutine.close(connection.Thread)
				
				-- Go to the next connection.
				connection = connection.Next
				-- Verify connection.
				if not connection then break end
			end
			
			-- Remove linked list reference, allowing for garbage collection.
			signal.Next = nil
		end
		
		-- Unlink methods.
		setmetatable(signal, nil)
	end
})})

-- Return signal create function.
return function()
	return setmetatable({}, Signal)
end :: CreateSignal
