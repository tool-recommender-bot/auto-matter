#!/bin/bash

set -euxo pipefail

mvn install -DskipTests=true

curl -s 'http://search.maven.org/solrsearch/select?q=g:%22com.fasterxml.jackson.core%22+AND+a:%22jackson-databind%22&core=gav&rows=100&wt=json' |
           jq -r '[.response.docs | .[].v |
                  {p: split("."), v:.} |
                  {major:.p[0] | tonumber, minor: .p[1] | tonumber, v:.v} |
                  select(.major >= 2 and .minor >= 4)] |
                  sort_by([.major, .minor, .v]) |
                  .[].v' |
           grep -v '2.4.0-rc' > jackson-databind-versions.txt

curl -s 'http://search.maven.org/solrsearch/select?q=g:%22com.fasterxml.jackson.datatype%22+AND+a:%22jackson-datatype-joda%22&core=gav&rows=100&wt=json' |
           jq -r '[.response.docs | .[].v |
                  {p: split("."), v:.} |
                  {major:.p[0] | tonumber, minor: .p[1] | tonumber, v:.v} |
                  select(.major >= 2 and .minor >= 4)] |
                  sort_by([.major, .minor, .v]) |
                  .[].v' |
           grep -v '2.4.0-rc' > jackson-joda-versions.txt

JACKSON=$(comm -12 jackson-databind-versions.txt jackson-joda-versions.txt)

for v in ${JACKSON}; do
  echo
  echo "Testing Jackson $v"
  echo "========================================================================"
  set -x
  mvn -Djackson.version=$v -pl jackson test
  set +x
done

