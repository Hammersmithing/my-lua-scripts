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
08. Diagnostics & Debug   24. Razor Edit            40. Track Properties
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

**Step 3: Add to Google Spreadsheet (Development tab)**
```bash
curl -L -X POST "https://script.google.com/macros/s/AKfycbyYRfKTTYlHSCaCW1pO2vvxRjR3FU6X699hXycJRGfDNGBGFNT7ypJDVzECuuis15q87w/exec" \
  -H "Content-Type: application/json" \
  -d '{
    "tab": "07. Development",
    "script_name": "SCRIPT_NAME.lua",
    "date_created": "YYYY-MM-DD",
    "use": "Brief description of what the script does",
    "file_path": "/Users/jahammersmith/Library/Application Support/REAPER/Scripts/Alden Hammersmith Custom Scripts/07. Development/SCRIPT_NAME.lua",
    "file_type": "lua",
    "notes": "",
    "osc_page": "",
    "button_id": "",
    "button_name": ""
  }'
```

**Step 4: Deploy and test in REAPER**
```bash
cp "/Users/jahammersmith/projects/my-lua-scripts/SCRIPT_NAME.lua" "/Users/jahammersmith/Library/Application Support/REAPER/Scripts/Alden Hammersmith Custom Scripts/07. Development/"
/Applications/REAPER.app/Contents/MacOS/REAPER -nonewinst "/Users/jahammersmith/Library/Application Support/REAPER/Scripts/Alden Hammersmith Custom Scripts/07. Development/SCRIPT_NAME.lua"
open -a REAPER
```

Note: This runs the script directly but does not add it to REAPER's Action List.

### After Testing
User tests in REAPER and reports back with ONE of these three outcomes:

**Option A: Needs more work NOW**
- User describes what needs to change
- Claude makes the edits, commits, pushes, and deploys again
- Repeat testing cycle

**Option B: Needs more work LATER (stop for now)**
- User says they want to pause development
- Claude adds TODO comment at top of script describing what needs work
- Claude commits and pushes to GitHub
- Claude updates the script in the development folder
- Session ends for this script

**Option C: Script is COMPLETE**
1. Claude suggests which of the 47 category folders the script should live in permanently
2. User confirms OR discusses alternative folder
3. Once agreed, Claude:
   - Moves script from `07. Development` to the permanent folder (with ALDENHammersmith_ prefix)
   - Deletes script from "07. Development" spreadsheet tab
   - Adds script to REAPER Action List (runs automatically, copies name to clipboard)
   - Adds script to permanent folder spreadsheet tab
   - Renames script in git repo to match final name (ALDENHammersmith_ prefix)
4. Script is done - ready to design a new script

### Moving to Permanent Folder
When moving to a permanent folder, rename the script with the prefix `ALDENHammersmith_`:
```bash
# Move and rename script to permanent folder (replace XX. Category with actual folder name)
mv "/Users/jahammersmith/Library/Application Support/REAPER/Scripts/Alden Hammersmith Custom Scripts/07. Development/SCRIPT_NAME.lua" "/Users/jahammersmith/Library/Application Support/REAPER/Scripts/Alden Hammersmith Custom Scripts/XX. Category/ALDENHammersmith_SCRIPT_NAME.lua"
```

### Delete from Development Tab in Spreadsheet
When script leaves development, remove it from the "07. Development" tab:
```bash
curl -L -X POST "https://script.google.com/macros/s/AKfycbyYRfKTTYlHSCaCW1pO2vvxRjR3FU6X699hXycJRGfDNGBGFNT7ypJDVzECuuis15q87w/exec" \
  -H "Content-Type: application/json" \
  -d '{"action": "delete", "tab": "07. Development", "script_name": "SCRIPT_NAME.lua"}'
```

### Adding to REAPER Action List (Automated)
After moving to permanent folder, Claude runs these commands to auto-register the script:
```bash
# Write the script path (with ALDENHammersmith_ prefix) to a temp file
echo "/Users/jahammersmith/Library/Application Support/REAPER/Scripts/Alden Hammersmith Custom Scripts/XX. Category/ALDENHammersmith_SCRIPT_NAME.lua" > /tmp/reaper_script_to_add.txt

# Run the helper script that adds it to the Action List and opens the Action List window
/Applications/REAPER.app/Contents/MacOS/REAPER -nonewinst "/Users/jahammersmith/Library/Application Support/REAPER/Scripts/Alden Hammersmith Custom Scripts/07. Development/_add-to-action-list.lua"
open -a REAPER
```
The script will run automatically, the core script name (e.g. "test-4") is copied to clipboard, then the Action List opens. User can paste (Cmd+V) to search and assign a hotkey.

### Adding to Google Spreadsheet Tracker
After adding to Action List, Claude adds the script to the tracking spreadsheet:
```bash
curl -L -X POST "https://script.google.com/macros/s/AKfycbyYRfKTTYlHSCaCW1pO2vvxRjR3FU6X699hXycJRGfDNGBGFNT7ypJDVzECuuis15q87w/exec" \
  -H "Content-Type: application/json" \
  -d '{
    "tab": "XX. Category",
    "script_name": "ALDENHammersmith_SCRIPT_NAME.lua",
    "date_created": "YYYY-MM-DD",
    "use": "Brief description of what the script does",
    "file_path": "/Users/jahammersmith/Library/Application Support/REAPER/Scripts/Alden Hammersmith Custom Scripts/XX. Category/ALDENHammersmith_SCRIPT_NAME.lua",
    "file_type": "lua",
    "notes": "",
    "osc_page": "",
    "button_id": "",
    "button_name": ""
  }'
```
The tab name matches the permanent folder name (e.g. "08. Diagnostics & Debug").

### Rename Script in Git Repo
After completing all steps, rename the script in git to match the final name:
```bash
git mv SCRIPT_NAME.lua ALDENHammersmith_SCRIPT_NAME.lua && git commit -m "Rename SCRIPT_NAME to final name with prefix" && git push
```

### TODO Comment Format
When a script needs more work (Option B), add this at the top:
```lua
--[[
  TODO:
  - Description of what needs to be fixed/added
  - Another item if needed
]]--
```

---

## OSC Control Surface (iPad via Open Stage Control)

### Overview
iPad control surface using **Open Stage Control** (browser-based, OSC protocol).
- iPad connects via Safari to Open Stage Control running on Mac
- Open Stage Control communicates with REAPER via OSC
- Bidirectional: faders in REAPER move faders on iPad and vice versa

### File Locations
- **Open Stage Control app**: `/Applications/open-stage-control.app`
- **Layout files**: `/Users/jahammersmith/Library/Application Support/REAPER/Alden Hammersmith open-stage-control/`
- **Current layout**: `IPAD Surface 5Pages.json`
- **REAPER OSC configs**: `/Users/jahammersmith/Library/Application Support/REAPER/OSC/`

### Launching Open Stage Control
1. Open the app: `open -a "open-stage-control"`
2. Configure launcher settings:
   - **send**: `127.0.0.1:8000`
   - **osc-port**: `9000`
   - **port**: `8080`
   - **load**: `/Users/jahammersmith/Library/Application Support/REAPER/Alden Hammersmith open-stage-control/IPAD Surface 5Pages.json`
3. Click Play button to start server
4. On iPad, open Safari and go to: `http://192.168.12.193:8080`

### REAPER OSC Settings
Location: Preferences → Control/OSC/Web → OSC: OpenStageControl
- **Mode**: Configure device IP + local port
- **Device IP**: `127.0.0.1`
- **Device port**: `9000`
- **Local listen port**: `8000`
- **Pattern config**: Default
- **Allow binding messages to REAPER actions and FX learn**: ✓ Checked

### Two Methods for Connecting Controls

#### Method 1: Action List Binding
Best for **buttons that trigger discrete actions**.
- Play/Stop/Record buttons
- Run a Lua script
- Toggle features on/off
- Any REAPER action

**How to set up:**
1. In REAPER: Actions → Show Action List
2. Find and select the action
3. Click "Add..." button
4. Choose the OSC binding option
5. Press the button on your iPad surface
6. The OSC address is now bound to that action

#### Method 2: Pattern Config (.ReaperOSC file)
Best for **faders and continuous controls** with bidirectional feedback.
- Track volume faders
- Pan knobs
- Send levels
- FX parameters

**How it works:**
- The `.ReaperOSC` file maps OSC addresses to REAPER functions
- Provides automatic bidirectional sync (move fader in REAPER → moves on iPad)
- Edit the file at: `/Users/jahammersmith/Library/Application Support/REAPER/OSC/Default.ReaperOSC`

### Quick Reference: What Method to Use

| Control Type | Method | Why |
|--------------|--------|-----|
| Play/Stop/Record | Action List | Discrete trigger |
| Run script | Action List | Discrete trigger |
| Toggle mute/solo | Action List | Discrete trigger |
| Track volume | Pattern Config | Continuous + bidirectional |
| Pan | Pattern Config | Continuous + bidirectional |
| FX parameter | Pattern Config or FX Learn | Continuous + bidirectional |

---

## Session Notes
*Add notes here as we work together. This section will persist between conversations.*

