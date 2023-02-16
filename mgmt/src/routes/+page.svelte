<script>
  export const prerender = true
</script>

<template lang="pug">
.app 
  .debug routes/+page.svelte
  p HelloWorlds
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
