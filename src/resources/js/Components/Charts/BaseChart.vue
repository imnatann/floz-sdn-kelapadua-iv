<script setup>
import { defineAsyncComponent, computed } from 'vue';

const ApexChart = defineAsyncComponent({
  loader: () => import('vue3-apexcharts'),
  ssr: false,
});

const props = defineProps({
  type: {
    type: String,
    default: 'bar',
    validator: (v) => ['bar', 'line', 'pie', 'donut', 'area'].includes(v),
  },
  series: {
    type: Array,
    default: () => [],
  },
  options: {
    type: Object,
    default: () => ({}),
  },
  height: {
    type: [Number, String],
    default: 300,
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const mergedOptions = computed(() => ({
  chart: {
    fontFamily: 'Inter, sans-serif',
    toolbar: { show: false },
    ...props.options?.chart,
  },
  colors: ['#f97316', '#fb923c', '#fdba74', '#fed7aa', '#ffedd5'],
  theme: {
    mode: 'light',
  },
  xaxis: {
    labels: {
      style: { fontSize: '12px', colors: '#64748b' },
    },
    ...props.options?.xaxis,
  },
  yaxis: {
    labels: {
      style: { fontSize: '12px', colors: '#64748b' },
    },
    ...props.options?.yaxis,
  },
  legend: {
    fontFamily: 'Inter, sans-serif',
    fontSize: '13px',
    ...props.options?.legend,
  },
  tooltip: {
    theme: 'light',
    ...props.options?.tooltip,
  },
  ...props.options,
  chart: {
    fontFamily: 'Inter, sans-serif',
    toolbar: { show: false },
    ...(props.options?.chart || {}),
  },
}));
</script>

<template>
  <div class="w-full">
    <!-- Loading skeleton -->
    <div v-if="loading" class="animate-pulse space-y-3" :style="`height: ${height}px`">
      <div class="h-full w-full rounded-xl bg-slate-100" />
    </div>

    <!-- Chart -->
    <Suspense v-else>
      <ApexChart
        :type="type"
        :series="series"
        :options="mergedOptions"
        :height="height"
        class="w-full"
      />
      <template #fallback>
        <div class="flex items-center justify-center rounded-xl bg-slate-50" :style="`height: ${height}px`">
          <span class="text-sm text-slate-400">Memuat grafik...</span>
        </div>
      </template>
    </Suspense>
  </div>
</template>
