-- ============================================================================
-- ADDON: MinimapIconBag (Versión 3.3.5a) / SMMB
-- ============================================================================

local exclusionList = {
    ["MinimapZoneTextButton"]    = true,
    ["MinimapToggleButton"]      = true,
    ["MinimapZoomIn"]            = true,
    ["MinimapZoomOut"]           = true,
    ["MiniMapVoiceChatFrame"]    = true,
    ["GameTimeFrame"]            = true,
    ["MiniMapTracking"]          = true,
    ["MiniMapTrackingButton"]    = true,
    ["MiniMapMeetingStoneFrame"] = true,
    ["MiniMapMailFrame"]         = true,
    ["MiniMapBattlefieldFrame"]  = true,
    ["MiniMapWorldMapButton"]    = true,
    ["MinimapBackdrop"]          = true,
    ["MinimapPing"]              = true,
    ["MinimapCompassTexture"]    = true,
    ["TimeManagerClockButton"]   = true,
    ["MIB_MinimapButton"]        = true,
    ["GuildInstanceDifficulty"]  = true,
    ["MiniMapInstanceDifficulty"]= true,
}

local iconosRecolectados = {}
local iconosExcluidos = {}
local OrganizarIconos -- Declaración anticipada

local naerFamilyAddons = {}

local function EsNaerFamily(icono)
    local nombre = icono:GetName()
    if not nombre then return false end
    local nombreLower = nombre:lower()
    for addonName in pairs(naerFamilyAddons) do
        if nombreLower:find(addonName, 1, true) then
            return true
        end
    end
    return false
end

-- 1. CONTENEDOR PRINCIPAL
local BagFrame = CreateFrame("Frame", "MIB_ContainerFrame", UIParent)
BagFrame:SetSize(160, 40)
BagFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
BagFrame:SetMovable(true)
BagFrame:EnableMouse(true)
BagFrame:SetClampedToScreen(true)
BagFrame:RegisterForDrag("LeftButton")
BagFrame:SetScript("OnDragStart", function(self)
    if not MinimapIconBagDB.fijarVentana then
        self:StartMoving()
    end
end)
BagFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
BagFrame:SetScript("OnHide", function(self)
    self:StopMovingOrSizing()
    if OrganizarIconos then OrganizarIconos() end
end)
BagFrame:Hide()

local function ActualizarFondo()
    if MinimapIconBagDB.fondoTransparente then
        BagFrame:SetBackdrop(nil)
    else
        BagFrame:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
        BagFrame:SetBackdropColor(0, 0, 0, 0.9)
    end
end

-- Helper para ajustar texturas de los iconos según el estilo
local function AjustarTexturaIcono(region, redondo, tamanoIcono, icono)
    if not region or not region.ClearAllPoints then return end

    if not region.SMMB_OrigCoords then
        local coords = { region:GetTexCoord() }
        if #coords == 0 then
            coords = { 0, 1, 0, 1 }
        end
        region.SMMB_OrigCoords = coords
    end

    region:ClearAllPoints()
    if redondo then
        local inset = math.floor(tamanoIcono * 0.20)
        region:SetPoint("TOPLEFT", icono, "TOPLEFT", inset, -inset)
        region:SetPoint("BOTTOMRIGHT", icono, "BOTTOMRIGHT", -inset, inset)
        if region.SetTexCoord then
            region:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        end
        region.SMMB_ModifiedCoords = true
    else
        region:SetAllPoints(icono)
        -- Solo restauramos si han sido modificadas para no invocar SetTexCoord innecesariamente
        if region.SetTexCoord and region.SMMB_ModifiedCoords and region.SMMB_OrigCoords then
            region:SetTexCoord(unpack(region.SMMB_OrigCoords))
            region.SMMB_ModifiedCoords = nil
        end
    end
end

-- 2. FUNCIÓN PARA APLICAR EL ESTILO A LOS ICONOS
local function AplicarEstiloIcono(icono)
    local tamanoIcono = MinimapIconBagDB.tamanoIcono or 33
    local redondo = MinimapIconBagDB.iconosRedondos

    -- Borde circular tipo Blizzard
    if redondo then
        if not icono.SMMB_RoundBorder then
            icono.SMMB_RoundBorder = icono:CreateTexture(nil, "OVERLAY")
            icono.SMMB_RoundBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        end
        icono.SMMB_RoundBorder:SetSize(tamanoIcono * (54 / 33), tamanoIcono * (54 / 33))
        icono.SMMB_RoundBorder:ClearAllPoints()
        icono.SMMB_RoundBorder:SetPoint("TOPLEFT", icono, "TOPLEFT", 0, 0)
        icono.SMMB_RoundBorder:Show()
    else
        if icono.SMMB_RoundBorder then
            icono.SMMB_RoundBorder:Hide()
        end
    end

    local regiones = { icono:GetRegions() }
    for _, region in ipairs(regiones) do
        if region:IsObjectType("Texture") then
            local textura = region:GetTexture()
            if textura then
                local texStr = string.lower(textura)
                if texStr:find("border") or texStr:find("zoombutton") or texStr:find("tracking") or texStr:find("background") then
                    if redondo or MinimapIconBagDB.quitarMarcosIconos then
                        region:Hide()
                    else
                        region:Show()
                    end
                else
                    AjustarTexturaIcono(region, redondo, tamanoIcono, icono)
                end
            end
        end
    end

    -- Si es un botón, ajustamos texturas de estado
    if icono:IsObjectType("Button") then
        local nt = icono:GetNormalTexture()
        if nt then
            AjustarTexturaIcono(nt, redondo, tamanoIcono, icono)
        end
        
        local pt = icono:GetPushedTexture()
        if pt then
            AjustarTexturaIcono(pt, redondo, tamanoIcono, icono)
        end
        
        local ht = icono:GetHighlightTexture()
        if ht then
            ht:ClearAllPoints()
            if redondo then
                if not icono.SMMB_RoundHighlight then
                    icono.SMMB_RoundHighlight = icono:CreateTexture(nil, "HIGHLIGHT")
                    icono.SMMB_RoundHighlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
                    icono.SMMB_RoundHighlight:SetBlendMode("ADD")
                end
                icono.SMMB_RoundHighlight:SetAllPoints(icono)
                icono.SMMB_RoundHighlight:Show()
                ht:Hide()
            else
                if icono.SMMB_RoundHighlight then
                    icono.SMMB_RoundHighlight:Hide()
                end
                ht:SetAllPoints(icono)
                ht:Show()
            end
        end
    end
end

-- 3. ORGANIZAR ICONOS
function OrganizarIconos()
    local columnasMax = MinimapIconBagDB.columnasMax or 5
    local tamanoIcono = MinimapIconBagDB.tamanoIcono or 33
    local espX = MinimapIconBagDB.paddingX or 4
    local espY = MinimapIconBagDB.paddingY or 4

    local xOfs = MinimapIconBagDB.fondoTransparente and 0 or 12
    local yOfs = MinimapIconBagDB.fondoTransparente and 0 or -12

    local cuenta = 0

    for _, icono in ipairs(iconosRecolectados) do
        if icono.SMMB_IntendedShown then
            local ok = pcall(function()
                icono:SetParent(BagFrame)
                if icono.ClearAllPoints then
                    icono:ClearAllPoints()
                end

                AplicarEstiloIcono(icono)

                local fila = math.floor(cuenta / columnasMax)
                local col = cuenta % columnasMax

                if icono.SetSize then
                    -- Forzamos a que todos midan lo mismo para que no se superpongan
                    icono:SetSize(tamanoIcono, tamanoIcono)
                end

                if icono.SetPoint then
                    icono:SetPoint("TOPLEFT", BagFrame, "TOPLEFT", xOfs + (col * (tamanoIcono + espX)), yOfs - (fila * (tamanoIcono + espY)))
                end

                icono.SMMB_PreventHook = true
                if BagFrame:IsShown() then
                    icono:Show()
                else
                    icono:Hide()
                end
                icono.SMMB_PreventHook = nil
            end)
            if ok then
                cuenta = cuenta + 1
            end
        else
            icono.SMMB_PreventHook = true
            icono:Hide()
            icono.SMMB_PreventHook = nil
        end
    end

    if cuenta > 0 then
        local filas = math.ceil(cuenta / columnasMax)
        local colsReales = math.min(cuenta, columnasMax)
        local paddingExtra = MinimapIconBagDB.fondoTransparente and 0 or 24
        local ancho = (colsReales * tamanoIcono) + ((colsReales - 1) * espX) + paddingExtra
        local alto = (filas * tamanoIcono) + ((filas - 1) * espY) + paddingExtra
        BagFrame:SetSize(math.max(ancho, 30), math.max(alto, 30))
    else
        BagFrame:SetSize(30, 30)
    end
end

-- 3b. VINCULAR EXCLUSIÓN A UN ICONO
local function VincularExclusion(icono)
    if icono.SMMB_Hooked then return end

    -- Guardamos si el addon quiere que esté visible
    icono.SMMB_IntendedShown = icono:IsShown()

    hooksecurefunc(icono, "Show", function(self)
        if self.SMMB_PreventHook then return end
        self.SMMB_IntendedShown = true
        if OrganizarIconos then OrganizarIconos() end
    end)

    hooksecurefunc(icono, "Hide", function(self)
        if self.SMMB_PreventHook then return end
        self.SMMB_IntendedShown = false
        if OrganizarIconos then OrganizarIconos() end
    end)

    local origOnEnter = icono:GetScript("OnEnter")
    local origOnLeave = icono:GetScript("OnLeave")
    local esBoton = icono:IsObjectType("Button")
    local origOnClick = esBoton and icono:GetScript("OnClick")

    icono:SetScript("OnEnter", function(self)
        if origOnEnter then origOnEnter(self) end
        
        local nombreRaw = self:GetName() or "<sin nombre>"
        local nombreLimpio = nombreRaw
        
        -- Limpiar nombres técnicos feos de la API (ej. LibDBIcon10_Skada -> Skada)
        if nombreLimpio:match("LibDBIcon10_(.*)") then
            nombreLimpio = nombreLimpio:match("LibDBIcon10_(.*)")
        end
        nombreLimpio = nombreLimpio:gsub("MinimapButton", "")
        nombreLimpio = nombreLimpio:gsub("MinimapBtn", "")
        nombreLimpio = nombreLimpio:gsub("MinimapIcon", "")
        nombreLimpio = nombreLimpio:gsub("MinimapFrame", "")
        nombreLimpio = nombreLimpio:gsub("Button", "")
        nombreLimpio = nombreLimpio:gsub("Btn", "")
        nombreLimpio = nombreLimpio:gsub("_", " ")
        
        -- Si al limpiar borramos todo, restauramos el original
        if nombreLimpio:match("^%s*$") then
            nombreLimpio = nombreRaw
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(nombreLimpio, 1, 1, 0)
        GameTooltip:AddLine("Shift + Clic Derecho: excluir de SMMB", 0.5, 0.5, 0.5)
        -- Pequeño texto extra para debug si es necesario
        -- GameTooltip:AddLine(nombreRaw, 0.3, 0.3, 0.3)
        GameTooltip:Show()
    end)

    icono:SetScript("OnLeave", function(self)
        if origOnLeave then origOnLeave(self) end
        GameTooltip:Hide()
    end)

    if esBoton then
        icono:SetScript("OnClick", function(self, button, ...)
            if button == "RightButton" and IsShiftKeyDown() then
                local nombre = self:GetName()
                if not nombre then
                    print("|cFFFF6666[SMMB]|r Este icono no tiene nombre y no puede excluirse permanentemente.")
                    return
                end
                iconosExcluidos[nombre] = true
                for i, v in ipairs(iconosRecolectados) do
                    if v == self then
                        table.remove(iconosRecolectados, i)
                        break
                    end
                end
                if OrganizarIconos then OrganizarIconos() end
                print("|cFF00FF00[SMMB]|r Icono excluido: " .. nombre)
                return
            end
            if origOnClick then
                origOnClick(self, button, ...)
            end
        end)
    end

    icono.SMMB_Hooked = true
end

-- 4. ESCANEAR MINIMAPA
local function EscanearMinimapa()
    local hijos = { Minimap:GetChildren() }

    for _, objeto in ipairs(hijos) do
        local nombre = objeto:GetName()

        if (objeto:IsObjectType("Button") or objeto:IsObjectType("Frame")) then
            if (nombre and (exclusionList[nombre] or iconosExcluidos[nombre])) or objeto == MIB_MinimapButton or objeto == BagFrame then
                -- skip
            else
                local w, h = objeto:GetSize()
                local esTamanioIcono = (w and w >= 15 and w <= 50 and h and h >= 15 and h <= 50)
                local nombreValido = (nombre and (nombre:lower():match("button") or nombre:lower():match("icon") or nombre:lower():match("minimap")))

                if esTamanioIcono or nombreValido then
                    -- Solo recolectamos si el botón está visible en el minimapa (evita recolectar botones desactivados/ocultos)
                    if objeto:IsShown() then
                        local yaRegistrado = false
                        for _, v in ipairs(iconosRecolectados) do
                            if v == objeto then yaRegistrado = true; break end
                        end

                        if not yaRegistrado then
                            table.insert(iconosRecolectados, objeto)
                            VincularExclusion(objeto)
                        end
                    end
                end
            end
        end
    end

    -- Orden estable: familia Naer primero, preservando el orden interno de cada grupo
    local naerList, otherList = {}, {}
    for _, icono in ipairs(iconosRecolectados) do
        if EsNaerFamily(icono) then
            table.insert(naerList, icono)
        else
            table.insert(otherList, icono)
        end
    end
    iconosRecolectados = {}
    for _, icono in ipairs(naerList) do table.insert(iconosRecolectados, icono) end
    for _, icono in ipairs(otherList) do table.insert(iconosRecolectados, icono) end

    if OrganizarIconos then OrganizarIconos() end
end

local SMMB_Options

-- 5. BOTÓN INICIADOR
local BotonLanzador = CreateFrame("Button", "MIB_MinimapButton", Minimap)
BotonLanzador:SetSize(33, 33)
BotonLanzador:SetFrameStrata("HIGH")
BotonLanzador:SetFrameLevel(20)
BotonLanzador.Highlight = BotonLanzador:CreateTexture(nil, "HIGHLIGHT")
BotonLanzador.Highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
BotonLanzador.Highlight:SetBlendMode("ADD")
BotonLanzador.Highlight:SetAllPoints(BotonLanzador)

local iconoTex = BotonLanzador:CreateTexture(nil, "BACKGROUND")
iconoTex:SetTexture("Interface\\AddOns\\SMMB\\icon.tga")
iconoTex:SetSize(20, 20)
iconoTex:SetPoint("CENTER", BotonLanzador, "CENTER", -1, 1)

local bordeTex = BotonLanzador:CreateTexture(nil, "OVERLAY")
bordeTex:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
bordeTex:SetSize(54, 54)
bordeTex:SetPoint("TOPLEFT", BotonLanzador, "TOPLEFT", 0, 0)


local function ActualizarPosicionLanzador()
    local radio = 80
    local x = math.cos(math.rad(MinimapIconBagDB.angulo)) * radio
    local y = math.sin(math.rad(MinimapIconBagDB.angulo)) * radio
    BotonLanzador:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

BotonLanzador:RegisterForDrag("LeftButton")

BotonLanzador:SetScript("OnDragStart", function(self)
    if MinimapIconBagDB.fijarBoton then return end

    self:LockHighlight()
    self:SetScript("OnUpdate", function()
        local xpos, ypos = GetCursorPosition()
        local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()
        xpos = xmin - xpos / Minimap:GetEffectiveScale() + 70
        ypos = ypos / Minimap:GetEffectiveScale() - ymin - 70
        MinimapIconBagDB.angulo = math.deg(math.atan2(ypos, xpos))
        ActualizarPosicionLanzador()
    end)
end)

BotonLanzador:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
end)

BotonLanzador:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
        InterfaceOptionsFrame_OpenToCategory(SMMB_Options)
    else
        if BagFrame:IsShown() then
            BagFrame:Hide()
        else
            BagFrame:Show()
            EscanearMinimapa()
        end
    end
end)
BotonLanzador:RegisterForClicks("LeftButtonUp", "RightButtonUp")

BotonLanzador:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("SMMB", 1, 0.8, 0)
    GameTooltip:AddLine("Click Izquierdo: Abrir/Cerrar bolsa.", 1, 1, 1)
    GameTooltip:AddLine("Click Derecho: Abrir opciones.", 1, 1, 1)
    GameTooltip:AddLine("Arrastra: Mover este botón (si no está fijado).", 0.5, 0.5, 0.5)
    GameTooltip:AddLine("/smmb: Abrir opciones.", 0.5, 1, 0.5)
    GameTooltip:Show()
end)
BotonLanzador:SetScript("OnLeave", function() GameTooltip:Hide() end)


-- 6. MENÚ DE OPCIONES
SMMB_Options = CreateFrame("Frame", "SMMB_OptionsPanel", UIParent)
SMMB_Options.name = "SMMB"

local tituloOpts = SMMB_Options:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
tituloOpts:SetPoint("TOPLEFT", 16, -16)
tituloOpts:SetText("SMMB - Configuración")

local descOpts = SMMB_Options:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
descOpts:SetPoint("TOPLEFT", tituloOpts, "BOTTOMLEFT", 0, -8)
descOpts:SetText("Ajusta la apariencia del contenedor de iconos del minimapa.")

local function CrearCheckbox(nombre, padre, texto, tooltip, dbKey, onClickFunc)
    local cb = CreateFrame("CheckButton", nombre, padre, "InterfaceOptionsCheckButtonTemplate")
    _G[nombre .. "Text"]:SetText(texto)
    cb.tooltipText = tooltip
    cb:SetScript("OnClick", function(self)
        MinimapIconBagDB[dbKey] = self:GetChecked() and true or false
        if onClickFunc then onClickFunc() end
    end)
    return cb
end

local function CrearSlider(nombre, padre, texto, tooltip, minVal, maxVal, step, dbKey, onValueChangedFunc)
    local slider = CreateFrame("Slider", nombre, padre, "OptionsSliderTemplate")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider.tooltipText = tooltip

    _G[nombre .. "Low"]:SetText(tostring(minVal))
    _G[nombre .. "High"]:SetText(tostring(maxVal))

    slider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor((value / step) + 0.5) * step
        MinimapIconBagDB[dbKey] = rounded
        _G[nombre .. "Text"]:SetText(texto .. ": " .. rounded)
        if onValueChangedFunc then onValueChangedFunc() end
    end)
    return slider, texto
end

-- Columna izquierda: Checkboxes
local cbFondo = CrearCheckbox("SMMB_CbFondo", SMMB_Options, "Fondo transparente", "Oculta el recuadro negro detrás de los iconos.", "fondoTransparente", function()
    ActualizarFondo()
    OrganizarIconos()
end)
cbFondo:SetPoint("TOPLEFT", descOpts, "BOTTOMLEFT", 0, -20)

local cbMarcos = CrearCheckbox("SMMB_CbMarcos", SMMB_Options, "Ocultar marcos originales", "Esconde los bordes originales de los iconos.", "quitarMarcosIconos", function()
    OrganizarIconos()
end)
cbMarcos:SetPoint("TOPLEFT", cbFondo, "BOTTOMLEFT", 0, -10)

local cbRedondos = CrearCheckbox("SMMB_CbRedondos", SMMB_Options, "Iconos redondos (estilo Blizzard)", "Muestra los iconos con un marco circular similar al minimapa original.", "iconosRedondos", function()
    OrganizarIconos()
end)
cbRedondos:SetPoint("TOPLEFT", cbMarcos, "BOTTOMLEFT", 0, -10)

local cbFijarBoton = CrearCheckbox("SMMB_CbFijarBoton", SMMB_Options, "Fijar botón del minimapa", "Evita que puedas arrastrar el botón SMMB.", "fijarBoton", nil)
cbFijarBoton:SetPoint("TOPLEFT", cbRedondos, "BOTTOMLEFT", 0, -10)

local cbFijarVentana = CrearCheckbox("SMMB_CbFijarVentana", SMMB_Options, "Fijar ventana de iconos", "Evita que puedas mover el contenedor de iconos.", "fijarVentana", nil)
cbFijarVentana:SetPoint("TOPLEFT", cbFijarBoton, "BOTTOMLEFT", 0, -10)

local botonReset = CreateFrame("Button", "SMMB_BotonReset", SMMB_Options, "UIPanelButtonTemplate")
botonReset:SetSize(120, 25)
botonReset:SetPoint("TOPLEFT", cbFijarVentana, "BOTTOMLEFT", 0, -20)
botonReset:SetText("Resetear SMMB")
botonReset:SetScript("OnClick", function()
    iconosExcluidos = {}
    iconosRecolectados = {}
    MinimapIconBagDB.iconosExcluidos = {}
    print("|cFF00FF00[SMMB]|r Exclusiones limpiadas. Recolectando iconos...")
    EscanearMinimapa()
end)

local botonRecolectar = CreateFrame("Button", "SMMB_BotonRecolectar", SMMB_Options, "UIPanelButtonTemplate")
botonRecolectar:SetSize(120, 25)
botonRecolectar:SetPoint("TOPLEFT", botonReset, "BOTTOMLEFT", 0, -10)
botonRecolectar:SetText("Forzar recolección")
botonRecolectar:SetScript("OnClick", function()
    EscanearMinimapa()
    print("|cFFFFFF00[SMMB]|r Escaneo manual completado.")
end)

-- Columna derecha: Sliders
local sliderCols, txtCols = CrearSlider("SMMB_SliderCols", SMMB_Options, "Máximo de columnas", "Cantidad de iconos por fila.", 1, 15, 1, "columnasMax", OrganizarIconos)
sliderCols:SetPoint("TOPLEFT", descOpts, "BOTTOMLEFT", 250, -35)

local sliderPadX, txtPadX = CrearSlider("SMMB_SliderPadX", SMMB_Options, "Espaciado Horizontal", "Separación entre iconos hacia los lados.", -15, 20, 1, "paddingX", OrganizarIconos)
sliderPadX:SetPoint("TOPLEFT", sliderCols, "BOTTOMLEFT", 0, -30)

local sliderPadY, txtPadY = CrearSlider("SMMB_SliderPadY", SMMB_Options, "Espaciado Vertical", "Separación entre iconos hacia arriba/abajo.", -15, 20, 1, "paddingY", OrganizarIconos)
sliderPadY:SetPoint("TOPLEFT", sliderPadX, "BOTTOMLEFT", 0, -30)

local sliderSize, txtSize = CrearSlider("SMMB_SliderSize", SMMB_Options, "Tamaño de iconos", "Ajusta el tamaño de los iconos en el contenedor.", 16, 50, 1, "tamanoIcono", OrganizarIconos)
sliderSize:SetPoint("TOPLEFT", sliderPadY, "BOTTOMLEFT", 0, -30)

SMMB_Options:SetScript("OnShow", function(self)
    cbFondo:SetChecked(MinimapIconBagDB.fondoTransparente)
    cbMarcos:SetChecked(MinimapIconBagDB.quitarMarcosIconos)
    cbRedondos:SetChecked(MinimapIconBagDB.iconosRedondos)
    cbFijarBoton:SetChecked(MinimapIconBagDB.fijarBoton)
    cbFijarVentana:SetChecked(MinimapIconBagDB.fijarVentana)

    sliderCols:SetValue(MinimapIconBagDB.columnasMax)
    _G["SMMB_SliderColsText"]:SetText(txtCols .. ": " .. MinimapIconBagDB.columnasMax)

    sliderPadX:SetValue(MinimapIconBagDB.paddingX)
    _G["SMMB_SliderPadXText"]:SetText(txtPadX .. ": " .. MinimapIconBagDB.paddingX)

    sliderPadY:SetValue(MinimapIconBagDB.paddingY)
    _G["SMMB_SliderPadYText"]:SetText(txtPadY .. ": " .. MinimapIconBagDB.paddingY)

    sliderSize:SetValue(MinimapIconBagDB.tamanoIcono)
    _G["SMMB_SliderSizeText"]:SetText(txtSize .. ": " .. MinimapIconBagDB.tamanoIcono)
end)

InterfaceOptions_AddCategory(SMMB_Options)

SLASH_SMMB1 = "/smmb"
SlashCmdList["SMMB"] = function(msg)
    msg = string.trim(msg or "")
    if msg == "reset" then
        iconosExcluidos = {}
        iconosRecolectados = {}
        MinimapIconBagDB.iconosExcluidos = {}
        print("|cFF00FF00[SMMB]|r Exclusiones limpiadas. Recolectando iconos...")
        EscanearMinimapa()
        return
    end
    InterfaceOptionsFrame_OpenToCategory(SMMB_Options)
end


-- 7. EVENTOS
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EventFrame:RegisterEvent("ADDON_LOADED")

EventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "SMMB" then
        MinimapIconBagDB = MinimapIconBagDB or {}
        if MinimapIconBagDB.angulo == nil then MinimapIconBagDB.angulo = 225 end
        if MinimapIconBagDB.fondoTransparente == nil then MinimapIconBagDB.fondoTransparente = true end
        if MinimapIconBagDB.quitarMarcosIconos == nil then MinimapIconBagDB.quitarMarcosIconos = true end
        if MinimapIconBagDB.iconosRedondos == nil then MinimapIconBagDB.iconosRedondos = false end
        if MinimapIconBagDB.tamanoIcono == nil then MinimapIconBagDB.tamanoIcono = 33 end
        if MinimapIconBagDB.fijarBoton == nil then MinimapIconBagDB.fijarBoton = false end
        if MinimapIconBagDB.fijarVentana == nil then MinimapIconBagDB.fijarVentana = false end
        if MinimapIconBagDB.paddingX == nil then MinimapIconBagDB.paddingX = 4 end
        if MinimapIconBagDB.paddingY == nil then MinimapIconBagDB.paddingY = 4 end
        if MinimapIconBagDB.columnasMax == nil then MinimapIconBagDB.columnasMax = 5 end
        if MinimapIconBagDB.iconosExcluidos == nil then MinimapIconBagDB.iconosExcluidos = {} end

        for k, v in pairs(MinimapIconBagDB.iconosExcluidos) do
            iconosExcluidos[k] = v
        end

        -- Escanear todos los addons cargados para detectar la familia Naer dinámicamente
        for i = 1, GetNumAddOns() do
            local name = GetAddOnInfo(i)
            if name then
                local partOf = GetAddOnMetadata(name, "X-Part-Of")
                if partOf and partOf:find("Addon Naer") then
                    local lowerName = name:lower()
                    naerFamilyAddons[lowerName] = true
                    
                    -- Soporte para alias de botones que no coinciden con el nombre de carpeta
                    if lowerName == "bufos" then
                        naerFamilyAddons["rbc"] = true
                        naerFamilyAddons["raidbuffchecker"] = true
                    elseif lowerName == "naeritemcheck" then
                        naerFamilyAddons["nic"] = true
                        naerFamilyAddons["naeritemcheck"] = true
                    end
                end
            end
        end

        ActualizarFondo()
    elseif event == "PLAYER_ENTERING_WORLD" then
        ActualizarPosicionLanzador()

        local tiempoTranscurrido = 0
        local tiempoTotal = 0

        self:SetScript("OnUpdate", function(selfFrame, elapsed)
            tiempoTranscurrido = tiempoTranscurrido + elapsed
            tiempoTotal = tiempoTotal + elapsed

            if tiempoTranscurrido >= 3.0 then
                EscanearMinimapa()
                tiempoTranscurrido = 0
            end

            if tiempoTotal >= 30.0 then
                selfFrame:SetScript("OnUpdate", nil)
            end
        end)
    end
end)
