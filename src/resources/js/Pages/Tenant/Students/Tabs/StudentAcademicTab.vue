<script setup>
import { computed } from 'vue';
import Badge from '@/Components/UI/Badge.vue';
import Card from '@/Components/UI/Card.vue';
import { Bar } from 'vue-chartjs';
import { Chart as ChartJS, Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale } from 'chart.js';

ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale);

const props = defineProps({
  student: Object,
  academicHistory: {
    type: Array,
    default: () => []
  }
});

const predicateColor = (p) => p === 'A' ? 'emerald' : p === 'B' ? 'blue' : p === 'C' ? 'amber' : 'rose';

const chartData = computed(() => ({
  labels: props.academicHistory.map(h => h.semester),
  datasets: [{
    label: 'Rata-rata Nilai',
    backgroundColor: '#10b981', // Emerald 500
    borderRadius: 6,
    data: props.academicHistory.map(h => h.average)
  }]
}));

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false }
  },
  scales: {
    y: {
        beginAtZero: true,
        max: 100,
        grid: { color: '#f1f5f9' }
    },
    x: {
        grid: { display: false }
    }
  }
};
</script>

<template>
  <div class="space-y-6">
    <!-- Academic Track Record Chart -->
    <Card v-if="academicHistory && academicHistory.length > 0" title="Track Record Akademik" subtitle="Grafik perkembangan rata-rata nilai per semester">
      <div class="h-64 w-full">
        <Bar :data="chartData" :options="chartOptions" />
      </div>
    </Card>

    <!-- Grade History Table -->
    <Card title="Riwayat Nilai Detail" subtitle="Semua nilai yang telah diinputkan">
      <div v-if="student.grades?.length" class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-slate-100">
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Mata Pelajaran</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Semester</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Nilai Akhir</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Predikat</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="grade in student.grades" :key="grade.id" class="border-b border-slate-50 transition-colors hover:bg-slate-50/50">
              <td class="px-4 py-3 font-medium text-slate-700">{{ grade.subject?.name }}</td>
              <td class="px-4 py-3 text-slate-500">{{ grade.semester?.name ? (grade.semester.academicYear?.name + ' - Sem ' + grade.semester.semester_number) : '-' }}</td>
              <td class="px-4 py-3 font-mono font-semibold text-slate-700">{{ grade.final_score ?? '—' }}</td>
              <td class="px-4 py-3">
                <Badge v-if="grade.predicate" :color="predicateColor(grade.predicate)" size="sm">{{ grade.predicate }}</Badge>
                <span v-else class="text-slate-300">—</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-else class="flex flex-col items-center gap-2 py-8">
        <span class="text-3xl">📝</span>
        <p class="text-sm text-slate-500">Belum ada riwayat nilai</p>
      </div>
    </Card>
  </div>
</template>
