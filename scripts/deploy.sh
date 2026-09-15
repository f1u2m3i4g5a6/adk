#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
firebase deploy --only firestore:rules,hosting
