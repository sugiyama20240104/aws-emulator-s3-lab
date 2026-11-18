#!/bin/sh
set -eu
bucket=my-study-bucket
key=photos/cat.jpg
account=$(aws sts get-caller-identity --query Account --output text)
[ "$account" = "000000000000" ] || { echo "Unexpected emulator account: $account" >&2; exit 1; }
echo "Emulator account: $account"
if ! aws s3api head-bucket --bucket "$bucket" 2>/dev/null; then
  aws s3 mb "s3://$bucket"
fi
aws s3 cp /opt/lab/cat.jpg "s3://$bucket/$key"
echo 'Object keys:'
aws s3api list-objects-v2 --bucket "$bucket" --query 'Contents[].Key' --output text
echo 'With / as the delimiter:'
aws s3api list-objects-v2 --bucket "$bucket" --delimiter / --query 'CommonPrefixes[].Prefix' --output text
file=$(mktemp)
trap 'rm -f "$file"' EXIT
aws s3 cp "s3://$bucket/$key" "$file"
original=$(sha256sum /opt/lab/cat.jpg)
retrieved=$(sha256sum "$file")
[ "${original%% *}" = "${retrieved%% *}" ] || { echo 'Downloaded bytes differ' >&2; exit 1; }
echo "OK: photos/cat.jpg matches the original."
