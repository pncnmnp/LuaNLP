local rex = require "rex_pcre"

function regex_tokenize(input)
    -- Algorithm ported from Jurafsky and Martin
    -- Edition 3, Chapter 2, Page 16 - Figure 2.12
    -- Breakdown:
    -- (?:[a-zA-Z]\\.){2,} - matches acronyms (https://stackoverflow.com/questions/35076016/regex-to-match-acronyms)
    -- [a-zA-Z]+(?:-[a-zA-Z]+)* - matches hyphenated words like Wall-E (https://stackoverflow.com/questions/49679128/modify-regex-to-include-hyphenated-words)
    -- \\$?\\d+(?:\\.\\d+)?%? - matches various numbers like currencies ($30.50), percentages (99%)
    -- \\.\\.\\. - matches ellipsis
    -- [{}.,;\'\"?():-_`!] - matches various symbols
    local tokens = rex.gmatch(input, "(?:[a-zA-Z]\\.){2,}|[a-zA-Z]+(?:-[a-zA-Z]+)*|\\$?\\d+(?:\\.\\d+)?%?|\\.\\.\\.|[{}.,;\'\"?():-_`!]")
    return tokens
end

str = "That U.S.A. poster-print costs $12.40 ... or 82% or 99.99% or even 12.40 even Wall-E would love it especially after A.B.C. purchased the product but who doesn't love wall-e! We all love him! Somebody knocked on the door. It must be Mr. White. He is the one who knocks (Breaking Bad reference). [2019]{cheese} Agai\"n"
val = 0
patt = regex_tokenize(str)
while val ~= nil do
    val = patt()
    print(val)
end