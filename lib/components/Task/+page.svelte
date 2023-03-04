<script>
  import Duration from '$components/Duration/+page.svelte'
  export let task = null
</script>

<template lang="pug">
+if('task')
  .task
    span {task.title}
    Duration(value='{task.duration}')
    +each('task.children as subtask')
      .subtask
        svelte:self(task='{subtask}')
</template>

<style lang="stylus">
.task
  width 100%
.task::before
  content '>'
  margin-right .5rem
.subtask
  margin-left .5rem
</style>
