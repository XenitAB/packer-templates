#!/bin/bash
set -e

docker pull ghcr.io/xenitab/github-actions/tools:latest

set +e
LATEST_TAGS=$(curl -s https://github.com/orgs/XenitAB/packages/container/github-actions%2Ftools/versions | grep "Label mr-1 mb-2 text-normal" | sed "s/.*<a .*>\(.*\)<\/a>/\1/g" | sort | tail -n 3)
for TAG in ${LATEST_TAGS}; do
    docker pull ghcr.io/xenitab/github-actions/tools:${TAG}
done
set -e
