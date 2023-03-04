<script>
  let val = ''
</script>

<template lang="pug">
// create an input and bind the val to variable
input(
  type="text"
  bind:value=val
  placeholder="1h"
)
</template>

<style lang="stylus">
input
  width 1rem
  border none
  border-bottom 1px solid grey
  font-size 1rem
input:focus
  outline none
  background-color #eee
</style>
