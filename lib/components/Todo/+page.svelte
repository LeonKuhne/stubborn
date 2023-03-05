<script>
  import Task from '$components/Task/+page.svelte'
  let tasks = [{
    title: 'Todo #1',
    duration: '2h',
    children: [{
      title: 'Subitem #1',
      duration: '1h',
      children: []
    }]
  }, {
    title: 'Todo #2',
    duration: '1h',
    children: [
      {
        title: 'Subitem #1',
        duration: '1h',
        children: []
      },
      {
        title: 'Subitem #2',
        duration: '1h',
        children: []
      }
    ]
  }]
</script>

<template lang="pug">
h2 Todo
div
  +each('tasks as task')
    Task(task='{task}')
</template>

<style lang="stylus">
</style>
