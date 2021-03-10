-- package.path = package.path .. ";../external/?.lua"
-- package.path = package.path .. ";./external/?.lua"
-- inspect = require("inspect")

package.path = package.path .. ";../stopword/?.lua"
package.path = package.path .. ";./stopword/?.lua"
stopwords = require("stopwords")

package.path = package.path .. ";../tokenizer/?.lua"
package.path = package.path .. ";./tokenizer/?.lua"
tokenizer = require "tokenization"

package.path = package.path .. ";../keyword/?.lua"
package.path = package.path .. ";./keyword/?.lua"
for_sorting = require "rake"

--[[
    TextTeaser - automatic summarization algorithm
    
    This module is a port of the Newspaper3k port of TextTeaser 
    which was originally written by Jolo Balbin in Scala.
    Both the Original version and Python port are provided under 
    the terms of the MIT License.

    TextTeaser Author: Jolo Balbin
    Newspaper3k's port Author: Lucas Ou-Yang
    Github (original): https://github.com/MojoJolo/textteaser
    Github (Newspaper3k's port): https://github.com/codelucas/newspaper/blob/master/newspaper/nlp.py
    (as of commit: f622011177f6c2e95e48d6076561e21c016f08c3)

    NOTE: 
        >> The results in this module may slightly differ from those 
           in Newspaper3k's implementation as the word and sentence tokenizers
           have different implementations.
           This module depends on ../tokenizer/tokenization.lua
        >> Relevant comments from the original source are preserved while porting.

    Relevant discussion regarding TextTeaser on HN:
    https://news.ycombinator.com/item?id=6536896
        >> In the above HN link, the author (MojoJolo) mentions referring to the paper:
        http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.222.6530&rep=rep1&type=pdf
--]]

-- converting stopwords to table form
local function stop_word_to_table(stop_list)
    stop_table = {}
    for _, word in pairs(stop_list) do
        stop_table[word] = true
    end
    return stop_table
end

local ideal = 20.0
local stopword_type = "nltk_eng"
local stop_word_list = stop_word_to_table(stopwords:stop_words(stopword_type))

local Summarize = {}

function Summarize.summarize(title, text, max_sents)
    if (not text) or (not title) or max_sents <= 0 then
        return {}
    end

    local summaries = {}
    -- The original source has a constraint on the sentence length of 10
    local sentence_func = tokenizer.sentence_tokenize(text)
    local sentences = {}
    for sentence in sentence_func do
        if string.len(sentence) > 10 then
            table.insert(sentences, sentence)
        end
    end
    -- print(inspect(sentences))

    -- This has to a table not list (need fast lookup ahead)
    local keys = Summarize.keywords(text)
    local titleWords = Summarize.split_words(title)

    -- Score sentences, and use the top 5 or max_sents sentences
    local i_ranks, s_ranks = Summarize.score(sentences, titleWords, keys)
    -- print(inspect(i_ranks), inspect(s_ranks))

    -- They have the same values, so sorting will produce identical key, value pairs
    i_ranks = for_sorting.sort_table(i_ranks, false, max_sents)
    s_ranks = for_sorting.sort_table(s_ranks, false, max_sents)

    local top_keys = {}
    for index, key in pairs(i_ranks) do
        top_keys[index] = key
    end
    i_ranks = for_sorting.sort_table(top_keys, true, max_sents)

    for _, key in ipairs(i_ranks) do
        table.insert(summaries, s_ranks[key])
    end
    return table.concat(summaries, " ")
end

function Summarize.score(sentences, titleWords, keywords)
    -- Score sentences based on different features
    local senSize = #sentences
    local i_ranks = {}
    local s_ranks = {}
    for i, s in pairs(sentences) do
        local sentence = Summarize.split_words(s)
        local titleFeature = Summarize.title_score(titleWords, sentence)
        local sentenceLength = Summarize.length_score(#sentence)
        -- we send i not i+1
        local sentencePosition = Summarize.sentence_position(i ,senSize)
        local sbsFeature = Summarize.sbs(sentence, keywords)
        local dbsFeature = Summarize.dbs(sentence, keywords)
        local frequency = (sbsFeature + dbsFeature) / 2.0 * 10.0
        -- Weighted average of scores from four categories
        -- print(i, titleFeature, sbsFeature, dbsFeature, sentenceLength, sentencePosition)
        local totalScore = (titleFeature*1.5 + frequency*2.0 + sentenceLength*1.0 + sentencePosition*1.0)/4.0

        
        if i_ranks[i] == nil then
            i_ranks[i] = totalScore
            s_ranks[s] = totalScore
        end
    end
    return i_ranks, s_ranks
end

local function math_fabs(num)
    -- Centralize! Also in sent/vader.lua
    if num >= 0 then
        return num
    elseif num < 0 then
        return (num * -1)
    end
end

function Summarize.sbs(words, keywords)
    local score = 0.0
    if #words == 0 then
        return 0
    end
    for _, word in pairs(words) do
        if keywords[word] ~= nil then
            score = score + keywords[word]
        end
    end
    return (1.0/math_fabs(#words)*score)/10.0
end

function Summarize.dbs(words, keywords)
    if (#words == 0) then
        return 0
    end

    local sum = 0
    local first = {}
    local second = {}

    for i, word in pairs(words) do
        if keywords[word] ~= nil then
            local score = keywords[word]
            if #first == 0 then
                first = {i, score}
            else
                second = first
                first = {i, score}
                local dif = first[1] - second[1]
                sum = sum + ((first[2] * second[2])/(dif^2))
            end
        end
    end

    local key_dup_check = {}
    -- no of intersections
    local k = 1
    for _, word in pairs(words) do
        if keywords[word] ~= nil then
            if key_dup_check[word] == nil then
                k = k + 1
                key_dup_check[word] = true
            end
        end
    end

    return (1/(k*(k+1.0)) * sum)
end

function Summarize.split_words(text)
    local tokens_func = tokenizer.regex_tokenize(text)
    local tokens = {}
    for token in tokens_func do
        if tokenizer.remove_punctuations(token) ~= "" and string.len(token) >= 3 then
            table.insert(tokens, tokenizer.remove_punctuations(string.lower(token)))
        end
    end
    return tokens
end

function Summarize.keywords(text)
    -- Get the top 10 keywords and their frequency scores ignores blacklisted
    -- words in stopwords, counts the number of occurrences of each word, and
    -- sorts them in reverse natural order (so descending) by number of
    -- occurrences.
    local NUM_KEYWORDS = 10
    local text = Summarize.split_words(text)
    if text ~= nil then
        local num_words = #text
        local freq = {}
        local count = 0
        for _, word in ipairs(text) do
            if stop_word_list[word] == nil 
            and (tokenizer.remove_punctuations(word) ~= "") 
            and string.len(word) >= 3 then
                if freq[word] ~= nil then
                    freq[word] = freq[word] + 1
                else
                    freq[word] = 1
                    count = count + 1
                end
            end
        end
        local min_size = nil
        if NUM_KEYWORDS < count then
            min_size = NUM_KEYWORDS
        else
            min_size = count
        end

        local max_for_denominator = nil
        if num_words > 1 then
            max_for_denominator = num_words
        else
            max_for_denominator = 1
        end

        local keywords, keywords_val = for_sorting.sort_table(freq, false, min_size)
        -- print(inspect(keywords), inspect(keywords_val))
        local keywords_table = {}
        for index, keyword in ipairs(keywords) do
            -- store the old value
            keywords_table[keyword] = keywords_val[index]
            -- compute article score
            local articleScore = keywords_table[keyword] * 1.0 / max_for_denominator
            -- modify the keyword value
            keywords_table[keyword] = articleScore * 1.5 + 1
        end
        return keywords_table
    else
        return {}
    end
end

function Summarize.length_score(sentence_len)
    return 1 - math_fabs(ideal - sentence_len) / ideal
end

function Summarize.title_score(title, sentence)
    local without_stop_title = {}
    local without_stop_title_count = 0
    local count = 0.0
    local max_val = 1
    if title ~= nil then
        for _, x in ipairs(title) do
            if stop_word_list[x] == nil then
                without_stop_title[x] = true
                without_stop_title_count = without_stop_title_count + 1
            end
        end
        for _, word in ipairs(sentence) do
            if stop_word_list[word] == nil and without_stop_title[word] == true then
                count = count + 1.0
            end
        end

        if without_stop_title_count > 1 then
            max_val = without_stop_title_count
        end
    end
    return count / max_val
end

function Summarize.sentence_position(i, size)
    -- Different sentence positions indicate different
    -- probability of being an important sentence.
    
    local normalized = i * 1.0 / size
    if (normalized > 1.0) then
        return 0
    elseif (normalized > 0.9) then
        return 0.15
    elseif (normalized > 0.8) then
        return 0.04
    elseif (normalized > 0.7) then
        return 0.04
    elseif (normalized > 0.6) then
        return 0.06
    elseif (normalized > 0.5) then
        return 0.04
    elseif (normalized > 0.4) then
        return 0.05
    elseif (normalized > 0.3) then
        return 0.08
    elseif (normalized > 0.2) then
        return 0.14
    elseif (normalized > 0.1) then
        return 0.23
    elseif (normalized > 0) then
        return 0.17
    else
        return 0
    end
end

return Summarize