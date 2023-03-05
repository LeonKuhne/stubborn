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
      button.expand('on:click={() => open = !open}') {open ? 'v' : '>'}
      +else()
        button.add('on:click={addTask}') +
    span {task.title}
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
.add, .expand
  display inline-block
  cursor pointer
  margin-right .5rem
.subtask
  margin-left .5rem
</style>
