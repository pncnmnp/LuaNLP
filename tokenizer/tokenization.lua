local rex = require "rex_pcre"

-- NOTE: Simple tokenization techniques as devised below have many caveats
-- See IR-Book for further details: 
-- https://nlp.stanford.edu/IR-book/html/htmledition/tokenization-1.html

function regex_tokenize(input)
    -- Algorithm ported from Jurafsky and Martin
    -- Edition 3, Chapter 2, Page 16 - Figure 2.12
    -- Breakdown:
    -- (?:[a-zA-Z]\\.){2,} - matches acronyms (https://stackoverflow.com/questions/35076016/regex-to-match-acronyms)
    -- (?:'[sS]|'[mM]|'[dD]|') |(?:'ll|'LL|'re|'RE|'ve|'VE|n't|N'T)  - matches contractions
    -- [a-zA-Z]+(?!'t)+(?:[-.]?[a-zA-Z]+)* - matches words which also contains hyphenated words like Wall-E and email-ids like abc@gmail.com -> 'abc', '@', and 'gmail.com' (https://stackoverflow.com/questions/49679128/modify-regex-to-include-hyphenated-words)
    -- \\$?\\d+(?:\\.\\d+)?%? - matches various numbers like currencies ($30.50), percentages (99%)
    -- \\.\\.\\. - matches ellipsis
    -- [{}.,;\'\"?():-_`!+-/|\\*] - matches various symbols
    -- Does not support all unicode characters
    local tokens = rex.gmatch(input, "(?:[a-zA-Z]\\.){2,}|(?:'[sS]|'[mM]|'[dD]|') |(?:'ll|'LL|'re|'RE|'ve|'VE|n't|N'T) |[a-zA-Z]+(?!'t)+(?:[-.]?[a-zA-Z]+)*|\\$?\\d+(?:\\.\\d+)?%?|\\.\\.\\.|[{}.,;\'\"?():-_`!+-/|\\*#%]")
    return tokens
end

function whitespace_tokenize(input)
    -- Tokenizes on whitespaces
    local tokens = rex.gmatch(input, "\\S+")
    return tokens
end

function character_tokenize(input)
    -- Tokenizes on characters
    local tokens = rex.gmatch(input, ".")
    return tokens
end

function test1()
    str1 = "what're who doesn't like to play football. you've been x punk'd hahaha coud've would've should've raj! you'll what're be late again? ridiculous! don't they'll what're you doing here we're "
    str2 = "That U.S.A. poster-print costs $12.40 ... or 82% or 99.99% or even 12.40 even Wall-E would love it especially after A.B.C. purchased the product but who doesn't love wall-e! We all love him! Somebody knocked on the door. It must be Mr. White. He is the one who knocks (Breaking Bad reference). [2019]{cheese} Agai\"\n 3+4/2-5*2 /|\\ or 3 % or M#Ash 22/10/10 is my birthday. 3+2+1 is the equation we are looking for! abc@gmail.com is my email id"
    val = "<START>"
    patt = regex_tokenize(str2)
    while val ~= nil do
        io.write(val .. "| ")
        val = patt()
    end
    print()
end

test1()