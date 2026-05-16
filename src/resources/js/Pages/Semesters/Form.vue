<script setup>
import { computed } from 'vue';
import { Head, Link, useForm } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import Button from '@/Components/UI/Button.vue';
import FormInput from '@/Components/UI/FormInput.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    academicYear: Object,
    semester: {
        type: Object,
        default: null,
    },
});

const isEditing = computed(() => !!props.semester);

const form = useForm({
    semester_number: props.semester?.semester_number ?? '',
    start_date: props.semester?.start_date ?? '',
    end_date: props.semester?.end_date ?? '',
});

function submit() {
    if (isEditing.value) {
        form.put(route('semesters.update', props.semester.id));
    } else {
        form.post(route('academic-years.semesters.store', props.academicYear.id));
    }
}
</script>

<template>
    <Head :title="isEditing ? 'Edit Semester' : 'Tambah Semester'" />

    <div class="max-w-xl">
        <!-- Breadcrumb -->
        <div class="mb-4 flex items-center gap-2 text-sm text-slate-500">
            <Link :href="route('academic-years.index')" class="hover:text-orange-600">Tahun Ajaran</Link>
            <span>/</span>
            <Link :href="route('academic-years.semesters.index', academicYear.id)" class="hover:text-orange-600">
                {{ academicYear.name }}
            </Link>
            <span>/</span>
            <span>{{ isEditing ? 'Edit Semester' : 'Tambah Semester' }}</span>
        </div>

        <h2 class="mb-6 text-xl font-bold text-slate-800">
            {{ isEditing ? 'Edit Semester' : 'Tambah Semester' }}
        </h2>

        <form @submit.prevent="submit" class="space-y-5 rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">Semester</label>
                <FormSelect v-model="form.semester_number" :error="form.errors.semester_number">
                    <option value="">Pilih Semester</option>
                    <option :value="1">Semester 1</option>
                    <option :value="2">Semester 2</option>
                </FormSelect>
                <p v-if="form.errors.semester_number" class="mt-1 text-sm text-red-600">{{ form.errors.semester_number }}</p>
            </div>

            <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">Tanggal Mulai</label>
                <FormInput
                    v-model="form.start_date"
                    type="date"
                    :error="form.errors.start_date"
                />
                <p v-if="form.errors.start_date" class="mt-1 text-sm text-red-600">{{ form.errors.start_date }}</p>
            </div>

            <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">Tanggal Selesai</label>
                <FormInput
                    v-model="form.end_date"
                    type="date"
                    :error="form.errors.end_date"
                />
                <p v-if="form.errors.end_date" class="mt-1 text-sm text-red-600">{{ form.errors.end_date }}</p>
            </div>

            <div class="flex items-center gap-3 pt-2">
                <Button type="submit" :disabled="form.processing">
                    {{ isEditing ? 'Simpan Perubahan' : 'Buat Semester' }}
                </Button>
                <Link :href="route('academic-years.semesters.index', academicYear.id)">
                    <Button type="button" variant="ghost">Batal</Button>
                </Link>
            </div>
        </form>
    </div>
</template>
