-- package.path = package.path .. ";../external/?.lua"
-- inspect = require("inspect")

--[[ 
The Porter Stemming Algorithm
* This code is ported to Lua using the Python implementation on Martin Porter's website: https://tartarus.org/martin/PorterStemmer/python.txt
* Porter algorithm paper: https://tartarus.org/martin/PorterStemmer/def.txt
--]]

local porter = {}
porter["b"] = ""
porter["k"] = 1
porter["k0"] = 1
porter["j"] = 1

porter.stem = function(self, p, i, j)
    self.b = p
    self.k = j
    self.k0 = i
    self.j = 1
    if self.k <= self.k0 + i then
        return self.b
    end

    self:step1ab()
    self:step1c()
    self:step2()
    self:step3()
    self:step4()
    self:step5()
    return string.sub(self.b, self.k0, self.k)
end

porter.cons = function(self, i)
    if string.sub(self.b, i, i) == 'a' or string.sub(self.b, i, i) == 'e' or string.sub(self.b, i, i) == 'i' or string.sub(self.b, i, i) == 'o' or string.sub(self.b, i, i) == 'u' then
        return false
    end
    if string.sub(self.b, i, i) == 'y' then
        if i == self.k0 then
            return true
        else
            return (not self:cons(i - 1))
        end
    end
    return true
end

porter.m = function(self)
    local n = 0
    local i = self.k0
    while true do
        if i > self.j then
            return n
        end
        if not self:cons(i) then
            break
        end
        i = i + 1
    end
    i = i + 1
    while true do
        while true do
            if i > self.j then
                return n
            end
            if self:cons(i) then
                break
            end
            i = i + 1
        end
        i = i + 1
        n = n + 1
        while true do
            if i > self.j then
                return n
            end
            if not self:cons(i) then
                break
            end
            i = i + 1
        end
        i = i + 1
    end
end

porter.vowelinstem = function(self)
    for i=self.k0, self.j do
        if not self:cons(i) then
            return true
        end
    end
    return false
end

porter.doublec = function(self, j)
    if j < (self.k0 + 1) then
        return false
    end
    if (string.sub(self.b, j, j) ~= string.sub(self.b, j-1, j-1)) then
        return false
    end
    return self:cons(j)
end

porter.cvc = function(self, i)
    if i < (self.k0 + 2) or (not self:cons(i)) or (self:cons(i-1)) or (not self:cons(i-2)) then
        return false
    end
    local ch = string.sub(self.b, i, i)
    if ch == 'w' or ch == 'x' or ch == 'y' then
        return false
    end
    return true
end

porter.ends = function(self, s)
    length = string.len(s)

    -- checks if last element is matching - tiny speedup
    if string.sub(s, length, length) ~= string.sub(self.b, self.k , self.k) then
        return false
    end
    if length > (self.k - self.k0) then
        return false
    end
    if string.sub(self.b, self.k - length + 1, self.k) ~= s then
        return false
    end
    self.j = self.k - length -- why? check!
    return true
end

porter.setto = function(self, s)
    length = string.len(s)
    self.b = string.sub(self.b, 1, self.j) .. s .. string.sub(self.b, self.j+length)
    self.k = self.j + length
end

porter.r = function(self, s)
    if self:m() > 0 then
        self:setto(s)
    end
end

porter.step1ab = function(self)
    if string.sub(self.b, self.k, self.k) == 's' then
        if self:ends("sses") then
            self.k = self.k - 2
        elseif self:ends("ies") then
            self:setto("i")
        elseif string.sub(self.b, self.k - 1, self.k - 1) ~= 's' then
            self.k = self.k - 1
        end
    end
    if self:ends("eed") then
        if self:m() > 0 then
            self.k = self.k - 1
        end
    elseif (self:ends("ed") or self:ends("ing")) and self:vowelinstem() then
        self.k = self.j
        if self:ends("at") then self:setto("ate")
        elseif self:ends("bl") then self:setto("ble")
        elseif self:ends("iz") then self:setto("ize")
        elseif self:doublec(self.k) then
            self.k = self.k - 1
            ch = string.sub(self.b, self.k, self.k)
            if ch == 'l' or ch == 's' or ch == 'z' then
                self.k = self.k + 1
            end
        elseif (self:m() == 1 and self:cvc(self.k)) then
            self:setto("e")
        end
    end
end

porter.step1c = function(self)
    if (self:ends("y") and self:vowelinstem()) then
        self.b = string.sub(self.b, 1, self.k-1) .. 'i' .. string.sub(self.b, self.k+1)
    end
end

porter.step2 = function(self)
    if string.sub(self.b, self.k-1, self.k-1) == 'a' then
        if self:ends("ational") then 
            self:r("ate")
        elseif self:ends("tional") then 
            self:r("tion")
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 'c' then
        if self:ends("enci") then 
            self:r("ence")
        elseif self:ends("anci") then 
            self:r("ance")
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 'e' then
        if self:ends("izer") then 
            self:r("ize")
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 'l' then
        if self:ends("bli") then 
            self:r("ble")
        -- To match the published algorithm, replace this phrase with
        --   if self:ends("abli") then self:r("able")
        elseif self:ends("alli") then 
            self:r("al")
        elseif self:ends("entli") then 
            self:r("ent")
        elseif self:ends("eli") then
            self:r("e")
        elseif self:ends("ousli") then 
            self:r("ous")
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 'o' then
        if self:ends("ization") then 
            self:r("ize")
        elseif self:ends("ation") then 
            self:r("ate")
        elseif self:ends("ator") then 
            self:r("ate")
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 's' then
        if self:ends("alism") then 
            self:r("al")
        elseif self:ends("iveness") then 
            self:r("ive")
        elseif self:ends("fulness") then 
            self:r("ful")
        elseif self:ends("ousness") then 
            self:r("ous")
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 't' then
        if self:ends("aliti") then 
            self:r("al")
        elseif self:ends("iviti") then 
            self:r("ive")
        elseif self:ends("biliti") then 
            self:r("ble")
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 'g' then
        if self:ends("logi") then 
            self:r("log")
        end
    end
end

porter.step3 = function(self)
    if string.sub(self.b, self.k, self.k) == 'e' then
        if self:ends("icate") then 
            self:r("ic")
        elseif self:ends("ative") then 
            self:r("")
        elseif self:ends("alize") then 
            self:r("al")
        end
    elseif string.sub(self.b, self.k, self.k) == 'i' then
        if self:ends("iciti") then 
            self:r("ic")
        end
    elseif string.sub(self.b, self.k, self.k) == 'l' then
        if self:ends("ical") then
            self:r("ic")
        elseif self:ends("ful") then 
            self:r("")
        end
    elseif string.sub(self.b, self.k, self.k) == 's' then
        if self:ends("ness") then 
            self:r("")
        end
    end
end

porter.step4 = function(self)
    if string.sub(self.b, self.k - 1, self.k - 1) == 'a' then
        if self:ends("al") then ;
        else return
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 'c' then
        if self:ends("ance") then ;
        elseif self:ends("ence") then ;
        else return
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 'e' then
        if self:ends("er") then ;
        else return
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 'i' then
        if self:ends("ic") then ;
        else return
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 'l' then
        if self:ends("able") then ;
        elseif self:ends("ible") then ;
        else return
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 'n' then
        if self:ends("ant") then ;
        elseif self:ends("ement") then ;
        elseif self:ends("ment") then ;
        elseif self:ends("ent") then ;
        else return
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 'o' then
        if self:ends("ion") and (string.sub(self.b, self.j, self.j) == 's' or string.sub(self.b, self.j, self.j) == 't') then ;
        elseif self:ends("ou") then ;
        else return
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 's' then
        if self:ends("ism") then ;
        else return
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 't' then
        if self:ends("ate") then ;
        elseif self:ends("iti") then ;
        else return
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 'u' then
        if self:ends("ous") then ;
        else return
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 'v' then
        if self:ends("ive") then ;
        else return
        end
    elseif string.sub(self.b, self.k - 1, self.k - 1) == 'z' then
        if self:ends("ize") then ;
        else return
        end
    else
        return
    end

    if self:m() > 1 then
        self.k = self.j
    end
end

porter.step5 = function(self)
    self.j = self.k
    if string.sub(self.b, self.k, self.k) == 'e' then
        a = self:m()
        if a > 1 or (a == 1 and not self:cvc(self.k-1)) then
            self.k = self.k - 1
        end
    end
    if string.sub(self.b, self.k, self.k) == 'l' and self:doublec(self.k) and self:m() > 1 then
        self.k = self.k -1
    end
end

return porter