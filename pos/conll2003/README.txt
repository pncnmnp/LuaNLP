Named Entity Recognition

HOW TO DOWNLOAD Conll2003 DATASET FOR TRAINING AND TESTING?
===========================================================

The train.txt, valid.txt, and test.txt can be obtained from https://www.kaggle.com/alaakhaled/conll003-englishversion.

Although the Kaggle dataset's metadata mentions that the data is under CC0: Public Domain, I am 
skeptical.

From Conll2003 website (https://www.clips.uantwerpen.be/conll2003/ner/) -
>   The English data is a collection of news wire articles from the Reuters Corpus. The annotation 
    has been done by people of the University of Antwerp. Because of copyright reasons we only make 
    available the annotations. In order to build the complete data sets you will need access to the 
    Reuters Corpus. It can be obtained for research purposes without any charge from NIST. 

Link to obtain the Reuters Corpus: https://trec.nist.gov/data/reuters/reuters.html

For the above reason, this library does not distribute the Conll2003 train, validation, and test 
data. If the Kaggle link does not work, do follow the instructions on NIST's website to obtain the 
dataset.

HOW TO PREPROCESS DATA?
=======================

Once the train.txt, valid.txt, and test.txt are downloaded, preprocessing and converting to '.json'
format can be done by running the Python script `parse.py`. Then `../conll2003_test.lua` can be 
executed to obtain the training and test information.

For the information about training your own model, refer to README.md at root path of this library.

HOW DOES AVERAGE PERCEPTRON PERFORM ON Conll2003 DATASET?
=========================================================

The below precision and recall data is based on 
three executions on the validation set

The results are a bit off from the ones seen in a similar paper:
Learning a Perceptron-Based Named Entity Chunker via Online Recognition Feedback
https://www.clips.uantwerpen.be/conll2003/pdf/15659car.pdf
(Page 4, Table 1 - English devel.)

[22:06][pos] lua5.3 conll2003_test.lua
Iter 1.000000: 190433.000000/200430.000000=95.012224
Iter 2.000000: 192083.000000/200427.000000=95.836888
Iter 3.000000: 194769.000000/200429.000000=97.176057
Iter 4.000000: 196072.000000/200426.000000=97.827627
Iter 5.000000: 196903.000000/200425.000000=98.242734
Iter 6.000000: 197454.000000/200428.000000=98.516175
Iter 7.000000: 197800.000000/200429.000000=98.688314
Iter 8.000000: 198078.000000/200426.000000=98.828495
LOC Precision: 0.90707751564757 Recall: 0.89971346704871
MISC Precision: 0.89149305555556 Recall: 0.80993690851735
ORG Precision: 0.87125591171834 Recall: 0.7925430210325
PER Precision: 0.92172272870167 Recall: 0.93108923467768
O Precision: 0.9897201329781 Recall: 0.99653396006932


[22:08][pos] lua5.3 conll2003_test.lua
Iter 1.000000: 190358.000000/200430.000000=94.974804
Iter 2.000000: 191961.000000/200427.000000=95.776018
Iter 3.000000: 194912.000000/200429.000000=97.247404
Iter 4.000000: 196209.000000/200426.000000=97.895982
Iter 5.000000: 196884.000000/200425.000000=98.233254
Iter 6.000000: 197443.000000/200428.000000=98.510687
Iter 7.000000: 197714.000000/200429.000000=98.645406
Iter 8.000000: 198069.000000/200426.000000=98.824005
LOC Precision: 0.90028763183126 Recall: 0.89684813753582
MISC Precision: 0.8994708994709 Recall: 0.80441640378549
ORG Precision: 0.86642221058146 Recall: 0.7906309751434
PER Precision: 0.92196803509872 Recall: 0.93426484598285
O Precision: 0.98974201763901 Recall: 0.99639152007217


[22:08][pos] lua5.3 conll2003_test.lua
Iter 1.000000: 190375.000000/200430.000000=94.983286
Iter 2.000000: 192061.000000/200427.000000=95.825912
Iter 3.000000: 194790.000000/200429.000000=97.186535
Iter 4.000000: 196187.000000/200426.000000=97.885005
Iter 5.000000: 196967.000000/200425.000000=98.274666
Iter 6.000000: 197521.000000/200428.000000=98.549604
Iter 7.000000: 197769.000000/200429.000000=98.672847
Iter 8.000000: 198024.000000/200426.000000=98.801553
LOC Precision: 0.9028379028379 Recall: 0.896370582617
MISC Precision: 0.89245446660885 Recall: 0.8115141955836
ORG Precision: 0.87579957356077 Recall: 0.78537284894837
PER Precision: 0.9157633942397 Recall: 0.93902826294062
O Precision: 0.99004458703909 Recall: 0.99629656007407
[22:09][pos] 
