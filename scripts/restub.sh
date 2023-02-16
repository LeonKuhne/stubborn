stubFile="$1"
projectName="$2"

if [ -d "$projectName" ]; then
  info "removing old project"
  rm -rf "$projectName"
fi

. "$(dirname $0)/stub.sh" "$stubFile" "$projectName"
