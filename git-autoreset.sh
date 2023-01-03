# #! /usr/bin/env sh

set -x

default_branch=$(git remote show origin | awk -F:\  '/HEAD branch: / { print $2 }')

git fetch origin --prune

checked_out_branch=$(git rev-parse --abbrev-ref HEAD)

if [ "$default_branch" != "$checked_out_branch" ]; then
    git update-ref -m reset\:\ robot\ moving\ to\ origin/$default_branch refs/heads/$default_branch origin/$default_branch
fi
