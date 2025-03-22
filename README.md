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

# ⚡ Performance, efficiency, features.
Signal+ is for developers who strive for performance and efficiency.<br>
And it still has all the features you'll ever need!

**It's perhaps the best of its kind,<br>
beating the top alternatives like<br>
GoodSignal and FastSignal.**
<br>
<br>

# 🚀 Get started!
## Quick setup
Let's first get the module. There are two ways:
- **Get it from the creator store:**
  - Click `Get` at the top of this post.
  - Click `Get Model` on the store.
  - Open the ToolBox in Roblox Studio.
  - Go to the `Inventory` tab.
  - Click on `Signal+`.
- **Get it from GitHub:**
  - Click `Git` at the top of this post.
  - Go to `Releases`.
  - Download the latest `.rbxm` file.
  - Find the file in your file explorer.
  - Drag the file into Roblox Studio.

## How to use it
In any script, simply require the module. It will return a signal creation function. Example:
```luau
local signalPlus = require(script.SignalPlus)

local mySignal = signalPlus() -- Will create a new signal.
```

## Documentation
`signalPlus()` -> Signal

### Signal:
- `:Connect(function)` -> Connection
  - Connects the given function.
- `:Once(function)` -> Connection
  - Connects the given function, but disconnects after first fire.
- `:Wait()`
  - Yields the current thread until the next fire.
- `:Fire()`
  - Fires all connections and resumes all waiting threads.
- `:DisconnectAll()`
  - Disconnects all connections.
- `:Destroy()`
  - Makes the signal unusable, and disconnects all connections.

### Connection:
- `:Disconnect()`
  - Disconnects the connection.
To reconnect make a new connection.
- `.Connected` -> boolean
