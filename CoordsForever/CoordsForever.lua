-- Coordenadas Forever

local ADDON = ...

local UPDATE_INTERVAL = 0.1
local ARRIVE_DISTANCE = 12      -- metros
local PREFIX = "|cff8ad4ffCoordenadas Forever|r: "

local DEFAULTS = {
    hud      = true,
    map      = true,
    cursor   = true,
    locked   = false,
    scale    = 1,

    point    = "TOP",
    relPoint = "TOP",
    x        = 0,
    y        = 0,
}

local db
local hud, hudZone, hudText, hudWay, hudArrow, driver
local mapPlayerText, mapCursorText
local pin

-- ---------------------------------------------------------------- utilidades

local function Say(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
end

-- 0-100, o nil si el jugador no esta en ese mapa
local function PlayerCoords(uiMapID)
    if not uiMapID then return nil end
    local pos = C_Map.GetPlayerMapPosition(uiMapID, "player")
    if not pos then return nil end
    local x, y = pos:GetXY()
    if not x or not y or (x == 0 and y == 0) then return nil end
    return x * 100, y * 100
end

local function CurrentMapID()
    return C_Map.GetBestMapForUnit("player")
end

local function ZoneName(uiMapID)
    local info = uiMapID and C_Map.GetMapInfo(uiMapID)
    return (info and info.name) or GetRealZoneText() or ""
end

-- el mapa abierto, o si no la zona del jugador
local function TargetMapID()
    local map = _G.WorldMapFrame
    if map and map:IsShown() and map.GetMapID then
        return map:GetMapID() or CurrentMapID()
    end
    return CurrentMapID()
end

-- "Los Baldíos" -> "losbaldios"
local ACCENTS = {
    ["á"] = "a", ["à"] = "a", ["â"] = "a", ["ä"] = "a", ["Á"] = "a", ["À"] = "a",
    ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e", ["É"] = "e", ["È"] = "e",
    ["í"] = "i", ["ì"] = "i", ["î"] = "i", ["ï"] = "i", ["Í"] = "i",
    ["ó"] = "o", ["ò"] = "o", ["ô"] = "o", ["ö"] = "o", ["Ó"] = "o",
    ["ú"] = "u", ["ù"] = "u", ["û"] = "u", ["ü"] = "u", ["Ú"] = "u", ["Ü"] = "u",
    ["ñ"] = "n", ["Ñ"] = "n", ["ç"] = "c", ["Ç"] = "c",
}

local function Simplify(text)
    text = string.gsub(text, "[\195][\128-\191]", ACCENTS)
    return (string.gsub(string.lower(text), "[^%w]", ""))
end

local zoneIndex

local function BuildZoneIndex()
    zoneIndex = {}
    local roots = { 946, 947 }
    if C_Map.GetFallbackWorldMapID then
        table.insert(roots, C_Map.GetFallbackWorldMapID())
    end

    for _, root in ipairs(roots) do
        for _, info in ipairs(C_Map.GetMapChildrenInfo(root, nil, true) or {}) do
            if info.mapType == Enum.UIMapType.Zone or info.mapType == Enum.UIMapType.Continent then
                local key = Simplify(info.name or "")
                if key ~= "" and not zoneIndex[key] then
                    zoneIndex[key] = info.mapID
                end
            end
        end
    end
end

-- uiMapID, o nil y las candidatas
local function FindZone(name)
    if not zoneIndex then BuildZoneIndex() end

    local wanted = Simplify(name)
    if wanted == "" then return nil, {} end
    if zoneIndex[wanted] then return zoneIndex[wanted] end

    local matches = {}
    for key, uiMapID in pairs(zoneIndex) do
        if string.find(key, wanted, 1, true) then
            table.insert(matches, uiMapID)
        end
    end

    if #matches == 1 then return matches[1] end
    return nil, matches
end

-- -------------------------------------------------------- punto de destino

-- metros, si esta en otra zona, y giro de la flecha
local function WaypointInfo()
    local w = db.way
    if not w then return nil end

    local playerMap = CurrentMapID()
    if playerMap ~= w.map then return nil, true end

    if not (C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end

    local playerPos = C_Map.GetPlayerMapPosition(playerMap, "player")
    if not playerPos then return nil end

    local _, playerWorld = C_Map.GetWorldPosFromMapPos(playerMap, playerPos)
    local _, targetWorld = C_Map.GetWorldPosFromMapPos(w.map, CreateVector2D(w.x / 100, w.y / 100))
    if not playerWorld or not targetWorld then return nil end

    -- en el mundo x va al norte e y al oeste
    local dx = targetWorld.x - playerWorld.x
    local dy = targetWorld.y - playerWorld.y
    local distance = math.sqrt(dx * dx + dy * dy)

    local bearing = math.atan2(dy, dx)
    local facing = (GetPlayerFacing and GetPlayerFacing()) or 0

    return distance, false, bearing - facing
end

local function ClearWaypoint(quiet)
    db.way = nil
    if pin then pin:Hide() end
    if not quiet then Say("destino borrado.") end
end

local function SetWaypoint(x, y, label, uiMapID)
    uiMapID = uiMapID or TargetMapID()
    if not uiMapID then
        Say("aqui no hay mapa al que anclar el destino.")
        return
    end

    db.way = { map = uiMapID, x = x, y = y, text = label or "" }

    local name = ZoneName(uiMapID)
    if label and label ~= "" then
        Say(format("destino: |cffffd100%.1f, %.1f|r en %s (%s).", x, y, name, label))
    else
        Say(format("destino: |cffffd100%.1f, %.1f|r en %s.", x, y, name))
    end
end

-- "[zona] 49.2 57.2 [texto]", tambien con comas
local function ParseCoords(text)
    if not text or text == "" then return nil end

    local numbers, firstStart, lastEnd = {}, nil, 0
    local init = 1
    while #numbers < 2 do
        local s, e, found = string.find(text, "(%d+[%.,]?%d*)", init)
        if not s then break end
        local value = tonumber((string.gsub(found, ",", ".")))
        if value then
            table.insert(numbers, value)
            firstStart = firstStart or s
            lastEnd = e
        end
        init = e + 1
    end

    if #numbers < 2 then return nil end

    local x, y = numbers[1], numbers[2]
    if x < 0 or x > 100 or y < 0 or y > 100 then return nil end

    return x, y, strtrim(string.sub(text, lastEnd + 1)), strtrim(string.sub(text, 1, firstStart - 1))
end

-- ------------------------------------------------------- recuadro en pantalla

local function SavePosition()
    if not hud or not db then return end

    local point, _, relPoint, x, y = hud:GetPoint()
    if not point then return end

    db.point, db.relPoint, db.x, db.y = point, relPoint, x, y
end

local function BuildHUD()
    hud = CreateFrame("Frame", "CoordsForeverHUD", UIParent)
    hud:SetSize(150, 34)
    hud:SetFrameStrata("MEDIUM")
    hud:SetClampedToScreen(true)
    hud:SetMovable(true)
    hud:EnableMouse(true)
    hud:RegisterForDrag("LeftButton")

    local bg = hud:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)
    hud.bg = bg

    hudZone = hud:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    hudZone:SetPoint("TOP", hud, "TOP", 0, -6)
    hudZone:SetTextColor(0.8, 0.8, 0.8)

    hudText = hud:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    hudText:SetPoint("TOP", hudZone, "BOTTOM", 0, -2)
    hudText:SetTextColor(1, 1, 1)

    hudArrow = hud:CreateTexture(nil, "ARTWORK")
    hudArrow:SetSize(16, 16)
    hudArrow:SetTexture("Interface\\MINIMAP\\MiniMap-DeadArrow")
    hudArrow:Hide()

    hudWay = hud:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    hudWay:SetPoint("TOP", hudText, "BOTTOM", 8, -3)
    hudWay:SetTextColor(1, 0.82, 0)
    hudWay:Hide()

    hudArrow:SetPoint("RIGHT", hudWay, "LEFT", -3, 0)

    hud:SetScript("OnDragStart", function(self)
        if not db.locked then self:StartMoving() end
    end)
    hud:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
end

local function ApplyHUDPosition()
    hud:ClearAllPoints()
    hud:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
    hud:SetScale(db.scale)
end

local function RefreshHUD()
    if not db.hud then
        hud:Hide()
        return
    end
    hud:Show()

    local uiMapID = CurrentMapID()
    local x, y = PlayerCoords(uiMapID)

    hudZone:SetText(ZoneName(uiMapID))
    if x then
        hudText:SetFormattedText("|cffffd100%.1f, %.1f|r", x, y)
    else
        hudText:SetText("|cff999999sin coordenadas|r")
    end

    local extraHeight = 0
    if db.way then
        local distance, elsewhere, turn = WaypointInfo()

        if elsewhere then
            hudWay:SetFormattedText("destino en %s", ZoneName(db.way.map))
            hudArrow:Hide()
        elseif distance then
            if distance <= ARRIVE_DISTANCE then
                -- se avisa una vez, la marca se queda
                if not db.way.arrived then
                    db.way.arrived = true
                    local label = db.way.text
                    Say(label ~= "" and format("has llegado: %s.", label) or "has llegado al destino.")
                    Say("la marca sigue puesta; |cffffd100/way borrar|r la quita.")
                end
                hudWay:SetText("has llegado")
                hudArrow:Hide()
            else
                db.way.arrived = nil
                hudWay:SetFormattedText("%d m", distance)
                hudArrow:SetRotation(turn or 0)
                hudArrow:Show()
            end
        else
            hudWay:SetFormattedText("%.1f, %.1f", db.way.x, db.way.y)
            hudArrow:Hide()
        end

        if db.way then
            hudWay:Show()
            extraHeight = hudWay:GetStringHeight() + 5
        end
    else
        hudWay:Hide()
        hudArrow:Hide()
    end

    local width = math.max(hudZone:GetStringWidth(), hudText:GetStringWidth())
    if db.way then
        width = math.max(width, hudWay:GetStringWidth() + 22)
    end
    hud:SetWidth(math.max(110, width + 22))
    hud:SetHeight(hudZone:GetStringHeight() + hudText:GetStringHeight() + 16 + extraHeight)
end

-- -------------------------------------------------------- textos en el mapa

-- lienzo del mapa y su tamano; si no lo da, el contenedor
local function CanvasFor(map)
    local child = map.ScrollContainer and map.ScrollContainer.Child
    if child then
        local width, height = child:GetWidth(), child:GetHeight()
        if width and height and width > 0 and height > 0 then
            return child, width, height
        end
    end

    local container = map.ScrollContainer
    if container then
        local width, height = container:GetWidth(), container:GetHeight()
        if width and height and width > 0 and height > 0 then
            return container, width, height
        end
    end

    return nil
end

local function BuildPin(map)
    local canvas = (map.ScrollContainer and map.ScrollContainer.Child)
        or map.ScrollContainer or map
    if not canvas or pin then return end

    pin = CreateFrame("Frame", "CoordsForeverPin", canvas)
    pin:SetSize(16, 16)
    pin:SetFrameStrata("TOOLTIP")   -- si no, las capas del mapa la tapan
    pin:SetFrameLevel((canvas:GetFrameLevel() or 0) + 500)

    -- rombo dorado con borde
    local border = pin:CreateTexture(nil, "BACKGROUND")
    border:SetColorTexture(0, 0, 0, 0.9)
    border:SetSize(14, 14)
    border:SetPoint("CENTER")
    border:SetRotation(math.pi / 4)

    local core = pin:CreateTexture(nil, "ARTWORK")
    core:SetColorTexture(1, 0.82, 0, 1)
    core:SetSize(9, 9)
    core:SetPoint("CENTER")
    core:SetRotation(math.pi / 4)

    pin.label = pin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pin.label:SetPoint("TOP", pin, "BOTTOM", 0, -1)
    local font, size = pin.label:GetFont()
    pin.label:SetFont(font, size, "OUTLINE")

    pin:Hide()
end

local function BuildMapTexts()
    local map = _G.WorldMapFrame
    if not map or mapPlayerText then return end

    local anchor = map.ScrollContainer or map

    local holder = CreateFrame("Frame", "CoordsForeverMapHolder", map)
    holder:SetAllPoints(anchor)
    holder:SetFrameLevel((map:GetFrameLevel() or 0) + 600)

    mapPlayerText = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mapPlayerText:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 14, 12)
    mapPlayerText:SetJustifyH("LEFT")

    mapCursorText = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mapCursorText:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -14, 12)
    mapCursorText:SetJustifyH("RIGHT")

    for _, fs in pairs({ mapPlayerText, mapCursorText }) do
        local font, size = fs:GetFont()
        fs:SetFont(font, size, "OUTLINE")
        fs:SetShadowOffset(1, -1)
    end

    BuildPin(map)
end

-- el lienzo cambia con el zoom, asi que se reancla en cada refresco
local function RefreshPin(map, shownMapID)
    if not pin then BuildPin(map) end
    if not pin then return end

    local w = db.way
    if not w or w.map ~= shownMapID then
        pin:Hide()
        return
    end

    local canvas, width, height = CanvasFor(map)
    if not canvas then
        pin:Hide()
        return
    end

    if pin:GetParent() ~= canvas then
        pin:SetParent(canvas)
        pin:SetFrameStrata("TOOLTIP")
        pin:SetFrameLevel((canvas:GetFrameLevel() or 0) + 500)
    end

    pin:ClearAllPoints()
    pin:SetPoint("CENTER", canvas, "TOPLEFT", (w.x / 100) * width, -(w.y / 100) * height)

    if w.text ~= "" then
        pin.label:SetText(w.text)
    else
        pin.label:SetFormattedText("%.1f, %.1f", w.x, w.y)
    end
    pin:Show()
end

local function RefreshMapTexts()
    local map = _G.WorldMapFrame
    if not mapPlayerText or not map or not map:IsShown() then return end

    local shownMapID = (map.GetMapID and map:GetMapID()) or CurrentMapID()

    if db.map then
        local x, y = PlayerCoords(shownMapID)
        if x then
            mapPlayerText:SetFormattedText("Jugador: |cffffd100%.1f, %.1f|r", x, y)
        else
            mapPlayerText:SetText("")
        end
    else
        mapPlayerText:SetText("")
    end

    if db.cursor then
        local container = map.ScrollContainer
        if container and container.GetNormalizedCursorPosition and container:IsMouseOver() then
            local cx, cy = container:GetNormalizedCursorPosition()
            if cx and cy and cx >= 0 and cx <= 1 and cy >= 0 and cy <= 1 then
                mapCursorText:SetFormattedText("Cursor: |cff8ad4ff%.1f, %.1f|r", cx * 100, cy * 100)
            else
                mapCursorText:SetText("")
            end
        else
            mapCursorText:SetText("")
        end
    else
        mapCursorText:SetText("")
    end

    RefreshPin(map, shownMapID)
end

-- ---------------------------------------------------------------- refresco

local elapsedSince = 0
local function OnUpdate(_, elapsed)
    elapsedSince = elapsedSince + elapsed
    if elapsedSince < UPDATE_INTERVAL then return end
    elapsedSince = 0
    RefreshHUD()
    RefreshMapTexts()
end

-- ------------------------------------------------------------ comandos

local function PrintHelp()
    Say("comandos:")
    Say("  |cffffd100/way 49.2 57.2|r - marca ese punto en el mapa")
    Say("  |cffffd100/way 49.2 57.2 Hgarth|r - igual, con nombre")
    Say("  |cffffd100/way Los Baldios 46 74|r - en otra zona")
    Say("  |cffffd100/way borrar|r - quita la marca")
    Say("  |cffffd100/way estado|r - dice que sabe el addon (para diagnosticar)")
    Say("  |cffffd100/coords|r - muestra u oculta el recuadro en pantalla")
    Say("  |cffffd100/coords lock|r - fija o suelta el recuadro")
    Say("  |cffffd100/coords reset|r - devuelve el recuadro arriba al centro")
    Say("  |cffffd100/coords scale <0.5-3>|r - tamano del recuadro")
    Say("  |cffffd100/coords pos|r - dice donde esta el recuadro guardado")
    Say("  |cffffd100/coords map|r - coordenadas del jugador en el mapa")
    Say("  |cffffd100/coords cursor|r - coordenadas del cursor en el mapa")
end

local function PrintState()
    local map = _G.WorldMapFrame
    local w = db.way

    Say("estado:")

    if w then
        Say(format("  destino: |cffffd100%.1f, %.1f|r (%s) en mapa %s (%s)",
            w.x, w.y, w.text ~= "" and w.text or "sin nombre",
            tostring(w.map), ZoneName(w.map)))
    else
        Say("  destino: |cffff5555ninguno guardado|r")
    end

    local playerMap = CurrentMapID()
    Say(format("  tu mapa: %s (%s)", tostring(playerMap), ZoneName(playerMap)))

    local shown = map and map:IsShown() and map.GetMapID and map:GetMapID()
    Say(format("  mapa abierto: %s", shown and format("%s (%s)", tostring(shown), ZoneName(shown)) or "cerrado"))

    Say(format("  marca: creada=%s mostrada=%s |cff8ad4ffefectiva=%s|r",
        pin and "si" or "|cffff5555NO|r",
        (pin and pin:IsShown()) and "si" or "no",
        (pin and pin.IsVisible and pin:IsVisible()) and "si" or "|cffff5555no|r"))

    if pin then
        Say(format("  nivel=%s estrato=%s alfa=%.2f escala=%.2f",
            tostring(pin:GetFrameLevel()), tostring(pin:GetFrameStrata()),
            pin:GetEffectiveAlpha() or -1, pin:GetEffectiveScale() or -1))

        local px, py = pin:GetCenter()
        local container = map and map.ScrollContainer
        local cx, cy
        if container then cx, cy = container:GetCenter() end

        if px and cx then
            local halfWidth = (container:GetWidth() or 0) / 2
            local halfHeight = (container:GetHeight() or 0) / 2
            local inside = math.abs(px - cx) <= halfWidth and math.abs(py - cy) <= halfHeight
            Say(format("  marca en %.0f,%.0f | ventana centro %.0f,%.0f | %s",
                px, py, cx, cy,
                inside and "|cff55ff55dentro de lo visible|r" or "|cffff5555FUERA de lo visible|r"))
        else
            Say(format("  posicion: marca=%s ventana=%s",
                px and "si" or "|cffff5555sin posicion|r", cx and "si" or "sin posicion"))
        end
    end

    local child = map and map.ScrollContainer and map.ScrollContainer.Child
    local container = map and map.ScrollContainer
    Say(format("  lienzo: %s | contenedor: %s",
        child and format("%.0f x %.0f", child:GetWidth() or 0, child:GetHeight() or 0) or "no existe",
        container and format("%.0f x %.0f", container:GetWidth() or 0, container:GetHeight() or 0) or "no existe"))

    if map then
        local _, width, height = CanvasFor(map)
        Say(format("  medida que se usa: %s",
            width and format("%.0f x %.0f", width, height) or "|cffff5555ninguna sirve|r"))
    end

    if not (map and map:IsShown()) then
        Say("  |cff999999(con el mapa cerrado estas medidas salen a cero; abrelo y repite)|r")
    end
end

local function HandleWay(msg)
    local text = strtrim(msg or "")
    local lowered = strlower(text)

    if lowered == "estado" then
        PrintState()
        return
    end

    if lowered == "" then
        Say("uso: |cffffd100/way 49.2 57.2|r (o |cffffd100/way borrar|r).")
        return
    end

    if lowered == "borrar" or lowered == "clear" or lowered == "quitar" then
        ClearWaypoint()
        return
    end

    local x, y, label, zone = ParseCoords(text)
    if not x then
        Say("no entiendo esas coordenadas. Prueba |cffffd100/way 49.2 57.2|r.")
        return
    end

    local uiMapID
    if zone ~= "" then
        local matches
        uiMapID, matches = FindZone(zone)
        if not uiMapID then
            if #matches == 0 then
                Say(format("no conozco ninguna zona llamada |cffffd100%s|r.", zone))
            else
                local names = {}
                for i, id in ipairs(matches) do
                    if i > 6 then break end
                    table.insert(names, ZoneName(id))
                end
                Say(format("|cffffd100%s|r encaja con varias zonas: %s. Escribe mas del nombre.",
                    zone, table.concat(names, ", ")))
            end
            return
        end
    end

    SetWaypoint(x, y, label, uiMapID)
end

local function HandleSlash(msg)
    local text = strtrim(msg or "")
    local cmd, arg = strsplit(" ", strlower(text), 2)

    if cmd == nil or cmd == "" then
        db.hud = not db.hud
        RefreshHUD()
        Say(db.hud and "recuadro visible." or "recuadro oculto.")

    elseif cmd == "way" then
        HandleWay(string.sub(text, 5))

    elseif cmd == "lock" then
        db.locked = not db.locked
        Say(db.locked and "recuadro fijado." or "recuadro suelto: arrastralo con el boton izquierdo.")

    elseif cmd == "reset" then
        db.point, db.relPoint = DEFAULTS.point, DEFAULTS.relPoint
        db.x, db.y, db.scale = DEFAULTS.x, DEFAULTS.y, DEFAULTS.scale
        ApplyHUDPosition()
        Say("recuadro devuelto arriba al centro.")

    elseif cmd == "pos" then
        Say(format("recuadro anclado por %s a %s de la pantalla, desplazado |cffffd100%.0f, %.0f|r.",
            tostring(db.point), tostring(db.relPoint), db.x, db.y))
        Say("se guarda al salir del juego, para este personaje, y vuelve sola al entrar.")

    elseif cmd == "scale" then
        local value = tonumber(arg)
        if value and value >= 0.5 and value <= 3 then
            db.scale = value
            ApplyHUDPosition()
            Say(format("tamano puesto a %.2f.", value))
        else
            Say("uso: /coords scale <0.5-3>")
        end

    elseif cmd == "map" then
        db.map = not db.map
        Say(db.map and "coordenadas del jugador en el mapa: si." or "coordenadas del jugador en el mapa: no.")

    elseif cmd == "cursor" then
        db.cursor = not db.cursor
        Say(db.cursor and "coordenadas del cursor: si." or "coordenadas del cursor: no.")

    else
        PrintHelp()
    end
end

-- ------------------------------------------------------------ arranque

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("VARIABLES_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == ADDON then
        CoordsForeverDB = CoordsForeverDB or {}
        db = CoordsForeverDB

        for key, value in pairs(DEFAULTS) do
            if db[key] == nil then db[key] = value end
        end

    elseif event == "VARIABLES_LOADED" then
        -- algunos clientes cargan las variables despues de ADDON_LOADED
        if CoordsForeverDB and CoordsForeverDB ~= db then
            db = CoordsForeverDB
            for key, value in pairs(DEFAULTS) do
                if db[key] == nil then db[key] = value end
            end
            if hud then ApplyHUDPosition() end
        end

    elseif event == "PLAYER_LOGIN" then
        BuildHUD()
        ApplyHUDPosition()

        -- el mapa puede cargarse mas tarde
        if _G.WorldMapFrame then
            BuildMapTexts()
        elseif EventUtil and EventUtil.ContinueOnAddOnLoaded then
            EventUtil.ContinueOnAddOnLoaded("Blizzard_WorldMap", BuildMapTexts)
        end

        driver = CreateFrame("Frame")
        driver:SetScript("OnUpdate", OnUpdate)
        RefreshHUD()

        SLASH_COORDSFOREVER1 = "/coords"
        SLASH_COORDSFOREVER2 = "/cf"
        SlashCmdList.COORDSFOREVER = HandleSlash

        SLASH_COORDSFOREVERWAY1 = "/way"
        SLASH_COORDSFOREVERWAY2 = "/ir"
        SlashCmdList.COORDSFOREVERWAY = HandleWay
    end
end)
