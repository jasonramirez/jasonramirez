#!/usr/bin/env bash
# Render build script. Referenced by render.yaml buildCommand.
set -o errexit

bundle install

# propshaft + dartsass-rails + importmap: assets:precompile runs dartsass:build.
bundle exec rails assets:precompile
bundle exec rails assets:clean
