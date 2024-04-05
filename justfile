set shell := ["bash", "-uc"]

gorn *args="":
    zig build run -- {{args}}

ungorn *args="":
    zig build run -- -u {{args}}


roundtrip file:
    cat {{file}} | zig build run | zig build run -- -u

# TODO bench larger json files, or a variety
bench-basic:
    zig build -Doptimize=ReleaseSafe && hyperfine \
    "./zig-out/bin/gorn testdata/big.json > /dev/null" \
    "gron testdata/big.json > /dev/null"

# if perf permission denied: https://github.com/andrewrk/poop/issues/17
# Can `sudo sysctl kernel.perf_event_paranoid=3`
bench-poop file:
    zig build -Doptimize=ReleaseSafe && poop \
    "./zig-out/bin/gorn {{file}}" \
    "gron {{file}}"

bench-large-line:
    zig build -Doptimize=ReleaseSafe && hyperfine \
    "./zig-out/bin/gorn testdata/large-line.json > /dev/null" \
    "gron testdata/large-line.json > /dev/null"

# huge.json is generated by `node bin/generate-huge-json.mjs testdata/huge.json`
bench-huge:
    zig build -Doptimize=ReleaseSafe && hyperfine \
    "./zig-out/bin/gorn testdata/huge.json > /dev/null" \
    "gron testdata/huge.json > /dev/null"

bench-roundtrip file:
    zig build -Doptimize=ReleaseSafe && hyperfine \
    "./zig-out/bin/gorn {{file}} | ./zig-out/bin/gorn -u > /dev/null" \
    "gron {{file}} | gron -u > /dev/null"

# gron appears to sort differently than `sort`, double check this?
diff-gron file *args="":
    zig build && diff <(./zig-out/bin/gorn {{file}} {{args}} | sort) <(gron {{file}} {{args}} | sort)

# arrays are formatted differently, so need to do compact for both
diff-roundtrip file:
    zig build && diff <(./zig-out/bin/gorn {{file}} | ./zig-out/bin/gorn -u) <(cat {{file}} | jq -c)

test-roundtrip:
    \fd json testdata --exclude "*stream*" --exec just diff-roundtrip

# Test stream separately
test-vs-gron:
    \fd json testdata --exclude "*stream*" --exec just diff-gron

test-vs-gron-stream:
    \fd stream.json testdata --exec just diff-gron --stream

# Test stream separately
#test-vs-ungron:
#    \fd json testdata --exclude "*stream*" --exec just diff-ungron
