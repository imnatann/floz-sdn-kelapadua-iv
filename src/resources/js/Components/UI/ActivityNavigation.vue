<script setup>
import { computed } from 'vue';
import { router } from '@inertiajs/vue3';
import Button from '@/Components/UI/Button.vue';

const props = defineProps({
  meeting: {
    type: Object,
    required: false,
    default: null,
  },
  currentActivityId: {
    type: [Number, String],
    required: true,
  },
  currentActivityType: {
    type: String, // 'material' or 'assignment'
    required: true,
  }
});

// Combine materials and assignments into a single timeline/list to find Prev/Next
const activities = computed(() => {
  let list = [];
  if (props.meeting?.materials) {
    props.meeting.materials.forEach(m => {
      list.push({ ...m, itemType: 'material' });
    });
  }
  if (props.meeting?.assignments) {
    props.meeting.assignments.forEach(a => {
      list.push({ ...a, itemType: 'assignment' });
    });
  }
  return list;
});

// Find current index to determine Prev/Next navigation
const currentIndex = computed(() => {
  return activities.value.findIndex(a => a.itemType === props.currentActivityType && a.id == props.currentActivityId);
});

const prevActivity = computed(() => {
  if (currentIndex.value > 0) return activities.value[currentIndex.value - 1];
  return null;
});

const nextActivity = computed(() => {
  if (currentIndex.value !== -1 && currentIndex.value < activities.value.length - 1) {
    return activities.value[currentIndex.value + 1];
  }
  return null;
});

const navigateTo = (activity) => {
  if (!activity) return;
  if (activity.itemType === 'material') {
    router.visit(`/tenant/materials/${activity.id}`);
  } else if (activity.itemType === 'assignment') {
    router.visit(`/tenant/assignments/${activity.id}`);
  }
};

// Handle navigating from select dropdown
const jumpToActivity = (event) => {
  const value = event.target.value;
  if (!value) return;
  const [type, id] = value.split('-');
  if (type === 'material') {
    router.visit(`/tenant/materials/${id}`);
  } else {
    router.visit(`/tenant/assignments/${id}`);
  }
};
</script>

<template>
  <div v-if="meeting" class="bg-slate-50 border-t border-slate-200 px-6 py-4 flex flex-col sm:flex-row items-center justify-between gap-4 flex-shrink-0 z-10 shadow-sm w-full">
    
    <!-- Prev Button -->
    <Button 
      :disabled="!prevActivity" 
      @click="navigateTo(prevActivity)"
      variant="secondary" 
      class="w-full sm:w-auto flex items-center justify-center gap-2"
      :class="{ 'opacity-50 cursor-not-allowed': !prevActivity }"
    >
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path></svg>
      Kegiatan Sebelumnya
    </Button>

    <!-- Jump To Select (shows all items in sequence) -->
    <div class="flex-1 w-full max-w-sm">
      <select 
        class="w-full bg-white border border-slate-300 rounded-lg px-4 py-2 text-sm focus:ring-1 focus:ring-blue-500 focus:border-blue-500 outline-none truncate"
        @change="jumpToActivity"
      >
        <option value="" disabled>Lompat ke kegiatan...</option>
        <option 
          v-for="idx in activities" 
          :value="`${idx.itemType}-${idx.id}`" 
          :key="`${idx.itemType}-${idx.id}`"
          :selected="idx.itemType === currentActivityType && idx.id == currentActivityId"
        >
         {{ idx.itemType === 'material' ? 'Materi' : 'Tugas' }}: {{ idx.title }}
        </option>
      </select>
    </div>

    <!-- Next Button -->
    <Button 
      :disabled="!nextActivity" 
      @click="navigateTo(nextActivity)"
      variant="secondary" 
      class="w-full sm:w-auto flex items-center justify-center gap-2"
      :class="{ 'opacity-50 cursor-not-allowed': !nextActivity }"
    >
      Kegiatan Berikutnya
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
    </Button>

  </div>
</template>
