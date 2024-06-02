-- Hent QBCore
local QBCore = exports['qb-core']:GetCoreObject()

-- Biler og items variabler
local carCategories = {"Compacts", "Coupes", "Muscle", "Off-road", "Sedans", "Sports", "Sports Classics", "SUVs"}
local items = {"metalscrap", "plastic", "copper", "iron", "aluminum", "steel", "glass", "rubber", "stoff"}

local currentCarCategory = nil
local lastChangeTime = nil

local classToCategory = {
    [0] = "Compacts",
    [1] = "Sedans",
    [2] = "SUVs",
    [3] = "Coupes",
    [4] = "Muscle",
    [5] = "Sports Classics",
    [6] = "Sports",
    [7] = "Super",
    [8] = "Motorcycles",
    [9] = "Off-road",
    [10] = "Industrial",
    [11] = "Utility",
    [12] = "Vans",
    [13] = "Cycles",
    [14] = "Boats",
    [15] = "Helicopters",
    [16] = "Planes",
    [17] = "Service",
    [18] = "Emergency",
    [19] = "Military",
    [20] = "Commercial",
    [21] = "Trains"
}

local function GetVehicleCategory(vehicle)
    local class = GetVehicleClass(vehicle)
    return classToCategory[class]
end

-- Velg randome items
local function chooseRandomItem(table)
    local keys = {}
    for key, value in pairs(table) do
        keys[#keys + 1] = key
    end
    return table[keys[math.random(1, #keys)]]
end

-- Oppdater bilkategori vær andre time
local function updateCarCategory()
    local currentTime = GetGameTimer() / 1000
    if lastChangeTime == nil or (currentTime - lastChangeTime >= 2 * 60 * 60) then
        currentCarCategory = chooseRandomItem(carCategories)
        lastChangeTime = currentTime
    end
end




local function SpawnPed()

    exports['ox_target']:addSphereZone({
        coords = vector3(2403.54, 3127.79, 48.15),
        radius = 2.0,
        debug = false,
        options = {
            {
                icon = 'fas fa-car',
                iconColor = 'white',
                label = 'Start skrapejobb',
                distance = 1.5,
                event = 'nxt-chopshop:interactWithPed' 
            }
        }
    })
end


-- Notifikasjoner
local function interactWithPed()
    updateCarCategory()

    lib.notify({
        title = "Hent "..currentCarCategory.."",
        description = 'Biltypen du skal stjele for meg',
        type = 'success'
    })
end

-- Interaksjon med PED
RegisterNetEvent('nxt-chopshop:interactWithPed')
AddEventHandler('nxt-chopshop:interactWithPed', function()
    interactWithPed()
end)

-- Start funksjon
Citizen.CreateThread(function()
    Citizen.Wait(5000) -- Vent i fem sekund for å laste inn
    SpawnPed()  
end)


-- Leveranse lokasjon
local deliveryPoint = vector4(2388.68, 3093.25, 48.15, 168.55)

-- Lever bil
local function deliverCar(player, car)
    if car.category == currentCarCategory then
        -- Gevinst
        local numItems = math.random(3, 6)
        local itemsReceived = {}  

        for i = 1, numItems do
            local item = chooseRandomItem(items)
            local quantity = math.random(5, 15)
            TriggerServerEvent('nxt-chopshop:server:giveItem', item, quantity)
            table.insert(itemsReceived, {item = item, quantity = quantity})  
        end

        -- Add rubber to items received
        local randomRubber = math.random(1, 10)
        TriggerServerEvent('nxt-chopshop:server:giveItem', "rubber", randomRubber)
        table.insert(itemsReceived, {item = "rubber", quantity = randomRubber})  

        -- Add stoff item if luck matches odd
        local luck = math.random(1, 8)
        local odd = math.random(1, 8)
        if luck == odd then
            local stoffQuantity = math.random(1, 8)
            TriggerServerEvent('nxt-chopshop:server:giveItem', "stoff", stoffQuantity)
            table.insert(itemsReceived, {item = "stoff", quantity = stoffQuantity})  
        end

        -- Log the items received
        local playerCoords = GetEntityCoords(player)
        local finalMessage = "Spiller fikk: " .. json.encode(itemsReceived)
      

        -- Slett kjøretøy
        local vehicle = GetVehiclePedIsIn(player, false)
        if vehicle ~= 0 then
            SetEntityAsMissionEntity(vehicle, true, true)
            DeleteEntity(vehicle)
        end

        currentCarCategory = nil
        lastChangeTime = nil

        -- Notifikasjon om leveranse og cooldown
        lib.notify({
            title = "Du skrapet bilen!",
            description = 'Godt jobbet',
            type = 'success'
        })

    else
        -- Feil kategori beskjed om du trykker E
        if IsControlJustReleased(0, 38) then
            local vehicle = GetVehiclePedIsIn(player, false)
            if vehicle ~= 0 then
                local modelHash = GetEntityModel(vehicle)
                local modelName = GetDisplayNameFromVehicleModel(modelHash)
                local vehicleCategory = GetVehicleCategory(vehicle)
                if vehicleCategory == currentCarCategory then
                    -- Deliver the vehicle and reward the player
                    deliverCar(player, {category = vehicleCategory})
                    return
                end
            end
            lib.notify({
                title = "Dette er feil type bil",
                description = 'Feil bil',
                type = 'error'
            })
        end
    end
end

-- Thread for å levere bil
Citizen.CreateThread(function()
    local inDeliveryZone = false
    local vehicleCategory = nil

    while true do
        Citizen.Wait(0) 

        -- Hent spillerens kjøretøy
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local coords = GetEntityCoords(ped)

        -- Sjekk om spilleren er i leveranse sonen
        local isInZone = Vdist(coords, deliveryPoint.xyz) < 15.0

        if isInZone then
            -- Om spilleren er i sonen sjekk type
            if not inDeliveryZone then
                inDeliveryZone = true
                vehicleCategory = GetVehicleCategory(vehicle)
            end

            if vehicle ~= 0 and GetVehicleCategory(vehicle) == currentCarCategory then
                DrawMarker(1, deliveryPoint.x, deliveryPoint.y, deliveryPoint.z - 1.0, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 15.0, 15.0, 1.0, 0, 255, 0, 100, false, true, 2, false, false, false, false)

                if IsControlJustReleased(0, 38) then
                    deliverCar(PlayerId(), {category = currentCarCategory})

                    SetEntityAsMissionEntity(vehicle, true, true)
                    DeleteEntity(vehicle)

                    currentCarCategory = nil
                    lastChangeTime = nil
                end
            end
        else
            if inDeliveryZone then
                inDeliveryZone = false
                vehicleCategory = nil
            end
        end
    end
end)
