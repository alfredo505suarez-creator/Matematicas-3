local tiempo = 0.25

local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "EstadoMatematico"
gui.ResetOnSpawn = false
gui.Parent = pg
local label = Instance.new("TextLabel", gui)
label.Size = UDim2.new(0, 360, 0, 40)
label.Position = UDim2.new(0.5, -180, 0.05, 0)
label.BackgroundTransparency = 0.4
label.TextColor3 = Color3.new(1,1,1)
label.TextScaled = true
label.Text = "Listo"

local function extraerNumeros(t)
    local nums = {}
    for n in string.gmatch(t, "%-?%d+") do
        table.insert(nums, tonumber(n))
    end
    return nums
end

local ops = {
    ["+"] = function(a,b) return a+b end,
    ["-"] = function(a,b) return a-b end,
    ["*"] = function(a,b) return a*b end,
    ["/"] = function(a,b) if b==0 then return nil end return a/b end,
    ["^"] = function(a,b) return a^b end,
    ["%"] = function(a,b) if b==0 then return nil end return a%b end
}

local function evalExp(t)
    t = t:gsub("%s+", "")
    local a,op,b = t:match("^(%-?%d+)([%+%-%*%/%^%%])(%-?%d+)$")
    if a and op and b and ops[op] then
        return ops[op](tonumber(a), tonumber(b))
    end
    return nil
end

local function siguienteDeSucesion(nums)
    if #nums < 2 then return nil end
    local d = nums[2] - nums[1]
    local arit = true
    for i=2,#nums-1 do
        if nums[i+1] - nums[i] ~= d then arit = false break end
    end
    if arit then return nums[#nums] + d end

    if nums[1] == 0 then return nil end
    local r = nums[2] / nums[1]
    local geom = true
    for i=2,#nums-1 do
        if nums[i] == 0 or math.abs((nums[i+1] / nums[i]) - r) > 1e-6 then geom = false break end
    end
    if geom then return nums[#nums] * r end

    return nil
end

local function encontrarPregunta()
    local candidatos = {}
    for _,d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            local txt = tostring(d.Text or "")
            if txt and #txt > 0 then
                if txt:find("%?") or txt:find("[%+%-%*%/%^%%]") or txt:find(",") or txt:find("=") then
                    table.insert(candidatos, {obj=d, text=txt})
                end
            end
        end
    end
    table.sort(candidatos, function(a,b) return #a.text > #b.text end)
    return candidatos[1]
end

local vim = game:GetService("VirtualInputManager")
local function pulsarRespuesta(valor)
    valor = tostring(valor)
    for _,d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextButton") then
            local txt = tostring(d.Text or "")
            if txt == valor then
                label.Text = "Respondiendo: "..valor
                wait(tiempo)
                pcall(function() d:Activate() end)
                local abs = d.AbsolutePosition
                local size = d.AbsoluteSize
                local cx, cy = abs.X + size.X/2, abs.Y + size.Y/2
                vim:SendMouseButtonEvent(cx, cy, 0, true, d, 0)
                vim:SendMouseButtonEvent(cx, cy, 0, false, d, 0)
                return true
            end
        end
    end
    return false
end

local function resolver(texto)
    texto = texto:gsub("¡.-!", ""):gsub("!", "")
    local v = evalExp(texto)
    if v ~= nil then return v end

    local nums = extraerNumeros(texto)
    local s = siguienteDeSucesion(nums)
    if s ~= nil then return s end

    local before, after = texto:match("^(.-)=(.-)$")
    if before then
        local val = evalExp(before)
        if val ~= nil then
            if after:find("%?") then return val end
        end
    end

    return nil
end

spawn(function()
    while true do
        local p = encontrarPregunta()
        if p then
            label.Text = "Leyendo..."
            local ans = resolver(p.text)
            if ans ~= nil then
                label.Text = "Respuesta: "..tostring(ans)
                pulsarRespuesta(ans)
            else
                label.Text = "No se pudo resolver"
            end
        else
            label.Text = "Esperando pregunta..."
        end
        wait(tiempo)
    end
end)
