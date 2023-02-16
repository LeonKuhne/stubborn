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
function tell() { info "$1" | indent "${C_CRIT}|$C_RESET " }
function fail() { err "$1" | indent "${C_ALERT}x$C_RESET " }

function verify() {
  if [ $# -ne 2 ]; then
    echo "usage: stub <file.stub> <output directory>"
  elif [ ! -f $1 ]; then
    echo "stub file not found"
  elif [ -d $2 ]; then
    echo "output directory already exists"
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
  tell "scafolding ./$PROJECT"
  npm init @svelte-add/kit@latest $PROJECT -- --demos false

  tell "adding preprocess to svelte.config.js"
  sed -i '' "1s/^/import preprocess from 'svelte-preprocess'\n/" $PROJECT/svelte.config.js
  sed -i '' "s/config = {/config = {\n\tpreprocess: preprocess({}),/" $PROJECT/svelte.config.js

  tell "adding aliases to svelte.config.js"
  sed -i '' "1s/^/import path from 'path'\n/" $PROJECT/svelte.config.js
  sed -i '' "s!kit: {!kit: {\n\
    alias: {\n\
      \$components: path.resolve('/src/components'),\n\
    },!" $PROJECT/svelte.config.js
}

function stub-install() {
  tell "initializing project and installing dependencies"
  (
    cd $PROJECT;
    npm install --save-dev -y svelte-preprocess pug sass
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

<style lang="sass">
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

function nav() {
  cat << EOF
<script>
  let options = [
    { name: "root", href: "/" },
  ]
</script>

<template lang="pug">
  nav
    ul
      +each('options as option')
        li
          a(href="{option.href}") {option.name}
  slot
</template>

<style lang="sass">

</style>
EOF
}

#
# COMMAND PARSERS
# 
# pages
#  / relative url
# items
#  - nested components
#  + static text/media
#  > links and buttons
#  = text input fields
# item modifiers
#  < zero or many
#  ? optional 
# multiple items
#  | or 

function stub-file() {
  tell "recreating src/routes/+page.svelte"
  template "$PROJECT" > $PROJECT/src/routes/+page.svelte

  tell "adding root layout"
  NAV_URL=$PROJECT/src/routes/+layout.svelte
  nav > $NAV_URL

  tell "creating components directory"
  mkdir $PROJECT/src/components

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

    # parse components (start with string)
    if [[ $NEXT_LINE == [a-zA-Z]* ]]; then
      stub-file-create-component
      continue
    fi

    # verify path set
    if [ -n "$PATH_URL" ]; then
      stub-page-item 
    else
      fail "no page context: $PATH_URL $NEXT_LINE"
    fi
  done < $STUB_FILE
}

function stub-file-create-page() {
  new_page_name=$(pascalCase "${NEXT_LINE:1}")
  PATH_URL=./$PROJECT/src/routes/$new_page_name
  # create page
  tell "creating page $PATH_URL"
  mkdir $PATH_URL
  # create svelte template
  template "routes/$new_page_name" > "$PATH_URL/+page.svelte"
  # add page to nav in layout
  sed -i '' "s/\(options = \[.*\)/\1\n\t\t{ name: \"$new_page_name\", href: \"\/$new_page_name\" },/" $NAV_URL
}

function stub-file-create-component() {
  new_component_name=$(pascalCase "$NEXT_LINE")
  PATH_URL=./$PROJECT/src/components/$new_component_name
  # create component
  tell "creating component $new_component_name"
  mkdir $PATH_URL
  # create svelte template
  template "components/$new_component_name" > "$PATH_URL/+page.svelte"
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

# add controls with variable bind
function stub-command-input() {
  case $LINE_MOD in
    \?)
      insert-script "let $LINE_CONTENT = '$LINE_CONTENT'";
      insert-content "input(bind:value=\"{$LINE_CONTENT}\")";
    ;;
    \<) fail "not implemented" ;;
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
      insert-content "  a(href=\"http://test.url\") $LINE_CONTENT" 
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
  sed -i '' "s!\(</template>\)!  $1\n\1!g" "$PATH_URL/+page.svelte"
}

# add script to svelte file
# 1: content
function insert-script() {
  sed -i '' "s!\(</script>\)!  $1\n\1!g" "$PATH_URL/+page.svelte"
}

#
# FIN

stub-run $@