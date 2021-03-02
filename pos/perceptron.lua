-- package.path = package.path .. ";../external/?.lua"
-- inspect = require("inspect")

--[[
    Averaged Perceptron based Parts of Speech Tagger

    This module is a port of NLTK's Averaged Perceptron Tagger 
    which in-turn was a port of Textblob's Averaged Perceptron Tagger.
    NLTK port's author: Long Duong <longdt219@gmail.com>
    Textblob's author: Matthew Honnibal <honnibal+gh@gmail.com>

    NLTK's port is provided under the terms of the MIT License.
    Link: https://github.com/nltk/nltk/blob/develop/nltk/tag/perceptron.py
    (as of NLTK's commit: df1b563049ffafa6ca7ef34b07bf88d98d22db70)

    Further Readings:
    * Matthew Honnibal's blog detailing the concept - 
      https://explosion.ai/blog/part-of-speech-pos-tagger-in-python
    * For an introduction to Parts of Speech Tagging - 
      https://web.stanford.edu/~jurafsky/slp3/8.pdf
    
    For performance on CoNLL-2000's test set, see ./conll2000/README.txt
--]]

local AveragedPerceptron = {}
local PerceptronTagger = {}

AveragedPerceptron.weights = {}
AveragedPerceptron.classes = {}
-- The accumulated values, for the averaging. These will be keyed by
-- feature/clas tuples
AveragedPerceptron._totals = {}
AveragedPerceptron._tstamps = {}
-- Number of instances seen
AveragedPerceptron.i = 0

AveragedPerceptron._softmax = function(self, scores)
    local exp_total = 0
    local conf = 0
    local best_label = nil
    for label, value in pairs(scores) do
        -- print(label, inspect(scores))
        scores[label] = math.exp(scores[label])
        exp_total = exp_total + scores[label]
    end
    for label, value in pairs(scores) do
        scores[label] = scores[label] / exp_total
        if scores[label] > conf then
            conf = scores[label]
            best_label = label
        end
    end
    return best_label, conf
end

AveragedPerceptron.predict = function(self, features, return_conf)
    local scores, scores_count = {}, 0
    for feat, value in pairs(features) do
        if self.weights[feat] == nil or value == 0 then
        else
            local weights = self.weights[feat]
            for label, weight in pairs(weights) do
                if scores[label] == nil then
                    scores[label] = 0.0
                    scores_count = scores_count + 1
                end
                scores[label] = scores[label] + (value*weight)
            end
        end
    end

    local best_label, conf = "", 0
    if scores_count ~= 0 then
        best_label, conf = self:_softmax(scores)
    else 
        best_label, conf = self.classes["VBZ"], 0
    end
    return best_label, conf
end

AveragedPerceptron.update = function(self, truth, guess, features)
    local function upd_feat(c, f, w, v)
        if self._totals[f] == nil then
            self._totals[f] = {}
        end
        if self._totals[f][c] == nil then
            self._totals[f][c] = 0
        end
        if self._tstamps[f] == nil then
            self._tstamps[f] = {}
            self._tstamps[f][c] = 0
        elseif self._tstamps[f][c] == nil then
            self._tstamps[f][c] = 0
        end
        -- print(c, f, self.i, inspect(w))
        self._totals[f][c] = self._totals[f][c] + ((self.i - self._tstamps[f][c]) * w)
        self._tstamps[f][c] = self.i
        self.weights[f][c] = w + v
    end

    -- print("Updating self.i - " .. self.i, truth, guess)
    self.i = self.i + 1
    if truth == guess then
        return nil
    end
    for f, _ in pairs(features) do
        if self.weights[f] == nil then
            self.weights[f] = {}
        end
        local weights = self.weights
        if weights[f][truth] ~= nil then
            upd_feat(truth, f, weights[f][truth], 1.0)
        elseif weights[f][truth] == nil then
            upd_feat(truth, f, 0.0, 1.0)
        end

        if weights[f][guess] ~= nil then
            upd_feat(guess, f, weights[f][guess], -1.0)
        elseif weights[f][guess] == nil then
            upd_feat(guess, f, 0.0, -1.0)
        end
    end
end

function round(x, n)
    -- https://stackoverflow.com/a/37792884
    n = math.pow(10, n or 0)
    x = x * n
    if x >= 0 then x = math.floor(x + 0.5) else x = math.ceil(x - 0.5) end
    return x / n
end

AveragedPerceptron.average_weights = function(self)
    for feat, weights in pairs(self.weights) do
        local new_feat_weights = {}
        for clas, weight in pairs(weights) do
            local total = self._totals[feat][clas]
            total = total + ((self.i - self._tstamps[feat][clas]) * weight)
            averaged = round(total / self.i, 3)
            if averaged ~= nil then
                new_feat_weights[clas] = averaged
            end
        end
        self.weights[feat] = new_feat_weights
    end
end

PerceptronTagger["START"] = {"-START-", "_START2-"}
PerceptronTagger["END"] = {"-END-", "-END2-"}

PerceptronTagger.model = AveragedPerceptron
PerceptronTagger.tagdict = {}
PerceptronTagger._sentences = {}
-- classes behaves as sets in NLTK's Python code, so in Lua, we represent it as indices in a table
PerceptronTagger.classes = {}

PerceptronTagger.make_context = function(self, tokens)
    local context = {self.START[1], self.START[2]}
    for _, token in ipairs(tokens) do
        table.insert(context, self:normalize(token))
    end
    table.insert(context, self.END[1])
    table.insert(context, self.END[2])
    return context
end

local function random_shuffle_sentences(sentences)
    for i = #sentences, 2, -1 do
        local j = math.random(i)
        sentences[i][1], sentences[i][2], sentences[j][1], sentences[j][2] = sentences[j][1], sentences[j][2], sentences[i][1], sentences[i][2]
    end
    return sentences
end

local function _pc(n, d)
    return (n/d)*100
end

PerceptronTagger.tag = function(self, tokens, return_conf, use_tagdict)
    -- tokens is not key-value pairs, simple array
    local prev, prev2 = self.START[1], self.START[2]
    local output = {}

    local context = self:make_context(tokens)
    for i, word in ipairs(tokens) do
        local tag, conf = nil, 0
        if use_tagdict == true then
            tag, conf = self.tagdict[word], 1.0
        elseif use_tagdict == false then
            tag, conf = nil, nil
        end

        if not tag then
            local features = self:_get_features(i, word, context, prev, prev2)
            tag, conf = self.model:predict(features, return_conf)
        end

        -- to prevent a length mismatch
        -- if return_conf=false, it will output conf as nil
        -- instead of not sending it at all
        table.insert(output, {word, tag, conf})
        -- print(inspect(output), tag, conf)

        prev2 = prev
        prev = tag
    end
    return output
end

PerceptronTagger.train = function(self, sentences, nr_iter)
    self._sentences = {}
    self:_make_tagdict(sentences)
    self.model.classes = self.classes
    for iter_=1, nr_iter do
        local c = 0
        local n = 0
        for _, sentence in ipairs(self._sentences) do
            -- Structure of `sentence` would be something like
            -- For two sentences:
            -- 1. Armadillo shells are bulletproof
            -- 2. Bananas grow upside-down
            -- {{{"Armadillo", "shells", "are", "bulletproof"},{"NNP", "NNS", "VBP", "JJ"}}, {{"Bananas", "grow", "upside-down"}, {"NNP", "VBD", "JJ"}}}
            local words, tags = {}, {}
            for i=1, #sentence do
                -- print(inspect(sentence))
                -- training set - quick fix - for nil indexes
                if sentence[i] == nil then
                    -- print(inspect(sentence), i)
                else
                    table.insert(words, sentence[i][1])
                    table.insert(tags, sentence[i][2])
                end
            end
            local prev, prev2 = self.START[1], self.START[2]
            local context = self:make_context(words)
            for i, word in ipairs(words) do
                -- print("CHECKING WORD " .. i, word)
                local guess = self.tagdict[word]
                if not guess then
                    local feats = self:_get_features(i, word, context, prev, prev2)
                    guess, _ = self.model:predict(feats, false)
                    -- print(tags[i], guess)
                    self.model:update(tags[i], guess, feats)
                end
                prev2 = prev
                prev = guess
                if guess == tags[i] then
                    c = c + 1
                end
                n = n + 1
            end
        end
        self._sentences = random_shuffle_sentences(self._sentences)
        print(string.format("Iter %f: %f/%f=%f", iter_, c, n, _pc(c,n)))
    end
    self._sentences = nil
    self.model:average_weights()
end

PerceptronTagger.normalize = function(self, word)
    if string.find(word, "-") ~= nil and string.sub(word, 1, 1) ~= "-" then
        return "!HYPHEN"
    end
    if string.find(word, "^%d+$") ~= nil and string.len(word) == 4 then
        return "!YEAR"
    end
    if word ~= nil and string.find(string.sub(word, 1, 1), "^%d+$") ~= nil then
        return "!DIGITS"
    end
    return string.lower(word)
end

PerceptronTagger._get_features = function(self, i, word, context, prev, prev2)
    local features = {}
    local no_str = ""
    -- print(i, word, prev, prev2)
    local function add(name, arg1, arg2)
        local index = name
        if arg1 ~= no_str then
            index = index .. " " .. arg1
        end
        if arg2 ~= no_str then
            index = index .. " " .. arg2
        end

        if features[index] ~= nil then
            features[index] = features[index] + 1
        else
            features[index] = 1
        end
    end

    local _i = i + #self.START
    -- print(inspect(context))
    add("bias", no_str, no_str)
    add("i suffix", string.sub(word, -3), no_str)
    if word then 
        add("i pref1", string.sub(word, 1, 1), no_str)
    else
        add("i pref1", no_str, no_str)
    end
    add("i-1 tag", prev, no_str)
    add("i-2 tag", prev2, no_str)
    add("i tag+i-2 tag", prev, prev2)
    add("i word", context[_i], no_str)
    add("i-1 tag+i word", prev, context[_i])
    add("i-1 word", context[_i - 1], no_str)
    add("i-1 suffix", string.sub(context[_i - 1], -3), no_str)
    add("i-2 word", context[_i - 2], no_str)
    add("i+1 word", context[_i + 1], no_str)
    add("i+1 suffix", string.sub(context[_i + 1], -3), no_str)
    add("i+2 word", context[_i + 2], no_str)
    return features
end

PerceptronTagger._make_tagdict = function(self, sentences)
    local counts = {}
    for _, sentence in ipairs(sentences) do
        table.insert(self._sentences, sentence)
        for _, word_n_tag in ipairs(sentence) do
            local word, tag = word_n_tag[1], word_n_tag[2]
            if counts[word] == nil then
                counts[word] = {}
            end
            if counts[word][tag] == nil then
                counts[word][tag] = 1
            else
                counts[word][tag] = counts[word][tag] + 1
            end

            if self.classes[tag] == nil then
                self.classes[tag] = tag
            end
        end
    end

    -- print(inspect(counts))
    local freq_thresh = 20
    local ambiguity_thresh = 0.97
    for word, tag_freqs in pairs(counts) do
        local tag, mode = nil, 0
        local n = 0
        for t, m in pairs(tag_freqs) do
            -- print(t, m)
            n = n + m
            if m > mode then
                tag = t
                mode = m
            end
        end

        if n >= freq_thresh and (mode/n) >= ambiguity_thresh then
            self.tagdict[word] = tag
        end
    end
end

return PerceptronTagger