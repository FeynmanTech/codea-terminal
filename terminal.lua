--[=[TAB:MD5]=]
md5 = {
  _VERSION     = "md5.lua 1.0.2",
  _DESCRIPTION = "MD5 computation in Lua (5.1-3, LuaJIT)",
  _URL         = "https://github.com/kikito/md5.lua",
  _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2013 Enrique García Cota + Adam Baldwin + hanzao + Equi 4 Software

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

-- bit lib implementions

local char, byte, format, rep, sub =
  string.char, string.byte, string.format, string.rep, string.sub
local bit_or, bit_and, bit_not, bit_xor, bit_rshift, bit_lshift

local ok, bit = pcall(require, 'bit')
if ok then
  bit_or, bit_and, bit_not, bit_xor, bit_rshift, bit_lshift = bit.bor, bit.band, bit.bnot, bit.bxor, bit.rshift, bit.lshift
else
  ok, bit = pcall(require, 'bit32')

  if ok then

    bit_not = bit.bnot

    local tobit = function(n)
      return n <= 0x7fffffff and n or -(bit_not(n) + 1)
    end

    local normalize = function(f)
      return function(a,b) return tobit(f(tobit(a), tobit(b))) end
    end

    bit_or, bit_and, bit_xor = normalize(bit.bor), normalize(bit.band), normalize(bit.bxor)
    bit_rshift, bit_lshift = normalize(bit.rshift), normalize(bit.lshift)

  else

    local function tbl2number(tbl)
      local result = 0
      local power = 1
      for i = 1, #tbl do
        result = result + tbl[i] * power
        power = power * 2
      end
      return result
    end

    local function expand(t1, t2)
      local big, small = t1, t2
      if(#big < #small) then
        big, small = small, big
      end
      -- expand small
      for i = #small + 1, #big do
        small[i] = 0
      end
    end

    local to_bits -- needs to be declared before bit_not

    bit_not = function(n)
      local tbl = to_bits(n)
      local size = math.max(#tbl, 32)
      for i = 1, size do
        if(tbl[i] == 1) then
          tbl[i] = 0
        else
          tbl[i] = 1
        end
      end
      return tbl2number(tbl)
    end

    -- defined as local above
    to_bits = function (n)
      if(n < 0) then
        -- negative
        return to_bits(bit_not(math.abs(n)) + 1)
      end
      -- to bits table
      local tbl = {}
      local cnt = 1
      local last
      while n > 0 do
        last      = n % 2
        tbl[cnt]  = last
        n         = (n-last)/2
        cnt       = cnt + 1
      end

      return tbl
    end

    bit_or = function(m, n)
      local tbl_m = to_bits(m)
      local tbl_n = to_bits(n)
      expand(tbl_m, tbl_n)

      local tbl = {}
      for i = 1, #tbl_m do
        if(tbl_m[i]== 0 and tbl_n[i] == 0) then
          tbl[i] = 0
        else
          tbl[i] = 1
        end
      end

      return tbl2number(tbl)
    end

    bit_and = function(m, n)
      local tbl_m = to_bits(m)
      local tbl_n = to_bits(n)
      expand(tbl_m, tbl_n)

      local tbl = {}
      for i = 1, #tbl_m do
        if(tbl_m[i]== 0 or tbl_n[i] == 0) then
          tbl[i] = 0
        else
          tbl[i] = 1
        end
      end

      return tbl2number(tbl)
    end

    bit_xor = function(m, n)
      local tbl_m = to_bits(m)
      local tbl_n = to_bits(n)
      expand(tbl_m, tbl_n)

      local tbl = {}
      for i = 1, #tbl_m do
        if(tbl_m[i] ~= tbl_n[i]) then
          tbl[i] = 1
        else
          tbl[i] = 0
        end
      end

      return tbl2number(tbl)
    end

    bit_rshift = function(n, bits)
      local high_bit = 0
      if(n < 0) then
        -- negative
        n = bit_not(math.abs(n)) + 1
        high_bit = 0x80000000
      end

      local floor = math.floor

      for i=1, bits do
        n = n/2
        n = bit_or(floor(n), high_bit)
      end
      return floor(n)
    end

    bit_lshift = function(n, bits)
      if(n < 0) then
        -- negative
        n = bit_not(math.abs(n)) + 1
      end

      for i=1, bits do
        n = n*2
      end
      return bit_and(n, 0xFFFFFFFF)
    end
  end
end

-- convert little-endian 32-bit int to a 4-char string
local function lei2str(i)
  local f=function (s) return char( bit_and( bit_rshift(i, s), 255)) end
  return f(0)..f(8)..f(16)..f(24)
end

-- convert raw string to big-endian int
local function str2bei(s)
  local v=0
  for i=1, #s do
    v = v * 256 + byte(s, i)
  end
  return v
end

-- convert raw string to little-endian int
local function str2lei(s)
  local v=0
  for i = #s,1,-1 do
    v = v*256 + byte(s, i)
  end
  return v
end

-- cut up a string in little-endian ints of given size
local function cut_le_str(s,...)
  local o, r = 1, {}
  local args = {...}
  for i=1, #args do
    table.insert(r, str2lei(sub(s, o, o + args[i] - 1)))
    o = o + args[i]
  end
  return r
end

local swap = function (w) return str2bei(lei2str(w)) end

local function hex2binaryaux(hexval)
  return char(tonumber(hexval, 16))
end

local function hex2binary(hex)
  local result, _ = hex:gsub('..', hex2binaryaux)
  return result
end

-- An MD5 mplementation in Lua, requires bitlib (hacked to use LuaBit from above, ugh)
-- 10/02/2001 jcw@equi4.com

local CONSTS = {
  0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
  0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
  0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
  0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
  0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
  0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
  0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
  0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
  0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
  0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
  0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
  0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
  0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
  0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
  0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
  0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
  0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
}

local f=function (x,y,z) return bit_or(bit_and(x,y),bit_and(-x-1,z)) end
local g=function (x,y,z) return bit_or(bit_and(x,z),bit_and(y,-z-1)) end
local h=function (x,y,z) return bit_xor(x,bit_xor(y,z)) end
local i=function (x,y,z) return bit_xor(y,bit_or(x,-z-1)) end
local z=function (f,a,b,c,d,x,s,ac)
  a=bit_and(a+f(b,c,d)+x+ac,0xFFFFFFFF)
  -- be *very* careful that left shift does not cause rounding!
  return bit_or(bit_lshift(bit_and(a,bit_rshift(0xFFFFFFFF,s)),s),bit_rshift(a,32-s))+b
end

local function transform(A,B,C,D,X)
  local a,b,c,d=A,B,C,D
  local t=CONSTS

  a=z(f,a,b,c,d,X[ 0], 7,t[ 1])
  d=z(f,d,a,b,c,X[ 1],12,t[ 2])
  c=z(f,c,d,a,b,X[ 2],17,t[ 3])
  b=z(f,b,c,d,a,X[ 3],22,t[ 4])
  a=z(f,a,b,c,d,X[ 4], 7,t[ 5])
  d=z(f,d,a,b,c,X[ 5],12,t[ 6])
  c=z(f,c,d,a,b,X[ 6],17,t[ 7])
  b=z(f,b,c,d,a,X[ 7],22,t[ 8])
  a=z(f,a,b,c,d,X[ 8], 7,t[ 9])
  d=z(f,d,a,b,c,X[ 9],12,t[10])
  c=z(f,c,d,a,b,X[10],17,t[11])
  b=z(f,b,c,d,a,X[11],22,t[12])
  a=z(f,a,b,c,d,X[12], 7,t[13])
  d=z(f,d,a,b,c,X[13],12,t[14])
  c=z(f,c,d,a,b,X[14],17,t[15])
  b=z(f,b,c,d,a,X[15],22,t[16])

  a=z(g,a,b,c,d,X[ 1], 5,t[17])
  d=z(g,d,a,b,c,X[ 6], 9,t[18])
  c=z(g,c,d,a,b,X[11],14,t[19])
  b=z(g,b,c,d,a,X[ 0],20,t[20])
  a=z(g,a,b,c,d,X[ 5], 5,t[21])
  d=z(g,d,a,b,c,X[10], 9,t[22])
  c=z(g,c,d,a,b,X[15],14,t[23])
  b=z(g,b,c,d,a,X[ 4],20,t[24])
  a=z(g,a,b,c,d,X[ 9], 5,t[25])
  d=z(g,d,a,b,c,X[14], 9,t[26])
  c=z(g,c,d,a,b,X[ 3],14,t[27])
  b=z(g,b,c,d,a,X[ 8],20,t[28])
  a=z(g,a,b,c,d,X[13], 5,t[29])
  d=z(g,d,a,b,c,X[ 2], 9,t[30])
  c=z(g,c,d,a,b,X[ 7],14,t[31])
  b=z(g,b,c,d,a,X[12],20,t[32])

  a=z(h,a,b,c,d,X[ 5], 4,t[33])
  d=z(h,d,a,b,c,X[ 8],11,t[34])
  c=z(h,c,d,a,b,X[11],16,t[35])
  b=z(h,b,c,d,a,X[14],23,t[36])
  a=z(h,a,b,c,d,X[ 1], 4,t[37])
  d=z(h,d,a,b,c,X[ 4],11,t[38])
  c=z(h,c,d,a,b,X[ 7],16,t[39])
  b=z(h,b,c,d,a,X[10],23,t[40])
  a=z(h,a,b,c,d,X[13], 4,t[41])
  d=z(h,d,a,b,c,X[ 0],11,t[42])
  c=z(h,c,d,a,b,X[ 3],16,t[43])
  b=z(h,b,c,d,a,X[ 6],23,t[44])
  a=z(h,a,b,c,d,X[ 9], 4,t[45])
  d=z(h,d,a,b,c,X[12],11,t[46])
  c=z(h,c,d,a,b,X[15],16,t[47])
  b=z(h,b,c,d,a,X[ 2],23,t[48])

  a=z(i,a,b,c,d,X[ 0], 6,t[49])
  d=z(i,d,a,b,c,X[ 7],10,t[50])
  c=z(i,c,d,a,b,X[14],15,t[51])
  b=z(i,b,c,d,a,X[ 5],21,t[52])
  a=z(i,a,b,c,d,X[12], 6,t[53])
  d=z(i,d,a,b,c,X[ 3],10,t[54])
  c=z(i,c,d,a,b,X[10],15,t[55])
  b=z(i,b,c,d,a,X[ 1],21,t[56])
  a=z(i,a,b,c,d,X[ 8], 6,t[57])
  d=z(i,d,a,b,c,X[15],10,t[58])
  c=z(i,c,d,a,b,X[ 6],15,t[59])
  b=z(i,b,c,d,a,X[13],21,t[60])
  a=z(i,a,b,c,d,X[ 4], 6,t[61])
  d=z(i,d,a,b,c,X[11],10,t[62])
  c=z(i,c,d,a,b,X[ 2],15,t[63])
  b=z(i,b,c,d,a,X[ 9],21,t[64])

  return A+a,B+b,C+c,D+d
end

----------------------------------------------------------------

function md5.sumhexa(s)
  local msgLen = #s
  local padLen = 56 - msgLen % 64

  if msgLen % 64 > 56 then padLen = padLen + 64 end

  if padLen == 0 then padLen = 64 end

  s = s .. char(128) .. rep(char(0),padLen-1) .. lei2str(8*msgLen) .. lei2str(0)

  assert(#s % 64 == 0)

  local t = CONSTS
  local a,b,c,d = t[65],t[66],t[67],t[68]

  for i=1,#s,64 do
    local X = cut_le_str(sub(s,i,i+63),4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4)
    assert(#X == 16)
    X[0] = table.remove(X,1) -- zero based!
    a,b,c,d = transform(a,b,c,d,X)
  end

  return format("%08x%08x%08x%08x",swap(a),swap(b),swap(c),swap(d))
end

function md5.sum(s)
  return hex2binary(md5.sumhexa(s))
end

--return md5
--[=[END_TAB]=]
--[=[TAB:ANSI]=]
ansi = {}

exceptions = {}

ansi[32] = [[ ]]
ansi[33] = [[!]]
ansi[34] = [["]]
ansi[35] = [[#]]
ansi[36] = [[$]]
ansi[37] = [[%]]
ansi[38] = [[&]]
ansi[39] = [[']]
ansi[40] = [[(]]
ansi[41] = [[)]]
ansi[42] = [[*]]
ansi[43] = [[+]]
ansi[44] = [[,]]
ansi[45] = [[-]]
ansi[46] = [[.]]
ansi[47] = [[/]]
ansi[48] = [[0]]
ansi[49] = [[1]]
ansi[50] = [[2]]
ansi[51] = [[3]]
ansi[52] = [[4]]
ansi[53] = [[5]]
ansi[54] = [[6]]
ansi[55] = [[7]]
ansi[56] = [[8]]
ansi[57] = [[9]]
ansi[58] = [[:]]
ansi[59] = [[;]]
ansi[60] = [[<]]
ansi[61] = [[=]]
ansi[62] = [[>]]
ansi[63] = [[?]]
ansi[64] = [[@]]
ansi[65] = [[A]]
ansi[66] = [[B]]
ansi[67] = [[C]]
ansi[68] = [[D]]
ansi[69] = [[E]]
ansi[70] = [[F]]
ansi[71] = [[G]]
ansi[72] = [[H]]
ansi[73] = [[I]]
ansi[74] = [[J]]
ansi[75] = [[K]]
ansi[76] = [[L]]
ansi[77] = [[M]]
ansi[78] = [[N]]
ansi[79] = [[O]]
ansi[80] = [[P]]
ansi[81] = [[Q]]
ansi[82] = [[R]]
ansi[83] = [[S]]
ansi[84] = [[T]]
ansi[85] = [[U]]
ansi[86] = [[V]]
ansi[87] = [[W]]
ansi[88] = [[X]]
ansi[89] = [[Y]]
ansi[90] = [[Z]]
ansi[91] = [[[]]
ansi[92] = [[\]]
ansi[93] = "]"
ansi[94] = [[^]]
ansi[95] = [[_]]
ansi[96] = [[`]]
ansi[97] = [[a]]
ansi[98] = [[b]]
ansi[99] = [[c]]
ansi[100] = [[d]]
ansi[101] = [[e]]
ansi[102] = [[f]]
ansi[103] = [[g]]
ansi[104] = [[h]]
ansi[105] = [[i]]
ansi[106] = [[j]]
ansi[107] = [[k]]
ansi[108] = [[l]]
ansi[109] = [[m]]
ansi[110] = [[n]]
ansi[111] = [[o]]
ansi[112] = [[p]]
ansi[113] = [[q]]
ansi[114] = [[r]]
ansi[115] = [[s]]
ansi[116] = [[t]]
ansi[117] = [[u]]
ansi[118] = [[v]]
ansi[119] = [[w]]
ansi[120] = [[x]]
ansi[121] = [[y]]
ansi[122] = [[z]]
ansi[123] = [[{]]
ansi[124] = [[|]]
ansi[125] = [[}]]
ansi[126] = [[~]]
ansi[127] = [[ ]]
ansi[128] = [[Ç]]
ansi[129] = [[ü]]
ansi[130] = [[é]]
ansi[131] = [[â]]
ansi[132] = [[ä]]
ansi[133] = [[à]]
ansi[134] = [[å]]
ansi[135] = [[ç]]
ansi[136] = [[ê]]
ansi[137] = [[ë]]
ansi[138] = [[è]]
ansi[139] = [[ï]]
ansi[140] = [[î]]
ansi[141] = [[ì]]
ansi[142] = [[Ä]]
ansi[143] = [[Å]]
ansi[144] = [[É]]
ansi[145] = [[æ]]
ansi[146] = [[Æ]]
ansi[147] = [[ô]]
ansi[148] = [[ö]]
ansi[149] = [[ò]]
ansi[150] = [[û]]
ansi[151] = [[ù]]
ansi[152] = [[ÿ]]
ansi[153] = [[Ö]]
ansi[154] = [[Ü]]
ansi[155] = [[¢]]
ansi[156] = [[£]]
ansi[157] = [[¥]]
ansi[158] = [[₧]]
ansi[159] = [[ƒ]]
ansi[160] = [[á]]
ansi[161] = [[í]]
ansi[162] = [[ó]]
ansi[163] = [[ú]]
ansi[164] = [[ñ]]
ansi[165] = [[Ñ]]
ansi[166] = [[ª]]
ansi[167] = [[º]]
ansi[168] = [[¿]]
ansi[169] = [[⌐]]
ansi[170] = [[¬]]
ansi[171] = [[½]]
ansi[172] = [[¼]]
ansi[173] = [[¡]]
ansi[174] = [[«]]
ansi[175] = [[»]]
ansi[176] = [[░]]
ansi[177] = [[▒]]
ansi[178] = [[▓]]   --exceptions[178] = true
ansi[179] = [[│]] -- │─┐└┘┌
ansi[180] = [[┤]]
ansi[181] = [[╡]]
ansi[182] = [[╢]]
ansi[183] = [[╖]]
ansi[184] = [[╕]]
ansi[185] = [[╣]]
ansi[186] = [[║]]
ansi[187] = [[╗]]
ansi[188] = [[╝]]
ansi[189] = [[╜]]
ansi[190] = [[╛]]
ansi[191] = [[┐]]
ansi[192] = [[└]]
ansi[193] = [[┴]]
ansi[194] = [[┬]]
ansi[195] = [[├]]
ansi[196] = [[─]]
ansi[197] = [[┼]]
ansi[198] = [[╞]]
ansi[199] = [[╟]]
ansi[200] = [[╚]]
ansi[201] = [[╔]]
ansi[202] = [[╩]]
ansi[203] = [[╦]]
ansi[204] = [[╠]]
ansi[205] = [[═]]
ansi[206] = [[╬]]
ansi[207] = [[╧]]
ansi[208] = [[╨]]
ansi[209] = [[╤]]
ansi[210] = [[╥]]
ansi[211] = [[╙]]
ansi[212] = [[╘]]
ansi[213] = [[╒]]
ansi[214] = [[╓]]
ansi[215] = [[╫]]
ansi[216] = [[╪]]
ansi[217] = [[┘]]
ansi[218] = [[┌]]
ansi[219] = [[█]]   --exceptions[219] = true
ansi[220] = [[▄]]   exceptions[220] = true
ansi[221] = [[▌]]   exceptions[221] = true
ansi[222] = [[▐]]   exceptions[222] = true
ansi[223] = [[▀]]   exceptions[223] = true
ansi[224] = [[α]]
ansi[225] = [[ß]]
ansi[226] = [[Γ]]
ansi[227] = [[π]]
ansi[228] = [[Σ]]
ansi[229] = [[σ]]
ansi[230] = [[µ]]
ansi[231] = [[τ]]
ansi[232] = [[Φ]]   exceptions[232] = true
ansi[233] = [[Θ]]   exceptions[233] = true
ansi[234] = [[Ω]]
ansi[235] = [[δ]]   exceptions[235] = true
ansi[236] = [[∞]]
ansi[237] = [[φ]]   exceptions[237] = true
ansi[238] = [[ε]]
ansi[239] = [[∩]]
ansi[240] = [[≡]]
ansi[241] = [[±]]
ansi[242] = [[≥]]
ansi[243] = [[≤]]
ansi[244] = [[⌠]]
ansi[245] = [[⌡]]
ansi[246] = [[÷]]
ansi[247] = [[≈]]
ansi[248] = [[°]]
ansi[249] = [[∙]]
ansi[250] = [[·]]
ansi[251] = [[√]]
ansi[252] = [[ⁿ]]
ansi[253] = [[²]]
ansi[254] = [[■]]   exceptions[254] = true
ansi[255] = [[ ]]

for n = 1, 31 do ansi[n] = " " end

for i, v in ipairs(ansi) do
    ansi[v] = i
end

ansiStr = table.concat(ansi)
saveProjectTab("ANSI_STR", "ansiStr = [=["..ansiStr.."]=]")

--[=[END_TAB]=]
--[=[TAB:ANSI_STR]=]
ansiStr = [=[                                !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■ ]=]
--[=[END_TAB]=]
--[=[TAB:utf8]=]
function Utf8to32(utf8str)
	assert(type(utf8str) == "string")
	local res, seq, val = {}, 0, nil
	for i = 1, #utf8str do
		local c = string.byte(utf8str, i)
		if seq == 0 then
			table.insert(res, val)
			seq = c < 0x80 and 1 or c < 0xE0 and 2 or c < 0xF0 and 3 or
			      c < 0xF8 and 4 or --c < 0xFC and 5 or c < 0xFE and 6 or
				  error("invalid UTF-8 character sequence")
			val = c & 2^(8-seq) - 1
		else
			val = (val << 6) | (c & 0x3F)
		end
		seq = seq - 1
	end
	table.insert(res, val)
	table.insert(res, 0)
	return res
end

function ANSI(s)
    if s:match(utf8.charpattern) then return string.pack(("I4"):rep(utf8.len(s) or 0), utf8.codepoint(s)) else return " " end
end
--[[
for n = 255, 65536 do
    local c = utf8.char(n)
    ansi[utf8.codepoint(c)] = c
end]]

--[=[END_TAB]=]
--[=[TAB:Interface]=]
function drawInterface()
    tint(255, 125)
    sprite("Documents:arrow_down", -50, 10)
    sprite("Documents:arrow_left", -75, 35)
    sprite("Documents:arrow_up", -50, 60)
    sprite("Documents:arrow_right", -25, 35)
    fill(255,125)
    rect(-60, 25, 20, 20)
end

--[=[END_TAB]=]
--[=[TAB:TextRender]=]
--[[
fsize = {}
fsize.h = 11     -- height
fsize.xh = 7    -- x-height
fsize.desc = 3  -- descent
fsize.fh = fsize.h + fsize.desc

fsize.w = 10
--]]

--

textren = textren or {}

textren.font = readImage("Documents:FDATA_MODES")

textren.vertex = [[
//
// A basic vertex shader
//

//This is the current model * view * projection matrix
// Codea sets it automatically
uniform mat4 modelViewProjection;

//This is the current mesh vertex position, colo 0and tex coord
// Set automatically
attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;

//This is an output variable that will be passed to the fragment shader
varying highp vec4 vColor;
varying highp vec2 vTexCoord;

// ARRAYSETUP

void main()
{
    //Pass the mesh color to the fragment shader
    vColor = color;
    vTexCoord = texCoord;
    
    //Multiply the vertex position by our combined transform
    gl_Position = modelViewProjection * position;
    // ARRAYS
}
]]

textren.fragment = [[
//
// A basic fragment shader
//

//Default precision qualifier
precision highp float;

//This represents the current texture on the mesh
uniform highp sampler2D texture;

//The interpolated vertex color for this fragment
varying vec4 vColor;

//The interpolated texture coordinate for this fragment
varying vec2 vTexCoord;

uniform highp sampler2D font;
uniform highp sampler2D text;
uniform highp sampler2D colormap;

uniform float fw;
uniform float tw;
uniform float fh;

uniform float scale;

uniform float fs;

uniform float tx;

uniform float rows;

void main()
{
    vec2 pos = vec2( gl_FragCoord.xy );
    pos.x -= tx;
    //Sample the texture at the interpolated coordinate
    //highp vec4 col = vColor * texture2D(font, vTexCoord);

    float posInText = vTexCoord.x;
    vec4 ccol = texture2D(text, vec2(posInText, vTexCoord.y));
    float characterX = float(int(ccol.r*255.))/255. * fw;
    float characterY = ccol.g*255./rows;

    float textPos = mod(pos.x, fs * scale) / scale + characterX;
    float textPosShifted = textPos / fw;
    float currentPixel = texture2D(font, vec2(textPosShifted, mod(vTexCoord.y*rows, 1.0)/fh+characterY)).a;

    vec4 cmap = texture2D(colormap, vec2(posInText, vTexCoord.y));
    int pix = 0;

    gl_FragColor = vec4(cmap.rgb, currentPixel);
    if (ccol.a == .0) {
        gl_FragColor.a = 1. - gl_FragColor.a;
    }
}
]]

--[[
shader("Documents:Dither")
--]]

function loadFont(size, str)
    
    local fontShader = shader(textren.vertex, textren.fragment)
    
    -- Create a mesh
    local m = mesh()
    
    -- Set vertices
    m.vertices = triangulate{
        vec2(0,0),
        vec2(str.width*4*size/2,0),
        vec2(str.width*4*size/2,4*size),
        vec2(0,4*size)
    }
    m.texCoords = triangulate{
        vec2(0,0),
        vec2(1,0),
        vec2(1,1),
        vec2(0,1)
    }
                    
    -- Set all vertex colors to white
    m:setColors(color(255))
    
    m.shader = fontShader
    m.shader.font = textren.font
    m.shader.text = str
    
    m.shader.rows = str.height
    
    m.shader.texture = m.shader.font
    
    m.shader.scale = size
    
    if textren.font then
        m.shader.fw = textren.font.width
        m.shader.tw = m.shader.text.width
    else
        m.shader.fw = 100
        m.shader.tw = 75
    end
    
    m.shader.fh = 8
    
    m.shader.fs = 4
    
    m.shader.tx = 10*size - ElapsedTime*100
    
    return m

end

function drawFont(m, text, colormap)
    m.shader.tx = math.floor((modelMatrix())[13]*2)
    if text then 
        m.shader.text = text
        m.shader.tw = m.shader.text.width
        local s = 4
        m.vertices = triangulate{
            vec2(0,0),--text.height),
            vec2((m.shader.text.width)*s*m.shader.scale/2,0),--text.height-2),
            vec2((m.shader.text.width)*s*m.shader.scale/2,s*m.shader.scale*text.height),
            vec2(0,s*m.shader.scale*text.height)
        }
        m.shader.rows = text.height
        m.shader.colormap = colormap
    end
    m:draw()
    --print(modelMatrix())
end
--loadFont()
--[=[END_TAB]=]
--[=[TAB:Icon]=]
function makeicon()
    noSmooth()
    local cmap = image(4,1)
    --setContext(cmap)
    for n=1,4 do cmap:set(n,1,color(255)) end
    local i = image(342, 342)
    setContext(i)
    background(0)
    fill(255)
    fontSize(200)
    textMode(CORNER)
    local ti = image(20,math.floor(HEIGHT/2/16*4/4)+1)
    setContext(ti)
    background(0,255)
    setContext(i)
    local m = "Mockterm v8.2.0     powered by txtrn    (c) FLC, 2015       Source code is      available on Git"
    for n = 1, #m do
        ti:set((n-1)%20+1, 10 - (n-1) // 20, color(m:sub(n,n):byte(), n <= 40 and 3 or 0, 0))
    end
    local t = loadFont(8, ti)
    font("Courier")
    --text(">_", 25, 25)
    translate(10.5,10)
    drawFont(t, ti, cmap)
    setContext()
    saveImage("Project:Icon", i)
end

--[=[END_TAB]=]
--[=[TAB:LoadChars]=]
if not(readImage("Project:char32") or true) then
    setup = function()
        print("Please wait while charsprites are loaded...")
        local chr, chri = {}, {}
        
        local s = 14
        cfont = "Inconsolata"
        
        stroke(255)
        fill(255)
        textMode(CORNER)
        font(cfont)
        fontSize(s)
        for c = 0, 255 do
            fill(255)
            local char = string.char(c)
            chr[char] = image(s/2, s+1)
            setContext(chr[char])
            --background(0)
            text(ansi[c] and ansi[c] or char, 0, 0)
            setContext()
            chri[char] = image(s/2, s+1)
            setContext(chri[char])
            background(255, 255, 255, 255)
            fill(0)
            text(char, 0, 0)
            setContext()
        end
        
        for i, v in pairs(chr) do
            --print(v)
            saveImage("Project:char" .. string.byte(i), v)
            saveImage("Project:ichar" .. string.byte(i), chri[i])
        end
        print"Finished loading charsprites - you may need to restart the project"
    end
end

--[=[END_TAB]=]
--[=[TAB:Main]=]
-- Terminal

--[[
readText("Project:UserData")
--]]

function setup()
    --FS = 1
    term.fmesh = loadFont(FS, term.text)
    loadChars()
    makeicon()
    displayMode(FULLSCREEN_NO_BUTTONS)
    loadCmds()
    onStart()
    dt = readImage("Documents:dt") or image(0,0) -- optional terminal desktop, probably a nice-looking gradient
    _print = print
        
    function pesc(x)
        return (x:gsub('%%', function()return "%%" end)
            :gsub('%^', '%%^')
            :gsub('%$', '%%$')
            :gsub('%(', '%%(')
            :gsub('%)', '%%)')
            :gsub('%.', '%%.')
            :gsub('%[', '%%[')
            :gsub('%]', '%%]')
            :gsub('%*', '%%*')
            :gsub('%+', '%%+')
            :gsub('%-', '%%-')
            :gsub('%?', '%%?')
        )
    end
    if readGlobalData("term_cmd") and readGlobalData("term_lib") and readProjectData("USER") then
        term.print(oentry)
    elseif readText("Project:UserData") and not(readProjectData"USER") and not(readGlobalData("term_cmd") and readGlobalData("term_lib")) then
        term.print("\1Welcome to MockTerm ver. 8.0!\1\nTo list commands, enter 'list' or 'help'. The two commands are exact copies of each other.\nTo get help for an individual command, type, 'help command_name'.\n\n")
        term.print("Setting a command project will allow users to easily add new commands - this can be done by creating anew tab in the command project, with the same name as the command being created.\n\nWould you like to register a command project now? (y/n) ")
        
        local cl = 0
        
        local getCmdLib = function(k)
            cur.y = cl
            if k == "\n" then
                local pn = trim(table.concat(c[termH - cur.y]):gsub("Project libraries: ", ""))
                saveGlobalData("term_lib", pn)
                term.print("\nCommand libraries saved as: " .. pn .. "\n")
                term.exit(oentry)
                loadCmds()
            end
        end
        
        local getCmdProj = function(k)
            cur.y = cl
            if k == "\n" then
                local pn = trim(table.concat(c[termH - cur.y]):gsub("Project name: ", ""))
                saveGlobalData("term_cmd", pn)
                term.print("\nCommand project saved as: " .. pn .. "\n")
                term.exit("")
                term.enter(getCmdLib)
                term.print("Project libraries: ")
                cl = cur.y
            end
        end
        
        local isAddingProject = false
        local proc = function(k)
            if k then
                term.exit("\n")
                if k == "y" then
                    term.enter(getCmdProj)
                    term.print("Project name: ")
                    cl = cur.y
                else
                    term.print(oentry)
                end
            end
        end
        term.enter(proc)
    else
        term.elevationColors = {[0]="\255",[1]="\160",[2]="\162"}
        loginY = cur.y
        loginO = {}
        if term.__USER then
            for i, v in pairs(term.__USER) do
                table.insert(loginO, i)
            end
        end
        table.insert(loginO, "[New user]")
        table.insert(loginO, "Exit")
        loginC = 1
        lnewUser = function()
            cmd.clear()
            cur.y = cur.y + 1
            local uelev = 0
            if #loginO == 2 then
                term.print("As the first user created, this account will have full system privileges.\n")
                uelev = 2
            end
            term.read("Username: ")
            coroutine.yield()
            local u = term.__READV
            term.read("Password:         ", true)
            coroutine.yield()
            local p1 = term.__READV
            term.read("Confirm password: ", true)
            coroutine.yield()
            local p2 = term.__READV
            if p1 ~= p2 then
                alert("Passwords did not match!")
                term.enter(loginF)
            elseif term.__USER and term.__USER[u] then
                alert("User already exists!")
                term.enter(loginF)
            else
                term.__USER = term.__USER or {}
                term.__USER[u] = {}
                term.__USER[u].pass = md5.sumhexa(p2)
                term.__USER[u].autorun = {}
                term.__USER[u].elevation = uelev
                saveText("Project:UserData", json.encode(term.__USER))
                restart()
            end
        end
        loginF = function(k)
            cmd.clear()
            k = k or ""
            cur.y = loginY
            if k:find("[qp]") then
                loginC = (loginC + #loginO - 2) % #loginO + 1
            elseif k:find("[al]") then
                loginC = loginC % #loginO + 1
            elseif k == "\n" then
                if loginC == #loginO then
                    close()
                elseif loginC == #loginO - 1 then
                    term.exit()
                    term.coroutine = coroutine.create(lnewUser)
                else
                    term.exit()
                    term.coroutine = coroutine.create(function()
                        cmd.clear()
                        term.read("Password: ", true)
                        coroutine.yield()
                        if term.__USER[loginO[loginC]].pass == md5.sumhexa(term.__READV) then
                            saveProjectData("USER", loginO[loginC])
                            restart()
                        else
                            term.print("Wrong password!")
                            coroutine.yield()
                        end
                    end)
                end
            end
            term.print("\n\254 Select user...\254\n\218" .. ("\196"):rep(termW - 3) .. "\191")
            for n = 0, #loginO do
                term.print(
                    (n == #loginO - 2 and "\195" or "\179") .. 
                    ((n == #loginO - 2 and "\196" or " ")):rep(termW - 3) .. 
                    (n == #loginO - 2 and "\180" or "\179")
                )
            end
            term.print("\192" .. ("\196"):rep(termW - 3) .. "\217\160Admin\n\162Superuser\n")
            cur.y = cur.y - #loginO - 4
            for i, v in ipairs(loginO) do
                term.print((i==loginC and "\179\254 " or "\179\3 ") .. term.elevationColors[term.__USER[v] and term.__USER[v].elevation or 0] .. v .. (i==loginC and "\254\255\n" or "\255\n"))
                if i == #loginO - 2 then
                    cur.y = cur.y + 1
                end
            end
            term.print("\192")
            cur.y = cur.y + 1
        end
        term.enter(loginF)
    end
    term.scroll = 0
end

ctx, cty = 0, 0

ibg = 50

-- This function gets called once every frame
function draw()
    -- This sets a dark background color 
    --background(255, 255, 255, 255)

    -- This sets the line thickness
    noStroke()
    background(term.bg)
    --[[
    spriteMode(CENTER)
    tint(255,255,255,ibg)
    if dt then sprite(dt, WIDTH/2, HEIGHT/4*3, dt.width / 2, dt.height / 2) end
    --]]
    --spriteMode(CORNER)
    
    --rectMode(CENTER)
    
    ctx = WIDTH / 2 - termW * chx / 2
    cty = math.floor(HEIGHT / 2 - chy)

    -- Do your drawing here
    translate(ctx*4/FS, cty)-- + math.floor(term.scroll*FS/2))
    noSmooth()
    showKeyboard()
    fps()
    term.main()
    --translate(-100, 0)
    --translate(0, -math.floor(term.scroll))
    drawInterface()
    
end

local scrolling = 0
local cscroll = 0

local lt = 0

--[[
sprite("Documents:arrow_down", -50, 10)
    sprite("Documents:arrow_left", -75, 35)
    sprite("Documents:arrow_up", -50, 60)
    sprite("Documents:arrow_right", -25, 35)
--]]

local function tscroll(x, y)
    if bounds(x - ctx, -60, -40) and bounds(y - cty, 0, 20) then
        term.move(0, 1)
    elseif bounds(x - ctx, -60, -40) and bounds(y - cty, 50, 70) then
        term.move(0, -1)
    elseif bounds(x - ctx, -85, -65) and bounds(y - cty, 25, 45) then
        term.move(-1, 0)
    elseif bounds(x - ctx, -35, -15) and bounds(y - cty, 25, 45) then
        term.move(1, 0)
    end
end

function touched(touch)
    if touch.state == BEGAN then
        scrolling = touch.y
        cscroll = term.getscroll()
        lt = ElapsedTime
        tscroll(touch.x, touch.y)
    elseif not term.locked then
        --term.scroll = chy - (cscroll + (scrolling - touch.y)) % chy
        term.setscroll((cscroll + (scrolling - touch.y) / chy))
    end
    if (touch.x>WIDTH-75 and touch.y>HEIGHT/2 and touch.y<HEIGHT/2+24 and touch.state == ENDED) then
        if not term.__READING then
            term.__READV = ""
        end
        cur.y = cur.y + 1
        --alert("returning")
        term.__READING = false
        term.__LASTTOUCH = true
    end
end


--[=[END_TAB]=]
--[=[TAB:Autorun]=]
function onStart()
    if readText("Project:UserData") then
        term.__USER = json.decode(readText("Project:UserData"))
        if readProjectData("USER") then
            for i, v in pairs(term.__USER[readProjectData("USER")].autorun) do
                strtocmd(readText("Documents:"..i), i:lower())
            end
        end
    end
end

--[=[END_TAB]=]
--[=[TAB:LoadCMD]=]
function loadCmds()
    local proj = ""
    
    proj = readGlobalData("term_cmd")
    local libs = readGlobalData("term_lib")
    
    local tabs, lt
    if proj then
        tabs = listProjectTabs(proj)
    end
    if libs then
        lt = listProjectTabs(libs)
    end
   
    if lt then
        for i, v in ipairs(lt) do
            if v ~= "Main" then
                local t = readProjectTab(libs .. ":" .. v)
                if t then
                    local c, err = loadstring(t)
                    if c then
                        c()
                    else
                        term.print("\5" .. err .. "\255")
                    end
                end
                --self.newline()
                --self.print("\n" .. entry)
            end
        end
    end 
    if tabs then
        for i, v in ipairs(tabs) do
            if v ~= "Main" then
                local t = readProjectTab(proj .. ":" .. v)
                if t then
                    local c, err = loadstring("return function(self, ...)local arg = {...} local params = arg[#arg] or {}\ntable.remove(arg, #arg)\nlocal print = function(...) term.print(..., '\\n') end\n" .. t .. " end")
                    if c then
                        cmd[v] = c()
                    else
                        term.print("\5" .. err .. "\255")
                    end
                end
                --self.newline()
                --self.print("\n" .. entry)
            end
        end
    end
end

function strtocmd(t, v)
    local c, err = loadstring("return function(self, ...)local arg = {...} local params = arg[#arg] or {}\ntable.remove(arg, #arg)\nlocal print = function(...) term.print(..., '\\n') end\n" .. t .. " end")
    if c then
        cmd[v] = c()
    else
        term.print("\5" .. err .. "\255")
    end
end
--[=[END_TAB]=]
--[=[TAB:Terminal]=]
-- cl.ALL_ERR_CRITICAL = false
--[[
string.char = utf8.char
string.byte = function(str)
    local t = {}
    for i, v in utf8.codes(str) do table.insert(t, v) end return unpack(t)
end--]]

if utf8.char(195) then print(utf8.char(195)) end

for n = 1, 65535 do
    local s = utf8.char(n)
    if s then
        utf8[s] = n
    else
        --print(n)
    end
end

print(utf8[utf8.char(195)])

FS = 4

local entry = "\4" .. (readProjectData("USER") or "MockTerm v8.0") .. " \255> "
oentry = entry

local es = #entry - 1

centry = es

font("Inconsolata")
fontSize(12)

tempimage = readImage("Project:char48")

local x, y = 8, 15+1

chx, chy = x, y
print(chx)

local w, h = math.floor((WIDTH - 200) / chx), math.floor(HEIGHT/2/chy*4/FS)+1--math.floor(31*13/chy)-1

termW, termH = w, h

--local term = window(300, 60, x * w, y * h, "Terminal")

term = {}

term.bg = 0

term.user = readProjectData"USER"

cur = vec2(1, 1)

scroll = 0

c, mod, invt, names, bold = {}, {}, {}, {}, {}

cols = {}

for row = 1, h do
    c[row] = {}
    mod[row] = {}
    invt[row] = {}
    bold[row] = {}
    for column = 1, w do
        c[row][column] = " "
        mod[row][column] = 0
        invt[row][column] = 0
        bold[row][column] = 0
    end
end

term.row = function(row, t)
    c[row + scroll] = t
end

local chr, ichr = {}, {}

local cf = {}

function loadChars()
    --ic, ici = readImage("Documents:char"), readImage("Documents:ichar")
    
    for n = 0, 255 do
        --chr[string.char(n)] = ic:copy(n*(chx), 0, chx, chy)
        --ichr[string.char(n)] = ici:copy(n*(chx), 0, chx, chy)
        mod[string.char(n)] = 0
    end
end

mod["\255"] = 255
cols[255] = color(255,255,255)
names[255] = "white"

mod["\2"] = 1
cols[2] = color(67)
names[2] = "darkgray"

mod["\3"] = 1
cols[3] = color(127)
names[3] = "gray"

mod["\4"] = 1
cols[4] = color(187)
names[4] = "lightgray"

mod["\128"] = 1
cols[128] = color(255,0,0)
names[128] = "red"

mod["\129"] = 1
cols[129] = color(0,255,0)
names[129] = "green"

mod["\130"] = 1
cols[130] = color(0,0,255)
names[130] = "blue"

mod["\5"] = 1
cols[5] = color(255,0,0)
names[5] = "red_compat"

mod["\6"] = 1
cols[6] = color(0,255,0)
names[6] = "green_compat"

mod["\7"] = 1
cols[7] = color(0,0,255)
names[7] = "blue_compat"

mod["\131"] = 1
cols[131] = color(0,255,255)
names[131] = "cyan"

mod["\132"] = 1
cols[132] = color(255,255,0)
names[132] = "yellow"

mod["\133"] = 1
cols[133] = color(255,0,255)
names[133] = "magenta"

mod["\134"] = 1
cols[134] = color(255,128,0)
names[134] = "orange"

function loadChars()
    ic, ici = readImage("Documents:char"), readImage("Documents:ichar")
    
    for n = 0, 255 do
        chr[string.char(n)] = ic:copy(n*chx, 0, chx, chy+1)
        ichr[string.char(n)] = ici:copy(n*chx, 0, chx, chy+1)
        mod[string.char(n)] = mod[string.char(n)] or 0
    end
end

function range(n, l, h)
    return math.max(l, math.min(n, h))
end

function bounds(n, l, h)
    return math.max(l, math.min(n, h)) == n
end

for n = 128, 134 do
    mod[string.char(n + 7)] = 1
    cols[n + 7] = color(
        range(cols[n].r - 128, 0, 255), 
        range(cols[n].g - 128, 0, 255), 
        range(cols[n].b - 128, 0, 255)
    )
    names[n + 7] = "dark" .. names[n]
    
    mod[string.char(n + 14)] = 1
    cols[n + 14] = color(
        range(cols[n].r - 67, 0, 255), 
        range(cols[n].g - 67, 0, 255), 
        range(cols[n].b - 67, 0, 255)
    )
    names[n + 14] = "light" .. names[n]
    
    mod[string.char(n + 21)] = 1
    cols[n + 21] = color(
        range(cols[n].r - 187, 0, 255), 
        range(cols[n].g - 187, 0, 255), 
        range(cols[n].b - 187, 0, 255)
    )
    names[n + 21] = "darkdark" .. names[n]
    
    mod[string.char(n + 28)] = 1
    cols[n + 28] = color(
        range(cols[n].r + 67, 0, 255), 
        range(cols[n].g + 67, 0, 255), 
        range(cols[n].b + 67, 0, 255)
    )
    names[n + 28] = "lightlight" .. names[n]
end

names[1] = "invert"
names[254] = "bold"

term.UNKNOWN_ERROR = -1
term.INSUFFICIENT_PRIVILEGE = -2
term.INVALID_INPUT = -3

colorcodes = {}

for i, v in pairs(mod) do
    table.insert(colorcodes, #colorcodes + 1, (string.byte(i)))
end
table.sort(colorcodes)

col = {}

for i, v in pairs(names) do
    col[v] = string.char(i)
end

local chrs = {chr, ichr}

local _print = _print or print

term.text = image(termW, termH)
setContext(term.text)
background(255)
setContext()

term.cmap = image(termW, termH)
setContext(term.cmap)
background(255)
setContext()

function setColor(x, y, c)
    term.cmap:set(x, y, cols[c] or color(255))
end

function setChar(x, y, char)
    --term.text:set(x, y, color(char))
    if c[y] then c[y][x] = char end
end

function getChar(x, y)
    return string.char(term.text:get(x, y))
end

function term.print(...)
    if not term.newline then function term.newline()
        cur.y = cur.y - 1
        --table.remove(c, #c)
        table.insert(c, 1, {})
        table.insert(mod, 1, {})
        table.insert(invt, 1, {})
        table.insert(bold, 1, {})
        for n = 1, termW do
            setChar(n, 1, " ")
            mod[1][n] = 0
            invt[1][n] = 0
            bold[1][n] = 0
        end
    end end
    local s = "\255"-- .. table.concat({...}, "")
    for i, v in ipairs{...} do
        if tostring(v) then
            s = s .. (type(v) == "string" and v or tostring(v))
        end
    end
    for n = 1, #s do
        local char = s:sub(n,n)
        local ch = string.byte(char)
        if cur.y >= termH then
            term.newline()
        end
        --_print(cur.x, cur.y)
        if not bounds(termH-cur.y, 1, term.text.height) then
            print("Invalid row: " .. (h-cur.y))
        elseif not bounds(cur.x, 1, term.text.width) then
            print("Invalid column")
        else
            setChar(cur.x, termH-cur.y, char)
        end
        if char == "\1" then
            invt[h-cur.y][cur.x] = 1
        elseif char == "\254" then
            bold[h-cur.y][cur.x] = 1
        elseif mod[char] ~= 0 and mod[h-cur.y] and not term.NO_COLOR then
            mod[h-cur.y][cur.x] = ch
            setColor(cur.x, h-cur.y, char)
        else
            cur.x = cur.x + 1
            if cur.x >= w or char == "\n" then
                cur.x = 1
                cur.y = cur.y + 1
                if cur.y >= h then
                    term.newline()
                end
            elseif char == "\r" then
                cur.x =1
            end
        end
    end
    --[[
    while #c > h do
        table.remove(c, #c)
        table.insert(c, 1, {})
        table.insert(mod, 1, {})
        for n = 1, w do
            c[1][n] = " "
            mod[1][n] = 0
        end
    end
    --]]
end

function term.printRaw(...)
    term.NO_COLOR = true
    term.print(...)
    term.NO_COLOR = false
end

io.write = term.print

cmd = {}
help = {}
usage = {}
do -- so I can auto-indent
    usage.help = "help [command]"
    help.help = "Lists the usage for command, or lists available commands if none is given."
    
    cmd.help = function(self, topic)
        if topic and help[topic] then
            term.print("\1\255USAGE: " .. (usage[topic] or "none available") .. "\1\n" .. help[topic])
        elseif topic and type(topic) == "string" then
            term.print('No help available for topic "' .. topic .. '"')
            if cmd[topic] or readText("Documents:" .. topic) then
                term.print('\nTry "' .. topic .. ' --help"')
            end
        else
            local n = 0
            for i, v in pairs(cmd) do
                term.print(i .. (" "):rep(15 - #i))
                if cur.x > termW - 14 then
                    term.print("\n")
                end
                n = n + 1
            end
            term.print("\nFor usage/development help, use the \254devhelp\254 command.")
        end
    end
    
    function cmd.width(self, _w)
        if not tonumber(_w) then
            term.print("Current width: " .. termW)
        else
            termW = tonumber(_w)
            term.print("\1Set width to " .. _w .. "\1")
        end
    end
    usage.width = "width (new_width)"
    help.width = "Sets terminal width to new_width"
    
    function cmd.height(self, _h)
        if not tonumber(_h) then
            term.print("Current height: " .. termH)
        else
            termH = tonumber(_h)
            if cur.y >= termH then
                cur.y = termH - 1
            end
            --term.h = h * chy
            moved = 2
            term.print("\1Set height to " .. _h .. "\1")
        end
    end
    usage.height = "height (new_height)"
    help.height = "Sets terminal width to new_height"
    
    cmd.list = cmd.help
    usage.list = "Same as help."
    help.list = 'Run "help help" for more info.'
    
    cmd.clear = function()
        --[[
        for row, rv in ipairs(c) do
            for column, cv in ipairs(rv) do
                c[row][column] = " "
                mod[row][column] = 0
                invt[row][column] = 0
                cur.x = 1
                cur.y = -1
            end
        end
        --[=[
        --]]
        --[[
        for n = #c, 2, -1 do
            table.remove(c, n)
        end
        --]]
        c = {}
        for row = 1, termH do
            c[row] = {}
            mod[row] = {}
            invt[row] = {}
            for column = 1, w do
                c[row][column] = " "
                mod[row][column] = 0
                invt[row][column] = 0
                bold[row][column] = 0
            end
        end
        cur.x = 1
        cur.y = 1
        SILENT = true--term.inprog
        --]=]
    end
    usage.clear = "clear (no params)"
    help.clear = "Clears the screen."
    
    cmd.time = function(self)
        local t = getTimeData()
        term.print("Time: " .. math.tointeger(t.hour-1)%12 + 1 .. ":" .. t.min .. ":" .. t.sec)
    end
    usage.time = "time (no params)"
    help.time = 'Prints the current time, in the format "hour:min:sec".'
    
    cmd.color = function(self, c)
        if type(c) == "table" then
            c = nil
        end
        if not c then
            for i, v in ipairs(colorcodes) do
                if names[v] then
                    term.print(v .. ": " .. string.char(v) .. names[v] .. string.char(v) .. "\255\n")
                end
            end
        elseif tonumber(c) then
            if names[tonumber(c)] then
                term.print(c .. ": " .. string.char(tonumber(c)) .. names[tonumber(c)] .. string.char(tonumber(c)) .. "\255")
            else
                term.print("\5Invalid color code " .. c .. "!")
            end
        else
            local ci
            for i, v in pairs(names) do
                if v == c then
                    ci = i
                end
            end
            if ci then
                term.print(string.char(ci) .. c .. string.char(ci) .. "\255: " .. ci)
            else
                term.print("\5No color code with name " .. c .. "!")
            end
        end
    end
    usage.color = "\255color [int index] [string name]"
    help.color = 
        "\255color int:         \4prints name of color at index (int), if available.\n" .. 
        "\255color string:      \4prints index of color with name (string), if available.\n" ..
        "\255color (no params): \4prints all colors and their respective indices."
    
    cmd.echo = function(self, ...)
        local t = {...}
        t[#t] = "\n" -- remove params arg
        term.print(unpack(t))
    end
    usage.echo = "echo text[, ...]"
    help.echo = "Prints all arguments passed to it."
    
    cmd.ls = function(self, loc)
        if loc=="Project" and not(term.__USER[readProjectData("USER") or -1]and(term.__USER[readProjectData("USER")].elevation>0)) then return term.INSUFFICIENT_PRIVILEGE end
        local t = assetList(type(loc) == "string" and loc or "Documents", TEXT)
        for i, v in ipairs(t) do
            term.print(v .. (" "):rep(25 - #v))
            if cur.x > w - 24 then
                term.print("\n")
            end
        end
    end
    usage.ls = "ls [asset_pack]"
    help.ls = "Lists all text files in the specified asset pack, or in Documents if no location is given"
    
    cmd.quit = function()
        close()
    end
    usage.quit = "quit (no params)"
    help.quit = "Exits the terminal."
    
    cmd.record = function()
        if isRecording() then
            term.print("\1\5Stopped recording\255\1")
            stopRecording()
        else
            term.print("\1\5Began recording\255\1")
            startRecording()
        end
    end
    usage.record = "record (no params)"
    help.record = "Begins recording, or stops recording if it is currently recording."
    
    cmd.fps = function()
        term.print("Current FPS: " .. getfps())
    end
    usage.fps = "fps (no params)"
    help.fps = "Displays the current FPS."
    
    function trim(s)
        if s then
            return (s:gsub("^%s*(.-)%s*$", "%1"))
        end
    end
    
    cmd.write = function(self, ...)
        local f = ""
        for i, v in ipairs{...} do
            if type(v) == "string" then
                f = f .. v .. " "
            end
        end
        f = trim(f)
        local t = (readText("Documents:" .. f))
        if t then
            t = t .. "\n"
            local m, occ = t:gsub("\n", "")
            local n = 1
            local title = f .. ".txt (" .. occ .. " lines)"
            term.print("\255\1" .. title .. (" "):rep(w - title:len() - 1) .. "\1\n")
            for s in t:gmatch("([^\n]-)\n") do
                term.print("\4\1" .. n .. (" "):rep(#(tostring(occ)) - #tostring(n)) .. ":\1\255 " .. s .. "\n")
                n = n + 1
            end
        else
            term.print("\5Error: no file " .. f .. "!")
        end
    end
    usage.write = "write filename"
    help.write = "Prints out contents of file (filename)"
    
    cmd.lua = function(self, f, ...)
        --local f = table.concat({...}, " ")
        if not f then
            return -1
        end
        local t = readText("Documents:" .. f)
        if t then
            _print = print
            print = function(...) local a = {...} table.insert(a, "\n") term.print(unpack(a)) end
            local c, err = loadstring(t)
            if c then
                c(...)
            else
                term.print("\5" .. err .. "\255")
            end
            print = _print
        else
            term.print("\5Error: no file " .. f .. "!")
        end
        --self.newline()
        --self.print("\n" .. entry)
    end
    usage.lua = "lua filename"
    help.lua = "Runs code from text asset (filename)"
    
    cmd.cl = function(self, f, ...)
        --local f = table.concat({...}, " ")
        if not f then
            return -1
        end
        local t = readText("Documents:" .. f)
        if t then
            _print = print
            print = function(...) local a = {...} table.insert(a, "\n") term.print(unpack(a)) end
            local c, err = pcall(cl.parse, t)
            if c then
                
            else
                term.print("\5" .. err .. "\255")
            end
            print = _print
        else
            term.print("\5Error: no file " .. f .. "!")
        end
        --self.newline()
        --self.print("\n" .. entry)
    end
    usage.cl = "cl filename"
    help.cl = "Runs CL code from text asset (filename)"
    
    cmd.exec = function(self, ...)
        local t = {...}
        t[#t] = nil
        local arg
        local f = table.concat(t, " ")
        if not f then
            return -1
        end
        local t = readText("Documents:" .. f)
        if t then
            t = t .. "\n"
            local n = 1
            term.print(entry)
            for s in t:gmatch("([^\n]+)\n") do
                term.exec(s)
                n = n + 1
            end
        else
            term.print("\5Error: no file " .. f .. "!")
        end
    end
    usage.exec = "exec filename"
    help.exec = "Executes contents of text asset (filename) as a batch file"
    
    cmd.bg = function(self, c)
        if tonumber(c) then
            term.bg = tonumber(c)
        else
            term.print("Enter a valid number!")
        end
    end
    usage.bg = "bg number (0-255)"
    help.bg = "Sets the background shade to (color)"
    
    cmd.fetch = function(url, cb)
        if type(cb) ~= "string" then
            cb = nil
        end
        if type(url) == "string" then
            local c = ""
            http.request(url, function(data) 
                c = data
                if c ~= "" then
                    if c:find("--cmd:.-\n") then
                        for n in c:gmatch("--cmd:(.-)\n") do
                            strtocmd(c, n)
                            term.print("\nfetch: Command stored as \1" .. n .. "\1\n")
                        end
                    elseif cb then
                        strtocmd(c, cb)
                        term.print("\nfetch: Command stored as \1" .. cb .. "\1\n")
                    else
                        term.print("\nfetch: No default name found, and no backup provided.\n")
                    end
                end
            end, function(data)
                term.print("\nfetch: " .. data .. "\n")
            end)
        end
    end
    
    cmd.wipe = function()
        saveGlobalData("term_cmd", nil)
        restart()
    end
    usage.wipe = "wipe (no params)"
    help.wipe = "Restarts CodeCL, wiping any cmdproject data"
    
    cmd.logout = function()
        saveProjectData("USER", nil)
        restart()
    end
    usage.logout = "logout (no params)"
    help.logout = "Logs out of the current user account"
    
    cmd.autorun = function()
        if not readProjectData("USER") then
            term.print("You do not have proper privileges!")
            return -1
        end
        aStart = 1
        aCur = 1
        aTbl = assetList("Documents", TEXT)
        term.enter(function(k)
            cmd.clear()
            cur.y = aStart
            k = k or "  "
            if k:find("[qp]") then
                aCur = (aCur + #aTbl - 2) % #aTbl + 1
            elseif k:find("[al]") then
                aCur = aCur % #aTbl + 1
            elseif k == "\n" and aNotFirst then
                if term.__USER[readProjectData("USER")].autorun[aTbl[aCur]] then
                    term.__USER[readProjectData("USER")].autorun[aTbl[aCur]] = nil
                else
                    term.__USER[readProjectData("USER")].autorun[aTbl[aCur]] = true
                end
                saveText("Project:UserData", json.encode(term.__USER))
            elseif k == "" then
                cmd.clear()
                term.exit()
            end
            aNotFirst = true
            for i, v in ipairs(aTbl) do
                if term.__USER[readProjectData("USER")].autorun[v] then
                    term.print("\1 \1 " .. (aCur == i and "\1" or "") .. v .. (aCur == i and "\1" or "") .. "\n")
                else
                    term.print((aCur == i and "  \1" or "  ") .. v .. (aCur == i and "\1\n" or "\n"))
                end
            end
        end)
    end
end    

function term.scroll(dist)
    scroll = scroll + dist
    scroll = range(scroll, 0, math.max(0, #c - termH))
end
function term.setscroll(pos)
    scroll = pos
    scroll = range(scroll, 0, math.max(0, #c - termH))
    term.scroll, scroll = chy - (scroll * chy) % chy, math.floor(scroll)
end
function term.getscroll()
    return scroll
end

function term.slock(v)
    term.locked = v
end

function term.enter(func, em)
    term.inprog = type(func) == "function" and func or function() end
    term.entry = ""
    term.exitmsg = em or ""
    centry = 1
end
function term.exit(tp)
    term.inprog = false
    centry = es
    entry = oentry
    term.print(tp or (term.exitmsg .. "\n" .. entry))
end

function term.read(msg, ispass, exitKey)
    term.__EXITKEY = exitKey or "\n"
    if msg then term.print(msg) end
    term.__READING = true
    term.__EPOS = cur.x
    term.__READV = ""
    term.__RC = 1
    term.__READING_PASSWORD = ispass or false
    coroutine.yield()
end
function term.read_system_password(min_elevation)
    if term.__USER[term.user].elevation < (min_elevation or 0) then
        term.print("Insufficient privileges")
        term.__READV = nil
        return -2
    end
    term.__EXITKEY = "\n"
    term.print("Enter the password for user " .. term.user .. ": ")
    term.__READING = true
    term.__EPOS = cur.x
    term.__READV = ""
    term.__RC = 1
    term.__READING_PASSWORD = true
    term.__SYSTEM_PASSWORD = true
    coroutine.yield()
end
function term.getInput()
    return term.__READV
end

term.__RC = 1
term.__READV = ""

term.readfile = function(name)
    return readText("Project:USER=" .. readProjectData("USER") .. "-" .. name)
end

term.savefile = function(name, data)
    return saveText("Project:USER=" .. readProjectData("USER") .. "-" .. name, data)
end

function term.move(x, y, isk)
    if term.inprog and not isk then
        local d = x < 0 and -1 or 1
        for n = 1, math.abs(x) do
            cur.x = math.max(1, cur.x + d)
        end
        d = y < 0 and -1 or 1
        for n = 1, math.abs(y) do
            cur.y = math.max(0, cur.y + d)
            if not c[y] then
                c[y] = {}
                for column = 1, termW do
                    c[y][column] = " "
                end
            end
        end
    else
        
    end
end

function term:command()
    local s = trim(table.concat(c[h-cur.y], "", centry, w)) .. " "
    --[[
    -- Done in exec
    cur.y = cur.y + 1
    cur.x = 1
    --]]
    if self then
        self.exec(s, true) -- Backwards compatibipmlity
    else
        term.exec(s, true)
    end
end

function term.exec(s, isUser, IGNORE)
    local s = trim(s) .. " "
    cur.y = cur.y + 1
    cur.x = 1
    if not(isUser or term.__CO) then
        term.print(entry .. s .. "\n")
    end
    
    if cmd[trim(s:sub(1, (s:find("%s") or 0) - 1))] then
        local a = s:sub(s:find("%s") or -1, -1)
        local args, params = {}, {}
        for arg in (a):gmatch("(%S+)%s") do
            table.insert(args, #args + 1, arg)
        end
        ---[[
        for i, v in ipairs(args) do
            if v:find("%-%-%S+") then
                --term.print("Param found:\n")
                table.remove(args, i)
                if v:find("%-%-[^%=]+%=%S+") then
                    --! deeper thinking
                    --term.print(v:sub(3, v:find("=") - 1) .. ": " .. v:sub(v:find("=") + 1, -1) .. "\n")
                    params[v:sub(3, v:find("=") - 1)] = v:sub(v:find("=") + 1, -1)
                else
                    params[v:sub(3, -1)] = true
                    --term.print(v:sub(3, -1) .. "\n")
                end
            end
        end
        --]]
        table.insert(args, params)
        local exit, r = pcall(cmd[trim(s:sub(1, (s:find("%s") or 0) - 1))], self, unpack(args))
        if term.coroutine and coroutine.status(term.coroutine) ~= "dead" then
            term.__CO = true
        end
        if exit and not (SILENT or term.__CO) then
            term.print("\n\3Process returned with exit code: \4" .. (exit and tostring(r) or (tostring(exit) .. tostring(r))) .. "\255\n")
        elseif r then
            term.print("\5Error: " .. r .. "\255\n")
        end
    else
        _print = print
        print = term.print
        sqrt = math.sqrt
        --local f, err = loadstring("return (" .. s .. ")")
        --if not f then
            f, err = loadstring("" .. s)
        --end
        if tonumber(s) then
            term.print("> \6" .. tonumber(s) .. "\255")
        elseif f then
            local f, err = pcall(f)
            if f and not(SILENT or term.__CO) then
                print("\nReturned: " .. tostring(err))
            elseif not SILENT then
                print("\n"..err)
            end
        elseif readText("Documents:" .. trim(s:sub(1, (s:find("%s") or 0) - 1))) then
            _print = print
            print = term.print
            local f, err = loadstring("return function(arg, params) " .. readText("Documents:" .. trim(s:sub(1, (s:find("%s") or 0) - 1))) .. " end")
            if f then
                local a = s:sub(s:find("%s") or -1, -1) .. " "
                local args, params = {}, {}
                for arg in a:gmatch("(%S+)%s") do
                    table.insert(args, arg)
                end
                for i, v in ipairs(args) do
                    if v:find("%-%-%S+") then
                        --term.print("Param found:\n")
                        table.remove(args, i)
                        --if v:find("%-%-[^%=]+%=%S+") then
                        if v:find("=") then
                            --! deeper thinking
                            --term.print(v:sub(3, v:find("=") - 1) .. ": " .. v:sub(v:find("=") + 1, -1) .. "\n")
                            params[v:sub(3, v:find("=") - 1)] = v:sub(v:find("=") + 1, -1)
                        else
                            params[v:sub(3, -1)] = true
                            --term.print(v:sub(3, -1) .. "\n")
                        end
                    end
                end
                local r, err = pcall(f(), args, params)
                if not(SILENT or term.__CO) then
                    term.print("\n")
                    term.print(r and ("Process returned with exit code: " .. tostring(err)) or ("\1\5" .. err .. "\255\1"))
                end
                print = _print
            else
                cmd.exec(s)
            end
        elseif not(SILENT or term.__CO) then
            local cm = trim(s:sub(1, (s:find("%s") or 0) - 1))
            s = 'Error: command "' .. trim(s:sub(1, (s:find("%s") or 0) - 1)) .. '" not found!\n\5' ..  err
            term.print(s)
        end
    end
    
    cur.y = cur.y + 1
    cur.x = 1
    --local s = entry
    if not IGNORE then SILENT=false if not(term.inprog)and not(term.__CO)then term.print(entry)end end
end

os.execute = term.exec

_HASRUN = false

function term:main()
    --c[h-cur.y][cur.x] = ansi[177]
    if not(term.coroutine) or (term.coroutine and coroutine.status(term.coroutine) == "dead") then
        if term.__CO then term.print("\n"..entry) end
        term.__CO = false
        term.__READING = false
        term.__READING_PASSWORD = false
    end
    --if term.key then
        --term.__ENTERED = trim(table.concat(c[termH-cur.y], "", term.__EPOS)) .. " "
        --_keyboard(term.key)
    --end
    --showKeyboard()
    tint(255, 255, 255, 255)
    --background(term.bg)
    if term.inprog then
        term.inprog(term.key)
    elseif term.coroutine and coroutine.status(term.coroutine) ~= "dead" then
        term.__CO = true
        if not(term.__READING) then
            --alert(term.__READV)
            term.__READING_PASSWORD = false
            if term.__SYSTEM_PASSWORD then
                term.__READV = term.__USER[term.user].pass == md5.sumhexa(term.__READV)
                term.__SYSTEM_PASSWORD = false
            end
            local r, err = coroutine.resume(term.coroutine, term.__READV)
            if err then
                term.print("\5Coroutine error: " .. err .. "\255\n")
            end
        end
    end
    term.key = nil
    local inv = 1
    local col = 0
    --local _c, _invt = c, invt
    --invt[h+scroll][1] = 1
    --invt[h+scroll][w] = 1
    --print(pr[1])
    local _c = {}
    local t = getTimeData()
    local hdr = "MockTerm v8.0 - Time: " .. math.tointeger(t.hour-1)%12 + 1 .. ":" .. t.min .. ":" .. t.sec .. ", FPS: " .. math.floor(getfps())
    for n = 1, w do
        _c[n] = hdr:sub(n,n) or " "
    end
    --print(pr[1])
    --[==[
    for y = 1 + scroll, h + scroll do
        for x = 1, w do
            --_print(c[y][x])
            inv = (inv + invt[y][x]) % 2
            ---[=[
            if cols[mod[y][x]] and mod[y][x] ~= col then
                tint(cols[mod[y][x]])
                col = mod[y][x]
            end
            --]=]
            if x == cur.x and y == h - cur.y then
                --inv = (inv+1) % 2
                sprite(chrs[(inv+1)%2+1][c[y][x]], (x-1) * chx, (y-1-scroll) * (chy))
            elseif not((c[y][x]):find("%s") and (inv==0)) then
                sprite(chrs[inv+1][c[y][x]], (x-1) * chx, (y-1-scroll) * (chy))
            end
        end
    end
    --]==]
    local ccol = color(255)
    local bo = 0
    local ch = 0
    for y = h + scroll, 1 + scroll, -1 do
        for x = 1, w do
            inv = (inv + invt[y][x]) % 2
            bo = (bo + bold[y][x]) % 2
            local inv = inv
            if x == cur.x and y == h - cur.y and math.floor(ElapsedTime*2 % 2) == 0 then inv = (inv+1)%2 end
            if cols[mod[y][x]] and mod[y][x] ~= col then
                ccol = cols[mod[y][x]]
            end
            if (y == h+scroll) then
                term.text:set(x, y-scroll, color(_c[x]:byte(), 0,0,0))
                term.cmap:set(x, y-scroll, color(255))
            else
                term.text:set(x, y-scroll, color(c[y][x]:byte(), bo*3,0,inv*255))
                term.cmap:set(x, y-scroll, ccol)
            end
        end
    end
    drawFont(term.fmesh, term.text, term.cmap)
    resetMatrix()
    fill(128)
    rect(WIDTH-75, HEIGHT/2, 100, 24)
    fill(0)
    font("SourceSansPro-Regular")
    fontSize(18)
    text("ACTION", WIDTH-68, HEIGHT/2)
    --invt[h+scroll][1] = 0
    --invt[h+scroll][w] = 0
end

function _keyboard(k)
    term.key = k
end
function keyboard(k)
    --_print(
    term.key = k
    term.__EXITKEY = term.__EXITKEY or "N/A"
    if k == "\n" or (term.__EXITKEY and k:find(term.__EXITKEY)) then
        if k == "\n" and not(term.inprog or term.__READING or term.__CO) then
            term.command()
            --term.key = ""
        elseif k:find(term.__EXITKEY) then
            if not term.__READING then
                term.__READV = ""
            end
            cur.y = cur.y + 1
            --alert("returning")
            term.__READING = false
            term.__EXITKEY = nil
        else
            cur.y = cur.y + 1
        end
        if term.__CO and term.__EXITKEY and term.__EXITKEY ~= "\n" and type(term.__READV) == "string" then
            term.__READV = term.__READV .. "\n"
            term.__RC = term.__RC + 1
        end
        cur.x = term.__CO and 1 or centry
        --if not(term.inprog or term.__CO) then for x = cur.x, w do setChar(x, h-cur.y, " ") end end
    elseif k == BACKSPACE and (cur.x > centry or (term.__CO and cur.x > term.__EPOS)) then
        cur.x = cur.x - 1
        if cur.x < 1 then
            cur.x = termW
            cur.y = cur.y - 1
            while c[termH - cur.y][cur.x] == " " do
                cur.x = cur.x - 1
            end
        end
        setChar(cur.x, h-cur.y, " ")
        if term.__CO then
            term.__RC = math.max(1, term.__RC - 1)
            term.__READV = term.__READV:sub(1, -2)
        end
    elseif k ~= BACKSPACE then
        if cur.x > w then
            cur.x = 1
            cur.y = cur.y + 1
        end
        setChar(cur.x, h-cur.y, term.__READING_PASSWORD and "\250" or k)
        cur.x = cur.x + 1
        if term.__CO then
            term.__READV = term.__READV .. k
            term.__RC = term.__RC + 1
        end
    end
end

--[=[END_TAB]=]
--[=[TAB:FPS]=]
--[[
For a simpler FPS estimate, try FPS=FPS.9+0.1DeltaTime
#ignore fps
#nofunc
--]]

socket = require("socket")
local f = 60
local pt = 0
function fps()
    f = f*.9 + (ElapsedTime-pt)*0.1
    pt = ElapsedTime
end

function getfps()
    return 1/f
end

--[=[END_TAB]=]
--[=[TAB:Time]=]
function getTimeData()
    local timestr = (os.date())
    
    local formstr = "(%a+)%s+(%a+)%s+(%d+)%s+(%d+):(%d+):(%d+)%s+(%d+)"
    
    --local formstr = "%a+%s%a+%s%d+%s%d+:%d+:%d+%s%d+"
    
    local tbl
    
    for day, mon, date, hour, min, sec, year in string.gmatch(timestr, formstr) do
        --print(day, mon, date, hour, min, sec, year)
        tbl = {
            ["day"] = day,
            ["mon"] = mon,
            ["date"] = date,
            ["hour"] = hour,
            ["min"] = min,
            ["sec"] = sec,
            ["year"] = year,
        }
    end
    
    return tbl
end
--[=[END_TAB]=]
--[=[TAB:ccConfig]=]
--[[
###########################################
##Codea Community Project Config Settings##
###########################################

##You can use # to comment out a line
##Use 1 for true and 0 for false


###########################################
#       Add project info below            #
#==========================================
ProjectName: EmuTerm
Version: 7.5 Release
Comments: Terminal emulator. Not written with XTerm or MS-DOS in mind; rather, it is designed as Codea most likely would have been were it a terminal. Documentation coming soon, once I have a good way to generate documentation for it.
Author: FLCode
##License Info: http://choosealicense.com
##Supported Licneses: MIT, GPL, Apache, NoLicense
License: NoLicense
#==========================================


###########################################
#                Settings                 #
[Settings]=================================
##Codea Community Configuration settings
##Format: Setting state

Button 0
NotifyCCUpdate 1
ResetUserOption 0
AddHeaderInfo 1
CCFOLDER alpha

[/Settings]================================



###########################################
#              Screenshots                #
[Screenshots]==============================
##Screenshots from your project.
##Format: url
##Example: http://www.dropbox.com/screenshot.jpg


[/Screenshots]=============================



###########################################
#                   Video                 #
[Video]====================================
##Link to a YouTube.com video.
##Format: url
##Example: http://www.youtube.com/videolink


[/Video]===================================



###########################################
#              Dependencies               #
[Dependencies]=============================
##Include the names of any dependencies here
##Format: Dependency
##Example: Codea Community


[/Dependencies]============================



############################################
#                   Tabs                   #
[Tabs]======================================
##Select which tabs are to be uploaded.
##Keyword 'not' excludes a tab or tabs. Keyword 'add' includes a tab or tabs.
##not * will exclude all tabs to allow for individual selection
##not *tab1 will look for any tab with tab1 on the end.
##not tab1* will look for any tab with tab1 at the beginning.
##Format: (add/not)(*)tab(*)
##Example: not Main --this will remove main.
##Example: not *tab1 --this will remove any tab with "tab1" on the end.
##Example: add Main --This will add Main back in.




[/Tabs]=====================================



#############################################
#                  Assets                   #
[Assets]=====================================
##Directory, path and url info for any assets besides the standard Codea assets.
##Format: Folder:sprite URL
##Example: Documents:sprite1 http://www.somewebsite.com/img.jpg


[/Assets]====================================
]]
--[=[END_TAB]=]
--[=[TAB:External]=]
function loadTerminal()
    -- Terminal

--[[
readText("Documents:cltest")
--]]

    loadChars()
    makeicon()
    displayMode(FULLSCREEN_NO_BUTTONS)
    loadCmds()
    dt = readImage("Documents:dt") or image(0,0) -- optional terminal desktop, probably a nice-looking gradient
    _print = print
        
    function pesc(x)
        return (x:gsub('%%', '%%%%')
            :gsub('%^', '%%%^')
            :gsub('%$', '%%%$')
            :gsub('%(', '%%%(')
            :gsub('%)', '%%%)')
            :gsub('%.', '%%%.')
            :gsub('%[', '%%%[')
            :gsub('%]', '%%%]')
            :gsub('%*', '%%%*')
            :gsub('%+', '%%%+')
            :gsub('%-', '%%%-')
            :gsub('%?', '%%%?')
        )
    end
    if readGlobalData("term_cmd") then
        term.print(oentry)
    else
        term.print("\1Welcome to CodeCL ver. 7.5!\1\nTo list commands, enter 'list' or 'help'. The two commands are exact copies of each other.\nTo get help for an individual command, type, 'help command_name'.\n\n")
        term.print("Setting a command project will allow users to easily add new commands - this can be done by creating a new tab in the\ncommand project, with the same name as the command being created.\nWould you like to register a command project now? (y/n) ")
        
        local cl = 0
        local getCmdProj = function(k)
            cur.y = cl
            if k == "\n" then
                local pn = trim(table.concat(c[termH - cur.y]):gsub("Project name: ", ""))
                saveGlobalData("term_cmd", pn)
                term.print("\nCommand project saved as: " .. pn .. "\n")
                term.exit(oentry)
                loadCmds()
            end
        end
        
        local isAddingProject = false
        local proc = function(k)
            if k then
                term.exit("\n")
                if k == "y" then
                    term.enter(getCmdProj)
                    term.print("Project name: ")
                    cl = cur.y
                else
                    term.print(oentry)
                end
            end
        end
        term.enter(proc)
    end
    
    ctx, cty = 0, 0
    
    ibg = 50
    
    -- This function gets called once every frame
    function draw()
        -- This sets a dark background color 
        --background(255, 255, 255, 255)
        
        -- This sets the line thickness
        noStroke()
        background(term.bg)
        spriteMode(CENTER)
        tint(255,255,255,ibg)
        if dt then sprite(dt, WIDTH/2, HEIGHT/4*3, dt.width / 2, dt.height / 2) end
        --spriteMode(CORNER)
        
        --rectMode(CENTER)
        
        ctx = WIDTH / 2 - termW * chx / 2
        cty = HEIGHT / 2 - chy
        
        -- Do your drawing here
        translate(ctx, cty)
        noSmooth()
        showKeyboard()
        fps()
        term.main()
        --translate(-100, 0)
        drawInterface()
        
    end
    
    local scrolling = 0
    local cscroll = 0
    
    local lt = 0
    
    --[[
    sprite("Documents:arrow_down", -50, 10)
        sprite("Documents:arrow_left", -75, 35)
        sprite("Documents:arrow_up", -50, 60)
        sprite("Documents:arrow_right", -25, 35)
    --]]
    
    local function tscroll(x, y)
        if bounds(x - ctx, -60, -40) and bounds(y - cty, 0, 20) then
            term.move(0, 1)
        elseif bounds(x - ctx, -60, -40) and bounds(y - cty, 50, 70) then
            term.move(0, -1)
        elseif bounds(x - ctx, -85, -65) and bounds(y - cty, 25, 45) then
            term.move(-1, 0)
        elseif bounds(x - ctx, -35, -15) and bounds(y - cty, 25, 45) then
            term.move(1, 0)
        end
    end
    
    function touched(touch)
        if touch.state == BEGAN then
            scrolling = touch.y
            cscroll = term.getscroll()
            lt = ElapsedTime
            tscroll(touch.x, touch.y)
        elseif not term.locked then
            term.setscroll(math.floor(cscroll + (scrolling - touch.y) / chy))
        end
    end
    

end

--[=[END_TAB]=]
