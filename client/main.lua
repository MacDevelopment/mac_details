local lib = exports.ox_lib
local details = {}
local activeTextTimers = {}
local holdingGTimers = {}
local holdingBackspaceTimers = {}
local arrowDict, arrowTex = "commonmenu", "arrowleft"

CreateThread(function()
    RequestStreamedTextureDict(arrowDict, true)
    while not HasStreamedTextureDictLoaded(arrowDict) do
        Wait(0)
    end
end)

RegisterCommand(Config.CommandName or 'detail', function(_, args)
    local text = table.concat(args, ' ')
    if text == '' then
        TriggerEvent('chat:addMessage', {
            args = { '^1Usage', '/detail [your detail text]' }
        })
        return
    end

    local placing = true
    CreateThread(function()
        while placing do
            Wait(0)
            local fwd = RaycastFromCamera()
            if not fwd then return end

            DrawText3D(fwd.x, fwd.y, fwd.z + 0.5, '?\nPress Enter to place')

            if IsControlJustPressed(0, 191) then
                TriggerServerEvent('detail:add', { coords = fwd, text = text })
                placing = false
            end
        end
    end)
end)

RegisterNetEvent('detail:syncAll', function(data) details = data end)
TriggerServerEvent('detail:requestSync')

CreateThread(function()
    while true do
        Wait(0)
        local ped   = PlayerPedId()
        local pos   = GetEntityCoords(ped)
        local myId  = GetPlayerServerId(PlayerId())
        local nearAny = false

        for id, v in pairs(details) do
            local dPos = vector3(v.coords.x, v.coords.y, v.coords.z)
            local dist = #(pos - dPos)

            if dist < Config.UsageDistance then
                nearAny = true
                local canRemove = not Config.OwnerOnlyRemove or v.owner == myId
                if not activeTextTimers[id] then
                    DrawText3D(dPos.x, dPos.y, dPos.z + 0.5, '?')
                    DrawGHintProgress(0)
                    if canRemove then
                        DrawBackspaceHint(0)
                    end
                end

                if not holdingGTimers[id] then
                    holdingGTimers[id] = 0
                end
                if IsControlPressed(0, Config.HoldToViewKey) then
                    if holdingGTimers[id] == 0 then
                        holdingGTimers[id] = GetGameTimer()
                    end
                    local heldTime = GetGameTimer() - holdingGTimers[id]
                    local progress = math.min(heldTime / Config.ViewHoldDuration, 1.0)
                    DrawGHintProgress(progress)

                    if heldTime >= Config.ViewHoldDuration and not activeTextTimers[id] then
                        activeTextTimers[id] = true
                        CreateThread(function()
                            local t0 = GetGameTimer()
                            while GetGameTimer() - t0 < Config.TextDuration do
                                Wait(0)
                                DrawText3D(dPos.x, dPos.y, dPos.z + 1.0, v.text)
                            end
                            activeTextTimers[id] = nil
                            holdingGTimers[id] = 0
                        end)
                    end
                else
                    holdingGTimers[id] = 0
                end

                if canRemove then
                    if not holdingBackspaceTimers[id] then
                        holdingBackspaceTimers[id] = 0
                    end
                    if IsControlPressed(0, Config.HoldToRemoveKey) then
                        if holdingBackspaceTimers[id] == 0 then
                            holdingBackspaceTimers[id] = GetGameTimer()
                        end
                        local heldTime = GetGameTimer() - holdingBackspaceTimers[id]
                        local progress = math.min(heldTime / Config.HoldDuration, 1.0)
                        DrawBackspaceHint(progress)

                        if heldTime >= Config.HoldDuration then
                            TriggerServerEvent('detail:remove', id)
                            holdingBackspaceTimers[id] = 0
                        end
                    else
                        holdingBackspaceTimers[id] = 0
                    end
                end
            end
        end

        if not nearAny then
            DrawGHintProgress(-1)
        end
    end
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(Config.TextScale, Config.TextScale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function DrawSquareProgress(x, y, size, progress)
    if progress <= 0 then return end
    progress = math.min(progress, 1.0)
    local thickness = 0.003                   
    local perimeter = size * 4
    local drawLen = perimeter * progress
    local remaining = drawLen

    if remaining > 0 then
        local topLen = math.min(size, remaining)
        DrawRect(
            x - size/2 + topLen/2,
            y - size/2,
            topLen,
            thickness,
            255, 255, 255, 255
        )
        remaining = remaining - topLen
    end

    if remaining > 0 then
        local rightLen = math.min(size, remaining)
        DrawRect(
            x + size/2,
            y - size/2 + rightLen/2,
            thickness,
            rightLen,
            255, 255, 255, 255
        )
        remaining = remaining - rightLen
    end

    if remaining > 0 then
        local bottomLen = math.min(size, remaining)
        DrawRect(
            x + size/2 - bottomLen/2,
            y + size/2,
            bottomLen,
            thickness,
            255, 255, 255, 255
        )
        remaining = remaining - bottomLen
    end

    if remaining > 0 then
        local leftLen = math.min(size, remaining)
        DrawRect(
            x - size/2,
            y + size/2 - leftLen/2,
            thickness,
            leftLen,
            255, 255, 255, 255
        )
        remaining = remaining - leftLen
    end
end

function DrawGHintProgress(progress)
    if progress < 0 then return end

    local x, y = 0.92, 0.95
    local size = 0.03

    DrawRect(x, y, size, size, 0, 0, 0, 180)

    if progress > 0 then
        DrawSquareProgress(x, y, size, progress)
    end

    SetTextFont(4)
    SetTextScale(0.4, 0.4)
    SetTextCentre(true)
    SetTextColour(255, 255, 255, 255)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName("G")
    EndTextCommandDisplayText(x, y - 0.012)

    SetTextFont(4)
    SetTextScale(0.35, 0.35)
    SetTextCentre(false)
    SetTextColour(255, 255, 255, 255)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName("View Detail:")
    EndTextCommandDisplayText(x - 0.055, y - 0.01)
end

function DrawBackspaceHint(progress)
    if progress < 0 then return end

    local x, y = 0.92, 0.90
    local size = 0.03

    DrawRect(x, y, size, size, 0, 0, 0, 180)

    if progress > 0 then
        DrawSquareProgress(x, y, size, progress)
    end

    DrawSprite("commonmenu", "arrowleft",
               x, y - 0.001,
               size * 0.6, size * 0.6,
               0.0, 255, 255, 255, 255)

    SetTextFont(4)
    SetTextScale(0.35, 0.35)
    SetTextCentre(false)
    SetTextColour(255, 255, 255, 255)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName("Remove Detail:")
    EndTextCommandDisplayText(x - 0.07, y - 0.01)
end

function RaycastFromCamera()
    local camRot = GetGameplayCamRot(2)
    local camPos = GetGameplayCamCoord()
    local direction = RotationToDirection(camRot)
    local destination = camPos + direction * 10.0
    local rayHandle = StartShapeTestRay(camPos, destination, -1, -1, 0)
    local _, hit, endCoords = GetShapeTestResult(rayHandle)
    if hit == 1 then return endCoords else return nil end
end

function RotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local cosX = math.abs(math.cos(x))
    return vec3(-math.sin(z) * cosX, math.cos(z) * cosX, math.sin(x))
end
