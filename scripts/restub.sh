stubFile="$1"
projectName="$2"

if [ -d "$projectName" ]; then
  info "removing old project"
  rm -rf "$projectName"
fi

echo "dir: $0"
. "$0/stub.sh" "$stubFile" "$projectName"
