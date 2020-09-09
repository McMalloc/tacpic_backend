#!/bin/bash

function escape_quotes {
    sed -r 's/(\")/\\"/g'
}
function escape_newlines {
    sed -r 's/(\n)//g'
}

function format {
    hash=$(git log -n1 --pretty=format:%h $1 | escape_quotes | escape_newlines)
    subject=$(git log -n1 --pretty=format:%s $1 | escape_quotes | escape_newlines)
    author=$(git log -n1 --pretty=format:%an $1 | escape_quotes | escape_newlines)
    commit=$(git log -n1 --pretty=format:%cE $1 | escape_quotes | escape_newlines)
    timestamp=$(git log -n1 --pretty=format:%at $1 | escape_quotes | escape_newlines)
    echo -n "{\"hash\":\"$hash\",\"subject\":\"$subject\",\"author\":\"$author\",\"timestamp\":\"$timestamp\",\"commit\":\"$commit\"}"
}

cd $1

> $2
echo -n '{"tag": "' >> $2
tag=$(git describe --tags | escape_quotes | escape_newlines)
echo -n "$tag" >> $2
echo -n '", "commits": [' >> $2

for hash in $(git rev-list --all)
do
  format "$hash" >> $2
  echo ',' >> $2
done
echo -n "{\"hash\":\"\",\"subject\":\"\",\"author\":\"\",\"timestamp\":\"\",\"commit\":\"\"}" >> $2

echo -n "]}" >> $2

