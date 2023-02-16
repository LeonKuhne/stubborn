stubFile="$1"
projectName="$2"

if [ -d "$projectName" ]; then
  info "removing old project"
  rm -rf "$projectName"
fi

. ./stub.sh "$stubFile" "$projectName"
