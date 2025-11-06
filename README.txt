BlizzAddonExtensions
====================

What it does
------------
- Modular WoW addon framework.
- Currently includes the TargetCastBar module (shows target's cast bar, red if interruptible, grey if not).

Installation
------------
1. Create folder: <WoW Dir>/_retail_/Interface/AddOns/BlizzAddonExtensions/
2. Place files and subfolders as shown above.
3. In-game run: /reload

Commands
--------
/bae list      → lists loaded modules
/bae lock      → locks draggable frames (modules that support it)
/bae unlock    → unlocks draggable frames
/bae reload    → reloads the UI

Extending
---------
- Add new modules inside the `Modules/` folder.
- Register them in Core using `BlizzAddonExtensions:RegisterModule("ModuleName", moduleTable)`.
- Each module can define: OnLoad(), OnEnable(), and OnCommand(cmd).
