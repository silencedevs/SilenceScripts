# Elerium library

## Einfacher Einstieg

1. Lade die Library und erstelle ein Fenster.
2. Erstelle einen Tab und füge Labels, Buttons oder Schalter hinzu.
3. Schreibe deine Script-Logik in die jeweilige `function`.

Dieses Beispiel kannst du direkt als Grundlage verwenden:

```lua
local base = "https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/libraries/"
local library = loadstring(game:HttpGet(base .. "eleriumv2.luau"))()

local window = library:AddWindow("Mein Script", {
    main_color = Color3.fromRGB(138, 0, 0),
    min_size = Vector2.new(500, 560),
    can_resize = true,
})

local tabs = {
    main = window:AddTab("Main"),
    info = window:AddTab("Info"),
}

tabs.main:AddHeading("Meine Funktionen")
tabs.main:AddLabel("Willkommen!")

tabs.main:AddButton("Klick mich", function()
    -- Hier kommt deine Aktion hin.
end)

tabs.main:AddSwitch("Funktion aktivieren", function(aktiv)
    -- aktiv ist true beim Einschalten und false beim Ausschalten.
end)

tabs.main:AddSlider("Geschwindigkeit", function(wert)
    -- Der Wert wird beim Loslassen übernommen.
end, {min = 0, max = 100})

tabs.info:AddLabel("Mein erstes UI")
tabs.main:Show()
```

`AddHeading()` ist eine Überschrift mit standardmäßig 16px. `AddLabel()` ist ein
normaler Text mit 14px. Mit `\n` fügst du weitere Zeilen ein:

```lua
local label = tabs.main:AddLabel("Hallo\nWelt")
label.Text = "Du kannst den Text später ändern."
```

### Customize und Configs hinzufügen

Lade die beiden optionalen Module **direkt nach der Library**, bevor du das
Fenster erstellst:

```lua
library:Use(loadstring(game:HttpGet(base .. "modules/Customize.luau"))())
library:Use(loadstring(game:HttpGet(base .. "modules/ConfigManager.luau"))())
```

Lass im Beispiel den Eintrag `info` zunächst aus der `tabs`-Tabelle weg. Füge
stattdessen **ganz am Ende**, nachdem alle Funktionen erstellt sind, Folgendes ein:

```lua
tabs.customize = window:AddCustomizeTab()
local configManager
tabs.configs, configManager = window:AddConfigTab({
    Folder = "Silence/Configs/MeinScript",
})
tabs.info = window:AddTab("Info")
tabs.info:AddLabel("Mein erstes UI")

configManager:LoadStartup()
tabs.main:Show()
```

Verschiebe dabei auch `tabs.info:AddLabel(...)` aus dem ersten Beispiel ans Ende.
So ist die Reihenfolge **Main → Customize → Configs → Info**. Verwende für jedes
Script einen eigenen Config-Ordner. Im Configs-Tab kannst du Profile speichern
und ein Startprofil auswählen; Customize speichert sein Aussehen automatisch.

Die folgenden Abschnitte enthalten die ausführlichere API-Referenz.

## Optional module tabs

```lua
local base = "https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/libraries/"
local library = loadstring(game:HttpGet(base .. "eleriumv2.luau"))()
library:Use(loadstring(game:HttpGet(base .. "modules/Customize.luau"))())
library:Use(loadstring(game:HttpGet(base .. "modules/ConfigManager.luau"))())

local window = library:AddWindow("My script", {
    main_color = Color3.fromRGB(138, 0, 0),
    min_size = Vector2.new(500, 560),
    can_resize = true,
})
local main = window:AddTab("Main")
local customize = window:AddCustomizeTab()
local configs, manager = window:AddConfigTab({Folder = "Silence/Configs/MyScript"})
local info = window:AddTab("Info")

main:AddHeading("Section")
main:AddLabel("A regular label")
local enabled = main:AddSwitch("Enabled", function(state) end)
enabled:SetConfigKey("Main.Enabled")

manager:LoadStartup()
```

Load startup profiles **after all script controls exist**. Alternatively, when the
config tab itself is added at the end, `{AutoLoad = true}` loads its startup profile
immediately. Both module methods accept an optional `Title` for their tab name.

The Muscle Legends scripts use Customize → Configs → Info as their final tabs.
Their config profiles are kept in separate Main/Farming folders under
`Silence/Configs/MuscleLegends`.

## Configs

Create, save, load, refresh, delete, and choose/clear a startup profile. Profiles
contain switches, sliders, dropdown selections, text inputs, colors, keybinds, and
appearance. Values and selections are loaded before switches; module-tab controls
and displayed stats are excluded.

Control keys default to tab/type/original label/occurrence. Controls returning a
data object also expose `GetValue()`, `SetValue(value)`, and
`SetConfigKey("stable.key")`. For script-owned state, including custom multi-selects:

```lua
window:RegisterConfig("SelectedItems", function()
    return selectedItems
end, function(value)
    selectedItems = value
    updateSelectionLabel()
end)
```

Bindings support JSON-compatible values, Color3, Font/KeyCode enums, and nested
tables of those values. `tab:SetConfigIgnored(true)` excludes its automatic bindings.

Manager methods: `Save(name)`, `Load(name)`, `Delete(name)`, `Refresh()`,
`SetAutoload(nameOrNil)`, `GetAutoload()`, `LoadAutoload()`, `LoadStartup()`.
`LoadStartup()` catches errors and reports them in the Configs tab.

## Customize

Main/background/text color, font, heading/label/control text size, and row spacing.
Color controls show a swatch; tapping it expands the picker. Font options preview
their own font. The window title and header controls retain their appearance.

Settings save automatically to `Silence/Customize/<PlaceId>/appearance.json` and
load when Customize is added. Override the folder with `{Folder = "..."}`.
Pending writes flush during close/reexecution. Startup configs preserve these
preferences; manual profile loads can restore and save a different appearance.

`window:GetTheme()`, `window:SetTheme({...})`, and `window:ResetTheme()` are available.
Theme keys: `MainColor`, `BackgroundColor`, `TextColor`, `Font`, `HeadingSize`,
`LabelSize`, `ControlSize`, `Spacing`.

## Labels and inputs

- `AddHeading(text)` defaults to 16px; `AddLabel(text)` defaults to 14px.
- `AddLabel("Hello\nWorld")` has the same row spacing as two separate labels.
- Labels retain the mutable `.Text`, `.Font`, `.TextSize`, and `.TextColor3` API.
- Sliders support mouse and touch. Their displayed value follows the drag; callbacks
  run on release by default. Cancellation keeps the previous committed value.
  Options: `min`, `max`, `step`, `readonly`, `commitOnRelease` (default true).
  `Set(value)` uses actual values and applies immediately; `IsDragging()` reports capture.
- Color pickers support mouse/touch, `Set(Color3)`, `SetOpen(bool)`, and `IsOpen()`.

## Windows and assets

Drag the title or non-interactive tab content to move the window. In overflowing
content, dragging along its scroll axis scrolls; perpendicular dragging moves the
window. Wheel and scrollbar input remain available. The minimum expanded height is
300px; minimum width follows the complete title and header controls. `min_size`
sets the initial size. The icon and minimize button toggle the animated collapsed
header; Close destroys the runtime and stops its managed work.

`window:SetSize(Vector2)`, `SetTitle(string)`, `Minimize(bool)`, and `Destroy()` are
available. Resize handles and scrollbars follow the main color and highlight while
used. PNG icons cache under `Silence/LibraryAssets`; see [asset credits](assets/README.md).
