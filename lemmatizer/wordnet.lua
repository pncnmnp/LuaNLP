-- package.path = package.path .. ";../external/?.lua"
-- inspect = require("inspect")

--[[
    The Wordnet Lemmatization Algorithm
    This algorithm has been ported from NLTK's nltk.stem.WordNetLemmatizer()
    [1] Source: https://www.nltk.org/_modules/nltk/stem/wordnet.html
    [2] Source: https://www.nltk.org/_modules/nltk/corpus/reader/wordnet.html

    NOTE:
    After obtaining a list of potential lemmas using nltk.corpus.wordnet._morphy(word, pos),
    the following codeblock is executed by NLTK:

    >> lemmas = wordnet._morphy(word, pos)
    >> return min(lemmas, key=len) if lemmas else word

    Therefore, for words such as "saw" and pos of "v", the lemmas obtained are - ["saw", "see"].
    Based on the above code, it returns "saw" as the lemma as words are of same length. 
    However, the question of which is right is subjective.

    To prevent confusion, wordnet._morphy provides all the possible lemmas. NLTK like functionality can be performed as follows:

    >> wn = require("wordnet")
    >> lemmas = wn:_morphy(word, pos, check_exceptions)
    >> if #lemmas ~= 0 then 
    >>     table.sort(lemmas)
    >>     return table[1]
    >> else
    >>     return word
    >> end
]]--

local wordnet = {}

wordnet["WORDNET_BASE_DIR"] = "./wordnet"

wordnet["ADJ"] = "a"
wordnet["ADJ_SAT"] = "s"
wordnet["ADV"] = "r"
wordnet["NOUN"] = "n"
wordnet["VERB"] = "v"

wordnet["MORPHOLOGICAL_SUBSTITUTIONS"] = {
    [wordnet["NOUN"]] = {
        {"s", ""},
        {"ses", "s"},
        {"ves", "f"},
        {"xes", "x"},
        {"zes", "z"},
        {"ches", "ch"},
        {"shes", "sh"},
        {"men", "man"},
        {"ies", "y"}
    },
    [wordnet["VERB"]] = {
        {"s", ""},
        {"ies", "y"},
        {"es", "e"},
        {"es", ""},
        {"ed", "e"},
        {"ed", ""},
        {"ing", "e"},
        {"ing", ""}
    },
    [wordnet["ADJ"]] = {
        {"er", ""}, 
        {"est", ""}, 
        {"er", "e"}, 
        {"est", "e"}
    },
    [wordnet["ADV"]] = {}
}

wordnet["MORPHOLOGICAL_SUBSTITUTIONS"][wordnet["ADJ_SAT"]] = wordnet["MORPHOLOGICAL_SUBSTITUTIONS"][wordnet["ADJ"]]

wordnet["_FILEMAP"] = {
    [wordnet["ADJ"]] = "adj", 
    [wordnet["ADV"]] = "adv", 
    [wordnet["NOUN"]] = "noun", 
    [wordnet["VERB"]] = "verb"
}

wordnet._exception_map = {}

--  A index that provides the file offset
--  Map from lemma -> pos -> synset_index -> offset
wordnet._lemma_pos_offset_map = {}

wordnet._load_exception_map = function(self)
    for pos, suffix in pairs(self._FILEMAP) do
        self._exception_map[pos] = {}
        local file = io.open(self.WORDNET_BASE_DIR .. "/" .. suffix .. ".exc", 'r')
        io.input(file)
        for line in io.lines() do
            local terms = {}
            local no_first_flag = false
            local first_term = ""
            for term in string.gmatch(line, "([^ ]+)") do
                if no_first_flag == true then
                    table.insert(terms, term)
                elseif no_first_flag == false then
                    no_first_flag = true
                    first_term = term
                end
            end
            -- self._exception_map[pos][term[1]] = table.move(terms, 2, #terms, 1, {})
            self._exception_map[pos][first_term] = terms
        end
    end
    self._exception_map[self.ADJ_SAT] = self._exception_map[self.ADJ]
end

--  load the exception file data into memory
wordnet:_load_exception_map()

wordnet._load_lemma_pos_offset_map = function(self)
    for _, suffix in pairs(self._FILEMAP) do
        local file = io.open(self.WORDNET_BASE_DIR .. "/index." .. suffix, 'r')
        io.input(file)
        for line in io.lines() do
            if not (string.sub(line, 1, 1) == " ") then
                local _iter = string.gmatch(line, "([^ ]+)")
                local function _next_token()
                    return _iter()
                end

                -- For lemma and part-of-speech
                local lemma = _next_token()
                local pos = _next_token()

                -- number of synsets for this lemma
                local n_synsets = tonumber(_next_token())
                assert(n_synsets > 0, "Number of synsets for the lemma is not greater than zero")

                -- ignoring the pointer symbols for all synsets of this lemma
                local n_pointers = tonumber(_next_token())
                for i=1,n_pointers do
                    _next_token()
                end

                -- Same as number of synsets
                local n_senses = tonumber(_next_token())
                assert(n_synsets == n_senses, "Number of synsets and senses are not equal")

                -- ignoring the number of senses ranked according to frequency
                _next_token()

                -- For synset offsets
                local synset_offsets = {}
                for i=1,n_synsets do
                    table.insert(synset_offsets, tonumber(_next_token()))
                end

                if self._lemma_pos_offset_map[lemma] == nil then
                    self._lemma_pos_offset_map[lemma] = {}
                end

                self._lemma_pos_offset_map[lemma][pos] = synset_offsets
                if pos == self.ADJ then
                    self._lemma_pos_offset_map[lemma][self.ADJ_SAT] = synset_offsets
                end
            end
        end
    end
end

--  Load the indices for lemmas and synset offsets
wordnet:_load_lemma_pos_offset_map()

wordnet._morphy = function(self, form, pos, check_exceptions)
    local exceptions = self._exception_map[pos]
    local substitutions = self.MORPHOLOGICAL_SUBSTITUTIONS[pos]

    local function apply_rules(forms)
        local modified_forms = {}
        for _, _form in pairs(forms) do
            for key, value in pairs(substitutions) do
                local old = value[1]
                local new = value[2]
                if string.sub(form, #_form-#old+1) == old then
                    table.insert(modified_forms, (string.sub(_form, 1, #_form-#old) .. new))
                end
            end
        end
        return modified_forms
    end

    local function filter_forms(forms)
        local result = {}
        local seen = {}
        for _, _form in pairs(forms) do
            if self._lemma_pos_offset_map[_form] ~= nil then
                if self._lemma_pos_offset_map[_form][pos] ~= nil then
                    if seen[_form] == nil then
                        seen[_form] = _form
                        table.insert(result, _form)
                    end
                end
            end
        end
        return result
    end

    -- 0. Check the exception lists
    if check_exceptions == true then
        local modified_forms = {form}
        if exceptions[form] ~= nil then
            for k, v in pairs(exceptions[form]) do
                table.insert(modified_forms, v)
            end
            return filter_forms(modified_forms)
        end
    end

    -- 1. Apply rules once to the input to get y1, y2, y3, etc.
    local forms = apply_rules({form})
    -- print("1" .. inspect(forms))

    -- 2. Return all that are in the database (and check the original too)
    local results = {form}
    for k,v in pairs(forms) do
        table.insert(results, v)
    end
    -- print("1.5" .. inspect(results))
    results = filter_forms(results)
    -- print("2" .. inspect(results))
    if #results ~= 0 then
        return results
    end

    -- 3. If there are no matches, keep applying rules until we find a match
    while #forms ~= 0 do
        forms = apply_rules(forms)
        results = filter_forms(results)
        -- print("3" .. inspect(results))
        if #results ~= 0 then
            return results
        end
    end

    return {}    
end

return wordnet