-- Estilo Forever: cristal oscuro, rayas de bronce, botones con relieve y brillo dorado.
-- Todo con la textura blanca del juego, sin imagenes propias.

local _, ns = ...

local S = {}
ns.style = S

local WHITE = "Interface\\Buttons\\WHITE8X8"
local FONT = "Fonts\\MORPHEUS.TTF"
-- Morpheus solo tiene letras latinas
local LATIN = { enUS = true, enGB = true, esES = true, esMX = true, deDE = true, frFR = true, itIT = true, ptBR = true }

S.colors = {
    border = { 0.50, 0.37, 0.18 },
    face   = { 0.055, 0.052, 0.048 },
    button = { 0.13, 0.12, 0.105 },
    hover  = { 0.19, 0.17, 0.13 },
    box    = { 0.035, 0.034, 0.03 },
    edge   = { 0.98, 0.84, 0.47 },
    inner  = { 0.73, 0.57, 0.17 },
    gold   = { 1, 0.82, 0 },
    title  = { 1, 0.86, 0.45 },
    text   = { 0.92, 0.90, 0.86 },
    dim    = { 0.55, 0.53, 0.50 },
}
local C = S.colors

S.TICK = "|TInterface\\Buttons\\UI-CheckBox-Check:18:18|t"

function S.Plain(parent, layer, sub)
    local t = parent:CreateTexture(nil, layer or "BORDER", nil, sub or 0)
    t:SetTexture(WHITE)
    return t
end

function S.Gradient(t, orientation, r1, g1, b1, a1, r2, g2, b2, a2)
    if t.SetGradient and CreateColor then
        t:SetGradient(orientation, CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
    elseif t.SetGradientAlpha then
        t:SetGradientAlpha(orientation, r1, g1, b1, a1, r2, g2, b2, a2)
    else
        t:SetVertexColor(r1, g1, b1, (a1 + a2) / 2)
    end
end

-- cuatro rayas de un pixel, a "inset" del borde
function S.Lines(frame, inset, layer, sub)
    inset = inset or 0
    local lines = {}
    local sides = {
        { "TOPLEFT", inset, -inset, "TOPRIGHT", -inset, -inset, true },
        { "BOTTOMLEFT", inset, inset, "BOTTOMRIGHT", -inset, inset, true },
        { "TOPLEFT", inset, -inset, "BOTTOMLEFT", inset, inset },
        { "TOPRIGHT", -inset, -inset, "BOTTOMRIGHT", -inset, inset },
    }
    for _, e in ipairs(sides) do
        local line = S.Plain(frame, layer or "BORDER", sub)
        line:SetPoint(e[1], e[2], e[3])
        line:SetPoint(e[4], e[5], e[6])
        if e[7] then line:SetHeight(1) else line:SetWidth(1) end
        table.insert(lines, line)
    end
    function lines:SetColor(r, g, b, a)
        for _, line in ipairs(self) do line:SetVertexColor(r, g, b, a or 1) end
    end
    lines:SetColor(C.border[1], C.border[2], C.border[3])
    return lines
end

-- encabezado con la letra de los titulos de mision
function S.Header(fs, size)
    if LATIN[(GetLocale and GetLocale()) or "enUS"] then
        fs:SetFont(FONT, size, "")
    end
    fs:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetShadowOffset(1, -1)
    return fs
end

function S.FadeIn(frame, duration, fromScale)
    if not frame.fadeIn then
        local group = frame:CreateAnimationGroup()
        local alpha = group:CreateAnimation("Alpha")
        alpha:SetFromAlpha(0)
        alpha:SetToAlpha(1)
        alpha:SetDuration(duration)
        alpha:SetSmoothing("OUT")
        if fromScale then
            local scale = group:CreateAnimation("Scale")
            scale:SetDuration(duration)
            scale:SetSmoothing("OUT")
            if scale.SetScaleFrom then
                scale:SetScaleFrom(fromScale, fromScale)
                scale:SetScaleTo(1, 1)
            else
                scale:SetScale(1 / fromScale, 1 / fromScale)
            end
            if scale.SetOrigin then scale:SetOrigin("CENTER", 0, 0) end
        end
        frame.fadeIn = group
    end
    frame.fadeIn:Stop()
    frame.fadeIn:Play()
end

-- raya dorada que se apaga hacia los lados
local function Fading(frame, layer, y, width, height, alpha, add)
    for half = 1, 2 do
        local t = S.Plain(frame, layer, 4)
        t:SetSize(width / 2, height)
        t:SetPoint(half == 1 and "TOPRIGHT" or "TOPLEFT", frame, "TOP", 0, y)
        if add then t:SetBlendMode("ADD") end
        if half == 1 then S.Gradient(t, "HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, alpha)
        else S.Gradient(t, "HORIZONTAL", 1, 0.82, 0, alpha, 1, 0.82, 0, 0) end
    end
end

-- ventana: borde, cristal, bordes oscuros, raya de bronce por dentro y titulo
function S.Window(frame, title, ruleY)
    local edge = S.Lines(frame, 0, "BACKGROUND")
    local edge2 = S.Lines(frame, 1, "BACKGROUND")
    edge2:SetColor(0, 0, 0, 0.8)

    local face = S.Plain(frame, "BACKGROUND", -1)
    face:SetPoint("TOPLEFT", 2, -2)
    face:SetPoint("BOTTOMRIGHT", -2, 2)
    face:SetVertexColor(C.face[1], C.face[2], C.face[3], 0.97)

    local glass = S.Plain(frame, "BORDER", 1)
    glass:SetPoint("TOPLEFT", 2, -2)
    glass:SetPoint("BOTTOMRIGHT", -2, 2)
    S.Gradient(glass, "VERTICAL", 0, 0, 0, 0.30, 1, 0.90, 0.70, 0.05)

    local size = 40
    for _, side in ipairs({ "LEFT", "RIGHT", "TOP", "BOTTOM" }) do
        local v = S.Plain(frame, "BORDER", 2)
        if side == "LEFT" or side == "RIGHT" then
            local x = side == "LEFT" and 2 or -2
            v:SetPoint("TOP" .. side, x, -2)
            v:SetPoint("BOTTOM" .. side, x, 2)
            v:SetWidth(size)
            if side == "LEFT" then S.Gradient(v, "HORIZONTAL", 0, 0, 0, 0.40, 0, 0, 0, 0)
            else S.Gradient(v, "HORIZONTAL", 0, 0, 0, 0, 0, 0, 0, 0.40) end
        else
            local y = side == "TOP" and -2 or 2
            v:SetPoint(side .. "LEFT", 2, y)
            v:SetPoint(side .. "RIGHT", -2, y)
            v:SetHeight(size)
            if side == "TOP" then S.Gradient(v, "VERTICAL", 0, 0, 0, 0, 0, 0, 0, 0.40)
            else S.Gradient(v, "VERTICAL", 0, 0, 0, 0.40, 0, 0, 0, 0) end
        end
    end

    local inner = S.Lines(frame, 5, "BORDER", 3)
    inner:SetColor(C.inner[1], C.inner[2], C.inner[3], 0.30)

    local width = frame:GetWidth()
    Fading(frame, "BORDER", -6, math.min(320, width - 20), 26, 0.10, true)
    if ruleY then Fading(frame, "ARTWORK", ruleY, width - 24, 1, 0.55) end

    local text = S.Header(frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"), 18)
    text:SetPoint("TOP", 0, -10)
    text:SetTextColor(C.title[1], C.title[2], C.title[3])
    text:SetText(title)

    frame:HookScript("OnShow", function(self) S.FadeIn(self, 0.18, 0.97) end)
    return text
end

-- recuadro hundido para listas
function S.Inset(parent, region)
    local face = S.Plain(parent, "BACKGROUND", 1)
    face:SetPoint("TOPLEFT", region, "TOPLEFT", 1, -1)
    face:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT", -1, 1)
    face:SetVertexColor(C.box[1], C.box[2], C.box[3], 0.92)
    local shade = S.Plain(parent, "BACKGROUND", 2)
    shade:SetPoint("TOPLEFT", region, "TOPLEFT", 1, -1)
    shade:SetPoint("TOPRIGHT", region, "TOPRIGHT", -1, -1)
    shade:SetHeight(10)
    S.Gradient(shade, "VERTICAL", 0, 0, 0, 0, 0, 0, 0, 0.45)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetAllPoints(region)
    holder:EnableMouse(false)
    local lines = S.Lines(holder, 0, "BACKGROUND")
    lines:SetColor(C.border[1], C.border[2], C.border[3], 0.60)
    return face
end

-- boton: relieve, sombra debajo y brillo dorado con el raton encima
function S.Button(btn)
    local face = S.Plain(btn, "BACKGROUND", 0)
    face:SetPoint("TOPLEFT", 1, -1)
    face:SetPoint("BOTTOMRIGHT", -1, 1)
    face:SetVertexColor(C.button[1], C.button[2], C.button[3])
    local lines = S.Lines(btn, 0, "BORDER", 0)

    local shade = S.Plain(btn, "BORDER", 1)
    shade:SetPoint("TOPLEFT", 1, -1)
    shade:SetPoint("BOTTOMRIGHT", -1, 1)
    local gloss = S.Plain(btn, "BORDER", 2)
    gloss:SetPoint("TOPLEFT", 1, -1)
    gloss:SetPoint("TOPRIGHT", -1, -1)
    gloss:SetHeight(1)
    gloss:SetVertexColor(1, 0.90, 0.74, 0.16)
    local drop = S.Plain(btn, "BACKGROUND", -2)
    drop:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 1, 0)
    drop:SetPoint("TOPRIGHT", btn, "BOTTOMRIGHT", -1, 0)
    drop:SetHeight(1)
    drop:SetVertexColor(0, 0, 0, 0.55)
    local wash = S.Plain(btn, "ARTWORK", -1)
    wash:SetPoint("TOPLEFT", 1, -1)
    wash:SetPoint("BOTTOMRIGHT", -1, 1)
    wash:SetBlendMode("ADD")
    S.Gradient(wash, "VERTICAL", 1, 0.82, 0, 0.18, 1, 0.82, 0, 0.03)
    wash:Hide()

    local function Press(down)
        if down then
            S.Gradient(shade, "VERTICAL", 1, 1, 1, 0.05, 0, 0, 0, 0.40)
        else
            S.Gradient(shade, "VERTICAL", 0, 0, 0, 0.40, 1, 1, 1, 0.05)
        end
        gloss:SetShown(not down)
    end
    Press(false)

    btn:HookScript("OnEnter", function()
        face:SetVertexColor(C.hover[1], C.hover[2], C.hover[3])
        lines:SetColor(C.edge[1], C.edge[2], C.edge[3])
        wash:Show()
    end)
    btn:HookScript("OnLeave", function()
        face:SetVertexColor(C.button[1], C.button[2], C.button[3])
        lines:SetColor(C.border[1], C.border[2], C.border[3])
        wash:Hide()
        Press(false)
    end)
    btn:HookScript("OnMouseDown", function() Press(true) end)
    btn:HookScript("OnMouseUp", function() Press(false) end)
    return btn
end

-- casilla: hueco oscuro con borde de bronce, dorado con el raton encima
function S.Check(check)
    local face = S.Plain(check, "BACKGROUND", 0)
    face:SetPoint("TOPLEFT", 1, -1)
    face:SetPoint("BOTTOMRIGHT", -1, 1)
    face:SetVertexColor(C.box[1], C.box[2], C.box[3])
    local shade = S.Plain(check, "BORDER", 1)
    shade:SetPoint("TOPLEFT", 1, -1)
    shade:SetPoint("BOTTOMRIGHT", -1, 1)
    S.Gradient(shade, "VERTICAL", 1, 1, 1, 0.03, 0, 0, 0, 0.35)
    local lines = S.Lines(check, 0, "BORDER", 0)
    check:HookScript("OnEnter", function() lines:SetColor(C.edge[1], C.edge[2], C.edge[3]) end)
    check:HookScript("OnLeave", function() lines:SetColor(C.border[1], C.border[2], C.border[3]) end)
    return check
end

-- marco de los botones de icono: borde de bronce, sombra y brillo dorado con el raton encima
function S.IconFrame(button)
    local back = S.Plain(button, "BACKGROUND", -1)
    back:SetPoint("TOPLEFT", -3, 3)
    back:SetPoint("BOTTOMRIGHT", 3, -3)
    back:SetVertexColor(0, 0, 0, 0.85)
    local holder = CreateFrame("Frame", nil, button)
    holder:SetPoint("TOPLEFT", -2, 2)
    holder:SetPoint("BOTTOMRIGHT", 2, -2)
    holder:SetFrameLevel(button:GetFrameLevel() + 1)
    holder:EnableMouse(false)
    local lines = S.Lines(holder, 0, "OVERLAY")
    local inner = S.Plain(holder, "OVERLAY", -1)
    inner:SetPoint("TOPLEFT", 2, -2)
    inner:SetPoint("BOTTOMRIGHT", -2, 2)
    S.Gradient(inner, "VERTICAL", 0, 0, 0, 0.35, 0, 0, 0, 0)
    local glow = holder:CreateTexture(nil, "OVERLAY", nil, 1)
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 0.9)
    glow:SetPoint("CENTER")
    glow:SetSize(button:GetWidth() * 1.8, button:GetHeight() * 1.8)
    glow:Hide()
    button:HookScript("OnEnter", function()
        lines:SetColor(C.edge[1], C.edge[2], C.edge[3])
        glow:Show()
    end)
    button:HookScript("OnLeave", function()
        lines:SetColor(C.border[1], C.border[2], C.border[3])
        glow:Hide()
    end)
    return holder
end

-- botoncito de esquina (cerrar, vetar, opciones)
function S.Corner(btn)
    local back = S.Plain(btn, "BACKGROUND", 0)
    back:SetAllPoints()
    S.Gradient(back, "VERTICAL", 0.04, 0.04, 0.035, 0.95, 0.14, 0.13, 0.11, 0.95)
    local lines = S.Lines(btn, 0, "BORDER")
    btn:HookScript("OnEnter", function() lines:SetColor(C.edge[1], C.edge[2], C.edge[3]) end)
    btn:HookScript("OnLeave", function() lines:SetColor(C.border[1], C.border[2], C.border[3]) end)
    return btn
end
