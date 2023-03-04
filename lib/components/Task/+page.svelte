<script>
  import Duration from '$components/Duration/+page.svelte'
  export let task = null
  export let open = false
</script>

<template lang="pug">
+if('task')
  .task
    .expand('on:click={() => open = !open}') {open ? 'v' : '>'}
    span {task.title}
    Duration(value='{task.duration}')
    +if('open')
      +each('task.children as subtask')
        .subtask
          svelte:self(task='{subtask}')
</template>

<style lang="stylus">
.task
  width 100%
.expand
  display inline-block
  cursor pointer
  margin-right .5rem
.subtask
  margin-left .5rem
</style>
