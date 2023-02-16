#!/bin/bash

# 
# MAIN

function stub-run() {
  notice "STUBBORN" | indent "${C_TITLE}*$C_RESET "

  # verify params
  stub-verify $@ || return 1
  STUB_FILE=$1
  PROJECT=$2

  # run stages
  stub-setup
  stub-file
  stub-install
  stub-start
}

#
# HELPERS

# use a bullet to indicate the start
function tell() { info "$1" | indent "${C_TITLE}|$C_RESET " }
function wiggle() { warn "$1" | indent "${C_CRIT}v$C_RESET " }
function fail() { err "$1" | indent "${C_ALERT}x$C_RESET " }

function verify() {
  if [ $# -ne 2 ]; then
    echo "usage: stub <file.stub> <output directory>"
  elif [ ! -f $1 ]; then
    echo "stub file not found"
  fi
}

function pascalCase() {
  echo "$1" | perl -pe 's/(?:\b|_)(\p{Ll})/\u$1/g' | sed 's/ //g'
}

function lowercase() {
  echo "$(tr '[:upper:]' '[:lower:]' <<< "${1:0:1}")${1:1}"
}

#
# BUILD STAGES

function stub-verify () {
  tell "verifying params"
  error=$(verify $@)
  if [ -n "$error" ]; then 
    fail "$error"
    return 1
  fi
  return 0
}


function stub-setup() {
  # skip if project exists
  if [ -d $PROJECT ]; then
    fail "project already exists: $PROJECT"
    return
  fi
  tell "scafolding ./$PROJECT"
  npm init @svelte-add/kit@latest $PROJECT -- --demos false

  tell "adding preprocess to svelte.config.js"
  sed -i '' "1s/^/import preprocess from 'svelte-preprocess'\n/" $PROJECT/svelte.config.js
  sed -i '' "s/config = {/config = {\n\tpreprocess: preprocess({\n\
    \n\
}),/" $PROJECT/svelte.config.js

  tell "adding aliases to svelte.config.js"
  sed -i '' "1s/^/import path from 'path'\n/" $PROJECT/svelte.config.js
  sed -i '' "s!kit: {!kit: {\n\
    alias: {\n\
      \$components: path.resolve('/src/components'),\n\
    },!" $PROJECT/svelte.config.js

  tell "creating components directory"
  mkdir $PROJECT/src/components

  rm $PROJECT/src/routes/+page.svelte

}

function stub-install() {
  tell "installing dependencies"
  (
    cd $PROJECT;
    npm install --save-dev -y svelte-preprocess pug stylus
    npx -y svelte-add@latest Leftium/pug-adder
    npm install
  )
}

function stub-start() {
  tell "starting the app"
  (cd $PROJECT; npm run dev -- --open)
}

#
# STARTER TEMPLATES

function template() {
  cat << EOF
<script>
</script>

<template lang="pug">
.app 
  .debug $1
</template>

<style lang="stylus">
.app
  padding: 10px
  border: 1px solid grey
  color: red
.debug
  color: green
.app > *
  padding-left: 10px
  margin: 0
  display: inline-block
</style>
EOF
}

#
# COMMAND PARSERS
# 
# headers
#  / page
#  * layout  
#  component
# items
#  - nested components
#  + static text/media
#  @ static link
#  > dynamic links/buttons
#  = text input fields
#  $ regular element
# item modifiers
#  < zero or many
#  ? optional 
# multiple items
#  | or 

function stub-file() {
  tell "parsing stub file for pages"
  PATH_URL=""
  while read line; do

    # reset page context on empty lines
    if [ -z "$line" ] || [ ]; then
      PATH_URL=""
      continue
    fi

    # ignore comments
    if [[ $line == \#* ]]; then
      continue
    fi

    # replace all but first whitespaces with pascalCases
    NEXT_LINE="$line"

    # parse pages (start with /)
    if [[ $NEXT_LINE == \/* ]]; then
      stub-file-create-page
      continue
    fi

    # parse layouts (start with *)
    if [[ $NEXT_LINE == \** ]]; then
      stub-file-create-layout
      continue
    fi

    # parse components (start with string)
    if [[ $NEXT_LINE == [a-zA-Z]* ]]; then
      stub-file-create-component
      continue
    fi

    # verify path set
    if [ -n "$PATH_URL" ]; then
      stub-page-item 
    else
      wiggle "no page context: $PATH_URL $NEXT_LINE"
    fi
  done < $STUB_FILE
}

function stub-template() {
  PATH_URL="./$PROJECT/src/$1"
  # create directory if doesn't exist
  if [ ! -d $(dirname $PATH_URL) ]; then
    mkdir $(dirname $PATH_URL)
  fi
  # use existing
  if [ -f $PATH_URL ]; then
    fail "file already exists: $PATH_URL"
    PATH_URL=""
  # use mirror 
  elif [ -f "./lib/$1" ]; then
    tell "mirroring $1"
    cat "./lib/$1" > $PATH_URL
    PATH_URL=""
  # create file
  elif [ ! -f $PATH_URL ]; then
    tell "creating $1"
    template "$1" > $PATH_URL
  fi
}

function stub-file-create-layout() {
  new_layout_path=$(pascalCase "${NEXT_LINE:1}")
  if [ -z "$new_layout_path" ]; then
    stub-template "routes/+layout.svelte"
    continue
  fi
  stub-template "routes/$new_layout_path/+layout.svelte"
}

function stub-file-create-page() {
  new_page_path=$(pascalCase "${NEXT_LINE:1}")
  if [ -z "$new_page_path" ]; then
    stub-template "routes/+page.svelte"
    continue
  fi
  stub-template "routes/$(pascalCase "$new_page_path")/+page.svelte"
}

function stub-file-create-component() {
  stub-template "components/$(pascalCase $NEXT_LINE)/+page.svelte"
}

function stub-page-item() {
  # parse arguments from line
  cmd=${NEXT_LINE:0:1}
  LINE_MOD=${NEXT_LINE:1:1}
  if [[ $LINE_MOD == ' ' ]]; then
    content=${NEXT_LINE:2}
  else
    content=${NEXT_LINE:3}
  fi
  LINE_CONTENT=$(pascalCase $content)

  # loop through each pipes
  for LINE_CONTENT in $(echo $LINE_CONTENT | tr "|" "\n"); do
    stub-command $cmd
  done
}

function stub-command() {
  case $1 in
    -) stub-command-component ;;
    +) stub-command-static ;;
    =) stub-command-input ;;
    \>) stub-command-link ;;
    \$) stub-command-element ;;
    \@) stub-command-link-static ;;
    *) fail "unknown command $1" ;;
  esac
}

#
# ADDER SYSTEMS

function stub-command-component() {
  import-script "$LINE_CONTENT"
  case $LINE_MOD in
    \?) 
      componentOptionVar="is$LINE_CONTENT"
      insert-script "let $componentOptionVar = true"
      insert-content "+if('$componentOptionVar')"
      insert-content "  $LINE_CONTENT"
    ;;
    \<) 
      componentOptionVar="$(lowercase $LINE_CONTENT)"
      componentOptionsVar="${componentOptionVar}s"
      insert-script "let $componentOptionsVar = ['one', 'two', 'three']"
      insert-content "+each('$componentOptionsVar as $componentOptionVar')"
      insert-content "  $LINE_CONTENT {$componentOptionVar}"
    ;;
    *) 
      insert-content "$LINE_CONTENT"
    ;;
  esac
}

# add static content
function stub-command-static() {
  case $LINE_MOD in
    \?) 
      listOptionVar="is$LINE_CONTENT"
      insert-script "let $listOptionVar = true"
      insert-content "+if('$listOptionVar')"
      insert-content "  p $listOptionVar"
    ;;
    \<) 
      listOptionVar="$(lowercase $LINE_CONTENT)"
      listOptionsVar="${listOptionVar}s"
      insert-script "let $listOptionsVar = ['one', 'two', 'three']"
      insert-content "+each('$listOptionsVar as $listOptionVar')"
      insert-content "  p $LINE_CONTENT {$listOptionVar}" 
    ;;
    *) insert-content "p $LINE_CONTENT" ;;
  esac
}

# add static component
function stub-command-element() {
  case $LINE_MOD in
    \?) fail "not implemented optional element" ;;
    \<) fail "not implemented many elements" ;;
    *) insert-content "$(lowercase $LINE_CONTENT)" ;;
  esac
}

# add controls with variable bind
function stub-command-input() {
  case $LINE_MOD in
    \?)
      inputOptionVar="is$LINE_CONTENT"
      inputVar="$(lowercase $LINE_CONTENT)"
      insert-script "let $inputVar = '$LINE_CONTENT'";
      insert-script "let $inputOptionVar = true"
      insert-content "+if('$inputOptionVar')"
      insert-content "  input(bind:value=\"{$inputVar}\")"
    ;;
    \<) fail "not implemented many inputs" ;;
    *)
      inputVar="$(lowercase $LINE_CONTENT)"
      insert-script "let $inputVar = '$LINE_CONTENT'";
      insert-content "input(bind:value=\"{$inputVar}\")";
    ;;
  esac
}

# add links
function stub-command-link() {
  case $LINE_MOD in
    \?)
      linkOptionVar="is$LINE_CONTENT"
      insert-script "let $linkOptionVar = true"
      insert-content "+if('$linkOptionVar')"
      insert-content "  a(href=\"/$LINE_CONTENT\") $LINE_CONTENT"
    ;;
    \<)
      linkOptionVar="$(lowercase $LINE_CONTENT)"
      linkOptionKey="${linkOptionVar}Key"
      linkOptionsVar="${linkOptionVar}s"
      insert-script "let $linkOptionsVar = {\n\
'one': https://one.url, \n\
'two': https://two.url, \n\
'three': https://three.url \n\
}"
      insert-content "+each('Object.entries($linkOptionsVar) as [$lineOptionKey, $linkOptionVar]')"
      insert-content "  a(href=\"/$linkOptionVar\") {$linkOptionsKey}"
    ;;
    *) insert-content "a(href=\"/$LINE_CONTENT\") $LINE_CONTENT" ;;
  esac
}

function stub-command-link-static() {
  case $LINE_MOD in
    \?) fail "not implemented optional static link" ;;
    \<) fail "not implemented many static links" ;;
    *) insert-content "a(href=\"http://sample.url\") $LINE_CONTENT" ;;
  esac
}

#
# FILE UPDATERS

# add component import to svelte file
# 1: component name
function import-script() {
  insert-script "import $1 from '\$components/$1/+page.svelte'"
}

# add layout to svelte file
# 1: content
function insert-content() {
  sed -i '' "s!\(</template>\)!  $1\n\1!g" $PATH_URL
}

# add script to svelte file
# 1: content
function insert-script() {
  sed -i '' "s!\(</script>\)!  $1\n\1!g" $PATH_URL
}

#
# FIN

stub-run $@