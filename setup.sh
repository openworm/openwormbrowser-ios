#!/usr/bin/env bash
# Installs CocoaPods and runs pod install to set up the project
set -euo pipefail

if ! command -v pod >/dev/null 2>&1; then
  echo "Installing CocoaPods..."
  gem install securerandom -v 0.3.2
  gem install cocoapods -v 1.16.2 --no-document
fi

pod install --repo-update --allow-root

echo "Pod installation complete"
