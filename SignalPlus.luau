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

An incredibly simple, open-source script signal module for Roblox,
with 3x the speed of RBXScriptSignals, while still error-prone.


GitHub:
https://github.com/AlexanderLindholt/SignalPlus

Devforum:
https://devforum.roblox.com/t/


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
export type Signal = {
	Connect: (callback: () -> ()) -> (),
	Wait: () -> (),
	Fire: (...any) -> (),
	Destroy: () -> ()
}

-- Create function.
return function()
	local connections = {}
	local waiting = {}
	
	local signal = {}
	
	signal.Connect = function(callback)
		-- Argument errors.
		if type(callback) ~= "function" then error("No callback provided.") end
		
		-- Connect callback.
		table.insert(connections, callback)
		-- Return disconnect function.
		return table.freeze({
			Disconnect = function()
				table.remove(connections, table.find(connections, callback))
			end
		})
	end
	
	signal.Wait = function()
		-- Insert the current thread to waiting, so that it can be resumed on fire.
		table.insert(waiting, coroutine.running())
		-- Yield (pause) the current thread.
		coroutine.yield()
	end
	
	signal.Fire = function(...)
		-- Fire to listeners.
		for _, callback in ipairs(connections) do
			coroutine.resume(coroutine.create(callback), ...) -- Run in seperate thread to avoid yield in this thread.
		end
		
		-- Resume waiting threads.
		if waiting then
			for _, thread in ipairs(waiting) do
				coroutine.resume(thread)
			end
			waiting = {}
		end
	end
	
	signal.Destroy = function()
		-- Clear up stuff to save on memory.
		connections = nil
		waiting = nil
		-- Get rid of the functions, so you can't use it anymore.
		table.clear(signal)
	end
	
	return signal :: Signal
end
