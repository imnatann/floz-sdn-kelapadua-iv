<script setup>
import { computed, ref } from 'vue';
import { Head, Link, router, usePage } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import CarryOverConfirmModal from './CarryOverConfirmModal.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    academicYear: Object,
    semesters: Array,
});

const page = usePage();
const canManage = computed(() => page.props.auth?.permissions?.manage_academic_years);
const flash = computed(() => page.props.flash || {});

const showModal = ref(false);
const targetSemester = ref(null);

const openActivateModal = (semester) => {
    targetSemester.value = semester;
    showModal.value = true;
};

function destroy(sem) {
    if (confirm(`Hapus Semester ${sem.semester_number}? Pastikan tidak ada nilai atau rapor yang terkait.`)) {
        router.delete(route('semesters.destroy', sem.id));
    }
}
</script>

<template>
    <Head :title="`Semester — ${academicYear.name}`" />

    <div>
        <!-- Breadcrumb -->
        <div class="mb-4 flex items-center gap-2 text-sm text-slate-500">
            <Link :href="route('academic-years.index')" class="hover:text-orange-600">Tahun Ajaran</Link>
            <span>/</span>
            <span class="font-medium text-slate-700">{{ academicYear.name }}</span>
            <span>/</span>
            <span>Semester</span>
        </div>

        <!-- Header -->
        <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
                <h2 class="text-xl font-bold text-slate-800">Semester — {{ academicYear.name }}</h2>
                <p class="text-sm text-slate-500 mt-0.5">Kelola semester untuk tahun ajaran ini</p>
            </div>
            <Link
                v-if="canManage && semesters.length < 2"
                :href="route('academic-years.semesters.create', academicYear.id)"
            >
                <Button>
                    <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                    </svg>
                    Tambah Semester
                </Button>
            </Link>
        </div>

        <!-- Flash -->
        <div v-if="flash.success" class="mb-4 flex items-center gap-2 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
            {{ flash.success }}
        </div>
        <div v-if="flash.error" class="mb-4 flex items-center gap-2 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {{ flash.error }}
        </div>

        <!-- Table -->
        <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
            <table class="min-w-full divide-y divide-slate-100">
                <thead class="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <tr>
                        <th class="px-4 py-3 text-left">Semester</th>
                        <th class="px-4 py-3 text-left">Periode</th>
                        <th class="px-4 py-3 text-left">Status</th>
                        <th class="px-4 py-3 text-left">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    <tr v-for="sem in semesters" :key="sem.id" class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-medium text-slate-800">Semester {{ sem.semester_number }}</td>
                        <td class="px-4 py-3 text-slate-600 text-sm">
                            {{ sem.start_date }} &ndash; {{ sem.end_date }}
                        </td>
                        <td class="px-4 py-3">
                            <Badge :variant="sem.is_active ? 'success' : 'default'">
                                {{ sem.is_active ? 'Aktif' : 'Tidak Aktif' }}
                            </Badge>
                        </td>
                        <td class="px-4 py-3">
                            <div v-if="canManage" class="flex items-center gap-2 flex-wrap">
                                <Button
                                    v-if="!sem.is_active"
                                    size="sm"
                                    variant="outline"
                                    @click="openActivateModal(sem)"
                                >
                                    Aktifkan
                                </Button>
                                <Link :href="route('semesters.edit', sem.id)">
                                    <Button size="sm" variant="ghost">Edit</Button>
                                </Link>
                                <Button size="sm" variant="danger" @click="destroy(sem)">Hapus</Button>
                            </div>
                            <span v-else class="text-slate-400 text-sm">&ndash;</span>
                        </td>
                    </tr>
                    <tr v-if="!semesters?.length">
                        <td colspan="4" class="px-4 py-12 text-center text-slate-400">
                            Belum ada semester untuk tahun ajaran ini.
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div class="mt-4">
            <Link :href="route('academic-years.index')" class="text-sm text-slate-500 hover:text-orange-600">
                &larr; Kembali ke Tahun Ajaran
            </Link>
        </div>
    </div>

    <CarryOverConfirmModal :show="showModal" :semester="targetSemester" @close="showModal = false" />
</template>
