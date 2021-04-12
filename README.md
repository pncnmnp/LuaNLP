# LuaNLP - Lua's NLP Toolkit

## Dependencies
This library is dependent on PCRE flavour of [`lrexlib`](https://github.com/rrthomas/lrexlib).
To install `lrexlib` -
```bash
luarocks install lrexlib-PCRE
```

## Guide
**This guide will take you around a short tour of LuaNLP**

LuaNLP supports many of the most used NLP tasks such as: 
* Word Tokenization
* Sentence Tokenization
* Stemming
* Lemmatization
* Parts-of-Speech Tagging 
* Sentiment Analysis
* Keyword Extraction
* Text Summarization
* Named-entity Recognition
* Stopwords and N-grams

> As of 12/04/21, Word sense disambiguation is under development.

Let us begin by loading some text -

As we are diving into the branches of Linguistics, I am selecting a relevant featured article 
from Wikipedia - *Rosetta Stone*.

```lua
text = [[The Rosetta Stone is a granodiorite stele inscribed with three versions of a decree 
issued in Memphis, Egypt in 196 BC during the Ptolemaic dynasty on behalf of King Ptolemy V 
Epiphanes. The top and middle texts are in Ancient Egyptian using hieroglyphic and Demotic scripts 
respectively, while the bottom is in Ancient Greek. The decree has only minor differences between 
the three versions, making the Rosetta Stone key to deciphering the Egyptian scripts.

The stone was carved during the Hellenistic period and is believed to have originally been 
displayed within a temple, possibly at nearby Sais. It was probably moved in late antiquity or 
during the Mameluk period, and was eventually used as building material in the construction of Fort 
Julien near the town of Rashid (Rosetta) in the Nile Delta. It was discovered there in July 1799 by 
French officer Pierre-François Bouchard during the Napoleonic campaign in Egypt. It was the first 
Ancient Egyptian bilingual text recovered in modern times, and it aroused widespread public 
interest with its potential to decipher this previously untranslated hieroglyphic script. 
Lithographic copies and plaster casts soon began circulating among European museums and scholars. 
When the British defeated the French they took the stone to London under the Capitulation of 
Alexandria in 1801. It has been on public display at the British Museum almost continuously since 
1802 and is the most visited object there.

Study of the decree was already underway when the first complete translation of the Greek text was 
published in 1803. Jean-François Champollion announced the transliteration of the Egyptian scripts 
in Paris in 1822; it took longer still before scholars were able to read Ancient Egyptian 
inscriptions and literature confidently. Major advances in the decoding were recognition that the 
stone offered three versions of the same text (1799); that the demotic text used phonetic 
characters to spell foreign names (1802); that the hieroglyphic text did so as well, and had 
pervasive similarities to the demotic (1814); and that phonetic characters were also used to spell 
native Egyptian words (1822–1824).

Three other fragmentary copies of the same decree were discovered later, and several similar 
Egyptian bilingual or trilingual inscriptions are now known, including three slightly earlier 
Ptolemaic decrees: the Decree of Alexandria in 243 BC, the Decree of Canopus in 238 BC, and the 
Memphis decree of Ptolemy IV, c. 218 BC. The Rosetta Stone is no longer unique, but it was the 
essential key to the modern understanding of ancient Egyptian literature and civilisation. The term 
'Rosetta Stone' is now used to refer to the essential clue to a new field of knowledge. ]]
```

Also we will be inspecting a lot of outputs, and writing multiple for loops to pass through
nested tables is no fun. So to make things easier, I am importing `inspect`.

From `inspect` documentation: *human-readable representations of tables*
```lua
package.path = package.path .. ";./external/?.lua"
inspect = require("inspect")
```

### Sentence Tokenization
Let us begin with Sentence Tokenization

To import -
```lua
tokenization = require("tokenizer.tokenization")
```

Performing sentence tokenization on the above text, we get - 
```lua
sent_tokenizer = tokenization.sentence_tokenize(text)
sent_tokens = {}
for sent_token in sent_tokenizer do 
    table.insert(sent_tokens, sent_token) 
    print(sent_token.."<S-END>") 
end
```

```
The Rosetta Stone is a granodiorite stele inscribed with three versions of a decree issued in Memphis, Egypt in 196 BC during the Ptolemaic dynasty on behalf of King Ptolemy V Epiphanes.<S-END>
The top and middle texts are in Ancient Egyptian using hieroglyphic and Demotic scripts respectively, while the bottom is in Ancient Greek.<S-END>
The decree has only minor differences between the three versions, making the Rosetta Stone key to deciphering the Egyptian scripts.<S-END>
The stone was carved during the Hellenistic period and is believed to have originally been displayed within a temple, possibly at nearby Sais.<S-END>
It was probably moved in late antiquity or during the Mameluk period, and was eventually used as building material in the construction of Fort Julien near the town of Rashid (Rosetta) in the Nile Delta.<S-END>
It was discovered there in July 1799 by French officer Pierre-François Bouchard during the Napoleonic campaign in Egypt.<S-END>
It was the first Ancient Egyptian bilingual text recovered in modern times, and it aroused widespread public interest with its potential to decipher this previously untranslated hieroglyphic script.<S-END>
Lithographic copies and plaster casts soon began circulating among European museums and scholars.<S-END>
When the British defeated the French they took the stone to London under the Capitulation of Alexandria in 1801.<S-END>
It has been on public display at the British Museum almost continuously since 1802 and is the most visited object there.<S-END>
Study of the decree was already underway when the first complete translation of the Greek text was published in 1803.<S-END>
Jean-François Champollion announced the transliteration of the Egyptian scripts in Paris in 1822; it took longer still before scholars were able to read Ancient Egyptian inscriptions and literature confidently.<S-END>
Major advances in the decoding were recognition that the stone offered three versions of the same text (1799); that the demotic text used phonetic characters to spell foreign names (1802); that the hieroglyphic text did so as well, and had pervasive similarities to the demotic (1814); and that phonetic characters were also used to spell native Egyptian words (1822–1824).<S-END>
Three other fragmentary copies of the same decree were discovered later, and several similar Egyptian bilingual or trilingual inscriptions are now known, including three slightly earlier Ptolemaic decrees: the Decree of Alexandria in 243 BC, the Decree of Canopus in 238 BC, and the Memphis decree of Ptolemy IV, c. 218 BC. The Rosetta Stone is no longer unique, but it was the essential key to the modern understanding of ancient Egyptian literature and civilisation.<S-END>
The term 'Rosetta Stone' is now used to refer to the essential clue to a new field of knowledge.<S-END>
```

As can be observed, the sentence tokenizer is not 100% perfect, and fails to tokenize the 
second last line - `Ptolemy IV, c. 218 BC. The Rosetta Stone is no`.

To be more concrete about the algorithm's limitations, out of the 52 english tests presented in
[Pragmatic Segmenter](https://github.com/diasks2/pragmatic_segmenter#the-golden-rules), this sentence tokenizer generates wrong output for - 

```14, 15, 18, 35, 36, 37, 38, 42, 45, 50, 51```

### Word Tokenization
Let us now explore Word Tokenization

To call the **Penn Treebank Word Tokenizer** -
```lua
penn_word_tokenizer = require("tokenizer.treebank")
```

Passing sentences (sent_tokens)
```lua
penn_word_tokenizer:tokenize(text, convert_parentheses, return_str)
```

```
Args:
    text: (::str::) Sentence to be tokenized
    convert_parentheses: (::bool::) Parentheses are converted to forms such as 
                         -LRB-, -LSB-, -RRB-, -RSB-, etc.
    return_str: (::bool::) If false, will split on the whitespaces and return the tokens,
                else, will return the unsplit string
```

```lua
for _, sent_token in ipairs(sent_tokens) do
    local tokens = penn_word_tokenizer:tokenize(sent_token, false, false)
    print(inspect(tokens))
end
```
```lua
{ "The", "Rosetta", "Stone", "is", "a", "granodiorite", "stele", "inscribed", "with", "three", "versions", "of", "a", "decree", "issued", "in", "Memphis", ",", "Egypt", "in", "196", "BC", "during", "the", "Ptolemaic", "dynasty", "on", "behalf", "of", "King", "Ptolemy", "V", "Epiphanes", "." }
{ "The", "top", "and", "middle", "texts", "are", "in", "Ancient", "Egyptian", "using", "hieroglyphic", "and", "Demotic", "scripts", "respectively", ",", "while", "the", "bottom", "is", "in", "Ancient", "Greek", "." }
{ "The", "decree", "has", "only", "minor", "differences", "between", "the", "three", "versions", ",", "making", "the", "Rosetta", "Stone", "key", "to", "deciphering", "the", "Egyptian", "scripts", "." }
{ "The", "stone", "was", "carved", "during", "the", "Hellenistic", "period", "and", "is", "believed", "to", "have", "originally", "been", "displayed", "within", "a", "temple", ",", "possibly", "at", "nearby", "Sais", "." }
{ "It", "was", "probably", "moved", "in", "late", "antiquity", "or", "during", "the", "Mameluk", "period", ",", "and", "was", "eventually", "used", "as", "building", "material", "in", "the", "construction", "of", "Fort", "Julien", "near", "the", "town", "of", "Rashid", "(", "Rosetta", ")", "in", "the", "Nile", "Delta", "." }
{ "It", "was", "discovered", "there", "in", "July", "1799", "by", "French", "officer", "Pierre-François", "Bouchard", "during", "the", "Napoleonic", "campaign", "in", "Egypt", "." }
{ "It", "was", "the", "first", "Ancient", "Egyptian", "bilingual", "text", "recovered", "in", "modern", "times", ",", "and", "it", "aroused", "widespread", "public", "interest", "with", "its", "potential", "to", "decipher", "this", "previously", "untranslated", "hieroglyphic", "script", "." }
{ "Lithographic", "copies", "and", "plaster", "casts", "soon", "began", "circulating", "among", "European", "museums", "and", "scholars", "." }
{ "When", "the", "British", "defeated", "the", "French", "they", "took", "the", "stone", "to", "London", "under", "the", "Capitulation", "of", "Alexandria", "in", "1801", "." }
{ "It", "has", "been", "on", "public", "display", "at", "the", "British", "Museum", "almost", "continuously", "since", "1802", "and", "is", "the", "most", "visited", "object", "there", "." }
{ "Study", "of", "the", "decree", "was", "already", "underway", "when", "the", "first", "complete", "translation", "of", "the", "Greek", "text", "was", "published", "in", "1803", "." }
{ "Jean-François", "Champollion", "announced", "the", "transliteration", "of", "the", "Egyptian", "scripts", "in", "Paris", "in", "1822", ";", "it", "took", "longer", "still", "before", "scholars", "were", "able", "to", "read", "Ancient", "Egyptian", "inscriptions", "and", "literature", "confidently", "." }
{ "Major", "advances", "in", "the", "decoding", "were", "recognition", "that", "the", "stone", "offered", "three", "versions", "of", "the", "same", "text", "(", "1799", ")", ";", "that", "the", "demotic", "text", "used", "phonetic", "characters", "to", "spell", "foreign", "names", "(", "1802", ")", ";", "that", "the", "hieroglyphic", "text", "did", "so", "as", "well", ",", "and", "had", "pervasive", "similarities", "to", "the", "demotic", "(", "1814", ")", ";", "and", "that", "phonetic", "characters", "were", "also", "used", "to", "spell", "native", "Egyptian", "words", "(", "1822–1824", ")", "." }
{ "Three", "other", "fragmentary", "copies", "of", "the", "same", "decree", "were", "discovered", "later", ",", "and", "several", "similar", "Egyptian", "bilingual", "or", "trilingual", "inscriptions", "are", "now", "known", ",", "including", "three", "slightly", "earlier", "Ptolemaic", "decrees", ":", "the", "Decree", "of", "Alexandria", "in", "243", "BC", ",", "the", "Decree", "of", "Canopus", "in", "238", "BC", ",", "and", "the", "Memphis", "decree", "of", "Ptolemy", "IV", ",", "c.", "218", "BC.", "The", "Rosetta", "Stone", "is", "no", "longer", "unique", ",", "but", "it", "was", "the", "essential", "key", "to", "the", "modern", "understanding", "of", "ancient", "Egyptian", "literature", "and", "civilisation", "." }
{ "The", "term", "'Rosetta", "Stone", "'", "is", "now", "used", "to", "refer", "to", "the", "essential", "clue", "to", "a", "new", "field", "of", "knowledge", "." }
```

There is an experimental version of Word tokenize present in 
`Tokenize.regex_tokenize` in `tokenization.lua`. 
This version is a blown-up version of algorithm present in **Jurafsky and Martin** 
Edition 3, Chapter 2, Page 16 - Figure 2.12

Let us now explore other useful functions in tokenization

### N-Grams

```lua
tokenization.generate_n_gram(input, n)
```
```
Args:
    input: sentence to be tokenized
    n: n_gram value
```

2-gram for the first sentence - 
```lua
inspect(tokenization.generate_n_gram(sent_tokens[1], 2))
```
```lua
{ { "The", "Rosetta" }, { "Rosetta", "Stone" }, { "Stone", "is" }, { "is", "a" }, { "a", "granodiorite" }, { "granodiorite", "stele" }, { "stele", "inscribed" }, { "inscribed", "with" }, { "with", "three" }, { "three", "versions" }, { "versions", "of" }, { "of", "a" }, { "a", "decree" }, { "decree", "issued" }, { "issued", "in" }, { "in", "Memphis," }, { "Memphis,", "Egypt" }, { "Egypt", "in" }, { "in", "196" }, { "196", "BC" }, { "BC", "during" }, { "during", "the" }, { "the", "Ptolemaic" }, { "Ptolemaic", "dynasty" }, { "dynasty", "on" }, { "on", "behalf" }, { "behalf", "of" }, { "of", "King" }, { "King", "Ptolemy" }, { "Ptolemy", "V" }, { "V", "Epiphanes." } }
```

**NOTE:** By default `tokenization.generate_n_gram` splits the input into tokens by splitting on 
whitespaces. To improve the performance, use `penn_word_tokenizer:tokenize(text, convert_parentheses, return_str)`, with `return_str = true`.
This will ensure that splitting on whitespaces will preserve the Treebank Tokenizer properties.

For example:
```lua
inspect(tokenization.generate_n_gram(penn_word_tokenizer:tokenize(sent_tokens[1], false, true), 2))
```

```lua
{ { "The", "Rosetta" }, { "Rosetta", "Stone" }, { "Stone", "is" }, { "is", "a" }, { "a", "granodiorite" }, { "granodiorite", "stele" }, { "stele", "inscribed" }, { "inscribed", "with" }, { "with", "three" }, { "three", "versions" }, { "versions", "of" }, { "of", "a" }, { "a", "decree" }, { "decree", "issued" }, { "issued", "in" }, { "in", "Memphis" }, { "Memphis", "," }, { ",", "Egypt" }, { "Egypt", "in" }, { "in", "196" }, { "196", "BC" }, { "BC", "during" }, { "during", "the" }, { "the", "Ptolemaic" }, { "Ptolemaic", "dynasty" }, { "dynasty", "on" }, { "on", "behalf" }, { "behalf", "of" }, { "of", "King" }, { "King", "Ptolemy" }, { "Ptolemy", "V" }, { "V", "Epiphanes" }, { "Epiphanes", "." } }
```

### Remove Punctuations

```lua
tokenization.remove_punctuations(input)
```
```lua
tokenization.remove_punctuations(sent_tokens[#sent_tokens-1])
```
```
Three other fragmentary copies of the same decree were discovered later and several similar Egyptian bilingual or trilingual inscriptions are now known including three slightly earlier Ptolemaic decrees the Decree of Alexandria in 243 BC the Decree of Canopus in 238 BC and the Memphis decree of Ptolemy IV c 218 BC The Rosetta Stone is no longer unique but it was the essential key to the modern understanding of ancient Egyptian literature and civilisation
```

### Emoji Tokenize

Finds all the text-based emojis (non-unicode) from the input text
```lua
tokenization.emoji_tokenize(input)
emojis = tokenization.emoji_tokenize("Hi there! :) It has been a long time :D")
for emoji in emojis do print(emoji) end
```
```
:)
:D
```

### Whitespace Tokenize

Tokenizes on whitespaces
```lua
tokenization.whitespace_tokenize(input)
```
```lua
whitespace_tokenizer = tokenization.whitespace_tokenize(sent_tokens[#sent_tokens])
whitespace_tokens = {}
for token in whitespace_tokenizer do table.insert(whitespace_tokens, token) end
inspect(whitespace_tokens)
```
```lua
{ "The", "term", "'Rosetta", "Stone'", "is", "now", "used", "to", "refer", "to", "the", "essential", "clue", "to", "a", "new", "field", "of", "knowledge." }
```

### Character Tokenize
Tokenizes on characters
```lua
tokenization.character_tokenize(input)
```
```lua
character_tokenizer = tokenization.character_tokenize(sent_tokens[#sent_tokens])
character_tokens = {}
for token in character_tokenizer do table.insert(character_tokens, token) end
inspect(character_tokens)
```
```lua
{ "T", "h", "e", " ", "t", "e", "r", "m", " ", "'", "R", "o", "s", "e", "t", "t", "a", " ", "S", "t", "o", "n", "e", "'", " ", "i", "s", " ", "n", "o", "w", " ", "u", "s", "e", "d", " ", "t", "o", " ", "r", "e", "f", "e", "r", " ", "t", "o", " ", "t", "h", "e", " ", "e", "s", "s", "e", "n", "t", "i", "a", "l", " ", "c", "l", "u", "e", " ", "t", "o", " ", "a", " ", "n", "e", "w", " ", "f", "i", "e", "l", "d", " ", "o", "f", " ", "k", "n", "o", "w", "l", "e", "d", "g", "e", "." }
```

### Stemming
The Porter stemmer implemented in this library is ported to Lua using the Python implementation on [Martin Porter's website](https://tartarus.org/martin/PorterStemmer/python.txt). The Porter algorithm can be found in the following paper - [Porter Algorithm](https://tartarus.org/martin/PorterStemmer/def.txt).

To import module -
```lua
porter_stemmer = require("stemmer.porter")
```

Syntax
```
porter_stemmer:stem(word, start_index, end_index)
Args:
    word: (::str::) Word to be stemmed
    start_index: (::int::) Starting index of the string (in almost all cases - 1)
    end_index: (::int::) Ending index of the string (in most cases, length of the string)
```

Stemming words in the 3rd sentence -
```lua
to_stem_words = penn_word_tokenizer:tokenize(sent_tokens[3], false, false)
for _, word in ipairs(to_stem_words) do
    local stemmed = porter_stemmer:stem(word, 1, string.len(word))
    print(word .. " -> " .. stemmed)
end
```
```
The -> The
decree -> decre
has -> ha
only -> onli
minor -> minor
differences -> differ
between -> between
the -> the
three -> three
versions -> version
, -> ,
making -> make
the -> the
Rosetta -> Rosetta
Stone -> Stone
key -> kei
to -> to
deciphering -> deciph
the -> the
Egyptian -> Egyptian
scripts -> script
. -> .
```

This stemming algorithm has been successfully tested using testcases from [Martin Porter's website](https://tartarus.org/martin/PorterStemmer/) ([Vocabulary](https://tartarus.org/martin/PorterStemmer/voc.txt) and [Output](https://tartarus.org/martin/PorterStemmer/output.txt)).

### Parts of Speech

An **averaged perceptron based Parts of Speech tagger** is implemented in this library. 
This module is a port of NLTK's Averaged Perceptron Tagger 
which in-turn was a port of Textblob's Averaged Perceptron Tagger.
For understanding of Parts-of-speech taggers and their implementations, refer the following 
readings -
* [Matthew Honnibal's blog detailing the concept](https://explosion.ai/blog/part-of-speech-pos-tagger-in-python)
* [For an introduction to Parts of Speech Tagging](https://web.stanford.edu/~jurafsky/slp3/8.pdf)

To import the module - 
```lua
pos_tagger = require("pos.perceptron")
```

Unlike the rest of the tasks, the **Parts of Speech tagger requires training on labelled data** 
before it can make meaningful predictions. By default, you can train on the `conll2000` dataset
using the code below.

**NOTE:** The pretrained model is not shipped, so using POS tagging requires mandatory training on 
some dataset.

Visualization of `train.txt` from `conll2000`:
```
Confidence NN B-NP
in IN B-PP
the DT B-NP
pound NN I-NP
is VBZ B-VP
.....
```

Syntax -
```
pos_tagger:train(sentences, nr_iter) -> To train the tagged sentences
    Args:
    sentences: Nested tables containing sentences and their corresponding parts-of-speech
               tags. For example - 
                     {
                        { {'today','NN'},{'is','VBZ'},{'good','JJ'},{'day','NN'} }, 
                        { {'yes','NNS'},{'it','PRP'},{'beautiful','JJ'} }
                     }
    nr_iter: (::int::) Number of training iterations

pos_tagger:tag(tokens, return_conf, use_tagdict) -> To tag the tokenized sentences
    Args:
    tokens: (::array::) Array of tokens
    return_conf: (::bool::) If true, returns the confidence scores of the tags
    use_tagdict: (::bool::) If true, uses tag dictionary for single-tag words.
                            If a token has a frequency of 20 or more and has a probability score 
                            greater than 97% of predicting a certain tag, that tag is stored in a 
                            dictionary. Such tokens' tags are then automatically indexed from this 
                            dictionary.
```

For training (this code along with the testing part can be found in `./pos/conll2000_test.lua`) -
```lua
TRAIN_FILE = "./pos/conll2000/train.txt"

function training(filename)
    local file = io.open(filename, "r")
    local done = false
    local training_set = {}
    while done ~= true do
        local found_end_of_sentence = false
        local sentence = {}
        while found_end_of_sentence ~= true do
            local sent = file:read()
            local func = string.gmatch(sent, "[^%s]+")
            local curr_word, tag, chunk_tag = func(), func(), func()
            if curr_word == nil then
                found_end_of_sentence = true
            -- we have reached the end
            elseif curr_word == "END_OF_TRAINING_FILE" then
                found_end_of_sentence = true
                done = true
            else
                table.insert(sentence, {curr_word, tag})
            end
        end
        table.insert(training_set, sentence)
    end
    pos_tagger:train(training_set, 8)
    file.close()
end
```

For testing on the eighth sentence, try -
```lua
inspect(pos_tagger:tag(penn_word_tokenizer:tokenize(sent_tokens[8], false, false), true, true))
```
```
{ { "Lithographic", "JJ", 0.99525661280489 }, { "copies", "NNS", 0.9999999944953 }, { "and", "CC", 1.0 }, { "plaster", "NN", 0.97827922854818 }, { "casts", "NNS", 0.99998149375758 }, { "soon", "RB", 1.0 }, { "began", "VBD", 1.0 }, { "circulating", "VBG", 0.99999854714063 }, { "among", "IN", 1.0 }, { "European", "JJ", 0.99999399618361 }, { "museums", "NNS", 0.99996446558515 }, { "and", "CC", 1.0 }, { "scholars", "NNS", 0.97589828477377 }, { ".", ".", 1.0 } }
```

On `conll-2000` testcases, the average perceptron-based implementation produces an accuracy of 97.33%. 
See `./pos/conll2000/README.txt` for more details.

### Lemmatization

Currently, for lemmatization, a **Wordnet-based lemmatization algorithm** is supported. This algorithm has been ported from NLTK's `nltk.stem.WordNetLemmatizer()` (sources are [`stem/wordnet.html`]() and [`corpus/reader/wordnet.html`](https://www.nltk.org/_modules/nltk/corpus/reader/wordnet.html)).

To import the module - 
```lua
wordnet = require("lemmatizer.wordnet")
```

Syntax -
```lua
wordnet:_morphy(word, pos, check_exceptions)
```
```
Args:
    word: (::str::) Word to be lemmatized
    pos: (::str::) Parts of Speech for the word
                   Available options are: 
                     "v" - Verb
                     "n" - Noun
                     "a" - Adjective
                     "s" - Satellite Adjective
                     "r" - Adverb
    check_exceptions: (::bool::) If true, it will check for any lemmatization related exceptions as 
                                 mentioned by Wordnet. For list of exceptions related to a 
                                 particular POS, see the respective `.exc` file in `./lemmatizer/wordnet`.
```

Additionaly, if curious regarding `s` and `a`, read [Different handling of Adjective and Satellite Adjective?](https://stackoverflow.com/questions/51634328/wordnetlemmatizer-different-handling-of-wn-adj-and-wn-adj-sat)

**Remember:** It is essential that the words to be lemmatized are in **lowercase**.

Lemmatizing the 3rd sentence - 
```lua
-- Tokenizer the sentence
to_lemmatize_words = penn_word_tokenizer:tokenize(sent_tokens[3], false, false)

-- Find out all the Parts of Speech of the words
pos_tags = pos_tagger:tag(to_lemmatize_words, false, true)

-- As wordnet deals with verbs, noun, adjective, and adverbs
-- And as the tags returned by `pos_tagger:tag` follow the BrillTagger conventions
-- like NN, RB, JJ, etc. We are creating a simple dictionary to map the 
-- BrillTagger conventions to Wordnet conventions.
map_tags = {N="n", J="a", R="r", V="v"}

for i, word in ipairs(to_lemmatize_words) do
    local lemmatized = word
    local first_char_of_pos = string.sub(pos_tags[i][2], 1, 1)
    local pos = map_tags[first_char_of_pos]

    if pos ~= nil then 
        -- find a lemmatized form for this word with a non-nil tag
        lemmatized = wordnet:_morphy(string.lower(word), pos, true)[1]

        -- If a word is not in Wordnet, wordnet:_morphy returns `nil`
        -- So, substituting nil with the original word
        if lemmatized == nil then
            lemmatized = word
        end
    end
    print(word .. " -> " .. lemmatized)
end
```
```
The -> The
decree -> decree
has -> have
only -> only
minor -> minor
differences -> difference
between -> between
the -> the
three -> three
versions -> version
, -> ,
making -> make
the -> the
Rosetta -> Rosetta
Stone -> stone
key -> key
to -> to
deciphering -> decipher
the -> the
Egyptian -> egyptian
scripts -> script
. -> .
```

**NOTE:** After obtaining a list of potential lemmas using `nltk.corpus.wordnet._morphy(word, pos)`, 
the following codeblock is executed by NLTK in Python:

```python
lemmas = wordnet._morphy(word, pos)
return min(lemmas, key=len) if lemmas else word
```

Therefore, for words such as `saw` and POS of `v`, the lemmas obtained are - `["saw", "see"]`.
Based on the above code, it returns `saw` as the lemma as words are of same length. 
However, the question of which is right is subjective.

To prevent confusion, `wordnet._morphy` provides all the possible lemmas. NLTK like functionality 
can be performed as follows:

```lua
wn = require("wordnet")
lemmas = wn:_morphy(word, pos, check_exceptions)
if #lemmas ~= 0 then 
    table.sort(lemmas)
    return table[1]
else
    return word
end
```

### Sentiment Analysis

For sentiment analysis, **VADER algorithm** is supported. The implementation 
in this library is a port of [vaderSentiment](https://github.com/cjhutto/vaderSentiment/) by CJ Hutto.

To import the module -
```lua
vader = require('sent.vader')
```

Syntax -
```lua
vader:polarity_scores(sentence)
```
```
Args:
    sentence:  (::str::) Sentence to be classified
```

As the above *Rosetta Stone* passage has neutral sentences, testing on a different example -
```lua
inspect(vader:polarity_scores("Ferrari WON the F1 World Championship!!!!"))
```
```lua
{
  compound = 0.8591,
  neg = 0.0,
  neu = 0.32,
  pos = 0.68
}
```

**Drawbacks** of using VADER algorithm:

As this is a lexicon and rule-based tool, it does not work in cases wherein the tokens are not in the lexicon, but convey sentiment. 
For example: from the dataset included in the Paper `From Group to Individual Labels using Deep Features, Kotzias et. al,. KDD 2015`

```
Amazon Reviews
(1) You can not answer calls with the unit, never worked once!
(2) Item Does Not Match Picture.
(3) Lasted one day and then blew up.
(4) Adapter does not provide enough charging current.
(5) I plugged it in only to find out not a darn thing worked.
```

All the selected sentences generate a *compound* score of 0 (i.e. neutral).

As mentioned by the vaderSentiment authors in their README:
> is specifically attuned to sentiments expressed in social media

See `./sent/test_vader.lua` for tests on the `Kotzias et. al,. KDD 2015` paper's dataset.

### Text Summarization

Let us now explore **TextTeaser**, an automatic summarization algorithm supported by this library.
This module is a port of the [Newspaper3k port](https://github.com/codelucas/newspaper/blob/master/newspaper/nlp.py) of TextTeaser which was originally written by [Jolo Balbin in Scala](https://github.com/MojoJolo/textteaser).

To import the module -
```lua
summarizer = require("summarize.textteaser")
```

Syntax -
```lua
summarizer.summarize(title, text, max_sents)
```

```
Args:
    title: (::str::) Title of the text body which is to be summarized
    text: (::str::) Text corpus to be summarized
    max_sents: (::int::) Number of sentences in the summary
```

Summarizing our *Rosetta Stone* passage -
```lua
inspect(summarizer.summarize("Rosetta Stone", text, 3))
```
```
"The Rosetta Stone is a granodiorite stele inscribed with three versions of a decree  issued in Memphis, Egypt in 196 BC during the Ptolemaic dynasty on behalf of King Ptolemy V  
Epiphanes. The decree has only minor differences between  the three versions, making the Rosetta Stone key to deciphering the Egyptian scripts. The term 'Rosetta Stone' is now used to 
refer to the essential clue to a new field of knowledge."
```

**NOTE:** The results in this module may slightly differ from those in Newspaper3k's 
implementation as the word and sentence tokenizers have different implementations.
This module depends on `./tokenizer/tokenization.lua`.

Relevant discussion regarding TextTeaser can be found on [Hacker News](https://news.ycombinator.com/item?id=6536896).
In this HN link, the author (MojoJolo) mentions referring to the paper: [Comments-Oriented Blog Summarization by Sentence Extraction](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.222.6530&rep=rep1&type=pdf).

### Keyword Extraction

This library supports keyword extraction using an algorithm known as **Rapid Automatic Keyword Extraction (RAKE)** algorithm.
This module is a Python port of RAKE by [Aneesha](https://github.com/aneesha/RAKE).

To import the module -
```lua
keywords = require("keyword.rake")
```

Syntax -
```lua
keywords:run(text, topn)
```
```
Args:
    text: (::str::) Text corpus for extracting keywords from.
    topn: (::int::) Number of keywords to be extracted
```

Extracting keywords from our *Rosetta Stone* passage -
```lua
keywords:run(text, 5)
```
```lua
{   
    "french officer pierre-françois bouchard", 
    "ancient egyptian bilingual text recovered", 
    "jean-françois champollion announced", 
    "slightly earlier ptolemaic decrees", 
    "aroused widespread public interest" 
}
```

**When to use RAKE:** RAKE can primarily be used for obtaining key phrases in text body.
For 1 or 2 token keywords, see the TextTeaser function `Summarize.keywords`.

**NOTE:** By default, this implementation uses the `Smart` Stoplist. To change this -
```lua
Rake.stopword_type = <your-choice>

-- By default, ./stopwords supports the following - 
-- Fox StopList, NLTK's english Stoplist, and Smart Stoplist

-- `build_stop_word_regex` is a local function in `./keyword/rake.lua`
Rake._stop_word_pattern = build_stop_word_regex(Rake.stopword_type)
Rake.run(text, topn)
```

### Named-entity Recognition
At present, the averaged perceptron based implementation for Parts-of-Speech tagging can be easily modified to support Named-Entity Recognition.

**What modification is required?**

Modify line in `AveragedPerceptron.predict` in `./pos/perceptron.lua` -
```lua
    else 
        best_label, conf = self.classes["VBZ"], 0
```
To -
```lua
    else 
        best_label, conf = self.classes["B-LOC"], 0
```
The above line provided a non-nil `guess` as a starting guess for the perceptron to compare with the `truth` and update its weigths.
As NER models do not possess `VBZ` class, we changed it to a more appropriate `B-LOC` class.

To import the module -
```lua
ner_tagger = require("pos.perceptron")
```

Similar to Parts of Speech tagger, **Named Entity Recognition requires training on labelled data** before it can make meaningful predictions. By default, you can train on the conll2003 dataset by following the instructions mentioned below:

To read instructions on how to download Conll2003 dataset inside `./pos/conll2003` and how to preprocess the data, 
refer to `./pos/conll2003/README.txt`.

Once `train.json`, `valid.json`, and `test.json` are obtained after the above mentioned preprocessing step, 
you can train the NER model using the following code -

```lua
json = require("external.json")
pt = require("pos.perceptron")

-- Assuming train.json and valid.json are in ./pos/conll2003/
TRAIN_FILE = "./pos/conll2003/train.json"

function to_json(filename)
    local file = io.open(filename, "r")
    local sents = file.read(file, "*a")
    file.close()
    sents = json.decode(sents)
    return sents
end

function training(filename)
    local training_set = to_json(filename)
    pt:train(training_set, 8)
end

training(TRAIN_FILE)
```

Performing NER on sixth sentence of *Rosetta Stone* passage -
```lua
-- It was discovered there in July 1799 by French officer Pierre-François Bouchard during the Napoleonic campaign in Egypt.
ner_sent = penn_word_tokenizer:tokenize(sent_tokens[6], false, false)
inspect(pt:tag(ner_sent))
```
```lua
{ { "It", "O", 0.99797167678855 }, { "was", "O", 0.99999994433959 }, { "discovered", "O", 1.0 }, { "there", "O", 0.99999999999938 }, { "in", "O", 0.99999999992923 }, { "July", "O", 0.99999850186825 }, { "1799", "O", 0.99999999999998 }, { "by", "O", 1.0 }, { "French", "B-MISC", 0.99999999671776 }, { "officer", "O", 0.99999999999989 }, { "Pierre-François", "O", 0.95948598745703 }, { "Bouchard", "B-PER", 0.91195727669638 }, { "during", "O", 0.9999994612422 }, { "the", "O", 1.0 }, { "Napoleonic", "B-MISC", 0.96769051909557 }, { "campaign", "O", 1.0 }, { "in", "O", 0.99999999999984 }, { "Egypt", "B-LOC", 0.99789478864941 }, { ".", "O", 0.99999836506797 } }
```

To test the model on `valid.json` or `test.json`, see `./pos/conll2003_test.lua`.

Average Precision and Recall results after testing on Conll2003 five times (each was trained for 8 iterations) -

___|LOC|MISC|ORG|PER|
|---|---|---|---|---|
Precision|0.8267|0.7416|0.7879|0.8617
Recall|0.8514|0.7725|0.7307|0.8930

The precision and recall for the `O` tag averaged around `0.987`.

## Feature Request
At present, this library supports a handful of algorithms. If there are any specific algorithms you would like me to port to Lua, add them to the discussion [LuaNLP Feature Requests](https://github.com/pncnmnp/LuaNLP/discussions/1). I will try implementing 1 feature every month.

## Author
Parth Parikh ([https://pncnmnp.github.io](https://pncnmnp.github.io))

## License
This library is licensed under [MIT License](https://github.com/pncnmnp/LuaNLP/blob/main/LICENSE). For details regarding licenses of the codebases being ported, see the respective `.lua` files.
