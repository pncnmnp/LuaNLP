import json

def get_contents(file):
    with open(file, "r") as f:
        file_contents = f.readlines()
    sentences = []
    i = 0
    while i < len(file_contents):
        if file_contents[i] == '-DOCSTART- -X- -X- O\n':
            pass
        elif file_contents[i] == "\n":
            pass
        elif file_contents[i][0].isalpha() == True:
            start_i = i
            sentence = []
            while file_contents[i] != "\n":
                content = file_contents[i].split(" ")
                sentence.append([content[0].strip(), content[-1].strip()])
                i += 1
            sentences.append(sentence)        
        i += 1
    with open(file.replace(".txt", ".json"), 'w') as outfile:
        json.dump(sentences, outfile)

for file in ["./train.txt", "./valid.txt", "./test.txt"]:
    get_contents(file)
    print("Parsed {}".format(file))