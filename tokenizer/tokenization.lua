local rex = require "rex_pcre"

--[[ NOTE: Simple tokenization techniques as devised below have many caveats
    See IR-Book for further details: 
    https://nlp.stanford.edu/IR-book/html/htmledition/tokenization-1.html
--]]

function regex_tokenize(input)
    --[[ Algorithm ported from Jurafsky and Martin
    Edition 3, Chapter 2, Page 16 - Figure 2.12

    Breakdown:
    >> (?:[a-zA-Z]\\.){2,} - matches acronyms (https://stackoverflow.com/questions/35076016/regex-to-match-acronyms)
    >> (?:'[sS]|'[mM]|'[dD]|') |(?:'ll|'LL|'re|'RE|'ve|'VE|n't|N'T)  - matches contractions
    >> [a-zA-Z]+(?!'t)+(?:[-.]?[a-zA-Z]+)* - matches words which also contains hyphenated words like Wall-E and email-ids like abc@gmail.com -> 'abc', '@', and 'gmail.com' (https://stackoverflow.com/questions/49679128/modify-regex-to-include-hyphenated-words)
    >> \\$?\\d+(?:\\.\\d+)?%? - matches various numbers like currencies ($30.50), percentages (99%)
    >> \\.\\.\\. - matches ellipsis
    >> [{}.,;\'\"?():-_`!+-/|\\*] - matches various symbols
    Does not support all unicode characters
    --]]
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

function sentence_tokenize(input)
    --[[ Tokenizes sentences by detecting sentence boundaries
    For detecting edge cases, the regular expression pattern was tested on https://github.com/diasks2/pragmatic_segmenter#the-golden-rules
    Out of the 52 english tests, it generates wrong output for - 14, 15, 18, 35, 36, 37, 38, 42, 45, 50, 51
    
    This function has difficulty separating the following scenarios - 
    * Multi-period abbreviations at the end of a sentence
    * Prepositive abbreviations like Dr. Doom or Mr. Penguin (partly solved - see local variable "titles")
    * Lists like - 
      ** a. Spiderman b. Superman c. Batman d. Mario
      ** 1. Iron Man 2. Captain America 3. Thor
    * I as a sentence boundary and I as an abbreviation
    * No whitespace in between sentences

    Disadvantage: * Lookbehind does not allow non-fixed width

    Breakdown:
    >> (?<=[a-z0-9\\)][.?!]) - positive lookbehind for [a-z ) 0-9] followed by [. ? !]
    >> (?<=[a-z0-9][.?!]\") - same as above but ending with " (double quotes)
    >> (?<=[?!][?!]) - positive lookbehind for ending with ??, !!, ?!, or !?
    >> (?<=\\.\\.) - positive lookbehind for ending with '..' like 'I never meant that....'
    >> (?<=\\. \\.)- positive lookbehind for ending with '. .' like 'I never meant that. . . .'
    >> (?<!%s) - negative lookbehind for terms in the local variable titles
                 done to mitigate issues with terms like Dr. Doom, and Mr. White
    >> (\\s|\r\n) - to match whitespace character or carriage return and newline feed
    >> (?=\"?[A-Z]) - positive lookahead for a capital letter which is optionally preceded by " (quote)
    >> (?=[0-9]\\.\\)) - positive lookahead used for lists like 3.) and 1.)
    >> (?=[0-9]\\.) - positive lookahead used for lists like 3. and 1.
    >> (?=[0-9]\\)) - positive lookahead used for lists like 3) and 1)
    --]]
    local titles = "Dr\\.|Esq\\.|Hon\\.|Jr\\.|Mr\\.|Mrs\\.|Ms\\.|Messrs\\.|Mmes\\.|Msgr\\.|Prof\\.|Rev\\.|Rt\\. Hon\\.|Sr\\.|St\\.|Mt\\.|Gen\\.|Capt\\.|Col\\.|Lt\\.|Sgt\\.|Mst\\."
    local tokens = rex.split(input, string.format("((?<=[a-z0-9\\)][.?!])|(?<=[a-z0-9][.?!]\")|(?<=[?!][?!])|(?<=\\.\\.)|(?<=\\. \\.))(?<!%s)(\\s|\r\n)(?=\"?[A-Z])|(\\s|\r\n)(?=[0-9]\\.\\))|(\\s|\r\n)(?=[0-9]\\.)|(\\s|\r\n)(?=[0-9]\\))", titles))
    return tokens
end

function test()
    str1 = "what're who doesn't like to play football. you've been x punk'd hahaha coud've would've should've raj! you'll what're be late again? ridiculous! don't they'll what're you doing here we're "
    str2 = "That U.S.A. poster-print costs $12.40 ... or 82% or 99.99% or even 12.40 even Wall-E would love it especially after A.B.C. purchased the product but who doesn't love wall-e! We all love him! Somebody knocked on the door. It must be Mr. White. He is the one who knocks (Breaking Bad reference). He [2019]{cheese} Agai\"\n 3+4/2-5*2 /|\\ or 3 % or M#Ash 22/10/10 is my birthday. 3+2+1 is the equation we are looking for! abc@gmail.com is my email id"
    str3 = "Sentence boundary disambiguation (SBD), also known as sentence breaking, sentence boundary detection, and sentence segmentation, is the problem in natural language processing of deciding where sentences begin and end. Natural language processing tools often require their input to be divided into sentences; however, sentence boundary identification can be challenging due to the potential ambiguity of punctuation marks. In written English, a period may indicate the end of a sentence, or may denote an abbreviation, a decimal point, an ellipsis, or an email address, among other possibilities. About 47% of the periods in the Wall Street Journal corpus denote abbreviations.[1] Question marks and exclamation marks can be similarly ambiguous due to use in emoticons, computer code, and slang. St. Michael's Church is on 5th st. near the light. I can see Mt. Fuji from here. That is JFK Jr.'s book."
    val = "<START>"
    patt = sentence_tokenize(str3)
    while val ~= nil do
        io.write(val .. "\n")
        val = patt()
    end
    print("<END>")
end

test()