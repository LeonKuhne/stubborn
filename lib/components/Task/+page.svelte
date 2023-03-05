<script>
  import Duration from '$components/Duration/+page.svelte'
  import TaskModel from '$models/Task/script.js'
  export let task = null
  let open = false

  let updates = 0
  const addTask = () => {
    // TODO instead get the task manager from the global model and use it to add a new task
    task.children.push({
      title: 'New task',
      duration: 0,
      children: []
    })
    open = true // expand new subtask
    updates++ // render update
  }
</script>

<template lang="pug">
+if('task')
  .task
    +if('task.children.length')
      button.item('on:click={() => open = !open}') {open ? 'v' : '>'}
    .title {task.title}
    .right
      button.item('on:click={addTask}') +
      Duration(value='{task.duration}')
  +if('open')
    +key('updates')
      +each('task.children as subtask')
        .subtask
          svelte:self(task='{subtask}')
</template>

<style lang="stylus">
.task
  width 100%
  display flex
.item
  display inline-block
  cursor pointer
  margin-right .5rem
  font-family monospace
.subtask
  margin-left .5rem
.title
  display inline-block
  flex 1
  margin-top .25rem
.right
  display inline-block
  max-width fit-content
button
  border none
  outline none
  cursor pointer
  color white
  background transparent
</style>
