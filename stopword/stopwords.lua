package.path = package.path .. ";../external/?.lua"
package.path = package.path .. ";./external/?.lua"
inspect = require("inspect")

--[[
    Stopwords module

    To read the Stoplist descriptions, go to ./stoplists/README.txt
    To use this module:
    >> st:stopwords(<stoplist-choice>)
    >> -- By default, stoplists supported are the following - 
    >> -- Fox StopList ("fox"), NLTK's english Stoplist ("nltk_eng"), and Smart Stoplist ("smart")
    >> -- See variable "list_match"
--]]

local FOX_FILE = "stopword/stoplists/fox.txt"
local SMART_FILE = "stopword/stoplists/smart.txt"
local NLTK_ENGLISH = "stopword/stoplists/nltk_english.txt"

local list_match = {fox=FOX_FILE, smart=SMART_FILE, nltk_eng=NLTK_ENGLISH}

local Stopwords = {}

local function fetch_stop_words(stop_word_file)
    print(stop_word_file)
    local stop_words = {}
    local file = io.open(stop_word_file, "r")
    -- local handle = io.popen("pwd")
    -- local result = handle:read("*a")
    -- handle:close()

    for line in file:lines() do
        if string.sub(line, 1, 1) ~= "#" then
            table.insert(stop_words, line)
        end
    end
    file:close()
    return stop_words
end

Stopwords.stop_words = function(self, stopword_type)
    return fetch_stop_words(list_match[stopword_type])
end

return Stopwords
-- print(inspect(Stopwords:stop_words("fox")))