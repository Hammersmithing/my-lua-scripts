# Project Context

## Overview
This is a Lua scripting project for REAPER (digital audio workstation).
Developer: Alden Hammersmith

## Tech Stack
- **Language**: Lua
- **Platform**: REAPER's built-in ReaScript API

## Key Information
- REAPER scripts use the `reaper.` namespace for API calls
- Console output uses `reaper.ShowConsoleMsg()`

## Script Development Workflow

### Folder Paths
- **Git repo (development)**: `/Users/jahammersmith/projects/my-lua-scripts`
- **REAPER scripts base**: `/Users/jahammersmith/Library/Application Support/REAPER/Scripts/Alden Hammersmith Custom Scripts/`
- **Development folder**: `07. Development` (testing goes here first)

### Script Categories (permanent folders)
Replace `07. Development` in the base path with any of these:
```
01. Automation Items    17. Meta                  33. Takes Properties
02. Autosampling        18. MIDI                  34. Templates
03. Batch Processing    19. MIDI Editor           35. Tempo and Time Signature
04. Color               20. MIDI Inline Editor    36. Time Selection
05. Composing           21. Mixing                37. Text Items and Item Notes
06. Cursor              22. Navigation            38. Theme
07. Development         23. Project               39. Tracks
08. Diagnostics/Debug   24. Razor Edit            40. Track Properties
09. Envelopes           25. Regions               41. Transport
10. Functions           26. Rendering             42. UI (RealmGui)
11. FX                  27. Routing               43. Various
12. FX Specific         28. Ruler                 44. Video
13. Items Editing       29. Sample Libraries      45. View
14. Items Properties    30. Spectral Edits        46. Web Interfaces
15. Markers             31. Stretch Markers       47. Workflows (Cross-cutting)
16. Media Explorer      32. Subprojects
```

### Starting a Session
Claude should ask: "What Lua script do you want to work on?"
- User can request an existing script in development
- User can describe an idea for a new script

### Creating/Editing a Script (Claude does all steps automatically)
When the user requests a new script or edits an existing one, Claude should execute ALL of these steps in sequence:

**Step 1: Write the script**
Create or edit the `.lua` file in the git repo.

**Step 2: Commit and push to GitHub**
```bash
git add SCRIPT_NAME.lua && git commit -m "Add/Update SCRIPT_NAME" && git push
```

**Step 3: Deploy and test in REAPER**
```bash
cp "/Users/jahammersmith/projects/my-lua-scripts/SCRIPT_NAME.lua" "/Users/jahammersmith/Library/Application Support/REAPER/Scripts/Alden Hammersmith Custom Scripts/07. Development/"
/Applications/REAPER.app/Contents/MacOS/REAPER -nonewinst "/Users/jahammersmith/Library/Application Support/REAPER/Scripts/Alden Hammersmith Custom Scripts/07. Development/SCRIPT_NAME.lua"
open -a REAPER
```

Note: This runs the script directly but does not add it to REAPER's Action List.

### After Testing
User tests and reports back:
- **If working**: Claude recommends a category folder (01-47), user confirms, Claude moves script to permanent folder
- **If not working**: Claude adds a TODO comment at top of script describing what needs more development, then commits and pushes to GitHub

### TODO Comment Format
When a script needs more work, add this at the top:
```lua
--[[
  TODO:
  - Description of what needs to be fixed/added
  - Another item if needed
]]--
```

---

## Session Notes
*Add notes here as we work together. This section will persist between conversations.*

