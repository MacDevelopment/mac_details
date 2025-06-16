local details = {}
local detailsLoaded = false

local function loadDetails()
    exports.oxmysql:execute('SELECT * FROM detail_markers', {}, function(result)
        for _, row in pairs(result) do
            details[row.id] = {
                id = row.id,
                text = row.text,
                coords = vector3(tonumber(row.x), tonumber(row.y), tonumber(row.z)),
                owner = row.owner
            }
        end
        detailsLoaded = true
        print("[mac_details] Details loaded from database.")
    end)
end

local function saveDetail(id, data)
    exports.oxmysql:execute(
        'REPLACE INTO detail_markers (id, text, x, y, z, owner) VALUES (?, ?, ?, ?, ?, ?)',
        { id, data.text, data.coords.x, data.coords.y, data.coords.z, data.owner }
    )
end

local function deleteDetail(id)
    exports.oxmysql:execute('DELETE FROM detail_markers WHERE id = ?', { id })
end

RegisterNetEvent('detail:requestSync', function()
    TriggerClientEvent('detail:syncAll', source, details)
end)

RegisterNetEvent('detail:add', function(data)
    if not detailsLoaded then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1ERROR', 'Details are still loading. Please try again shortly.' } })
        return
    end
    data.owner = source
    if type(data.coords) ~= "vector3" then
        data.coords = vector3(tonumber(data.coords.x), tonumber(data.coords.y), tonumber(data.coords.z))
    end
    exports.oxmysql:execute(
        'INSERT INTO detail_markers (text, x, y, z, owner) VALUES (?, ?, ?, ?, ?)',
        { data.text, data.coords.x, data.coords.y, data.coords.z, data.owner },
        function(result)
            if not result or not result.insertId then
                print('[mac_details] Error: Failed to insert new detail into DB.')
                TriggerClientEvent('chat:addMessage', source, { args = { '^1ERROR', 'Failed to save detail. Please try again.' } })
                return
            end
            local id = result.insertId
            data.id = id
            details[id] = {
                id = id,
                text = data.text,
                coords = data.coords,
                owner = data.owner
            }
            TriggerClientEvent('detail:syncAll', -1, details)
        end
    )
end)

RegisterNetEvent('detail:remove', function(id)
    if not detailsLoaded then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1ERROR', 'Details are still loading. Please try again shortly.' } })
        return
    end
    local src = source
    if details[id] then
        if details[id].owner == src or hasAdminPermission(src) then
            details[id] = nil
            deleteDetail(id)
            TriggerClientEvent('chat:addMessage', src, { args = { '^2SUCCESS', 'Detail removed.' } })
            TriggerClientEvent('detail:syncAll', -1, details)
        else
            TriggerClientEvent('chat:addMessage', src, { args = { '^1ERROR', 'You do not have permission to remove this detail.' } })
        end
    end
end)

local function hasAdminPermission(src)
    return IsPlayerAceAllowed(src, "admin")
end

RegisterCommand('cleardetail', function(source, args)
    if not detailsLoaded then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1ERROR', 'Details are still loading. Please try again shortly.' } })
        return
    end
    if not hasAdminPermission(source) then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1ERROR', 'You do not have permission to use this command.' } })
        return
    end
    local id = args[1]
    if not id or not details[id] then
        return
    end
    details[id] = nil
    deleteDetail(id)
    TriggerClientEvent('chat:addMessage', source, { args = { '^2SUCCESS', 'Detail removed.' } })
    TriggerClientEvent('detail:syncAll', -1, details)
end, false)

loadDetails()
