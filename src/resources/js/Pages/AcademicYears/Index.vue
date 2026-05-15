<script setup>
import { computed } from 'vue';
import { Head, Link, router, usePage } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import Pagination from '@/Components/UI/Pagination.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    academicYears: Object,
});

const page = usePage();
const canManage = computed(() => page.props.auth?.permissions?.manage_academic_years);
const flash = computed(() => page.props.flash || {});

const hasActiveAy = computed(() => props.academicYears?.data?.some(ay => ay.is_active));

function activateBootstrap(ay) {
    if (!confirm(`Tandai ${ay.name} sebagai TA aktif inisial? Setelah ada TA aktif, perubahan harus via Kenaikan Kelas.`)) return;
    router.post(route('academic-years.activate', ay.id), {}, {
        preserveScroll: false,
        replace: false,
    });
}

function destroy(id) {
    if (confirm('Hapus tahun ajaran ini? Pastikan tidak ada kelas yang terkait.')) {
        router.delete(route('academic-years.destroy', id), {}, {
            preserveScroll: false,
            replace: false,
        });
    }
}
</script>

<template>
    <Head title="Tahun Ajaran" />

    <div>
        <!-- Header -->
        <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
                <h2 class="text-xl font-bold text-slate-800">Tahun Ajaran</h2>
                <p class="text-sm text-slate-500 mt-0.5">Kelola tahun ajaran dan semester</p>
            </div>
            <Link v-if="canManage" :href="route('academic-years.create')">
                <Button>
                    <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                    </svg>
                    Tambah Tahun Ajaran
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
                        <th class="px-4 py-3 text-left">Nama</th>
                        <th class="px-4 py-3 text-left">Periode</th>
                        <th class="px-4 py-3 text-left">Status</th>
                        <th class="px-4 py-3 text-left">Semester</th>
                        <th class="px-4 py-3 text-left">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    <tr v-for="ay in academicYears.data" :key="ay.id" class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ ay.name }}</td>
                        <td class="px-4 py-3 text-slate-600 text-sm">
                            {{ ay.start_date }} &ndash; {{ ay.end_date }}
                        </td>
                        <td class="px-4 py-3">
                            <Badge :variant="ay.is_active ? 'success' : 'default'">
                                {{ ay.is_active ? 'Aktif' : 'Tidak Aktif' }}
                            </Badge>
                        </td>
                        <td class="px-4 py-3">
                            <Link
                                :href="route('academic-years.semesters.index', ay.id)"
                                class="text-orange-600 hover:underline text-sm font-medium"
                            >
                                {{ ay.semesters_count }} Semester
                            </Link>
                        </td>
                        <td class="px-4 py-3">
                            <div v-if="canManage" class="flex items-center gap-2 flex-wrap">
                                <span v-if="ay.is_active" class="inline-flex items-center rounded-md bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-700">
                                    Aktif
                                </span>
                                <Link
                                    v-else-if="hasActiveAy"
                                    :href="`/year-transition/create?target_academic_year_id=${ay.id}`"
                                    class="inline-flex items-center rounded-md bg-blue-600 px-2 py-1 text-xs font-medium text-white hover:bg-blue-700"
                                >
                                    Mulai Kenaikan Kelas
                                </Link>
                                <button
                                    v-else
                                    @click="activateBootstrap(ay)"
                                    class="inline-flex items-center rounded-md bg-emerald-600 px-2 py-1 text-xs font-medium text-white hover:bg-emerald-700"
                                >
                                    Tandai Aktif (Inisial)
                                </button>
                                <Link :href="route('academic-years.edit', ay.id)">
                                    <Button size="sm" variant="ghost">Edit</Button>
                                </Link>
                                <Button size="sm" variant="danger" @click="destroy(ay.id)">Hapus</Button>
                            </div>
                            <span v-else class="text-slate-400 text-sm">&ndash;</span>
                        </td>
                    </tr>
                    <tr v-if="!academicYears.data?.length">
                        <td colspan="5" class="px-4 py-12 text-center text-slate-400">
                            Belum ada tahun ajaran.
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div class="mt-6">
            <Pagination :links="academicYears.links" />
        </div>
    </div>
</template>
