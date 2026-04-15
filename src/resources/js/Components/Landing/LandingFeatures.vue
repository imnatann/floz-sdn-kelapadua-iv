<script setup>
import { Link } from '@inertiajs/vue3';
import MastraBox from '@/Components/Landing/MastraBox.vue';
import RadialProgress from '@/Components/Landing/RadialProgress.vue';

// No script logic needed for now, handled by template
</script>

<template>
    <div class="relative z-20 bg-[#09090b] text-white pt-24 pb-32 overflow-hidden px-4 md:px-8">
        
        <!-- Header Section -->
        <div class="max-w-7xl mx-auto mb-20 text-center">
            <span class="text-xs font-mono text-orange-500 tracking-widest uppercase mb-4 block">
                SISTEM MANAJEMEN SEKOLAH TERINTEGRASI
            </span>
            <h2 class="text-4xl md:text-6xl font-bold tracking-tighter text-white mb-6">
                Satu Platform.<br />
                <span class="text-slate-500">Kontrol Tanpa Batas.</span>
            </h2>
            <p class="text-slate-400 text-lg max-w-2xl mx-auto">
                FLOZ LMS mengubah cara sekolah beroperasi. Dari manajemen siswa hingga laporan keuangan, semua terhubung dalam satu ekosistem "Anti-Grid" yang mulus.
            </p>
        </div>

        <!-- Anti-Grid Layout Container -->
        <!-- We use a specifically crafted grid to enable the 'connected' look -->
        <div class="max-w-[1200px] mx-auto grid grid-cols-1 md:grid-cols-12 gap-[var(--gap)] auto-rows-[minmax(100px,auto)]">
            
            <!-- TOP ROW -->
            <!-- Box 1: Student Management (Top Left) -->
            <MastraBox class="md:col-span-4 h-64 p-8" 
                :curveBottomRight="true" 
                :connectBottom="true"
            >
                <div class="h-full flex flex-col justify-between">
                    <div class="w-10 h-10 rounded bg-orange-500/10 flex items-center justify-center text-orange-500">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path></svg>
                    </div>
                    <div>
                        <h3 class="text-xl font-bold mb-2">Kesiswaan</h3>
                        <p class="text-slate-400 text-sm">Database siswa terpusat dengan riwayat lengkap.</p>
                    </div>
                </div>
            </MastraBox>

            <!-- Box 2: Teacher Tools (Top Middle - Spans 2 cols visually, but distinct structure) -->
             <MastraBox class="md:col-span-8 h-64 p-8 relative overflow-hidden group"
                :curveBottomLeft="true"
                :connectBottom="true"
             >
                <div class="absolute inset-0 bg-gradient-to-br from-blue-900/10 to-transparent opacity-50 group-hover:opacity-100 transition-opacity"></div>
                <div class="relative z-10 flex flex-col md:flex-row items-center h-full gap-8">
                    <div class="flex-1">
                        <div class="w-10 h-10 rounded bg-blue-500/10 flex items-center justify-center text-blue-500 mb-4">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.384-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path></svg>
                        </div>
                        <h3 class="text-2xl font-bold mb-2">Guru & Akademik</h3>
                        <p class="text-slate-400">Manajemen jurnal, presensi, dan penilaian dalam satu klik.</p>
                    </div>
                    <!-- Decorative Code Block / Visual -->
                    <div class="flex-1 w-full bg-[#0a0a0a] border border-slate-800 rounded-lg p-4 font-mono text-xs text-slate-500">
                        <div class="flex gap-2 mb-2">
                            <div class="w-2 h-2 rounded-full bg-red-500"></div>
                            <div class="w-2 h-2 rounded-full bg-yellow-500"></div>
                            <div class="w-2 h-2 rounded-full bg-green-500"></div>
                        </div>
                        <p><span class="text-purple-400">class</span> <span class="text-yellow-200">Teacher</span> {</p>
                        <p class="pl-4"><span class="text-blue-400">submitGrade</span>(studentId, score) {</p>
                        <p class="pl-8">database.<span class="text-blue-200">save</span>(score);</p>
                        <p class="pl-8"><span class="text-green-400">return</span> <span class="text-orange-400">"Success"</span>;</p>
                        <p class="pl-4">}</p>
                        <p>}</p>
                    </div>
                </div>
            </MastraBox>


            <!-- MIDDLE ROW (The "Hub") -->
            
            <!-- Box 3: Finance (Left Vertical) -->
            <MastraBox class="md:col-span-3 h-96 p-8"
                :curveTopRight="true"
                :curveBottomRight="true"
                :connectRight="false" 
            >
                <div class="h-full flex flex-col justify-between">
                    <div class="w-10 h-10 rounded bg-green-500/10 flex items-center justify-center text-green-500">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                    </div>
                    <div>
                        <h3 class="text-xl font-bold mb-2">Keuangan</h3>
                        <p class="text-slate-400 text-sm">SPP, Tagihan, dan Laporan Kas Sekolah.</p>
                        <div class="mt-8 pt-6 border-t border-slate-800">
                            <div class="flex justify-between items-center mb-2">
                                <span class="text-xs text-slate-500">Pemasukan</span>
                                <span class="text-xs text-green-500">+12%</span>
                            </div>
                            <div class="h-1 w-full bg-slate-800 rounded-full overflow-hidden">
                                <div class="h-full bg-green-500 w-[75%]"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </MastraBox>


            <MastraBox class="md:col-span-6 h-96 p-0 group relative overflow-hidden flex items-center justify-center"
                :curveTopLeft="true"
                :curveTopRight="true"
                :curveBottomLeft="true"
                :curveBottomRight="true"
            >
                <div class="absolute inset-0 bg-slate-900/50"></div>
                
                <RadialProgress :series="[
                    { label: 'Efisien Waktu', percent: 88, color: 'text-green-500', hexColor: '#22c55e' },
                    { label: 'Digitalisasi', percent: 72, color: 'text-orange-500', hexColor: '#f97316' },
                    { label: 'Akurasi Data', percent: 95, color: 'text-blue-500', hexColor: '#3b82f6' }
                ]" />

                <!-- Contextual Label -->
                <div class="absolute bottom-6 text-center w-full px-4">
                     <p class="text-xs text-slate-500 max-w-sm mx-auto">
                        *Berdasarkan dampak rata-rata implementasi sekolah digital.
                     </p>
                </div>
            </MastraBox>

            <!-- Box 5: Reports (Right Vertical) -->
            <MastraBox class="md:col-span-3 h-96 p-8"
                :curveTopLeft="true"
                :curveBottomLeft="true"
            >
               <div class="h-full flex flex-col justify-between">
                    <div class="w-10 h-10 rounded bg-purple-500/10 flex items-center justify-center text-purple-500">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
                    </div>
                    <div>
                        <h3 class="text-xl font-bold mb-2">Laporan</h3>
                        <p class="text-slate-400 text-sm">Cetak Rapor Kurikulum Merdeka & K13 otomatis.</p>
                        <div class="mt-4 flex flex-col gap-2">
                            <div class="flex items-center gap-2 text-xs text-slate-500">
                                <div class="w-1 h-1 rounded-full bg-white"></div> PDF Ready
                            </div>
                            <div class="flex items-center gap-2 text-xs text-slate-500">
                                <div class="w-1 h-1 rounded-full bg-white"></div> Excel Export
                            </div>
                        </div>
                    </div>
                </div>
            </MastraBox>


            <!-- BOTTOM ROW -->
            <!-- Box 6: Integration / WhatsApp (Bottom Left - Spans 2) -->
            <MastraBox class="md:col-span-8 h-64 p-8 relative overflow-hidden"
                :curveTopRight="true"
                :connectTop="true"
            >
                <div class="flex flex-col md:flex-row items-center h-full gap-8 relative z-10">
                     <div class="flex-1">
                        <div class="w-10 h-10 rounded bg-green-600/10 flex items-center justify-center text-green-500 mb-4">
                           <!-- WhatsApp Icon -->
                           <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.893 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.884-.001 2.225.651 3.891 1.746 5.634l-.999 3.648 3.742-.981zm11.387-5.464c-.074-.124-.272-.198-.57-.347-.297-.149-1.758-.868-2.031-.967-.272-.099-.47-.149-.669.149-.198.297-.768.967-.941 1.165-.173.198-.347.223-.644.074-.297-.149-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.297-.347.446-.521.151-.172.2-.296.3-.495.099-.198.05-.372-.025-.521-.075-.148-.669-1.611-.916-2.206-.242-.579-.487-.501-.669-.51l-.57-.01c-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.463 1.065 2.875 1.213 3.074.149.198 2.095 3.2 5.076 4.487.709.306 1.263.489 1.694.626.712.226 1.36.194 1.872.118.571-.085 1.758-.719 2.006-1.413.248-.695.248-1.29.173-1.414z"/></svg>
                        </div>
                        <h3 class="text-2xl font-bold mb-2">Notifikasi WhatsApp</h3>
                        <p class="text-slate-400">Kirim tagihan SPP & info sekolah langsung ke WA orang tua.</p>
                    </div>
                </div>
            </MastraBox>
            
            <!-- Box 7: Cloud / Access (Bottom Right) -->
            <MastraBox class="md:col-span-4 h-64 p-8"
                :curveTopLeft="true"
                :connectTop="true"
            >
                 <div class="h-full flex flex-col justify-between">
                    <div class="w-10 h-10 rounded bg-cyan-500/10 flex items-center justify-center text-cyan-500">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z"></path></svg>
                    </div>
                    <div>
                        <h3 class="text-xl font-bold mb-2">Cloud Based</h3>
                        <p class="text-slate-400 text-sm">Akses dari mana saja. Tanpa insfrastruktur server di sekolah.</p>
                    </div>
                </div>
            </MastraBox>

        </div>



    </div>
</template>
