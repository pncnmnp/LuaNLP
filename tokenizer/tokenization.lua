local rex = require "rex_pcre"

--[[ NOTE: Simple tokenization techniques as devised below have many caveats
    See IR-Book for further details: 
    https://nlp.stanford.edu/IR-book/html/htmledition/tokenization-1.html
--]]

local Tokenize = {}

-- Lots of repetition for this function!
-- CENTRALIZE THIS!
local function escape_pattern(text)
    -- Escaping strings for gsub
    -- https://stackoverflow.com/a/34953646/7543474
    return text:gsub("([^%w])", "%%%1")
end

function Tokenize.generate_n_gram(input, n)
    -- To generate n-grams
    local white_space_tokens = Tokenize.whitespace_tokenize(input)
    local tokens = {}
    for token in white_space_tokens do
        table.insert(tokens, token)
    end

    if n < 1 then
        return {}
    end

    local n_grams = {}
    -- If the n-grams value is greater than no of tokens found
    if #tokens < n then
        return {tokens}
    end

    for i=1, #tokens-n+1 do
        local gram = {}
        table.move(tokens, i, i+n-1, 1, gram)
        table.insert(n_grams, gram)
    end
    return n_grams
end

function Tokenize.remove_punctuations(input)
    -- Replaces all punctuations in the text with ""
    -- Punctuations (from Python's string.punctuation)
    local puncts = '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'
    local escape_puncts = escape_pattern(puncts)
    local without_puncs = string.gsub(input, string.format("[%s]+", escape_puncts), "")
    return without_puncs
end

function Tokenize.regex_tokenize(input)
    --[[ Algorithm ported from Jurafsky and Martin
    Edition 3, Chapter 2, Page 16 - Figure 2.12

    TODO: * date of birth - 07/09/09, 12th, 1st, 2nd (one capture)
    * Numerical equations like 2+3/3
    * Abbreviations like Dr. Mr. [done]
    * .007, 099 (one capture) and IPs like 8.8.8.8 [done]

    Breakdown:
    >> (?:[a-zA-Z]\\.){2,} - matches acronyms (https://stackoverflow.com/questions/35076016/regex-to-match-acronyms)
    >> (?:'[sS]|'[mM]|'[dD]|') |(?:'ll|'LL|'re|'RE|'ve|'VE|n't|N'T)  - matches contractions
    >> (?:(?!n't|N'T)[a-zA-Z])+(?!'t)+(?:[-.][a-zA-Z]+)* - matches all words which also contains hyphenated words like Wall-E and email-ids like abc@gmail.com -> 'abc', '@', and 'gmail.com' (https://stackoverflow.com/questions/49679128/modify-regex-to-include-hyphenated-words)
    >> \\$?\\d+(?:\\.\\d+)?%? - matches various numbers like currencies ($30.50), percentages (99%)
    >> \\.\\.\\. - matches ellipsis
    >> [{}.,;\'\"?():-_`!+-/|\\*] - matches various symbols
    Does not support all unicode characters
    --]]
    local titles = "Dr\\.|Esq\\.|Hon\\.|Jr\\.|Mr\\.|Mrs\\.|Ms\\.|Messrs\\.|Mmes\\.|Msgr\\.|Prof\\.|Rev\\.|Rt\\. Hon\\.|Sr\\.|St\\.|Mt\\.|Gen\\.|Capt\\.|Col\\.|Lt\\.|Sgt\\.|Mst\\.|Maj\\.|Brig\\.|Cmnd\\.|Sen\\.|Rep\\.|Revd\\.|Assn\\."
    local extract = string.format("(?:[a-zA-Z]\\.){2,}|(?:'[sS]|'[mM]|'[dD]|') |(?:%s)|(?:'ll|'LL|'re|'RE|'ve|'VE|n't|N'T) |(?:(?!n't|N'T)[a-zA-Z])+(?:[-.][a-zA-Z]+)*|[\\$\\.]?\\d+(?:\\.\\d+)*%%?|\\.\\.\\.|[{}.,;\'\"?():-_`!+\\-\\/|\\*#%%]", titles)
    local tokens = rex.gmatch(input, extract)
    return tokens
end

function Tokenize.emoji_tokenize(input)
    -- Finds all the text-based emojis (non-unicode) from the input text
    -- From https://stackoverflow.com/a/28077780
    local tokens = rex.gmatch(input, "(\\:\\w+\\:|\\<[\\/\\]?3|[\\(\\)\\\\D|\\*\\$][\\-\\^]?[\\:\\;\\=]|[\\:\\;\\=B8][\\-\\^]?[3DOPp\\@\\$\\*\\\\)\\(\\/\\|])(?=\\s|[\\!\\.\\?]|$)")
    return tokens
end

function Tokenize.whitespace_tokenize(input)
    -- Tokenizes on whitespaces
    local tokens = rex.gmatch(input, "\\S+")
    return tokens
end

function Tokenize.character_tokenize(input)
    -- Tokenizes on characters
    local tokens = rex.gmatch(input, ".")
    return tokens
end

function Tokenize.sentence_tokenize(input)
    --[[ Tokenizes sentences by detecting sentence boundaries using orthographic information as primary evidence

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
    >> (\\s+|\r\n) - to match whitespace characters or carriage return and newline feed
    >> (?=\"?[A-Z]) - positive lookahead for a capital letter which is optionally preceded by " (quote)
    >> (?=[0-9]\\.\\)) - positive lookahead used for lists like 3.) and 1.)
    >> (?=[0-9]\\.) - positive lookahead used for lists like 3. and 1. (controversial - will split decimals!)
    >> (?=[0-9]\\)) - positive lookahead used for lists like 3) and 1)
    --]]
    local titles = "Dr\\.|Esq\\.|Hon\\.|Jr\\.|Mr\\.|Mrs\\.|Ms\\.|Messrs\\.|Mmes\\.|Msgr\\.|Prof\\.|Rev\\.|Rt\\. Hon\\.|Sr\\.|St\\.|Mt\\.|Gen\\.|Capt\\.|Col\\.|Lt\\.|Sgt\\.|Mst\\.|Maj\\.|Brig\\.|Cmnd\\.|Sen\\.|Rep\\.|Revd\\.|Assn\\."
    local tokens = rex.split(input, string.format("((?<=[a-z0-9\\)][.?!])|(?<=[a-z0-9][.?!]\")|(?<=[?!][?!])|(?<=\\.\\.)|(?<=\\. \\.))(?<!%s)(\\s+|\r\n)(?=\"?[A-Z])|(\\s+|\r\n)(?=[0-9]\\.\\))|(\\s+|\r\n)(?=[0-9]\\.[^0-9])|(\\s+|\r\n)(?=[0-9]\\))", titles))
    return tokens
end

local function test()
    local str1 = "what're who doesn't like to play football. you've been x punk'd hahaha coud've would've should've raj! you'll what're be late again? ridiculous! don't they'll what're you doing here we're "
    local str2 = "That U.S.A. poster-print costs $12.40 ... or 82% or 99.99% or even 12.40 even Wall-E would love it especially after A.B.C. purchased the product but who doesn't love wall-e! We all love him! Somebody knocked on the door. It must be Mr. White. He is the one who knocks (Breaking Bad reference). He [2019]{cheese} Agai\"\n 3+4/2-5*2 /|\\ or 3 % or M#Ash 22/10/10 is my birthday. 3+2+1 is the equation we are looking for! abc@gmail.com is my email id"
    local str3 = "Sentence boundary disambiguation (SBD), also known as sentence breaking, sentence boundary detection, and sentence segmentation, is the problem in natural language processing of deciding where sentences begin and end. Natural language processing tools often require their input to be divided into sentences; however, sentence boundary identification can be challenging due to the potential ambiguity of punctuation marks. In written English, a period may indicate the end of a sentence, or may denote an abbreviation, a decimal point, an ellipsis, or an email address, among other possibilities. About 47% of the periods in the Wall Street Journal corpus denote abbreviations.[1] Question marks and exclamation marks can be similarly ambiguous due to use in emoticons, computer code, and slang. St. Michael's Church is on 5th st. near the light. I can see Mt. Fuji from here. That is JFK Jr.'s book."

    -- From https://github.com/fnl/syntok/blob/master/syntok/segmenter_test.py
    local str4 = "One sentence per line. And another sentence on the same line. (How about a sentence in parenthesis?) Or a sentence with \"a quote!\" 'How about those pesky single quotes?' [And not to forget about square brackets.] And, brackets before the terminal [2]. You know Mr. Abbreviation I told you so. What about the med. staff here? But the undef. abbreviation not. And this f.e. is tricky stuff. I.e. a little easier here. However, e.g., should be really easy. Three is one btw., is clear. Their presence was detected by transformation into S. lividans. Three subjects diagnosed as having something. What the heck??!?! (A) First things here. (1) No, they go here. [z] Last, but not least. (vii) And the Romans, too. Let's meet at 14.10 in N.Y.. This happened in the U.S. last week. Brexit: The E.U. and the U.K. are separating. Refugees are welcome in the E.U.. But they are thrown out of the U.K.. And they never get to the U.S.. The U.S. Air Force was called in. What about the E.U. High Court? And then there is the U.K. House of Commons. Now only this splits: the EU. A sentence ending in U.S. Another that will not split. 12 monkeys ran into here. Nested (Parenthesis. (With words inside! (Right.)) (More stuff. Uff, this is it!)) In the Big City. How we got an A. Mathematics . dot times. An abbreviation at the end.. This is a sentence terminal ellipsis... This is another sentence terminal ellipsis.... An easy to handle G. species mention. Am 13. Jän. 2006 war es regnerisch. The basis for Lester B. Pearson's policy was later. This model was introduced by Dr. Edgar F. Codd after initial criticisms. This quote \"He said it.\" is actually inside. B. Obama fas the first black US president. A. The first assumption. B. The second bullet. C. The last case. 1. This is one. 2. And that is two. 3. Finally, three, too. A 130 nm CMOS power amplifier (PA) operating at 2.4 GHz. Its power stage is composed of a set of amplifying cells. Specimens (n = 32) were sent for 16S rRNA PCR. 16S rRNA PCR could identify an organism in 10 of 32 cases (31.2%). Cannabis sativa subsp. sativa at Noida was also confirmed. Eight severely CILY-affected villages of Grand-Lahou in 2015. Leaves, inflorescences and trunk borings were collected. Disturbed the proper intracellular localization of TPRBK. Moreover, the knockdown of TPRBK expression. Elevated expression of LC3. Importantly, immunohistochemistry analysis revealed it. Bacterium produced 45U/mL -mannanase at 50 degrees C. The culture conditions for high-level production. Integration (e.g., on-chip etc.), can translate to lower cost. The invasive capacity of S. Typhi is high. Most pRNAs have a length of 8-15 nt, very few up to 24 nt. The average length of pRNAs tended to increase from stationary to outgrowth conditions. Results: In AAA, significantly enhanced mRNA expression was observed (p <= .001). MMPs with macrophages (p = .007, p = .018, and p = .015, resp.). And synth. muscle cells with MMPs (p = .020, p = .018, and p = .027, respectively). (C) 2017 Company Ltd. All rights reserved. (C) 2017 Company B.V. All rights reserved. Northern blotting and RT-PCR. C2m9 and C2m45 carried missense mutations. The amplifier consumes total DC power of 167 uW. The input-referred noise is 110 nV/sqrt(Hz). Inflammation via activation of TLR4. We also identify a role for TLR4. Effects larger (eta(2) = .53), with cognition (eta(2) = .14) and neurocognition (eta(2) = .16). All validations show a good approximation of the behavior of the DMFC. In addition, a simulated application of a circuit system is explained. Conclusions: Our data suggest CK5/6, CK7, and CK18 in the subclassification of NSCLC. Copyright (C) 2018 S. Korgur AG, Basel. Gelatin degradation by MMP-9. ConclusionThis study provides clear evidence. A sampling frequency of 780 MHz. The figure-of-merit of the modulator is there. Patients with prodromal DLB. In line with the literature on DLB. This is verse 14;45 in the test; Splitting on semi-colons. The discovery of low-mass nulceli (AGN; NGC 4395 and POX 52; Filippenko & Sargent 1989; Kunth et al. 1987) triggered a quest; it has yielded today more than 500 sources. Always last, clear closing example."

    local str5="These are the list items- 1) Hello world 2. bye bye"
    local val = "<START>"
    local patt = sentence_tokenize(str6)
    while val ~= nil do
        io.write(val .. "|")
        val = patt()
    end
    print("<END>")
end

-- test()

return Tokenize