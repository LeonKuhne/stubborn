<script>
  import Tag from '$components/Tag/+page.svelte'
  let tags = [{
    title: 'Tag #1',
    duration: '2h',
  }, {
    title: 'Tag #2',
    duration: '1h',
  }]
</script>

<template lang="pug">
h2 Labels
div 
  +each('tags as tag')
    Tag(tag='{tag}')
</template>

<style lang="stylus">
</style>
