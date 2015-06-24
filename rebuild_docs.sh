#!/bin/bash

set -o errexit -o nounset

rev=$(git rev-parse --short HEAD)

ldoc -d $CIRCLE_ARTIFACTS/docs .

cd $CIRCLE_ARTIFACTS/docs

git init
git config user.name "Kyle McLamb"
git config user.email "kjmclamb@gmail.com"

git remote add upstream "https://$GH_API@github.com/Alloyed/ltrie.git"
git fetch upstream
git reset upstream/gh-pages

git add -A .
git commit -m "rebuild pages at ${rev}"
git push -q upstream HEAD:gh-pages

rm -rf .git
