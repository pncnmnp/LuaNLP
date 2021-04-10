# README

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
* Stopwords and N-grams

> As of 13/03/21, Named entity recognition, and Word sense disambiguation
are under development.

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
