<script>
  export let value = '1h'
</script>

<template lang="pug">
// create an input and bind the val to variable
input(
  type="text"
  'bind:value={value}'
  placeholder="1h"
)
</template>

<style lang="stylus">
input
  width 1.25rem
  border none
  border-bottom 1px solid grey
  font-size 1rem
  font-family monospace
input:focus
  outline none
  background-color #eee
</style>
