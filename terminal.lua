--[=[TAB:Main]=]
--[[
saveText("Documents:termhl")
--]]
usage.dist = "dist [x1,y1 x2,y2] [x1 y1 x2 y2]"
help.dist = "Displays the distance between the two given points"
--[=[END_TAB]=]
--[=[TAB:bold]=]
print("\254" .. table.concat(arg, " ") .. "\254")
--[=[END_TAB]=]
--[=[TAB:devhelp]=]
dh = dh or {}

dh.mo = {}
dh.funcs = {}

dh.order = {"Program development", "Exit"}

dh.mo["Program development"] = {
    "Command repository project how-to", 
    "Basic command structure", 
    "Arguments/parameters",
    "Example program"
}

-- │─┐└┘┌
dh.code = function(code)
    term.print("\3\218" .. ("\196"):rep(termW-3).."\191")
    for ln in (code .. "\n"):gmatch("(.-)\n") do
        term.print("\3\179\255 " .. ln .. (" "):rep(termW-4-#ln) .. "\3\179")
    end
    term.print("\3\192" .. ("\196"):rep(termW-3).."\217\255")
end

function dh.sep()
    term.print(col.gray .. ("\196"):rep(termW - 1) .. "\255\n")
end

dh.funcs["Program development"] = {
function()
    cmd.clear()
    print("\1\255Command repositories\1")
    print("User-written commands can be added to MockTerm via a command repository - if a repo is set, MockTerm assigns each tab in the repo to a command (with the same name as the given tab).")
    print("\n" .. col.gray .. 'In the setup menu, the command repository is referred to as the "command project."\255')
    term.read("\nPress any key to continue...", false, ".")
    coroutine.yield()
    cur.y = cur.y - 1
    dh.sep()
    print("\rWhen a tab in the command repo is loaded, the code inside it is packed into a function, which is called whenever the command is run.\nIt can be useful to think of command code not as a separate script, but as a function called inside the terminal, with access to most of the internals.")
    term.read("\nPress any key to continue...", false, ".")
    coroutine.yield()
    cur.y = cur.y - 1
    dh.sep()
    print("\rThis open-ness comes at a cost - it is possible to modify the internal data and processes of the terminal, in potentially unexpected ways.")
    term.read("\nPress any key to continue...", false, ".")
    coroutine.yield()
    cur.y = cur.y - 1
end,
function()
    cmd.clear()
    print("\1\255Command structure\1")
    print("Although different in concept, external commands are structured similarly to a stand-alone script")
    print("\nThe simplest commands, in fact, can usually be run as individual programs in a raw Lua emvironment and behave exactly as they do in this environment.")
    term.read("\nPress any key to continue...", false, ".")
    coroutine.yield()
    cur.y = cur.y - 1
    dh.sep()
    print("\rThe Hello World program, for example, is simple:")
    dh.code('print("Hello World")')
    term.read("\nPress any key to continue...", false, ".")
    coroutine.yield()
    cur.y = cur.y - 1
end,
function()
    cmd.clear()
    print("\1\255Arguments & Parameters\1")
    print("MockTerm supports the same arguments format as every other terminal:")
    dh.code[[Arguments:
    some_command arg1 arg2
Parameters:
    some_command --flag1 --boolean --param1=value]]
    term.read("\nPress any key to continue...", false, ".")
    coroutine.yield()
    cur.y = cur.y - 1
    dh.sep()
    print("\rThese values are passed to the command source as the tables \254arg\254 and \254params\254.")
    print("Arguments can be read exactly as they are in standalone Lua:")
    dh.code("first_arg = arg[1]")
    print("Parameters are stored by name, and are read like this:")
    dh.code[[foo = params.bar]]
    term.read("\nPress any key to continue...", false, ".")
    coroutine.yield()
    cur.y = cur.y - 1
    dh.sep()
    print("\rParameters can be set with or without arguments.\nWith no argument (\254--param\254), the parameter is simply set to \254true\254.")
    print("Parameter arguments are passed to the command without being evaluated, so this statement:")
    dh.code[[something --number=1+1]]
    print('will set \254params.number\254 to "1+1", not 4.')
    term.read("\nPress any key to continue...", false, ".")
    coroutine.yield()
    cur.y = cur.y - 1
end,
function()
    print("This isn't supported yet, so read through the source code or something.")
end
}

dh.cmenu = nil

dh.sel = 1

dh.menuLevel = 1

dh.nff = false

function dh.mainMenu(k)
    k = k or ""
    cmd.clear()
    if k == "l" or k == "a" then
        dh.sel = dh.sel % #dh.order + 1
    elseif k == "p" or k == "q" then
        dh.sel = (dh.sel + #dh.order - 2) % #dh.order + 1
    end
    cur.y = 2
    for i, v in ipairs(dh.order) do
        term.print((i == dh.sel and "\255" or col.gray) .. v .. (i == dh.sel and "\255" or col.white).."\n")
    end
    if k == "\n" and dh.nff then
        if dh.menuLevel == 1 then
            dh.cmenu = dh.order[dh.sel]
            dh.order = dh.mo[dh.order[dh.sel]]
            dh.menuLevel = 2
        else
            term.coroutine = coroutine.create(dh.funcs[dh.cmenu][dh.sel])
            term.exit("")
        end
        if not dh.order then term.exit("") end
        dh.nff = false
    else
        dh.nff = true
    end
end

term.enter(dh.mainMenu)
--[=[END_TAB]=]
--[=[TAB:hl]=]
if not(arg and arg[1]) then
    print("\5Please specify a source tab!\255")
    return "no tab specified"
end
--test

--[[
test
]]

---[[
--local test="test"
--]]
--print(tostring(arg[2]))

if not hlc then
    hlc = {}
    indh = {}
    ec = {}
    ec["for"] = col.lightlightblue
    ec["do"] = col.lightlightblue
    ec["if"] = col.lightlightblue
    ec["local"] = col.lightlightblue
    ec["not"] = col.lightlightblue
    ec["else"] = col.lightlightblue
    ec["return"] = col.lightlightblue
    ec["then"] = col.lightlightblue
    ec["while"] = col.lightlightblue
    ec["until"] = col.lightlightblue
    ec["in"] = col.lightlightblue
    ec["end"] = col.lightlightmagenta
    ec["elseif"] = col.lightlightblue
    ec["function"] = col.lightlightcyan
    
    ec["self"] = col.lightlightred
    
    indh["%("] = col.lightlightyellow
    indh["%)"] = col.lightlightyellow
    indh["%{"] = col.lightlightyellow
    indh["%}"] = col.lightlightyellow
    indh["%["] = col.lightlightyellow
    indh["%]"] = col.lightlightyellow
    
    hlc["[0-9]+"] = col.lightlightmagenta
    
    hlc["true"] = col.lightlightgreen
    hlc["false"] = col.lightlightred
    
    indh["%+"] = col.lightlightyellow
    indh["%-"] = col.lightlightyellow
    indh["/"] = col.lightlightyellow
    indh["%*"] = col.lightlightyellow
    indh["%%"] = col.lightlightyellow
    indh["^"] = col.lightlightyellow
    indh["~="] = col.lightlightyellow
    indh["=="] = col.lightlightyellow
    hlc["="] = col.lightlightyellow
    indh["<"] = col.lightlightyellow
    indh[">"] = col.lightlightyellow
end

local f = arg[1] -- table.concat(arg, " ")
--print(f)
--1print((arg[2] and (arg[2] .. ":") or "Terminal_cmd:") .. f)
local s, t = pcall(readProjectTab, (arg[2] and (arg[2] .. ":") or "Terminal_cmd:") .. f)
if not s then
    print("No cmd tab " .. f .. ", searching for file")
    t = readText("Documents:" .. f)
    s = t
end
if s then
    --print(tostring(pesc))
    t = "\n" .. t .. "\n"
    for i, v in pairs(ec) do
        --_print(v)
        t = t:gsub("([^A-Za-z0-9])(" .. i .. ")([^A-Za-z0-9])", function(a,b,c)return a..v..b..c.."\255" end)
    end
    for i, v in pairs(hlc) do
        --_print(v)
        t = t:gsub("([^A-Za-z0-9])(" .. i .. ")", function(a,b) return a..v..b.."\255" end)
        t = t:gsub("(" .. i .. ")([^A-Za-z0-9])", function(a,b) return v..a.."\255"..b end)
    end
    for i, v in pairs(indh) do
        --_print(v)
        t = t:gsub("(" .. i .. ")",  function(a) return v..a.."\255" end)
    end
    for str in t:gmatch('%b""') do
        local o = str
        for i, v in pairs(col) do
            str = str:gsub(v, "")
        end
        str = str:gsub("%%", function()return "%%" end)
        t = t:gsub("(" .. pesc(o) .. ")", col.lightlightorange .. str .. "\255")
    end
    ---[[
    for str in t:gmatch("%b''") do
        local o = str
        for i, v in pairs(col) do
            str = str:gsub(v, "")
        end
        str = str:gsub("%%", function()return "%%" end)
        t = t:gsub("(" .. pesc(o) .. ")", col.lightlightorange .. str .. "\255")
    end
    for str in t:gmatch("%-\255" .. col.lightlightyellow .. "%-\255.-\n") do
        local o = str
        for i, v in pairs(col) do
            str = str:gsub(v, "")
        end
        str = str:gsub("%%", function()return "%%" end)
        t = t:gsub(pesc(o), col.gray .. str .. "\255")
    end
    for str in t:gmatch("[^-]%-%-%[%[.-%]%]") do
        local o = str
        for i, v in pairs(col) do
            str = str:gsub(v, "")
        end
        for l in (str .. "\n"):gmatch("[^\n]+\n") do -- so fancy
            str = str:gsub(pesc(l), col.gray .. l)
        end
        str = str:gsub("%%", function()return "%%" end)
        t = t:gsub(pesc(o), col.gray .. str .. "\255")
    end
    --]]
    print("Parsed")
    local m, occ = t:gsub("\n", "")
    local n = 1
    local title = f .. ".lua (" .. occ .. " lines)"
    term.print("\1\255" .. title .. (" "):rep(termW - title:len() - 1) .. "\n\1")
    for s in t:gmatch("([^\n]-)\n") do
        term.print("\4\1" .. n .. (" "):rep(#(tostring(occ)) - #tostring(n)) .. ":\1\255 " .. s .. "\n")
        n = n + 1
    end
else
    print("\5Error: no cmd tab " .. f .. "!\255")
end
--[=[END_TAB]=]
--[=[TAB:log]=]
jmenuOptions = {"New entry", "List entries", "Search entries", "Search for text in entries", "Setup", "Exit"}
jmenuSelect = 1

function jNewLog()
    term.read("Enter your password: ", true)
    coroutine.yield()
    if md5.sumhexa(term.getInput()) == term.readfile("jPass") then
        term.read("\nLog Title: ")
        coroutine.yield()
        local title = term.getInput()
        term.read("\nEnter your log: ", false, "  ")
        coroutine.yield()
        local e = term.readfile("jEntries") or ""
        local t = getTimeData()
        e = e .. os.time() .. ":{"..title.."}{" .. term.getInput() .. "};\n"
        term.savefile("jEntries", e)
    else
        print("Wrong password!")
    end
    term.enter(jmainMenu)
end

function jList()
    term.read("Enter your password: ", true)
    coroutine.yield()
    if md5.sumhexa(term.getInput()) == term.readfile("jPass") then
        local t = term.readfile("jEntries")
        local e = {}
        for time, title, val in t:gmatch("(%d+):(%b{}){(.-)};\n") do
            term.print("\n\1" .. os.date("%c", tonumber(time)) .. ": " .. title:sub(2,-2) .. "\1\n" .. val .. "\n")
        end
    else
        print("Wrong password!")
        print(term.getInput())
    end
    term.read("", false, "")
    term.enter(jmainMenu)
end

function jSearch()
    term.read("Enter your password: ", true)
    coroutine.yield()
    if md5.sumhexa(term.getInput()) == term.readfile("jPass") then
        term.read("Search query: ")
        coroutine.yield()
        local t = term.readfile("jEntries")
        local e = {}
        for time, title, val in t:gmatch("(%d+):(%b{}){(.-)};\n") do
            if title:lower():find(term.getInput():lower():gsub("\n", "")) then
                term.print("\n\1" .. os.date("%c", tonumber(time)) .. ": " .. title:sub(2,-2) .. "\1\n" .. val .. "\n")
            end
        end
    else
        print("Wrong password!")
    end
    term.read("", false, "")
    term.enter(jmainMenu)
end

function jSearchText()
    term.read("Enter your password: ", true)
    coroutine.yield()
    if md5.sumhexa(term.getInput()) == term.readfile("jPass") then
        term.read("Search query: ")
        coroutine.yield()
        local t = term.readfile("jEntries")
        local e = {}
        for time, title, val in t:gmatch("(%d+):(%b{}){(.-)};\n") do
            if val:lower():find(term.getInput():lower():gsub("\n", "")) then
                term.print("\n\1" .. os.date("%c", tonumber(time)) .. ": " .. title:sub(2,-2) .. "\1\n" .. val:gsub(term.getInput(), "\254" .. term.getInput() .. "\254") .. "\n")
            end
        end
    else
        print("Wrong password!")
    end
    term.read("", false, "")
    term.enter(jmainMenu)
end

function jSetup()
    term.read("Enter your password:  ", true)
    coroutine.yield()
    local first = term.getInput()
    term.read("Retype your password: ", true)
    coroutine.yield()
    if term.getInput() == first then
        term.savefile("jPass", md5.sumhexa(first))
        term.savefile("jEntries", term.readfile("jEntries") or "")
    else
        term.print("Passwords did not match!\n")
    end
    term.enter(jmainMenu)
end

function jmainMenu(k)
    k = k or ""
    cmd.clear()
    if k == "l" or k == "a" then
        jmenuSelect = jmenuSelect % #jmenuOptions + 1
    elseif k == "p" or k == "q" then
        jmenuSelect = (jmenuSelect + #jmenuOptions - 2) % #jmenuOptions + 1
    end
    cur.y = 2
    for i, v in ipairs(jmenuOptions) do
        term.print((i == jmenuSelect and "\255" or col.gray) .. v .. (i == jmenuSelect and "\255" or col.white).."\n")
    end
    if k == "\n" and jNotFirstFrame then
        if jmenuSelect == 1 then
            term.coroutine = coroutine.create(jNewLog)
        elseif jmenuSelect == 2 then
            term.coroutine = coroutine.create(jList)
        elseif jmenuSelect == 3 then
            term.coroutine = coroutine.create(jSearch)
        elseif jmenuSelect == 4 then
            term.coroutine = coroutine.create(jSearchText)
        elseif jmenuSelect == 5 then
            term.coroutine = coroutine.create(jSetup)
        end
        term.exit("")
        jNotFirstFrame = false
    else
        jNotFirstFrame = true
    end
end

term.enter(jmainMenu)
--[=[END_TAB]=]
--[=[TAB:md5]=]
term.coroutine = coroutine.create(function()
    term.read("Enter the string to be encrypted: ", true)
    coroutine.yield()
    term.print("MD5: " .. md5.sumhexa(term.getInput()))
end)
--[=[END_TAB]=]
--[=[TAB:readpass]=]
term.coroutine = coroutine.create(function()
    term.read("Enter your password: ", true)
    coroutine.yield()
    term.print("You typed: " .. term.getInput())
end)

--[=[END_TAB]=]
--[=[TAB:sphere]=]

 
local shades = {'.', ':', '!', '*', 'o', 'e', '&', '#', '%', '@'}
 
local function normalize (vec)
    local len = math.sqrt(vec[1]^2 + vec[2]^2 + vec[3]^2)
    return {vec[1]/len, vec[2]/len, vec[3]/len}
end
 
local light = normalize{30, 30, -50}
 
local function dot (vec1, vec2)
    local d = vec1[1]*vec2[1] + vec1[2]*vec2[2] + vec1[3]*vec2[3]
    return d < 0 and -d or 0
end
 
local function draw_sphere (radius, k, ambient)
    for i = math.floor(-radius),-math.floor(-radius) do
        local x = i + .5
        local line = ''
        for j = math.floor(-2*radius),-math.floor(-2*radius) do
            local y = j / 2 + .5
            if x^2 + y^2 <= radius^2 then
                local vec = normalize{x, y, math.sqrt(radius^2 - x^2 - y^2)}
                local b = dot(light,vec) ^ k + ambient
                local intensity = math.floor ((1 - b) * #shades)
                line = line .. (shades[intensity] or shades[1])
            else
                line = line .. ' '
            end
        end
        print (line)
    end
end
 
draw_sphere (20, 4, 0.1)
draw_sphere (10, 2, 0.4)
--[=[END_TAB]=]
--[=[TAB:encode]=]
__e = 2.71828182845904523536028747135266249775724709369995
    
function __encrypt(str, key, offset, sc)
    local off = offset or 25
    local s = key or 0
    local rs = ""
    sc = sc or 50
    for n = 1, str:len() do
        local c = string.byte(str:sub(n, n + 1))
        c = (math.floor(c + (math.sin(s ^ __e) + 1) * sc) + off) % 255
        print(c)
        local nc = string.char(c)
        --print(c, nc)
        --print(rs)
        rs = rs .. nc
        --print(string.char(math.floor(c)), c)
        s = s + 1
    end
    --print(string.format("%q", str))
    --print(rs)
    return rs
end

function __decrypt(str, key, offset, sc)
    local off = offset or 25
    local s = key or 0
    local rs = ""
    sc = sc or 50
    for n = 1, str:len() do
        local c = string.byte(str:sub(n, n + 1))
        c = (math.ceil(c - off - (math.sin(s ^ __e) + 1) * sc)) % 255
        local nc = string.char(c)
        --print(c, nc)
        --print(rs)
        rs = rs .. nc
        --print(string.char(math.floor(c)), c)
        s = s + 1
    end
    --print(string.format("%q", str))
    --print(rs)
    return rs
end


--[=[END_TAB]=]
--[=[TAB:nano]=]
nano = nano or {}

if params.help then
    print(col.gray.."\1Usage: \255nano [filename]\1\nOpens filename for editing")
else
    term.coroutine = coroutine.create(function()
        if arg[1] then
            nano.fn = arg[1] .. ".txt"
            nano.text = readText("Documents:" .. arg[1])
            if not nano.text then
                return "No file"
            end
        else
            nano.fn = "[New file]"
            nano.text = ""
        end
        coroutine.yield()
        nano._, nano.lines = nano.text:gsub("\n", "")
        nano.head = nano.fn .. " (" .. nano.lines .. " lines)"
        term.print("\1\255"..nano.fn..(" "):rep(termW - #nano.head) .. "\1\n")
        coroutine.yield()
        nano.cline = 1
        for l in (nano.text.."\n"):gmatch(".-\n") do
            term.print(col.lightgray.."\1"..nano.cline..":"..(" "):rep(#(tostring(nano.lines))-#tostring(nano.cline)).."\1\255 "..l)
            nano.cline = nano.cline + 1
            if nano.cline%10==0 then coroutine.yield()end
        end
    end)
end
--[=[END_TAB]=]
--[=[TAB:dbar]=]
__DBX, __DBY = cur.x, cur.y
-- │─┐└┘┌
local s = "│─┐└┘┌"
for n = 1, 6 do print(s:sub(n,n):byte()) end

term.coroutine = coroutine.create(function()
    term.print("┌"..("─"):rep(termW-4).."┐\n│"..(" "):rep(termW-4).."│\n└"..("─"):rep(termW-4).."┘")
    cur.x = __DBX
    cur.y = __DBY+2
    for n = 1, termW-1 do
        term.print("#")
        coroutine.yield()
    end
end)

--[=[END_TAB]=]
--[=[TAB:cotest]=]
local f = function(input)
    term.print("Enter some text: ")
    term.read()
    coroutine.yield()
    --if ElapsedTime // 1 % 3 == 0 then coroutine.yield() end
    --alert(termH-cur.y)
    c[termH-cur.y][cur.x] = ansi[177]
    term.print("\nYou typed: \1" .. term.__READV .. "\1\n")
    
    --alert("test")
    for n = 0, 10 do
        term.print(n)
        if n < 10 then term.print(",") end
        coroutine.yield()
    end
end

term.coroutine = coroutine.create(f)
--[=[END_TAB]=]
--[=[TAB:for]=]
for n = 1, arg[1] do term.exec(arg[2] .. " " .. n, true, true) end
--[=[END_TAB]=]
--[=[TAB:nb]=]
if params.help then
    print("\1Usage: nb num\1\nPrints number num in binary form")
    return 0
elseif not arg[1] then
    print("Enter a number!")
    return -1
end

local s = ""
for n = 0, math.log(arg[1], 2) do
    s = s .. (arg[1] >> n & 1)
end
term.print(s)
--[=[END_TAB]=]
--[=[TAB:dist]=]
if not(arg[1]) or arg[1] == "help" then 
    print("\1Usage: distance x1, y1, x2, y2\1\nDisplays the distance between points (x1,y1) and (x2,y2)")
    return 1
end
if not arg[2] then
    return "Invalid argument format!"
end
if arg[1]:find("[%d%.%-]+%,[%d%.%-]+") and arg[2]:find("[%d%.%-]+%,[%d%.%-]+") then
    local x1, y1, x2, y2
    for x, y in arg[1]:gmatch("([%d%.%-]+)%,([%d%.%-]+)") do
        x1, y1 = x, y
    end
    for x, y in arg[2]:gmatch("([%d%.%-]+)%,([%d%.%-]+)") do
        x2, y2 = x, y
    end
else
    x1 = arg[1]
    y1 = arg[2]
    x2 = arg[3]
    y2 = arg[4]
end

x1 = tonumber(x1)
y1 = tonumber(y1)
x2 = tonumber(x2)
y2 = tonumber(y2)

if not(x1 and x2 and y1 and y2) then
    print("\5Error: invalid number!\255")
    return -1
end

local d = math.sqrt((x2-x1)^2 + (y2-y1)^2)

print("Distance: " .. d)
return true
--[=[END_TAB]=]
--[=[TAB:src]=]
if not arg[1] then
    print("\5Please specify a source tab!\255")
    return
end

local f = table.concat(arg, " ")
local s, t = pcall(readProjectTab, "Terminal_cmd:" .. f)
if s then
    t = t .. "\n"
    local m, occ = t:gsub("\n", "")
    local n = 1
    local title = f .. ".lua (" .. occ .. " lines)"
    term.print("\255\1" .. title .. (" "):rep(termW - title:len() - 1) .. "\1\n")
    for s in t:gmatch("([^\n]-)\n") do
        term.print("\4\1" .. n .. (" "):rep(#(tostring(occ)) - #tostring(n)) .. ":\1\255 " .. s .. "\n")
        n = n + 1
    end
else
    print("\5Error: no cmd tab " .. f .. "!\255")
end
--[=[END_TAB]=]
--[=[TAB:regtest]=]
local f = function(k)
    if tostring(k) == "" then
        term.exit()
    end
end

term.print("\255Press backspace to exit...\n")

term.enter(f)
--[=[END_TAB]=]
--[=[TAB:paramtest]=]
print("\1Params:\1\n")
for i, v in pairs(params) do
    print("\255" .. i .. " : \4" .. tostring(v) .. "\255\n")
end

print("\1Args:\1\n")
for i, v in ipairs(arg) do
    print("\255" .. i .. " : \4" .. v .. "\255\n")
end

return 1
--[=[END_TAB]=]
--[=[TAB:img]=]
if params.help then
    print("\1USAGE: img name_of_img\1\nDisplays an image as ascii art")
    return 1
end

return -2
--[=[END_TAB]=]
--[=[TAB:ansi]=]
if params.help then
    print("\255\1USAGE: ansi char\1\nPrints the ANSI value of char if char is a number, the character code if char is a non-number, or every ANSI character if char is not given")
elseif arg[1] then
    if tonumber(arg[1]) and tonumber(arg[1]) < 256 and tonumber(arg[1]) > 0 then
        print(arg[1] .. ": " .. arg[1]:char())
    else
        print(arg[1] .. ": " .. arg[1]:byte())
    end
else
    local s = "return '"
    for n = 32, 253 do
        s = s .. "\\" .. n
    end
    local f = loadstring(s .. "'")
    term.printRaw((params.bold and "\254" or "")..f()..(params.bold and "\254\n" or "\n"))
end

--[=[END_TAB]=]
--[=[TAB:edit]=]
cmd.clear()

local hdr = {}
local hs = "\255\1EDIT: "
for i, v in ipairs(arg) do
    hs = hs .. v .. " "
end
hs = hs .. "\1"
hs = trim(hs)
for n = 1, termW do
    if n <= #hs then
        hdr[n] = hs:sub(n, n)
    else
        hdr[n] = " "
    end
end

--term.row(termH, hdr)
local t = "\n\n" .. readText("Documents:" .. (arg and arg[1]))
print(t)

function editor(k)
    term.row(termH, hdr)
    cur.y = math.max(2, cur.y)
    if CurrentTouch.state == BEGAN and CurrentTouch.x > WIDTH - 25 then
        term.exit()
    end
end

term.enter(editor)

--[=[END_TAB]=]
--[=[TAB:load]=]
if arg[1] then
    loadProgram(arg[1], arg[2], arg[3], arg[4])
else
    print("Please specify a project to load!")
end

--[=[END_TAB]=]
--[=[TAB:systemlogin]=]
term.coroutine = coroutine.create(function()
    term.read_system_password(1)
    coroutine.yield()
    term.print(term.getInput() and "Success" or "Could not authenticate")
end)

--[=[END_TAB]=]
--[=[TAB:tabs]=]
local t = listProjectTabs(arg[1] or " ")
if t then
    for i, v in ipairs(t) do
        print(i .. ": " .. v)
    end
else
    return -1
end

--[=[END_TAB]=]
