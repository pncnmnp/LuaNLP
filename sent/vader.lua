-- package.path = package.path .. ";../external/?.lua"
-- inspect = require("inspect")

package.path = package.path .. ";../external/?.lua"
package.path = package.path .. ";../tokenizer/?.lua"
json = require "json"
tokenizer = require "tokenization"

--[[
    VADER Algorithm for Sentiment Analysis

    This module is a port of vaderSentiment for Lua
    vaderSentiment is provided under the terms of the MIT License
    Github: https://github.com/cjhutto/vaderSentiment/
    (as of vaderSentiment commit: 0150f59077ad3b8d899eff5d4c9670747c2d54c2)
    vaderSentiment author: CJ Hutto

    From original source: 
    Relevant "Thanks" - 
    >> Thanks to George Berry for reducing the 
       time complexity from something like O(N^4) to O(N).

    Relevant Paper: 
    Hutto, C.J. & Gilbert, E.E. (2014). VADER: A Parsimonious Rule-based Model for
    Sentiment Analysis of Social Media Text. Eighth International Conference on
    Weblogs and Social Media (ICWSM-14). Ann Arbor, MI, June 2014.

    NOTE: Relevant comments from the original source are preserved while porting.

    Usage:
    >> s:polarity_scores("This phone has an awesome battery back-up of 2 hours.")

    Drawbacks: As this is a lexicon and rule-based tool, it does not work in cases wherein the tokens are not in the lexicon, but convey sentiment. For example: 
    (From the dataset included in the Paper 'From Group to Individual Labels using Deep Features', Kotzias et. al,. KDD 2015)

    Amazon Reviews
    (1) You can not answer calls with the unit, never worked once!
    (2) Item Does Not Match Picture.
    (3) Lasted one day and then blew up.
    (4) Adapter does not provide enough charging current.
    (5) I plugged it in only to find out not a darn thing worked.

    All the selected sentences generate a "compound" score of 0 (i.e. neutral).

    As mentioned by the vaderSentiment authors in README:
    > is specifically attuned to sentiments expressed in social media

    See test_vader.lua for tests on the [Kotzias et. al,. KDD 2015] paper's dataset
--]]

-- Punctuations (from Python's string.punctuation)
PUNCTS = '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'

-- (empirically derived mean sentiment intensity rating increase for booster words)
B_INCR = 0.293
B_DECR = -0.293

-- (empirically derived mean sentiment intensity rating increase for using ALLCAPs to emphasize a word)
C_INCR = 0.733
N_SCALAR = -0.74

-- It will be easier if this is in tables format than array
-- Will help when `for word in neg_words`
NEGATE = {["aint"]=true, ["arent"]=true, ["cannot"]=true, ["cant"]=true, ["couldnt"]=true, ["darent"]=true, ["didnt"]=true, ["doesnt"]=true, ["ain't"]=true, ["aren't"]=true, ["can't"]=true, ["couldn't"]=true, ["daren't"]=true, ["didn't"]=true, ["doesn't"]=true, ["dont"]=true, ["hadnt"]=true, ["hasnt"]=true, ["havent"]=true, ["isnt"]=true, ["mightnt"]=true, ["mustnt"]=true, ["neither"]=true, ["don't"]=true, ["hadn't"]=true, ["hasn't"]=true, ["haven't"]=true, ["isn't"]=true, ["mightn't"]=true, ["mustn't"]=true, ["neednt"]=true, ["needn't"]=true, ["never"]=true, ["none"]=true, ["nope"]=true, ["nor"]=true, ["not"]=true, ["nothing"]=true, ["nowhere"]=true,["oughtnt"]=true, ["shant"]=true, ["shouldnt"]=true, ["uhuh"]=true, ["wasnt"]=true, ["werent"]=true,["oughtn't"]=true, ["shan't"]=true, ["shouldn't"]=true, "uh-uh", ["wasn't"]=true, ["weren't"]=true,["without"]=true, ["wont"]=true, ["wouldnt"]=true, ["won't"]=true, ["wouldn't"]=true, ["rarely"]=true, ["seldom"]=true, ["despite"]=true}

-- booster/dampener 'intensifiers' or 'degree adverbs'
-- http://en.wiktionary.org/wiki/Category:English_degree_adverbs

BOOSTER_DICT = {["absolutely"]= B_INCR, ["amazingly"]= B_INCR, ["awfully"]= B_INCR, ["completely"]= B_INCR, ["considerable"]= B_INCR, ["considerably"]= B_INCR,      ["decidedly"]= B_INCR, ["deeply"]= B_INCR, ["effing"]= B_INCR, ["enormous"]= B_INCR, ["enormously"]= B_INCR, ["entirely"]= B_INCR, ["especially"]= B_INCR, ["exceptional"]= B_INCR, ["exceptionally"]= B_INCR, ["extreme"]= B_INCR, ["extremely"]= B_INCR, ["fabulously"]= B_INCR, ["flipping"]= B_INCR, ["flippin"]= B_INCR, ["frackin"]= B_INCR, ["fracking"]= B_INCR, ["fricking"]= B_INCR, ["frickin"]= B_INCR, ["frigging"]= B_INCR, ["friggin"]= B_INCR, ["fully"]= B_INCR,       ["fuckin"]= B_INCR, ["fucking"]= B_INCR, ["fuggin"]= B_INCR, ["fugging"]= B_INCR, ["greatly"]= B_INCR, ["hella"]= B_INCR, ["highly"]= B_INCR, ["hugely"]= B_INCR, ["incredible"]= B_INCR, ["incredibly"]= B_INCR, ["intensely"]= B_INCR, ["major"]= B_INCR, ["majorly"]= B_INCR, ["more"]= B_INCR, ["most"]= B_INCR, ["particularly"]= B_INCR, ["purely"]= B_INCR, ["quite"]= B_INCR, ["really"]= B_INCR, ["remarkably"]= B_INCR, ["so"]= B_INCR, ["substantially"]= B_INCR,      ["thoroughly"]= B_INCR, ["total"]= B_INCR, ["totally"]= B_INCR, ["tremendous"]= B_INCR, ["tremendously"]= B_INCR, ["uber"]= B_INCR, ["unbelievably"]= B_INCR, ["unusually"]= B_INCR, ["utter"]= B_INCR, ["utterly"]= B_INCR, ["very"]= B_INCR, ["almost"]= B_DECR, ["barely"]= B_DECR, ["hardly"]= B_DECR, ["just enough"]= B_DECR, ["kind of"]= B_DECR, ["kinda"]= B_DECR, ["kindof"]= B_DECR, ["kind-of"]= B_DECR, ["less"]= B_DECR, ["little"]= B_DECR, ["marginal"]= B_DECR, ["marginally"]= B_DECR, ["occasional"]= B_DECR, ["occasionally"]= B_DECR, ["partly"]= B_DECR, ["scarce"]= B_DECR, ["scarcely"]= B_DECR, ["slight"]= B_DECR, ["slightly"]= B_DECR, ["somewhat"]= B_DECR, ["sort of"]= B_DECR, ["sorta"]= B_DECR, ["sortof"]= B_DECR, ["sort-of"]= B_DECR}

-- check for sentiment laden idioms that do not contain lexicon words (future work, not yet implemented)
SENTIMENT_LADEN_IDIOMS = {["cut the mustard"]= 2, ["hand to mouth"]= -2, ["back handed"]= -2, ["blow smoke"]= -2, ["blowing smoke"]= -2, ["upper hand"]= 1, ["break a leg"]= 2, ["cooking with gas"]= 2, ["in the black"]= 2, ["in the red"]= -2, ["on the ball"]= 2, ["under the weather"]= -2}

-- check for special case idioms and phrases containing lexicon words
SPECIAL_CASES = {["the shit"]= 3, ["the bomb"]= 3, ["bad ass"]= 1.5, ["badass"]= 1.5, ["bus stop"]= 0.0, ["yeah right"]= -2, ["kiss of death"]= -1.5, ["to die for"]= 3, ["beating heart"]= 3.1, ["broken heart"]= -2.9 }

local function negated(input_words, include_nt)
    -- To determine if input contains negation
    local mod_input_words = {}
    for _, w in ipairs(input_words) do
        table.insert(mod_input_words, string.lower(tostring(w)))
    end

    local neg_words = NEGATE
    for _, word in ipairs(mod_input_words) do
        if neg_words[word] == true then
            return true
        end
    end
    if include_nt == true then
        for _, word in ipairs(mod_input_words) do
            if string.find(word, "n't") ~= nil then
                return true
            end
        end
    end
    return false
end

local function normalize(score, alpha)
    --[[
        Normalize the score to be between -1 and 1 using an alpha that 
        approximates the max expected value
    --]]
    local norm_score = score/(math.sqrt((score*score) + alpha))
    if norm_score < -1.0 then
        return -1.0
    elseif norm_score > 1.0 then
        return 1.0
    else
        return norm_score
    end
end

local function isupper(word)
    --[[
        Mimicking Python's isupper() function.
        From Python 3.6 docs - 
        >> Return true if all cased characters [4] in the string are uppercase 
        AND THERE IS AT LEAST ONE CASED CHARACTER, false otherwise.
        From Python's source code:
        https://github.com/python/cpython/blob/c304c9a7efa8751b5bc7526fa95cd5f30aac2b92/Objects/bytes_methods.c#L219
    --]]
    one_cased_character = false
    for char in string.gmatch(word, ".") do
        if string.find(char, "[a-z]") ~= nil then
            return false
        end
        if one_cased_character == false and string.find(char, "[A-Z]") ~= nil then
            one_cased_character = true
        end
    end
    return one_cased_character
end

local function scalar_inc_dec(word, valence, is_cap_diff)
    local scalar = 0.0
    local word_lower = string.lower(word)
    if BOOSTER_DICT[word_lower] ~= nil then
        scalar = BOOSTER_DICT[word_lower]
        if valence < 0 then
            scalar = scalar * (-1)
        end
        -- check if the booster/dampener word is in ALL CAPS
        if isupper(word) == true and is_cap_diff == true then
            if valence > 0 then
                scalar = scalar + C_INCR
            else
                scalar = scalar - C_INCR
            end
        end
    end
    return scalar
end

local function allcap_differential(words)
    -- Check whether just some words in the input are ALL CAPS
    local is_different = false
    local allcap_words = 0
    for _, word in ipairs(words) do
        if isupper(word) then
            allcap_words = allcap_words + 1
        end
    end
    local cap_differential = #words - allcap_words
    if 0 < cap_differential and cap_differential < #words then
        is_different = true
    end
    return is_different
end

local function escape_pattern(text)
    -- https://stackoverflow.com/a/34953646/7543474
    return text:gsub("([^%w])", "%%%1")
end

-- Identify sentiment-relevant string-level properties of input text.
local SentiText = {}

SentiText.text = ""

SentiText._strip_punc_if_word = function(self, token)
    -- Removes all trailing and leading punctuation
    -- If the resulting string has two or fewer characters,
    -- then it was likely an emoticon, so return original string
    -- (ie ":)" stripped would be "", so just return ":)"
    local function punc_strip(_token)
        -- This function mimics Python's strip() with punctuations
        local escape_puncts = escape_pattern(PUNCTS)
        local find_puncs = string.gmatch(_token, string.format("[%s]+", escape_puncts))
        local all_puncs = {}
        for chars in find_puncs do 
            local escape_char = escape_pattern(chars)
            table.insert(all_puncs, escape_char)
        end

        if #all_puncs == 0 then
            return _token
        end

        local start, _end = string.find(_token, all_puncs[1])
        if start == 1 then
            _token = string.sub(_token, _end+1, #_token)
        end
        _token = string.reverse(_token)
        start, _end = string.find(_token, all_puncs[#all_puncs])
        if start == 1 then
            _token = string.sub(_token, _end+1, #_token)
        end
        return string.reverse(_token)
    end

    local stripped = punc_strip(token)
    if string.len(stripped) <= 2 then
        return token
    end
    return stripped
end

SentiText._words_and_emoticons = function(self)
    -- Removes leading and trailing puncutation
    -- Leaves contractions and most emoticons
    --     Does not preserve punc-plus-letter emoticons (e.g. :D)
    local wes = tokenizer.whitespace_tokenize(self.text)
    local stripped = {}
    for token in wes do
        table.insert(stripped, self:_strip_punc_if_word(token))
    end
    return stripped
end

SentiText.words_and_emoticons = SentiText:_words_and_emoticons()
SentiText.is_cap_diff = allcap_differential(SentiText.words_and_emoticons)

-- Give a sentiment intensity score to sentences.
local SentimentIntensityAnalyzer = {}

-- Reminder: move to the top
LEXICON_FILE = "./vader_lexicons/vader_lexicon.txt"
EMOJI_LEXICON="./vader_lexicons/emoji_utf8_lexicon.txt"

SentimentIntensityAnalyzer.make_lex_dict = function(self)
    -- Convert lexicon file to directory
    local lex_dict = {}
    local file = io.open(self.lexicon_full_filepath, "r")
    for line in file:lines() do
        -- rstrip won't be necessary here
        if line then
            local line_sections = string.gmatch(line, "[^\t]+")
            local word = line_sections()
            local measure = line_sections()
            lex_dict[word] = tonumber(measure)
        end
    end
    return lex_dict
end

SentimentIntensityAnalyzer.make_emoji_dict = function(self)
    -- Convert emoji lexicon file to a dictionary
    local emoji_dict = {}
    local file = io.open(self.emoji_full_filepath, "r")
    for line in file:lines() do
        local line_sections = string.gmatch(line, "[^\t]+")
        local emoji = line_sections()
        local description = line_sections()
        emoji_dict[emoji] = description
    end
    return emoji_dict
end

SentimentIntensityAnalyzer.polarity_scores = function(self, text)
    -- Return a float for sentiment strength based on the input text.
    -- Positive values are positive valence, negative value are negative
    -- valence.
    -- convert emojis to their textual descriptions
    local text_no_emoji = ""
    local prev_space = true
    for character in string.gmatch(text, utf8.charpattern) do
        if self.emojis[character] ~= nil then
            local description = self.emojis[character]
            if not prev_space then
                text_no_emoji = text_no_emoji .. " "
            end
            text_no_emoji = text_no_emoji .. description
            prev_space = false
        else
            text_no_emoji = text_no_emoji .. character
            prev_space = (text_no_emoji == ' ')
        end
    end
    text = text_no_emoji
    local sentitext = SentiText
    sentitext.text = text
    sentitext.words_and_emoticons = sentitext:_words_and_emoticons()
    sentitext.is_cap_diff = allcap_differential(sentitext.words_and_emoticons)

    local sentiments = {}
    local words_and_emoticons = sentitext.words_and_emoticons
    for i, item in ipairs(words_and_emoticons) do
        local valence = 0
        -- check for vader_lexicon words that may be used as modifiers or negations
        -- <<ASK>> why are these 0 right here?
        -- <<ANSWER>> they are ignoring it here. Later in the "sentiment_valence()" they
        -- visit the previous tokens (and call "scalar_inc_dec") to create the dampening effect
        if BOOSTER_DICT[string.lower(item)] ~= nil then
            table.insert(sentiments, valence)
        -- for "kind of" compound word
        elseif (i < #words_and_emoticons) and string.lower(item) == "kind" and string.lower(words_and_emoticons[i+1]) == "of" then
            table.insert(sentiments, valence)
        else
            sentiments = self:sentiment_valence(valence, sentitext, item, i, sentiments)
        end
    end
    -- print(inspect(sentiments))
    sentiments = self:_but_check(words_and_emoticons, sentiments)
    local valence_dict = self:score_valence(sentiments, text)
    return valence_dict
end

SentimentIntensityAnalyzer.sentiment_valence = function(self, valence, sentitext, item, i, sentiments)
    local is_cap_diff = sentitext.is_cap_diff
    local words_and_emoticons = sentitext.words_and_emoticons
    local item_lowercase = string.lower(item)
    if self.lexicon[item_lowercase] ~= nil then
        -- getting the sentiment valence
        valence = self.lexicon[item_lowercase]
        -- print("UP", valence, item, inspect(sentiments))

        -- check for "no" as negation for an adjacent lexicon item 
        -- vs "no" as its own stand-alone lexicon item
        -- check if curr is "no", i is not the end of the sentence and the next word is in the lexicon (i.e. it has a sentiment)
        if item_lowercase == "no" and i ~= #words_and_emoticons and self.lexicon[string.lower(words_and_emoticons[i+1])] ~= nil then
            -- don't use valence of "no" as a lexicon item. Instead set it's valence to 0.0 and negate the next item
            valence = 0.0
        end
        if (i > 1 and string.lower(words_and_emoticons[i-1]) == "no") or
           (i > 2 and string.lower(words_and_emoticons[i-2]) == "no") or
           (i > 3 and string.lower(words_and_emoticons[i-3]) == "no" and (string.lower(words_and_emoticons[i - 1]) == "or" or string.lower(words_and_emoticons[i - 1]) == "nor")) then
            valence = self.lexicon[item_lowercase] * N_SCALAR
        end

        -- check if sentiment laden word is in ALL CAPS (while others aren't)
        -- <<ASK>> I dont understand the "while others aren't" comment from original codebase
        -- "allcap_differential" does not seem to be doing that, it just checks if there are capital words in the input words
        -- Also looks similar to one in "scalar_inc_dec"
        if isupper(item) and is_cap_diff then
            if valence > 0 then
                valence = valence + C_INCR
            else
                valence = valence - C_INCR
            end
        end

        for start_i=1, 3 do
            -- dampen the scalar modifier of preceding words and emoticons
            -- (excluding the ones that immediately preceed the item) based
            -- on their distance from the current item.
            
            -- cannot be start_i + 1 here as it will start with "prev-prev" not "prev" word
            -- we need "== nil" to mimick "not in self.lexicon"
            if i > start_i and 
            self.lexicon[string.lower(words_and_emoticons[i - start_i])] == nil then
                local s = scalar_inc_dec(words_and_emoticons[i - start_i], valence, is_cap_diff)
                if start_i == 2 and s ~= 0 then
                    s = s * 0.95
                end
                if start_i == 3 and s ~= 0 then
                    s = s * 0.9
                end
                valence = valence + s
                valence = self:_negation_check(valence, words_and_emoticons, start_i, i)
                if start_i == 3 then
                    valence = self:_special_idioms_check(valence, words_and_emoticons, i)
                end
            end
        end
        valence = self:_least_check(valence, words_and_emoticons, i)
        -- print("INSIDE", valence, self.lexicon[item_lowercase], item, i)
        -- print("BELOW", valence, item, inspect(sentiments))
    end
    table.insert(sentiments, valence)
    -- print("OUT", valence, self.lexicon[item_lowercase], item, i)
    return sentiments
end

SentimentIntensityAnalyzer._least_check = function(self, valence, words_and_emoticons, i)
    -- check for negation case using "least"
    if i > 2 and self.lexicon[string.lower(words_and_emoticons[i-1])] ~= nil 
      and string.lower(words_and_emoticons[i-1]) == "least" then
        if string.lower(words_and_emoticons[i-2]) ~= "at" and string.lower(words_and_emoticons[i-2]) ~= "very" then
            valence = valence * N_SCALAR
        end
    elseif i > 1 and self.lexicon[string.lower(words_and_emoticons[i-1])] ~= nil
      and string.lower(words_and_emoticons[i-1]) == "least" then
        valence = valence * N_SCALAR
    end
    return valence
end

SentimentIntensityAnalyzer._but_check = function(self, words_and_emoticons, sentiments)
    -- check for modification in sentiment due to contrastive conjunction 'but'
    local words_and_emoticons_lower = {}
    local bi = 0
    for i, w in ipairs(words_and_emoticons) do
        local mod_w = string.lower(tostring(w))
        table.insert(words_and_emoticons_lower, mod_w)
        if mod_w == "but" then
            bi = i
        end
    end
    if bi ~= 0 then
        for i, sentiment in ipairs(sentiments) do
            local si = i
            if si < bi then
                table.remove(sentiments, si)
                table.insert(sentiments, si, sentiment*0.5)
            elseif si > bi then
                table.remove(sentiments, si)
                table.insert(sentiments, si, sentiment*1.5)
            end
        end
    end
    return sentiments
end

SentimentIntensityAnalyzer._special_idioms_check = function(self, valence, words_and_emoticons, i)
    local words_and_emoticons_lower = {}
    for _, w in ipairs(words_and_emoticons) do
        local mod_w = string.lower(tostring(w))
        table.insert(words_and_emoticons_lower, mod_w)
    end
    local onezero = string.format("%s %s", words_and_emoticons_lower[i-1], words_and_emoticons_lower[i])

    local twoonezero = string.format("%s %s %s", words_and_emoticons_lower[i-2], words_and_emoticons_lower[i-1], words_and_emoticons_lower[i])

    local twoone = string.format("%s %s", words_and_emoticons_lower[i-2], words_and_emoticons_lower[i-1])

    local threetwoone = string.format("%s %s %s", words_and_emoticons_lower[i-3], words_and_emoticons_lower[i-2], words_and_emoticons_lower[i-1])

    local threetwo = string.format("%s %s", words_and_emoticons_lower[i-3], words_and_emoticons_lower[i-2])

    local sequences = {onezero, twoonezero, twoone, threetwoone, threetwo}

    for _, seq in ipairs(sequences) do
        if SPECIAL_CASES[seq] ~= nil then
            valence = SPECIAL_CASES[seq]
            break
        end
    end

    -- not #words_and_emoticons_lower - 1
    if #words_and_emoticons_lower > i then
        local zeroone = string.format("%s %s", words_and_emoticons_lower[i], words_and_emoticons_lower[i+1])
        if SPECIAL_CASES[zeroone] ~= nil then
            valence = SPECIAL_CASES[zeroone]
        end
    end

    if #words_and_emoticons_lower > i + 1 then
        local zeroonetwo = string.format("%s %s %s", words_and_emoticons_lower[i], words_and_emoticons_lower[i+1], words_and_emoticons_lower[i+2])
        if SPECIAL_CASES[zeroonetwo] ~= nil then
            valence = SPECIAL_CASES[zeroonetwo]
        end
    end

    -- check for booster/dampener bi-grams such as 'sort of' or 'kind of'
    local n_grams = {threetwoone, threetwo, twoone}
    for _, n_gram in pairs(n_grams) do
        if BOOSTER_DICT[n_gram] ~= nil then
            valence = valence + BOOSTER_DICT[n_gram]
        end
    end

    return valence
end

SentimentIntensityAnalyzer._sentiment_laden_idioms_check = function(self, valence, senti_text_lower)
    -- NOT GETTING CALLED
    -- Future Work
    -- check for sentiment laden idioms that don't contain a lexicon word

    -- Assuming "senti_text_lower" is a dict
    -- IF it is a list, pass it as dict with values as true
    local idioms_valences = {}
    local sum_idioms_valences = 0
    for idiom in pairs(SENTIMENT_LADEN_IDIOMS) do
        if senti_text_lower[idiom] ~= nil then
            -- print(idiom, inspect(senti_text_lower))
            valence = SENTIMENT_LADEN_IDIOMS[idiom]
            table.insert(idioms_valences, valence)
            sum_idioms_valences = sum_idioms_valences + valence
        end
    end
    if #idioms_valences > 0 then
        valence = (sum_idioms_valences / #idioms_valences)
    end
    return valence
end

SentimentIntensityAnalyzer._negation_check = function(self, valence, words_and_emoticons, start_i, i)
    local words_and_emoticons_lower = {}
    for _, w in ipairs(words_and_emoticons) do
        local mod_w = string.lower(tostring(w))
        table.insert(words_and_emoticons_lower, mod_w)
    end
    -- start_i is 1,3
    if start_i == 1 then
        -- 1 word preceding lexicon word (w/o stopwords)
        -- Here too - 
        -- cannot be start_i + 1 here as it will start with "prev-prev" not "prev" word
        if negated({words_and_emoticons_lower[i - start_i]}, true) then
            valence = valence * N_SCALAR
        end
    end

    -- 2 words preceding lexicon word position
    if start_i == 2 then
        if words_and_emoticons_lower[i-2] == "never" and
            (words_and_emoticons_lower[i-1] == "so" or words_and_emoticons_lower[i-1] == "this") then
                valence = valence * 1.25
        elseif words_and_emoticons_lower[i-2] == "without" and words_and_emoticons_lower[i-1] == "doubt" then
            valence = valence
        elseif negated({words_and_emoticons_lower[i - start_i]}, true) then
            valence = valence * N_SCALAR
        end
    end

    -- 3 words preceding lexicon word position
    if start_i == 3 then
        if words_and_emoticons_lower[i-3] == "never" 
          and ((words_and_emoticons_lower[i - 2] == "so" 
                or words_and_emoticons_lower[i - 2] == "this") 
            or (words_and_emoticons_lower[i - 1] == "so" 
                or words_and_emoticons_lower[i - 1] == "this")) then
            valence = valence * 1.25
        elseif words_and_emoticons_lower[i - 3] == "without" and
          (words_and_emoticons_lower[i - 2] == "doubt" or words_and_emoticons_lower[i - 1] == "doubt") then
            valence = valence
        elseif negated({words_and_emoticons_lower[i -start_i]}, true) then
            valence = valence * N_SCALAR
        end
    end
    return valence
end

SentimentIntensityAnalyzer._punctuation_emphasis = function(self, text)
    -- add emphasis from exclamation points and question marks
    local ep_amplifier = self:_amplify_ep(text)
    local qm_amplifier = self:_amplify_qm(text)
    local punct_emph_amplifier = ep_amplifier + qm_amplifier
    return punct_emph_amplifier
end

SentimentIntensityAnalyzer._amplify_ep = function(self, text)
    -- check for added emphasis resulting from exclamation points (up to 4 of them)
    local ep_count = 0
    for i in string.gmatch(text, "[!]") do 
        ep_count = ep_count + 1 
    end

    if ep_count > 4 then
        ep_count = 4
    end
    -- (empirically derived mean sentiment intensity rating increase for
    -- exclamation points)
    local ep_amplifier = ep_count * 0.292
    return ep_amplifier
end

SentimentIntensityAnalyzer._amplify_qm = function(self, text)
    -- check for added emphasis resulting from question marks (2 or 3+)
    local qm_count = 0
    for i in string.gmatch(text, "[?]") do
        qm_count = qm_count + 1
    end
    local qm_amplifier = 0
    if qm_count > 1 then
        if qm_count <= 3 then
            -- (empirically derived mean sentiment intensity rating increase for
            -- question marks)
            qm_amplifier = qm_count * 0.18
        else
            qm_amplifier = 0.96
        end
    end
    return qm_amplifier
end

SentimentIntensityAnalyzer._sift_sentiment_scores = function(self, sentiments)
    -- want separate positive versus negative sentiment scores
    local pos_sum = 0.0
    local neg_sum = 0.0
    local neu_count = 0
    for _, sentiment_score in pairs(sentiments) do
        if sentiment_score > 0 then
            -- compensates for neutral words that are counted as 1
            pos_sum = pos_sum + sentiment_score + 1
        end
        if sentiment_score < 0 then
            -- when used with math.fabs(), compensates for neutrals
            -- fabs is float absolute for python
            neg_sum = neg_sum + sentiment_score - 1
        end
        if sentiment_score == 0 then
            neu_count = neu_count + 1
        end
    end
    return pos_sum, neg_sum, neu_count
end

SentimentIntensityAnalyzer.score_valence = function(self, sentiments, text)
    local function math_fabs(num)
        if num >= 0 then
            return num
        elseif num < 0 then
            return (num * -1)
        end
    end

    local function round(x, n)
        -- https://stackoverflow.com/a/37792884
        local n = math.pow(10, n or 0)
        local x = x * n
        if x >= 0 then x = math.floor(x + 0.5) else x = math.ceil(x - 0.5) end
        return x / n
    end    

    local compound, pos, neg, neu = 0.0, 0.0, 0.0, 0.0
    if sentiments then
        local sum_s = 0
        for _, sent in pairs(sentiments) do
            sum_s = sum_s + sent
        end

        local punct_emph_amplifier = self:_punctuation_emphasis(text)
        if sum_s > 0 then
            sum_s = sum_s + punct_emph_amplifier
        elseif sum_s < 0 then
            sum_s = sum_s - punct_emph_amplifier
        end

        -- Taking the alpha value as 15
        compound = normalize(sum_s, 15)
        -- discriminate between positive, negative and neutral sentiment scores
        local pos_sum, neg_sum, neu_count = self:_sift_sentiment_scores(sentiments)

        if pos_sum > math_fabs(neg_sum) then
            pos_sum = pos_sum + punct_emph_amplifier
        elseif pos_sum < math_fabs(neg_sum) then
            neg_sum = neg_sum - punct_emph_amplifier
        end

        local total = pos_sum + math_fabs(neg_sum) + neu_count
        pos = math_fabs(pos_sum/total)
        neg = math_fabs(neg_sum/total)
        neu = math_fabs(neu_count/total)
    else
        compound = 0.0
        pos = 0.0
        neg = 0.0
        neu = 0.0
    end

    local sentiment_dict = {neg=round(neg, 3), pos=round(pos, 3), neu=round(neu, 3), compound=round(compound, 4)}

    return sentiment_dict
end

SentimentIntensityAnalyzer.lexicon_full_filepath = LEXICON_FILE
SentimentIntensityAnalyzer.lexicon = SentimentIntensityAnalyzer:make_lex_dict()

SentimentIntensityAnalyzer.emoji_full_filepath = EMOJI_LEXICON
SentimentIntensityAnalyzer.emojis = SentimentIntensityAnalyzer:make_emoji_dict()
-- Note: Unsure - how to replace the codecs.open part. Relying on io.open for now 

return SentimentIntensityAnalyzer