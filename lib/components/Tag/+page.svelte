<script>
  import Duration from '$components/Duration/+page.svelte'
  export let tag = null
  let movingAverage = '1h'
</script>

<template lang="pug">
+if('tag')
  .tag
    .title {tag.title}
    .options
      Duration(value='{tag.duration}')
      .divider
      Duration(value='{movingAverage}')
</template>

<style lang="stylus">
.tag
  display flex
.options *
  display inline-block
  margin-left .5rem
.divider::before
  content '/'
  margin-left -0.4rem
</style>
