#!/bin/bash
set -e

BASE_DIR=$(cd $(dirname $0); pwd)

EXIT_CODE=0

check_links() {
    set +e
    for i in `sed -E -e 's/[ \(\)"]/\n/g' $1 |
          grep -E -e "^http://[^\.]+" -e "^https://[^\.]+" -e "^ftp://[^\.]+" |
          grep -v "example.com" |
          grep -v "localdomain" |
          grep -v "localhost" |
          grep -E -v "\.test$|\.test/" |
          sort | uniq`; do
        curl -s -f $i > /dev/null
        if [ $? -ne 0 ]; then
          echo $1: $i
          EXIT_CODE=1
        fi
    done
    set -e
}

check_documents() {
    for i in `find $1 -name "*.md" | grep -v "/node_modules/" | grep -v "/config/" | grep -v "/bower_components/"`; do
        check_links $i
    done
}

for i in `find ${BASE_DIR} -name src.tmp`; do
    check_documents $i
done

exit ${EXIT_CODE}
