-- The testcases are from Martin Porter's website: https://tartarus.org/martin/PorterStemmer/
-- Vocabulary: https://tartarus.org/martin/PorterStemmer/voc.txt
-- Output: https://tartarus.org/martin/PorterStemmer/output.txt

porter = require("porter")
package.path = package.path .. ";../external/?.lua"
json = require("json")
TESTS_FILE = "./test_cases.json"

function get_tests(filename)
    local file = io.open(filename, "r")
    local tests = file.read(file, "*a")
    file.close()
    tests = json.decode(tests)
    return tests
end

function check(filename)
    local tests = get_tests(filename)
    local match = 0
    local mismatch = 0
    for k,v in pairs(tests) do
        local stemmed = porter:stem(k, 1, string.len(k))
        if stemmed ~= v then
            print("MISMATCH! Actual: " .. v .. ", Error one: " .. stemmed)
            mismatch = mismatch + 1
        else match = match + 1
        end
    end
    print("Matches: " .. match .. ", Mismatches: " .. mismatch)
end

check(TESTS_FILE)