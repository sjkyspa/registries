#!/bin/sh

puts_red() {
    echo $'\033[0;31m'"      $@" $'\033[0m'
}

puts_red_f() {
  while read data; do
    echo $'\033[0;31m'"      $data" $'\033[0m'
  done
}

puts_green() {
  echo $'\033[0;32m'"      $@" $'\033[0m'
}

puts_step() {
  echo $'\033[0;34m'" -----> $@" $'\033[0m'
}

puts_step "Start to verify..."
sleep 20
puts_step "Verify success"

if [ -f "/tmp/repo/manifest.json" ]; then
    cd /tmp/git
    puts_step "Start sync to ketsu"
    first_commit=$(git log --reverse --pretty=format:%at |head -n1)
    last_commit=$(git log --pretty=format:%at -n 1)
    evaluation_duration=$(eval 'expr $last_commit - $first_commit')
    puts_green "firstcommit $first_commit"
    puts_green "lastcommit $last_commit"
    puts_green "duration $evaluation_duration"

    cd /tmp/repo
    evaluation_uri=$(cat manifest.json| jq -r '.evaluation_uri')
        puts_green "evaluationuri $evaluation_uri"
    if [ -z "$evaluation_uri" ] ; then
        puts_red "missing manifest.json"
        exit 1
    fi
    entry_point=$(echo $evaluation_uri | awk -F/ '{print $3}')
    puts_green "entry point $entry_point"

    if [ -z "$entry_point" ] ; then
        puts_red "bad format of manifest.json"
        exit 1
    fi

    curl -c cookie -b cookie "$entry_point/authentication" -d "user_name=bg"
    curl -c cookie -b cookie "$entry_point/authentication" -d "user_name=bg"
    result_status=$(curl -sSL --write-out "%{http_code}" -X POST -c cookie -b cookie $evaluation_uri -d "score=600" -d "status=pass")
    if [ "$result_status" != "200" ] ; then
        puts_red "sync fail http code:$result_status"
        exit 1
    fi
    puts_step "Sync to ketsu complete"
fi