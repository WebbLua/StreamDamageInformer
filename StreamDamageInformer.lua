script_name('StreamDamageInformer')
script_author("Webb")
script_version("17.06.2023")
script_version_number(1)

local main_color, main_color_hex = 0xFFFAFA, "{FFFAFA}"
local prefix, updating_prefix, error_prefix = "[StreamDamage] ", "{FF0000}[UPDATING]{FFFAFA} ", "{FF0000}[ERROR] "

function try(f, catch_f)
    local status, exception = pcall(f)
    if not status then
        catch_f(exception)
    end
end

try(function()
    ev = require 'samp.events'
    weapons = require 'game.weapons'
    inicfg = require 'inicfg'
    dlstatus = require'moonloader'.download_status
    encoding = require 'encoding'
    encoding.default = 'CP1251'
    u8 = encoding.UTF8
end, function(e)
    sampAddChatMessage(prefix .. error_prefix .. "An error occurred while loading libraries", 0xFF0000)
    sampAddChatMessage(prefix .. error_prefix .. "For more information, view the console (~)", 0xFF0000)
    print(error_prefix .. e)
    script.unload = true
    thisScript():unload()
end)

local sd_ini, server

local config = {
    settings = {
        status = false
    }
}

if sd_ini == nil then
    sd_ini = inicfg.load(config, StreamDamage)
    inicfg.save(sd_ini, StreamDamage)
end

local script = {
    v = {num, date},
    loaded = false,
    unload = false,
    update = false,
    checkedUpdates = false,
    telegram = {
        nick = "@ibm287",
        url = "https://t.me/ibm287"
    },
    request = {
        complete = true,
        free = true
    },
    label = {}
}

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then
        return
    end
    while not isSampAvailable() do
        wait(0)
    end

    while sampGetCurrentServerName() == "SA-MP" do
        wait(0)
    end
    server = sampGetCurrentServerName():gsub('|', '')
    server = (server:find('02') and 'Two' or (server:find('Revo') and 'Revolution' or
                 (server:find('Legacy') and 'Legacy' or (server:find('Classic') and 'Classic' or ""))))

    sampRegisterChatCommand("sdamage", function()
        sd_ini.settings.status = not sd_ini.settings.status
        inicfg.save(sd_ini, StreamDamage)
        script.sendMessage("Инфомер " ..
                               (sd_ini.settings.status and "активирован" or "деактивирован"))
    end)

    script.loaded = true

    while sampGetGamestate() ~= 3 do
        wait(0)
    end
    while sampGetPlayerScore(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) <= 0 and not sampIsLocalPlayerSpawned() do
        wait(0)
    end

    script.checkUpdates()

    while not script.checkedUpdates do
        wait(0)
    end

    script.sendMessage("Успешно запущен. Запустить информер - " .. main_color_hex ..
                           "/sdamage")
    while true do
        wait(0)
        textLabelOverPlayerNickname()
    end
end

function ev.onSendBulletSync(data) -- targetType, targetId, origin, target, center, weaponId
    if sd_ini.settings.status then
        if data.targetType == 1 and sampIsPlayerConnected(data.targetId) then
            local t = {}
            t.weapon = weapons.get_name(data.weaponId)
            local id = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
            local scolor = string.sub(string.format('%x', sampGetPlayerColor(id)), 3)
            local scolor = scolor == "ffff" and "fffafa" or scolor
            t.shooter = {
                color = scolor,
                id = id,
                nick = sampGetPlayerNickname(id)
            }
            local tcolor = string.sub(string.format('%x', sampGetPlayerColor(data.targetId)), 3)
            local tcolor = tcolor == "ffff" and "fffafa" or tcolor
            t.target = {
                color = tcolor,
                id = data.targetId,
                nick = sampGetPlayerNickname(data.targetId)
            }
            sampAddChatMessage(string.format("{%s}%s[%s]%s shot at {%s}%s[%s]%s with %s", t.shooter.color,
                t.shooter.nick, t.shooter.id, main_color_hex, t.target.color, t.target.nick, t.target.id,
                main_color_hex, t.weapon), main_color)
        end
    end
end

function ev.onBulletSync(id, data) -- targetType, targetId, origin, target, center, weaponId
    if sd_ini.settings.status then
        if data.targetType == 1 and (sampIsPlayerConnected(data.targetId) or data.targetId == select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) then
            local t = {}
            t.weapon = weapons.get_name(data.weaponId)
            local scolor = string.sub(string.format('%x', sampGetPlayerColor(id)), 3)
            local scolor = scolor == "ffff" and "fffafa" or scolor
            t.shooter = {
                color = scolor,
                id = id,
                nick = sampGetPlayerNickname(id)
            }
            local tcolor = string.sub(string.format('%x', sampGetPlayerColor(data.targetId)), 3)
            local tcolor = tcolor == "ffff" and "fffafa" or tcolor
            t.target = {
                color = tcolor,
                id = data.targetId,
                nick = sampGetPlayerNickname(data.targetId)
            }
            sampAddChatMessage(string.format("{%s}%s[%s]%s shot at {%s}%s[%s]%s with %s", t.shooter.color,
                t.shooter.nick, t.shooter.id, main_color_hex, t.target.color, t.target.nick, t.target.id,
                main_color_hex, t.weapon), main_color)
        end
    end
end

textlabel = {}
function textLabelOverPlayerNickname()
    for i = 0, 1000 do
        if textlabel[i] ~= nil then
            sampDestroy3dText(textlabel[i])
            textlabel[i] = nil
        end
    end
    for i = 0, 1000 do
        if sampIsPlayerConnected(i) and sampGetPlayerScore(i) ~= 0 then
            local nick = sampGetPlayerNickname(i)
            if script.label[server] ~= nil then
                if script.label[server][nick] ~= nil then
                    if textlabel[i] == nil then
                        textlabel[i] = sampCreate3dText(u8:decode(script.label[server][nick].text),
                            tonumber(script.label[server][nick].color), 0.0, 0.0, 0.8, 15.0, false, i, -1)
                    end
                end
            end
        else
            if textlabel[i] ~= nil then
                sampDestroy3dText(textlabel[i])
                textlabel[i] = nil
            end
        end
    end
end

function script.checkUpdates() -- проверка обновлений
    lua_thread.create(function()
        local response = request("https://raw.githubusercontent.com/WebbLua/StreamDamageInformer/main/version.json")
        local data = decodeJson(response)
        if data == nil then
            script.sendMessage("Не удалось получить информацию про обновления")
            script.unload = true
            thisScript():unload()
            return
        end
        script.v.num = data.version
        script.v.date = data.date
        script.url = data.url
        script.label = decodeJson(request(data.label))
        if data.telegram then
            script.telegram = data.telegram
        end
        if script.v.num > thisScript()['version_num'] then
            script.sendMessage(updating_prefix .. "Обнаружена новая версия скрипта от " ..
                                   data.date .. ", начинаю обновление...")
            script.updateScript()
            return true
        end
        script.checkedUpdates = true
    end)
end

function request(url) -- запрос по URL
    while not script.request.free do
        wait(0)
    end
    script.request.free = false
    local path = os.tmpname()
    while true do
        script.request.complete = false
        download_id = downloadUrlToFile(url, path, download_handler)
        while not script.request.complete do
            wait(0)
        end
        local file = io.open(path, "r")
        if file ~= nil then
            local text = file:read("*a")
            io.close(file)
            os.remove(path)
            script.request.free = true
            return text
        end
        os.remove(path)
    end
    return ""
end

function download_handler(id, status, p1, p2)
    if stop_downloading then
        stop_downloading = false
        download_id = nil
        return false -- прервать загрузку
    end

    if status == dlstatus.STATUS_ENDDOWNLOADDATA then
        script.request.complete = true
    end
end

function script.updateScript()
    script.update = true
    downloadUrlToFile(script.url, thisScript().path, function(_, status, _, _)
        if status == 6 then
            script.sendMessage(updating_prefix .. "Скрипт был обновлён!")
            if script.find("ML-AutoReboot") == nil then
                thisScript():reload()
            end
        end
    end)
end

function script.sendMessage(t)
    sampAddChatMessage(prefix .. u8:decode(t), main_color)
end

function onScriptTerminate(s, bool)
    if s == thisScript() and not bool then
        for i = 0, 1000 do
            if textlabel[i] ~= nil then
                sampDestroy3dText(textlabel[i])
                textlabel[i] = nil
            end
        end
        if not script.update then
            if not script.unload then
                script.sendMessage(error_prefix ..
                                       "Скрипт крашнулся: отправьте файл moonloader\\moonloader.log разработчику в tg: " ..
                                       script.telegram.nick)
            else
                script.sendMessage("Скрипт был выгружен")
            end
        else
            script.sendMessage(updating_prefix .. "Перезагружаюсь...")
        end
    end
end