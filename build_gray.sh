#!/bin/bash
set -e
export HOME=`pwd`

BINARY_DIR=$HOME/binary

git clone https://github.com/v2fly/gray.git
cd gray
GITVER=$(git describe --tags || git rev-parse --short HEAD)
go get -v -t -d ./...
mkdir -p $BINARY_DIR

GOOS=windows GOARCH=amd64 go build -ldflags="-s -w -X main.MAINVER=${GITVER}" -v -o $BINARY_DIR/gray_amd64_windows.exe .
GOOS=windows GOARCH=386 go build -ldflags="-s -w -X main.MAINVER=${GITVER}" -v -o $BINARY_DIR/gray_386_windows.exe .
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w -X main.MAINVER=${GITVER}" -v -o $BINARY_DIR/gray_amd64_linux .
GOOS=linux GOARCH=386 go build -ldflags="-s -w -X main.MAINVER=${GITVER}" -v -o $BINARY_DIR/gray_386_linux .

pack_and_upload() {
  echo 'Uploading artifacts...'
  cd $BINARY_DIR
  local build_time=`date +"%Y%m%d%H%M%S"`
  tar --owner=0 --group=0 -cJf "$HOME/gray.tar.xz" *
  curl -T "$HOME/gray.tar.xz" "https://transfer.sh/gray-$build_time.$GITVER.tar.xz"
  echo
  [ -n "$TELEGRAM_BOTOKEN" ] && curl -s \
    -F "chat_id=${TELEGRAM_BOTOKEN#*/}" \
    -F "document=@$HOME/gray.tar.xz" \
    -F "caption=GRay-$build_time.$GITVER" \
    "https://api.telegram.org/bot${TELEGRAM_BOTOKEN%/*}/sendDocument" >/dev/null
  [ -n "$TERACLOUD_TOKEN" ] && curl -s -u "${TERACLOUD_TOKEN%@*}" -T "$HOME/gray.tar.xz" \
    "https://${TERACLOUD_TOKEN#*@}/dav/artifacts/gray-$build_time.$GITVER.tar.xz" >/dev/null
}

cd $BINARY_DIR
if [ "$(ls -A .)" ]; then
  echo 'Build finished.'
  ls -hl
  [ -n "$SHARE_ARTIFACTS" ] && pack_and_upload || true
  exit 0
fi

echo 'No build found at release directory!'
exit 1
