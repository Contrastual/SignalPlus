<div align="center">

<img src="https://raw.githubusercontent.com/AlexanderLindholt/SignalPlus/refs/heads/main/Logo.png"></img>

A super fast, memory efficient, open-source script signal module<br>
for Roblox, with all features of RBXScriptSignals and even more.

[<img src="https://raw.githubusercontent.com/AlexanderLindholt/LinkButtons/refs/heads/main/Static/Module.png"></img>](https://create.roblox.com/store/asset/118793070598362) ​ [<img src="https://raw.githubusercontent.com/AlexanderLindholt/LinkButtons/refs/heads/main/Static/Devforum.png"></img>](https://devforum.roblox.com/t/signal%EF%BD%9Csuper-fast-featureful-script-signal/3552231)
</div>
<br>
<br>
<br>
<br>

# ✨ Why Signal+?
It's simply better.
- 3x as fast as RBXScriptSignals (BindableEvents).
- Memory efficient.
- Incredibly simple.
<br>
<br>

# 🚀 Get started!
In any script, simply require the module. It will return a signal creation function. Example:
```luau
local signalPlus = require(script.SignalPlus)

local mySignal = signalPlus() -- Will create a new signal.
```

The signal functions are as follows:
- Connect -> {Disconnect: function}
- Wait
- Fire
- Destroy

*Note that all functions use `.` syntax, not `:` syntax.*
