-- package.path = package.path .. ";./external/?.lua"
-- package.path = package.path .. ";../external/?.lua"
-- inspect = require("inspect")

local rex = require "rex_pcre"

--[[
    Penn Treebank Tokenizer (word tokenizer)
    This module is a Lua port of Penn Treebank Tokenizer as seen in NLTK
    To the best of my knowledge, Penn Treebank's source is provided by NLTK
    under the terms of Apache License 2.0.

    The exact sentence in the header file of the ported file (treebank.py) is - 
    >> For license information, see LICENSE.TXT
    Which as of commit 22d8f42e71e90fb74fa1eacfa6b2b7d86af52e93 is Apache License 2.0.
    NLTK version's authors: Edward Loper and Michael Heilman

    The Treebank tokenizer uses regular expressions to tokenize text as in Penn Treebank.
    This implementation is a port of the tokenizer sed script written by Robert McIntyre
    and available at http://www.cis.upenn.edu/~treebank/tokenizer.sed.

    NOTE: The Tokenize.regex_tokenize in tokenization.lua is an experimental implementation
    of word tokenize. For more stability, it is recommended to use this implementation.
--]]

local TreebankWordTokenizer = {}
-- Starting quotes
TreebankWordTokenizer.STARTING_QUOTES = {
    {"^\"", "``"},
    {"(``)", " %1 "},
    {"([ \\(\\[{<])(\"|\'{2})", "%1 `` "}
}

-- Punctuations
-- If NO SENTENCE-BASED TOKENIZATION is done before the 5th step (%1 %2%3 one), 
-- word tokenization will fail miserably
-- 5th step handles the final period
-- Replaced the \g<0> in NLTK's source with %1
TreebankWordTokenizer.PUNCTUATION = {
    {"([:,])([^\\d])", " %1 %2"},
    {"([:,])$", " %1 "},
    {"\\.\\.\\.", " ... "},
    {"[;@#$%&]", " %1 "},
    {"([^\\.])(\\.)([\\]\\)}>\"']*)\\s*$", "%1 %2%3"}, 
    {"[?!]", " %1 "},
    {"([^'])' ", "%1 ' "}
}

-- Pads parentheses
TreebankWordTokenizer.PARENS_BRACKETS = {
    {"[\\]\\[\\(\\)\\{\\}\\<\\>]", " %1 "}
}

-- Optionally: Convert parentheses, brackets and converts them to PTB symbols.
TreebankWordTokenizer.CONVERT_PARENTHESES = {
    {"\\(", "-LRB-"},
    {"\\)", "-RRB-"},
    {"\\[", "-LSB-"},
    {"\\]", "-RSB-"},
    {"\\{", "-LCB-"},
    {"\\}", "-RCB-"}
}

TreebankWordTokenizer.DOUBLE_DASHES = {
    {"--", " -- "}
}

TreebankWordTokenizer.ENDING_QUOTES = {
    {'"', " '' "},
    {"(\\S)(\'\')", "%1 %2 "},
    {"([^' ])('[sS]|'[mM]|'[dD]|') ", "%1 %2 "},
    {"([^' ])('ll|'LL|'re|'RE|'ve|'VE|n't|N'T) ", "%1 %2 "}
}

local MacIntyreContractions = {}

-- As contractions in NLTK use re.IGNORECASE flag
-- To substitute the effect, below code is in caps and without it
MacIntyreContractions.CONTRACTIONS2 = {
    {"(?i)\\b(can)(?#X)(not)\\b", " %1 %2 "},
    {"(?i)\\b(CAN)(?#X)(NOT)\\b", " %1 %2 "},
    {"(?i)\\b(d)(?#X)('ye)\\b", " %1 %2 "},
    {"(?i)\\b(D)(?#X)('YE)\\b", " %1 %2 "},
    {"(?i)\\b(gim)(?#X)(me)\\b", " %1 %2 "},
    {"(?i)\\b(GIM)(?#X)(ME)\\b", " %1 %2 "},
    {"(?i)\\b(gon)(?#X)(na)\\b", " %1 %2 "},
    {"(?i)\\b(GON)(?#X)(NA)\\b", " %1 %2 "},
    {"(?i)\\b(got)(?#X)(ta)\\b", " %1 %2 "},
    {"(?i)\\b(GOT)(?#X)(TA)\\b", " %1 %2 "},
    {"(?i)\\b(lem)(?#X)(me)\\b", " %1 %2 "},
    {"(?i)\\b(LEM)(?#X)(ME)\\b", " %1 %2 "},
    {"(?i)\\b(more)(?#X)('n)\\b", " %1 %2 "},
    {"(?i)\\b(MORE)(?#X)('N)\\b", " %1 %2 "},
    {"(?i)\\b(wan)(?#X)(na)\\s", " %1 %2 "},
    {"(?i)\\b(WAN)(?#X)(NA)\\s", " %1 %2 "}
}

MacIntyreContractions.CONTRACTIONS3 = {
    {"(?i) ('t)(?#X)(is)\\b", " %1 %2 "},
    {"(?i) ('T)(?#X)(IS)\\b", " %1 %2 "},
    {"(?i) ('t)(?#X)(was)\\b", " %1 %2 "},
    {"(?i) ('T)(?#X)(WAS)\\b", " %1 %2 "}
}

TreebankWordTokenizer.tokenize = function(self, text, convert_parentheses, return_str)
    for _, reg_sub in ipairs(self.STARTING_QUOTES) do
        local regexp, substitution = reg_sub[1], reg_sub[2]
        text = rex.gsub(text, regexp, substitution)
    end
    
    for _, reg_sub in ipairs(self.PUNCTUATION) do
        local regexp, substitution = reg_sub[1], reg_sub[2]
        text = rex.gsub(text, regexp, substitution)
    end
    
    -- Handles parantheses
    local regexp_paran, substitution_paran = self.PARENS_BRACKETS[1][1], self.PARENS_BRACKETS[1][2]
    text = rex.gsub(text, regexp_paran, substitution_paran)
    
    -- Optionally convert parentheses
    if convert_parentheses == true then
        for _, reg_sub in ipairs(self.CONVERT_PARENTHESES) do
            local regexp, substitution = reg_sub[1], reg_sub[2]
            text = rex.gsub(text, regexp, substitution)
        end    
    end
    
    -- Handles double dash
    local regexp_dd, substitution_dd = self.DOUBLE_DASHES[1][1], self.DOUBLE_DASHES[1][2]
    text = rex.gsub(text, regexp_dd, substitution_dd)

    -- add extra space to make things easier
    text = " " .. text .. " "

    for _, reg_sub in ipairs(self.ENDING_QUOTES) do
        local regexp, substitution = reg_sub[1], reg_sub[2]
        text = rex.gsub(text, regexp, substitution)
    end

    for _, reg_sub in ipairs(MacIntyreContractions.CONTRACTIONS2) do
        local regexp, substitution = reg_sub[1], reg_sub[2]
        text = rex.gsub(text, regexp, substitution)
    end

    for _, reg_sub in ipairs(MacIntyreContractions.CONTRACTIONS3) do
        local regexp, substitution = reg_sub[1], reg_sub[2]
        text = rex.gsub(text, regexp, substitution)
    end

    -- We are not using CONTRACTIONS4 since
    -- they are also commented out in the SED scripts
    if return_str == true then
        return text
    else
        local tokens = {}
        for token in rex.split(text, " ") do
            if token ~= "" then
                table.insert(tokens, token)
            end
        end
        return tokens
    end
end

return TreebankWordTokenizer