#!/bin/sh
set -e

# Replace __API_BASE_URL__ placeholder in the Flutter web index.html
# with the runtime API_BASE_URL value injected by Docker.
if test -n "$API_BASE_URL"; then
  sed -i "s|__API_BASE_URL__|$API_BASE_URL|g" /usr/share/nginx/html/index.html
fi

if test -n "$IU_ALUMNI_BOT_URL"; then
  sed -i "s|__IU_ALUMNI_BOT_URL__|$IU_ALUMNI_BOT_URL|g" /usr/share/nginx/html/index.html
fi

exec nginx -g "daemon off;"
