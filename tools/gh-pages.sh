#!/usr/bin/env bash
SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR/../docs
git init
git add -A
git commit -m "Deploy: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
git remote add origin ssh://git@github.com/nqou-net/www.nqou.net.git
git push --force origin HEAD:gh-pages
