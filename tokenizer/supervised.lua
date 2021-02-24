-- This is experimental and has performance issues
-- Sentence Segmentation using supvervised learning on Treebank corpus
-- https://www.nltk.org/book/ch06.html#sentence-segmentation

package.path = package.path .. ";../external/?.lua"
json = require "json"
inspect = require "inspect"
naive_bayes = require('nb')
tokenize = require "tokenization"

TREEBANK_RAW_SENTS_PATH = "treebank.json"

function to_json(filename)
    local file = io.open(filename, "r")
    local sents = file.read(file, "*a")
    file.close()
    sents = json.decode(sents)
    return sents
end

-- https://stackoverflow.com/a/54140176
function do_tables_match(a, b)
    return table.concat(a) == table.concat(b)
end

function make_boundaries(sents)
    --[[
    'boundaries' contains the sentence boundary token's indexes
    --]]
    local tokens = {}
    local boundaries = {}
    local offset = 1

    for key, sent in ipairs(sents) do
        if do_tables_match(sent, {".", "START"}) ~= true then
            for str_key, str_token in ipairs(sent) do
                table.insert(tokens, str_token)
                offset = offset + string.len(str_token)
                table.insert(boundaries, offset-1)
            end
        end
    end
    return tokens, boundaries
end

local function is_upper(token)
    if string.match(token, "[A-Z]") ~= nil then
        return "_TRUE_"
    end
    return "_FALSE_"
end

local function check_one_word_char(token)
    if string.len(token) == 1 then
        return "_YES_"
    end
    return "_NO_"
end

function punct_features(tokens, i)
    return {
        next_word_cap = is_upper(string.sub(tokens[i+1], 1, 1)),
        prev_word = string.lower(tokens[i-1]),
        punct = tokens[i],
        prev_word_one_char = check_one_word_char(tokens[i-1])
    }
end

function in_boundary(boundaries, i)
    for j = 1, #boundaries do
        if i == boundaries[j] then 
            return true 
        end
    end
    return false
end

function feature_set(tokens, boundaries)
    local features = {}
    for i = 1, #tokens-1 do
        if string.match(tokens[i], "[.?!]") ~= nil and string.len(tokens[i]) == 1 then
            table.insert(features, {punct_features(tokens, i), in_boundary(boundaries, i)})
        end
    end
    return features
end

function make_features(filename)
    local sents = to_json(filename)
    local tokens, boundaries = make_boundaries(sents)
    -- print(inspect(tokens))
    local features = feature_set(tokens, boundaries)
    -- print(inspect(features))
    return features
end

function naive_bayes_learn(features)
    local classifier = naive_bayes.new()
    classifier:init({"next_word_cap", "punct", "prev_word_one_char"}, {true, false})

    for i=1, #features do
        classifier:learn(features[i][1], features[i][2])
    end
    -- print(inspect(classifier))
    return classifier
end

function segment_sentences(words, classifier)
    start = 1
    sents = {}
    for i, word in ipairs(words) do
        -- if i ~= 1 and i~= #words then
        --     print(i, word)
        -- end

        if i ~= #words and string.match(word, "[.?!]") ~= nil and classifier:predict(punct_features(words, i)) == true then
            table.insert(sents, table.move(words, start, i, 1, {}))
            start = i + 1
        end
    end

    -- for no break points - i.e. single sentence - starting or from ending
    if start < #words then
        table.insert(sents, table.move(words, start, #words, 1, {}))
    end
    print(inspect(sents))
    return sents
end

features = make_features(TREEBANK_RAW_SENTS_PATH)
classifier = naive_bayes_learn(features)

test = "Antimatter - the most explosive substance possible - can be manufactured in small quantities using any large particle accelerator, but this will take preposterous amounts of time to produce the required amounts. If you can create the appropriate machinery, it may be possible to find or scrape together an approximately Earth-sized chunk of rock and simply to \"flip\" it all through a fourth spacial dimension, turning it all to antimatter at once."
tokens = {}
for token in tokenize.regex_tokenize(test) do
    table.insert(tokens, token)
end
segment_sentences(tokens, classifier)