<script setup>
import { ref, watch, onMounted } from 'vue'

const props = defineProps({
  items: {
    type: Array,
    required: true,
  },
  command: {
    type: Function,
    required: true,
  },
})

const selectedIndex = ref(0)
const scrollContainer = ref(null)

watch(() => props.items, () => {
  selectedIndex.value = 0
})

const onKeyDown = ({ event }) => {
  if (event.key === 'ArrowUp') {
    upHandler()
    return true
  }

  if (event.key === 'ArrowDown') {
    downHandler()
    return true
  }

  if (event.key === 'Enter') {
    enterHandler()
    return true
  }

  return false
}

const upHandler = () => {
  selectedIndex.value = ((selectedIndex.value + props.items.length) - 1) % props.items.length
}

const downHandler = () => {
  selectedIndex.value = (selectedIndex.value + 1) % props.items.length
}

const enterHandler = () => {
  selectItem(selectedIndex.value)
}

const selectItem = (index) => {
  const item = props.items[index]

  if (item) {
    props.command(item)
  }
}

defineExpose({
  onKeyDown,
})
</script>

<template>
  <div class="items bg-white rounded-lg shadow-xl border border-slate-200 overflow-hidden min-w-[200px] p-1">
    <button
      v-for="(item, index) in items"
      :key="index"
      class="flex items-center gap-2 w-full text-left px-3 py-2 text-sm rounded-md transition-colors"
      :class="{ 'bg-slate-100 text-slate-900': index === selectedIndex, 'text-slate-600 hover:bg-slate-50': index !== selectedIndex }"
      @click="selectItem(index)"
    >
      <div v-if="item.icon" class="flex items-center justify-center h-5 w-5 rounded border border-slate-200 bg-white text-slate-500">
         <!-- Simple Icon Rendering (Wait for lucid or similar, or assume SVG passed) -->
         <component :is="item.icon" v-if="typeof item.icon === 'object'" class="w-3 h-3" />
         <!-- Fallback for simple string icons/emojis -->
         <span v-else class="text-xs">{{ item.icon }}</span>
      </div>
      
      <div>
          <p class="font-medium" :class="index === selectedIndex ? 'text-slate-900' : 'text-slate-700'">{{ item.title }}</p>
          <p v-if="item.description" class="text-xs text-slate-400 truncate max-w-[180px]">{{ item.description }}</p>
      </div>
    </button>
  </div>
</template>
