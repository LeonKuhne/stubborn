<script>
  import Task from '$components/Task/+page.svelte'
  let tasks = [{
    title: 'Todo #1',
    duration: '2h',
    children: [
      {
        title: 'Subitem #1',
        duration: '1h',
        children: []
      }
    ]
  }]
</script>

<template lang="pug">
.app 
  .debug components/Todo/+page.svelte
  +each('tasks as task')
    Task(task='{task}')
</template>

<style lang="stylus">
.app
  padding 10px
  border 1px solid grey
  color red
.debug
  color green
.app > *
  padding-left 10px
  margin 0
  display inline-block
</style>
