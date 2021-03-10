package.path = package.path .. ";../stopword/?.lua"
package.path = package.path .. ";./stopword/?.lua"
stopwords = require("stopwords")

package.path = package.path .. ";../tokenizer/?.lua"
package.path = package.path .. ";./tokenizer/?.lua"
tokenizer = require "tokenization"

-- package.path = package.path .. ";./external/?.lua"
-- package.path = package.path .. ";../external/?.lua"
-- inspect = require("inspect")

rex = require "rex_pcre"

--[[
    Rapid Automatic Keyword Extraction (RAKE) algorithm

    This module is a Python port of RAKE by Aneesha.
    The Python port is provided under the terms of the MIT License.
    Github: https://github.com/aneesha/RAKE
    Author: Aneesha
    (as of commit 22474be2ba9a88d78ea2f2efd8d1f8115af869e1)

    Relevant paper:
    Rapid Automatic Keyword Extraction (RAKE) algorithm as described in: Rose, S., Engel, D., 
    Cramer, N., & Cowley, W. (2010). Automatic Keyword Extraction from Individual Documents. In M. 
    W. Berry & J. Kogan (Eds.), Text Mining: Theory and Applications: John Wiley & Sons.

    NOTE: By default, this implementation uses the "Smart" Stoplist. 
          To change this -
          >> Rake.stopword_type = <your-choice>
          >> -- By default, ../stopwords supports the following - 
          >> -- Fox StopList, NLTK's english Stoplist, and Smart Stoplist
          >> Rake._stop_word_pattern = build_stop_word_regex(Rake.stopword_type)
          >> Rake.run(text, topn)

    When to use RAKE: RAKE can primarily be used for obtaining key phrases in text body
    For 1 or 2 token keywords - see the TextTeaser function Summarize.keywords
--]]

local function is_number(s)
    if tonumber(is_number) ~= nil then
        return true
    else
        return false
    end
end

local function separate_words(text, min_word_return_size)
    local words = {}
    -- local text_without_puncs = tokenizer.remove_punctuations(text)
    for single_word in rex.split(text, "[^a-zA-Z0-9_\\+\\-/]") do
        local current_word = string.lower(single_word)
        -- leave numbers in phrase, but don't count as words, 
        -- since they tend to invalidate scores of their phrases
        if string.len(current_word) > min_word_return_size and 
            current_word ~= '' and not is_number(current_word) then
                table.insert(words, current_word)
        end
    end
    return words
end

local function split_sentences(text)
    local sentence_delimiters = '[.!?,;:\t\\\\"\\(\\)\\\']|\\s\\-\\s'
    local sentences = {}
    for sentence in rex.split(text, sentence_delimiters) do
        table.insert(sentences, string.lower(sentence))
    end
    return sentences
end

local function build_stop_word_regex(stopword_type)
    local stop_word_list = stopwords:stop_words(stopword_type)
    local stop_word_regex_list = {}
    for _, word in ipairs(stop_word_list) do
        local word_regex = "\\b" .. word .. "(?![\\w-])"
        table.insert(stop_word_regex_list, word_regex)
    end
    local stop_word_pattern = ""
    for index, regex in ipairs(stop_word_regex_list) do
            stop_word_pattern = stop_word_pattern .. regex .. "|"
    end
    return string.sub(stop_word_pattern, 1, -2)
end

local function generate_candidate_keywords(sentence_list, stopword_pattern)
    local phrase_list = {}

    for _, s in ipairs(sentence_list) do
        local tmp = rex.gsub(s, stopword_pattern, "|")
        for phrase in rex.gmatch(tmp, "\\b[^|]+\\b") do
            local mod_phrase = string.lower(phrase)
            if mod_phrase ~= "" then
                table.insert(phrase_list, mod_phrase)
            end
        end
    end
    return phrase_list
end

local function calculate_word_scores(phraseList)
    local word_frequency = {}
    local word_degree = {}
    for _, phrase in ipairs(phraseList) do
        local word_list = separate_words(phrase, 0)
        local word_list_length = #word_list
        local word_list_degree = word_list_length - 1
        for _, word in ipairs(word_list) do
            if word_frequency[word] == nil then
                word_frequency[word] = 0
            end
            if word_degree[word] == nil then
                word_degree[word] = 0
            end
            word_frequency[word] = word_frequency[word] + 1
            word_degree[word] = word_degree[word] + word_list_degree
        end
    end
    for item in pairs(word_frequency) do
        word_degree[item] = word_degree[item] + word_frequency[item]
    end

    local word_score = {}
    for item in pairs(word_frequency) do
        if word_score[item] == nil then
            word_score[item] = 0
        end
        word_score[item] = word_degree[item] / (word_frequency[item]*1.0)
    end
    return word_score
end

local function generate_candidate_keyword_scores(phrase_list, word_score)
    local keyword_candidates = {}
    for _, phrase in pairs(phrase_list) do
        if keyword_candidates[phrase] == nil then
            keyword_candidates[phrase] = 0
        end
        local word_list = separate_words(phrase, 0)
        local candidate_score = 0
        for _, word in ipairs(word_list) do
            candidate_score = candidate_score + word_score[word]
        end
        keyword_candidates[phrase] = candidate_score
    end
    return keyword_candidates
end

local Rake = {}
Rake.stopword_type = "smart"
Rake._stop_word_pattern = build_stop_word_regex(Rake.stopword_type)

Rake.run = function(self, text, topn)
    local sentence_list = split_sentences(text)

    local phrase_list = generate_candidate_keywords(sentence_list, self._stop_word_pattern)
    local word_scores = calculate_word_scores(phrase_list)

    local keyword_candidates = generate_candidate_keyword_scores(phrase_list, word_scores)
    local sorted_keywords, sorted_values = Rake.sort_table(keyword_candidates, false, topn)    
    return sorted_keywords, sorted_values
end

function Rake.sort_table(user_table, asc, topn)
    -- https://stackoverflow.com/a/58336368/7543474
    local keys = {}
    for key, _ in pairs(user_table) do
        table.insert(keys, key)
    end
    if asc == true then
        table.sort(keys, function(keyLhs, keyRhs) return user_table[keyLhs] < user_table[keyRhs] end)
    elseif asc == false then
        table.sort(keys, function(keyLhs, keyRhs) return user_table[keyLhs] > user_table[keyRhs] end)
    end

    local till = 0
    local till_end = 0
    if topn == nil then
        till_end = #keys
    else
        till_end = topn
    end

    local new_table = {}
    local sorted_values = {}
    for _, key in ipairs(keys) do
        till = till + 1
        table.insert(new_table, key)
        table.insert(sorted_values, user_table[key])
        if till == till_end then
            break
        end
    end
    return new_table, sorted_values
end

return Rake