-- НАСТРОЙКИ СКРИПТА
local Settings = {
  DEBUG = false, --ОТЛАДКА ДЛЯ ОТПРАВКИ / ПОЧИНКИ РАЗРАБОТЧИКОМ
  --CheckForUpdates = false, -- Не используется
  ClearScreen = true, --Default: true
  RewriteOS = false, --Подделывает вашу ОС для персонализации меню
  RewriteOSTo = "windows", -- На какую?
  DisablePlugins = false -- Отключит систему плагинов (ускорит загрузку скрипта до милисекунд)
}

local exitphrases = {
    "exit",
    "выход",
    "выйти",
  "out",
  "get out",
  "уйти"
}

local plugin_links = {
  "https://github.com/ssavnayt/UniLuaTools/raw/refs/heads/main/modules/helloworld.lua",
  --"https://example.com" -- PLUGIN ERROR TEST
}

local plugin_files = {
  "plugin.lua" -- Later, fixing functions :)
}

local function pluginload()
  if Settings.DisablePlugins == false then
    local total = #plugin_links
    for i, url in ipairs(plugin_links) do
        local prcnt = i / total * 100
        print("Загружаем плагин... " .. i .. "/" .. total .. " (" .. prcnt .. "%)")
        local Plugin = nil
        local success, result = pcall(function()
            local handle = io.popen("curl -Ls " .. url)
            if not handle then
                error("Не удалось запустить curl")
            end
            local code = handle:read("*a")
            handle:close()
            if not code or code == "" then
                error("Получен пустой код плагина")
            end
            local func, err = load(code)
            if not func then
                error("Ошибка компиляции: " .. tostring(err))
            end
            return func()
        end)
        if not success then
            print("[ERROR] Ошибка загрузки плагина: " .. tostring(result))
            fr()
        else
            Plugin = result
        end
        if Plugin ~= nil then
            if not Plugin.Name then
                print("ERROR: NO PLUGIN NAME DETECTED!")
            end
            if not Plugin.Execute then
                print("ERROR: NO PLUGIN EXECUTABLE FUNCTION FOUND!")
            end
            if not Plugin.Support then
                print("ERROR: NO PLUGIN SUPPORT TABLE FOUND")
            end
        end
        table.insert(Menu, {
            Text = (Plugin and Plugin.Name) or "ERROR loading plugin with link #"..i,
            Execute = (Plugin and Plugin.Execute) or nofunc,
            Support = (Plugin and Plugin.Support) or {"universal"}
        })
    end
  end
  cls()
end

function nofunc()
  dprint("noexecutable, returning error...")
  print("Ошибка: запускаемая функция не найдена!")
  fr()
  cls()
  return
end

function isexit(text)
  dprint("checking for exit..")
    for _, phrase in ipairs(exitphrases) do
        if string.lower(text) == phrase then
            return true
        end
    end
end


local function getOS()
  dprint("fetching os info...")
    if Settings.RewriteOS == true then
        devos = Settings.RewriteOSTo or "android"
        return devos
    end
    -- Windows
    if package.config:sub(1, 1) == "\\" then
        devos = "windows"
        return devos
    end
    -- Android
    if os.getenv("ANDROID_ROOT") or os.getenv("ANDROID_DATA") then
        devos = "android"
        return devos
    end
    local f = io.open("/system/build.prop", "r")
    if f then
        f:close()
        devos = "android"
        return devos
    end
    -- Linux
    local p = io.popen("uname -s 2>/dev/null")
    if p then
        local result = p:read("*l")
        p:close()
        if result == "Linux" then
            devos = "linux"
            return devos
        end
    end
    devos = "unknown"
    return devos
end

local function initmenu()
  dprint("initiating menu...")
  Menu = {
    [1] = {
        Text = "Randomizer",
        Execute = randomizer,
      Support = {"universal"} -- IN DEV
    },
    [2] = {
        Text = "Цикличный рандом",
        Execute = looprand,
      Support = {"universal"}
    },
    [3] = {
        Text = "Проверка скорости",
        Execute = speedtest,
      Support = {"linux", "windows", "android"}
    },
    [4] = {
        Text = "Информация об устройстве",
        Execute = aboutdevice,
      Support = {"android"}
    },
    [5] = {
        Text = "Камень ножницы бумага",
        Execute = rps,
      Support = {"universal"}
    },
    [6] = {
        Text = "Архиватор",
        Execute = zipr,
      Support = {"linux", "android"}
    },
    [7] = {
        Text = "Календарь",
        Execute = calendar,
      Support = {"android", "linux", "windows"}
    },
    [8] = {
        Text = "Хешер md5 (Android)",
        Execute = hashr,
      Support = {"android", "linux"}
    },
    [9] = {
        Text = "Генератор UUID",
        Execute = uidg,
      Support = {"android"}
    },
    [10] = {
        Text = "Кодировка Base64",
        Execute = b64,
      Support = {"universal"}
    },
    [11] = {
        Text = "Тест совместимости",
        Execute = featuretest,
      Support = {"universal"}
    },
    [12] = {
        Text = "Custom RNG",
        Execute = rng,
      Support = {"universal"}
    },
    [13] = {
        Text = "Трассировка пути (Non-Android)",
        Execute = traceroute,
      Support = {"android", "linux", "windows"}
    },
    [14] = {
      Text = "Мой IP",
      Execute = myip,
      Support = {"universal"}
    },
    [15] = {
      Text = "Загрузить файл онлайн",
      Execute = uploadfile,
      Support = {"universal"}
    },
    [16] = {
      Text = "Маскировка URL/Текста в ссылку",
      Execute = maskurl,
      Support = {"universal"}
    },
    [17] = {
      Text = "Генератор сидов",
      Execute = seedgen,
      Support = {"universal"}
    }
  }
end

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
--Да, обычный base64 encode (шотает все)
function b64_enc(data)
  dprint("decoding string "..data)
    return ((data:gsub('.', function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do
            r = r .. (b % 2^i - b % 2^(i-1) > 0 and '1' or '0')
        end
        return r
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i = 1, 6 do
            c = c + (x:sub(i,i) == '1' and 2^(6-i) or 0)
        end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data % 3 + 1])
end

local function mprint() -- Menu print
  dprint("trying to print menu..")
    for id, data in ipairs(Menu) do
        if not data.Support then
            print(id .. ". " .. data.Text)
          dprint("ID "..id.. "With text "..data.Text.."do not have Support array")
        else
            for _, os in ipairs(data.Support) do
                if os == devos or os == "universal" then
                    print(id .. ". " .. data.Text)
                    break
                end
              --print(id .. ". " ..data.Text.. " (НЕДОСТУПЕН)")
            end
        end
    end
end

function dprint(text) -- Принт отладки+чек
  if Settings.DEBUG == true then
    print(text)
  end
end

function cls(times)-- Чистка экрана
  if Settings.ClearScreen == true then
  dprint("trying: UNIX")
    if not os.execute("clear") then
      dprint("trying: WIN")
      if not os.execute("cls") then --Для windows
        dprint("None of clears supported?..")
        print("Неподдерживается: cls, может ios?")
      end
    end
  end
end

function wait(secs)
  dprint("Checking secs...")
  if tonumber(secs) then
    dprint("checking secs: Universal")
    if not os.execute("sleep "..secs) then -- I think universal?...
      print("Неподдерживается: sleep")
      fr()
    end
  end
end

function nanos()
  dprint("getting time...")
    local f = io.popen("date +%s%N")
    local n = f:read("*n")
    f:close()
    return n or 0
end

function fr() --Заморозка (на lua, универсальный)
  dprint("freezing...")
  io.read()
end

function randomizer() --Рандомайзер
  print('Введите число от которого рандом \nлибо напишите exit для выхода в меню')
  local from = io.read()
  if isexit(from) == true then dprint("exiting randomizer..") cls() return end
  if not tonumber(from) then dprint("NaN num") print('НЕ ЧИСЛО') fr() cls() return randomizer() end
  cls() 
  dprint("waiting for 2nd num")
  print('Введите второе число')
  local to = io.read()
  cls()
  if not tonumber(to) then dprint("NaN num 2") print('НЕ ЧИСЛО') randomizer() end
  if tonumber(to) <= tonumber(from) then dprint("incorrect set") print('Неправильный набор чисел') fr() cls() randomizer() end
  print('Результат: '..math.random(from, to).. '\nНажмите enter для продолжения')
  fr()
  cls()
  dprint("again")
  return randomizer()
end

function looprand()
  print("[PRINT] Напишите кол-во кругов \nВведите exit для выхода")
  local loopcount = io.read()
  if isexit(loopcount) == true then
    dprint("exiting..")
    cls()
    return
  end
  cls()
  print("[PRINT] Введите начальное число")
  local randstart = io.read()
  cls()
  print("[PRINT] Введите конечное число")
  local randend = io.read()
  cls()
  print("[PRINT] Режим эффективности? \n 1 - эффективность (быстрый+статистика) \n 2 - обычный (средний, только кол-во сгенерированых) \n 3 - медленный (для старых устройств и больших циклов, без статистики)")
  local fixperf = io.read()
  if not fixperf == "1" and not fixperf == "2" and not fixperf == "3" then
    dprint("invalid state, dropping 2...")
    print("[ERROR] Невалидное состояние , выбираем по умолчанию(2)")
    fixperf = "2"
    print("[WARN] Включаю 2 режим...")
  elseif fixperf == '3' then
    print("[PRINT] Выберите уровень увеличения производительности: ")
    local perfboost = io.read()
  end
  print("[INFO] Включаю "..fixperf.." режим...")
  --L00P START
  for i=1, loopcount do
   if i == tonumber(loopcount) then
     local final = math.random(randstart, randend)
     print("[INFO] Ваше число:"..final)
     fr()
     return looprand()
   else
     if fixperf == "1" then
       cls()
       print("[INFO] Число генераций: "..i)
       print("[INFO] Прогресс%: "..i/loopcount*100 .. "процентов")
       print("[INFO] Последнее число: "..math.random(randstart, randend)) --Генерируется прямо в print()
     elseif fixperf == "3" then
       math.random(randstart, randend)
     else
       print("[INFO] Последнее число: "..math.random(randstart, randend))
       cls()
     end
   end
 end
end

function speedtest()
  print("Введите размер файла в MБ \n Напишите exit для выхода")
  local input = io.read()
  if isexit(input) == true then
    dprint("exiting..")
    cls()
    return
  end
  local mb = tonumber(input)
  if not mb then
    cls()
    print("Неверное число, попробуйте снова")
    fr()
    cls()
    return speedtest()
  end
  
  local bytes = mb * 1024 * 1024
  local url   = "https://speed.cloudflare.com/__down?bytes="..bytes..
                "&_="..os.time()..math.random(1,9999) --ХОСТ (CLOUDFLARE)
  

  local cmd = string.format(
    "curl -s -S -f -w '%%{size_download}' -o /dev/null -H 'Cache-Control: no-cache' '%s' 2>&1", url)

  print("Проверяем скорость файлом в "..mb.." MБ …")
  local t0   = nanos()
  local pipe = io.popen(cmd)
  local out  = pipe:read("*a")
  local ok, _, code = pipe:close()
  local t1   = nanos()

  if not ok then
    print("curl комманда не удалась с кодом: ("..(code or "?").."): "..out)
    return speedtest()
  end

  local got   = tonumber(out) or 0
  local dt_ns = t1 - t0
  local dt_s  = dt_ns / 1e9
  local speed = (got / (1024*1024)) / dt_s

  print(string.format("Получено %.2f MiB за %.3f с. \n Скорость:  %.2f MiB/s",
                      got/(1024*1024), dt_s, speed))
  fr()
  cls()
  return speedtest()
end

function aboutdevice()
    -- Вспомогательная функция (переименовал в get для ясности)
    local function get(cmd)
      dprint("getting "..cmd)
        local pipe = io.popen(cmd .. " 2>/dev/null")
        if not pipe then return "—" end
        local output = pipe:read("*a")
        pipe:close()
        output = output:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\n", " ")
        return output ~= "" and output or "—"
    end
  
    print("Модель:            " .. get("getprop ro.product.model"))
    print("Производитель:     " .. get("getprop ro.product.manufacturer"))
    print("Android:           " .. get("getprop ro.build.version.release") ..
          " (SDK " .. get("getprop ro.build.version.sdk") or os.execute('printenv API_LEVEL').. ")")
    print("Архитектура:       " .. get("uname -m"))
    print("Ядер:              " .. get("nproc || grep -c '^processor' /proc/cpuinfo"))
    print("ОЗУ всего:         " .. get("free -h 2>/dev/null | grep Mem | awk '{print $2}' || " ..
                                 "cat /proc/meminfo 2>/dev/null | grep MemTotal | awk '{printf \"%.1f GB\", $2/1024/1024}'"))
    print("\nUptime:            " .. get("uptime -p || uptime"))

    -- Сеть
    print("\nСеть:")
    print("  Внешний IPv4:    " .. get("curl -s ifconfig.me || curl -s icanhazip.com || curl -s ipinfo.io/ip || echo '— (нет интернета?)'"))

    -- Root-проверка
    local root_detected = get("su -c 'whoami' 2>/dev/null || which su 2>/dev/null || echo '—'")
    print("\nRoot:              " .. (root_detected ~= "—" and "Обнаружен!" or "Нет / скрыт"))

  fr()
  cls()
  return
end

function rps() -- Камень ножницы бумага
  if not rpscn or not rpscb then
    rpscn = 0
    rpscb = 0
    dprint("BUGFIXING RPS values...")
  end
  print('Выберите: \n Камень (введите 1) \n Ножницы (введите 2) \n Бумага (введите 3) \n Счет: '..rpscn..' \n Счет бота: '..rpscb..' \nВведите exit для выхода')
  local rpsc = io.read()
  local rpsc = string.lower(rpsc) -- В низкие делаем
  if isexit(rpsc) then
    dprint("exiting..")
    cls()
    return
  end
  cls()
  if rpsc == 'камень' then -- Поправки
    rpsc = '1'
  elseif rpsc == 'ножницы' then
    rpsc = '2'
  elseif rpsc == 'бумага' then
    rpsc = "3"
  elseif tonumber(rpsc) and tonumber(rpsc) < 4 then
    rpsc = math.floor(tonumber(rpsc))
  else
    print("[ERROR] Неверный вариант")
    fr()
    cls()
    return rps()
  end
  dprint("user "..rpsc)
  local botanswer = math.random(1, 3) -- Имплементация бота на рандоме
  if rpsc == 1 then -- В слова
    rpscw = 'камень'
  elseif rpsc == 2 then
    rpscw = 'ножницы'
  elseif rpsc == 3 then
    rpscw = "бумага"
  else
    print("Ошибка в декодировке вашего ответа")
    print("Ваш выбор: "..rpscw.. "\n Цифровой вариант: "..rpsc)
  end
  
  if botanswer == 1 then -- В слова бота
    baw = 'камень'
  elseif botanswer == 2 then
    baw = 'ножницы'
  elseif botanswer == 3 then
    baw = "бумага"
  else
    print("ОШИБКА ВЫБОРА БОТА (ожидалось: 1-3, получилось: "..botanswer.. ")")
    fr()
    cls()
    return rps()
  end
  dprint("bot answered "..botanswer)
  
  if botanswer == rpsc then
    print("Ничья, ваш выбор такой же как у бота: "..rpscw)
  elseif botanswer == 1 and rpsc == 2 or botanswer == 2 and rpsc == 3 or botanswer == 3 and rpsc == 1 then
    print("Бот победил, ваш выбор: "..rpscw)
    rpscb = rpscb + 1
  elseif botanswer == 1 and rpsc == 3 or botanswer == 2 and rpsc == 1 or botanswer == 3 and rpsc == 2 then
    print("Вы победили, ваш выбор: "..rpscw)
    rpscn = rpscn + 1
  else --Проверка ошибок
    print("[ERROR] Недопустимые параметры выхода бота")
    print("Ваш выбор: "..rpscw)
  end
  print("Выбор бота: "..baw)
  fr()
  cls()
  rps()
end

function zipr() --TO DEBUG DO NOT FORGET
  print("Выберите метод сжатия: \ntar (рекомендуется, tar.*, ANDROID / LINUX ONLY), введите 1 \ngzip (.gz только, часто работает, ANDROID / LINUX), введите 2 \nВведите exit для выхода")
  local zipmd = io.read()
  if isexit(zipmd) == true then
    cls()
    return
  end
  if not tonumber(zipmd) or tonumber(zipmd) < 1 or tonumber(zipmd) > 2 then
    print("Неверное число, введите 1 или 2")
    fr()
    cls()
    return zipr()
  end --1 это tar 2 это gzip
  cls()
  print("Введите путь к файлу который нужно сжать")
  local targetfile = io.read()
  local checkf = io.open(targetfile, "r")
  if not checkf then --Проверка файла
    print("Файл не существует, либо его путь неверный")
    fr()
    cls()
    return zipr()
  end
  cls()
  if tonumber(zipmd) == 2 then
    print("Выберите режим сжатия (только цифрами) : \n 1 - слабый \n 9 - Наилучший")
    local zipstr = io.read()
    if not tonumber(zipstr) then
      print("Неправильно выбран режим сжатия, введите число, пожалуйста")
      fr()
      cls()
      return zipr()
    end
    os.execute("gzip -"..zipstr.." -k " ..targetfile)    -- Сжатие через gzip
  elseif tonumber(zipmd) == 1 then
    print("Выберите метод сжатия (цифрами)")
    print("zstd (Баланс сжатия и скорости, не везде работает, введите 1)")
    print("xz (Максимальное сжатие, не везде работает, медленно, введите 2)")
    print("lz4 (НЕ РАБОТАЕТ НА АНДРОИД, Наибыстрый, минимальное сжатие, введите 3)")
    print("bzip (Работает везде, среднее сжатие, медленно, введите 4)")
    local rmd = io.read()
    if not tonumber(rmd) or tonumber(rmd) > 4 or tonumber(rmd) < 1 then
      print("Неверное число, проверьте верность и попробуйте еще раз")
      fr()
      cls()
      return zipr()
    end
    rmd = tonumber(rmd)
    cls()
    if rmd == 1 then
      os.execute('time tar --zstd -cf '..targetfile..'.tar.zst '..targetfile)
      print("Готово, файл сохранен в: "..targetfile.. ".tar.zst")
    elseif rmd == 2 then
      os.execute('time tar -cJf '..targetfile..'.tar.xz '..targetfile)
      print("Готово, файл сохранен в: "..targetfile.. ".tar.xz")
    elseif rmd == 3 then
      os.execute('time tar --lz4 -cf '..targetfile..'.tar.lz4 '..targetfile)
      print("Готово, файл сохранен в: "..targetfile.. ".tar.lz4")
    elseif rmd == 4 then
      os.execute('time tar -cjf '..targetfile..'.tar.bz2 '..targetfile)
      print("Готово, файл сохранен в: "..targetfile.. ".tar.bz2")
    else
      print("ОШИБКА СЖАТИЯ: НЕВЕРНЫЙ RMD")
      print("RMD: "..rmd)
    end
  end
  fr()
  cls()
  return zipr()
end

function calendar()
  local t = os.date("*t")
  dprint("trying: ANDROID")
  if not os.execute('cal') then
    dprint("trying: UNIX date (maybe Windows)")
    if not os.execute('date') then
      print("НЕ НАЙДЕН ПОСТАВЩИК КАЛЕНДАРЯ, ПОДДЕРЖКА ТОЛЬКО Unix")
    end
  else
    if not os.execute('date') then
      dprint("using date from UNIX")
      print("Сегодня "..t.day.. "."..t.month.."."..t.year.. " года")
    end
  end
  randfact = math.random(1, 2)
  print("\n")
  print("getting random fact...")
      if randfact == 1 then
        print("Вы знали, что сегодня " .. t.yday ..
    " день в году, получается прошло " ..
    string.format("%.2f", t.yday / 365 * 100) .. "% года?")
      elseif randfact == 2 then
        print("Вы знали, что если сложить все числа из нынешнего времени, то получится " ..t.year + t.day + t.month + t.hour + t.min + t.sec + t.wday + t.yday)
      end
  print("\nНажмите Enter чтоб выйти")
  fr()
  cls()
  return
end

function hashr()
  print("Введите путь к файлу \nВведите exit для выхода")
  local tfileh = io.read()
  if isexit(tfileh) == true then
    dprint("exiting...")
    cls()
    return
  end
  local checkf = io.open(tfileh, "r")
  if not checkf then
    print("Файл не существует, либо его путь неверный")
    fr()
    cls()
    return hashr()
  end
  cls()
  dprint("getting hashes via android...")
  print('Хэш md5:')
  os.execute('md5sum '..tfileh)
  print('\nХэш sha1:')
  os.execute('sha1sum '..tfileh)
  print('\nХэш sha224:')
  os.execute('sha224sum '..tfileh)
  print('\nХэш sha256:')
  os.execute('sha256sum '..tfileh)
  print('\nХэш sha384:')
  os.execute('sha384sum '..tfileh)
  print('\nХэш sha512:')
  os.execute('sha512sum '..tfileh)
  fr()
  cls()
  return hashr()
end

function uidg()
  print('Ваш UUID: ')
  if not os.execute("uuidgen") then
    print("Не поддерживается")
  end
  print("\n Введите exit чтоб выйтм")
  text = io.read()
  if text == exit then
    dprint("exiting...")
    cls()
    return
  end
  cls()
  return uidg()
end

function b64()
  print('Режим работы: \n Decode - 1 \n Encode - 2\nВведите exit для выхода')
  local b64m = io.read()
  if isexit(b64m) == true then
    dprint("exiting..")
    cls()
    return
  end
  if not tonumber(b64m) or tonumber(b64m) > 2 or tonumber(b64m) < 1 then
    cls()
    print('Неверный выбор')
    fr()
    return b64()
  end
  print('Введите текст: ')
  local b64text = io.read()
  if b64m == '2' then --Кодировка
    os.execute("echo "..b64text.." > tmp.txt")
    if not os.execute("uuencode -m tmp.txt tmp2.txt > altxz.txt") then
      result = b64_enc(b64text)
      os.execute("echo "..b64text.." > altxz.txt")
      --print(result)
    end
    cls()
    --print(result)
    os.execute('cat altxz.txt')
    if result then print(result) end
    --Очистка
    os.execute('rm altxz.txt')
    os.execute('rm tmp.txt')
  elseif b64m == "1" then --Декодировка
    os.execute("echo "..b64text.." > tmp.txt")
    if not os.execute("base64 -d tmp.txt > altxz.txt") then
      print("ПОСТАВЩИК base64 недоступен")
    end
    cls()
    os.execute('cat altxz.txt')
    --Очистка
    os.execute('rm altxz.txt')
    os.execute('rm tmp.txt')
  else
    cls()
    print('Неверный выбор')
    fr()
    return b64()
  end
  --print("\n\n1 И ПОСЛЕДНЯЯ СТРОЧКИ НЕ ОТНОСЯТСЯ К ЗАКОДИРОВАНОМУ ТЕКСТУ") -- ТОЛЬКО В UUENCODE
  fr()
  cls()
  return b64()
end

function featuretest()
  dprint("drawing values...")
  local winvalue = 0
  local linvalue = 0
  local wait, clear, nanosval, base64, rm, uuencode, echo, cat, uuidgen, sums, cal, tracktime, tar, gz

  dprint("trying: sleep UNIVERSAL")
  if os.execute("sleep 0") then -- WAIT TEST
    wait = true
    winvalue = winvalue + 1
    linvalue = linvalue + 1
  else
    wait = false
  end

  --Clear Screen test
  dprint("trying clear screen (win)")
  if not os.execute("cls") then
    clear = false
    dprint("trying clear screen (unix/android)")
    if not os.execute("clear") then
      clear = false
    else
      clear = true
      linvalue = linvalue + 1
    end
  else
    clear = true
    winvalue = winvalue + 1
  end

  --Time test
  dprint("trying: nanos (UNIVERSAL)")
  if nanos() == 0 then
    nanosval = false
  else
    nanosval = true
  end

  --Base64 test
  dprint("trying base64 (UNIX)")
  if not os.execute("base64 --help > b64test_tmp.txt") then
    base64 = false
    winvalue = winvalue + 1
  else
    base64 = true
    linvalue = linvalue + 1
  end

  --rm test
  dprint("trying remove (UNIVERSAL)")
  if not os.execute("rm --help > rmtest.txt") then
    rm = false
    winvalue = winvalue + 1
  else
    os.execute("rm -f rmtest.txt")
    os.execute("rm -f b64test_tmp.txt")
    rm = true
    linvalue = linvalue + 1
  end

  --uuencode test
  dprint("trying uuencode (android)")
  if not os.execute("uuencode --help > uenct.txt") then
    winvalue = winvalue + 1
    uuencode = false
  else
    uuencode = true
    linvalue = linvalue + 1
  end

  -- Echo test
  if os.execute("echo TESTING ECHO...") then
    echo = true
    winvalue = winvalue + 1
    linvalue = linvalue + 1
  else
    echo = false
  end

  --Cat test
  os.execute("echo testtest > cattest.txt")
  if os.execute("cat cattest.txt") then
    linvalue = linvalue + 1
    cat = true
  else
    winvalue = winvalue + 1
    cat = false
  end

  --uuidgen test
  if not os.execute("uuidgen") then
    uuidgen = false
    linvalue = linvalue + 1
  else
    uuidgen = true
    winvalue = winvalue + 1
  end

  --md5sum test
  if not os.execute('md5sum cattest.txt') then
    sums = false
    winvalue = winvalue + 1
  else
    sums = true
    linvalue = linvalue + 1
  end

  --Linux calendar test
  if not os.execute("cal > datetest.txt") then
    cal = false
    winvalue = winvalue + 1
  else
    cal = true
    linvalue = linvalue + 1
  end

  -- time elapsing test
  if not os.execute("time --help") then
    tracktime = false
    winvalue = winvalue + 1
  else
    tracktime = true
    linvalue = linvalue + 1
  end

  --tar test
  if not os.execute("tar --help") then
    tar = false
  else
    tar = true
    winvalue = winvalue + 1
    linvalue = linvalue + 1
  end

  --gzip test
  if not os.execute("gzip -9 gztest2.tar.gz datetest.txt") then
    gz = true
    linvalue = linvalue + 1
  else
    gz = false
    linvalue = linvalue + 1
  end
  
  if rm then
    -- Cleanup all temporary files (независимо от ОС)
    os.execute("rm -f b64test_tmp.txt rmtest.txt uenct.txt cattest.txt datetest.txt helptest.txt tartest.tar.gz gztest2.tar.gz datetest.txt.gz 2>/dev/null")
  else
    --Clean all temp (WIN)
    os.execute("del /f /q b64test_tmp.txt rmtest.txt uenct.txt cattest.txt datetest.txt helptest.txt tartest.tar.gz gztest2.tar.gz datetest.txt.gz 2>nul")
  end

  --Results
  cls()
  print("Результаты: \n 1) Баллы виндоус: "..winvalue.. "\n 2) Баллы Linux (и Android): "..linvalue.. "\nФичи:\n")
  print("1) Clear: "..tostring(clear))
  print("2) Time (nanos): "..tostring(nanosval))
  print("3) Base64: "..tostring(base64))
  print("4) File remove (rm, Linux): "..tostring(rm))
  print("5) uuencode: "..tostring(uuencode))
  print("6) Echo: "..tostring(echo))
  print("7) Cat: "..tostring(cat))
  print("8) UUID generator (Linux): "..tostring(uuidgen))
  print("9) Md5 summaries: "..tostring(sums))
  print("10) Visual calendar: "..tostring(cal))
  print("11) Elapsed time tracker: "..tostring(tracktime))
  print("12) Tar: "..tostring(tar))
  print("13) GZip: "..tostring(gz))
  fr()
  if linvalue > winvalue then
    print("Судя по коммандам, скорее всего у вас Linux дистрибутив, либо андроид")
  elseif winvalue > linvalue then
    print("Судя по коммандам, скорее всего у вас Windows либо другая ОС")
  else
    print("[ERROR] Ошибка команды вывода результата баллов ОС (может они равны?)")
  end
  cls()
end

function rng()
    print("Введите сид ниже:")
    local seedtxt = io.read()
    local seed
    if seedtxt == "" or seedtxt == nil then
      dprint("got "..seedtxt)
        print("Неверный ввод, попробуйте снова")
      fr()
      cls()
      return rng()
    elseif isexit(seedtxt) == true then
      cls()
      return
    else
        seed = tonumber(seedtxt)
        if not seed then
            print("Ошибка: введено не число. Используем случайный сид.")
            seed = math.random(1, 67676767)
        end
    end
  cls()
  print("Сгенерировать число от 1 до:")
  local randto = io.read()
  randto = tonumber(randto)
  if not randto then
    print("Не является числом!")
    fr()
    cls()
    return rng()
  end
    local state = seed
    local a = 1664525
    local c = 1013904223
    local m = 2^32
    -- Генерируем одно случайное число
    state = (a * state + c) % m
    local random_num = 1 + (state % randto)  -- целое от 1 до 100
  local random_num = math.floor(random_num)
    -- Выводим результат
    print(random_num)
    fr()
  cls()
  return rng()
end

function traceroute()
  print("напишите хост для traceroute, если это IPv6, припишите в начало сообщения - 6")
  host = io.read()
  if string.sub(host, 1) == "-" then
    print("неверный IP/HOST, ID ошибки: 1")
    fr()
  end
  if not os.execute("toybox > /dev/null") then
    os.execute("traceroute "..host)
  else
    dprint("android socket stub")
    print("Андроид не поддерживается")
  end
  fr()
  cls()
  return traceroute() -- ДОПИСАТЬ ДЛЯ АНДРОИД
end

function myip()
    dprint("getting IP...")
    local function request(url)
        local handle = io.popen(
            'curl -s --connect-timeout 3 --max-time 3 "' .. url .. '"'
        )
      dprint("trying "..url)
        if not handle then return nil end
        local result = handle:read("*a")
        handle:close()
        if result == "" then return nil end
        return result
    end
    -- Основной API
    local json_ip = request("https://ipapi.co/json/")
    -- Проверка ответа
    local ip, country, countrycode
    if json_ip then
        ip = json_ip:match('"ip"%s*:%s*"([^"]+)"')
        country = json_ip:match('"country_name"%s*:%s*"([^"]+)"')
        countrycode = json_ip:match('"country_code"%s*:%s*"([^"]+)"')
    end
    -- Резервный API
    if not ip then
        dprint("Primary API failed, trying backup...")
        json_ip = request("https://api.ipify.org?format=json")
        if json_ip then
            ip = json_ip:match('"ip"%s*:%s*"([^"]+)"')
        end
    end
    cls()
    if ip then
        print("IP адрес: " .. ip)
        print("Код страны: " .. tostring(countrycode or "Unknown"))
        print("Страна: " .. tostring(country or "Unknown"))
    else
        print("Не удалось получить IP (timeout/error)")
    end
  fr()
    return
end

function uploadfile()
    print("Напишите путь к файлу (exit для выхода)")
    print("Если ваш файл в "..io.popen("pwd"):read().. ",не пишите путь, только название:")
    local path = io.read()
    if isexit(path) == true then
        return
    end
    local file = io.open(path, "r")
    if not file then
        print("Файл не существует")
      fr()
      cls()
        return uploadfile()
    end
    file:close()
    local command = 'curl -sS -w "\\nHTTP_CODE:%{http_code}" -F "file=@' .. path .. '" https://tmpfiles.org/api/v1/upload'
    --нишевый curl 
    local handle = io.popen(command)
    local response = handle:read("*a")
    handle:close()
    local body, status = response:match("^(.-)HTTP_CODE:(%d+)%s*$")
    dprint("HTTP Status: " .. tostring(status))
    dprint("Ответ сервера: " .. tostring(body))
    local url = body and body:match('"url"%s*:%s*"([^"]+)"')
    if url then
        local download_url = url:gsub("tmpfiles.org/", "tmpfiles.org/dl/")
        print("Готово! Ссылка: " .. download_url)
        dprint("trying copy method: android < 15")
        os.execute('echo -n "' .. download_url .. '" | termux-clipboard-set') --Не работает на новых телефонах
        print("Ссылка скопирована в буфер обмена!")
    else
      print("Не удалось извлечь ссылку!")
      print("Сырой ответ (для диагностики): "..body)
    end
    return uploadfile()
end

function maskurl()
  local maskingurl = "https://axorax.github.io/urlmskr/"
  print("Введите ссылку для маскировки")
  local input = io.read()
  local encodedtext = b64_enc(input)
  dprint(encodedtext, input)
  local outurl = maskingurl .. encodedtext
  print("Готово! Ссылка:")
  print(outurl)
  fr()
  cls()
  return
end

function seedgen()
  local randseed = math.randomseed(math.random(67, math.random(1, 67000000000)))
  --Double rand :)
  print("Ваш сид: "..randseed)
  print("Чтоб выйти напишите exit или выход")
  local input = io.read()
  if isexit(input) == true then
    dprint("exiting...")
    return
  end
  cls()
  return seedgen()
end

exitapp = false --Не обращайте внимания :)

local function main() -- Меню
  print("Здравствуйте, " .. io.popen("whoami"):read("*l"))
  print("Добро пожаловать в UniLuaTools V3.0.1 (22.11.2026)")
  dprint("CPU TIME: ".. os.clock() - start_time .. "секунд")
  print("телеграмм: @cepoxo/@WHTKINFO")
  getOS()
  mprint() --Логично что выводит меню
  dprint("test debug menu (if is, then menu works):"..Menu[8].Support[1]) 
  local mode = io.read()
  cls() -- Уменьшил колво строк от cls
  if isexit(mode) == true then
    print("Выходим...")
    exitapp = true
  end
  if not Menu[tonumber(mode)] and exitapp == false then
    print("Неверный ввод")
    fr()
    cls()
  elseif Menu[tonumber(mode)] then
    Menu[tonumber(mode)].Execute()
  end
end

start_time = os.clock()

initmenu()
pluginload()

while true do --Menu L00P 
  if exitapp == "nil" or not exitapp then
    main()
  elseif exitapp == true then
    pcall(function()
      os.exit(1)
    end)
    break
  else
    -- Только не надо флиппить байты прошу
    dprint("invalid value, maybe byte flipping?")
    error("[ERROR] Значение exitapp вывело ни false, ни true: "..exitapp)
    print("Нажмите Enter чтоб вернуться в меню")
    fr()
    cls()
    print("Завершаем скрипт...")
    pcall(function()
      os.exit(1)
    end)
    break -- если не exit
  end
end