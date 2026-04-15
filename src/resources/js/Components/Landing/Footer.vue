<script setup>
import { Link } from '@inertiajs/vue3';
</script>

<template>
    <footer class="bg-[#09090b] pt-16 border-t border-slate-800/50 pb-8 px-4 md:px-8">
        <div class="max-w-7xl mx-auto">
            <div class="grid grid-cols-1 md:grid-cols-4 gap-12 mb-12">
                <div class="col-span-1 md:col-span-1">
                    <div class="flex items-center gap-2 mb-6">
                        <div class="h-8 w-8 bg-gradient-to-br from-orange-500 to-orange-600 rounded-lg flex items-center justify-center text-white font-bold">F</div>
                        <span class="text-xl font-bold text-white">FLOZ LMS</span>
                    </div>
                    <p class="text-slate-500 text-sm leading-relaxed">
                        Sistem Manajemen Sekolah Terintegrasi. Mengelola akademik, keuangan, dan data siswa dalam satu platform cloud yang aman.
                    </p>
                </div>
                
                <div>
                    <h4 class="text-white font-bold mb-4">Platform</h4>
                    <ul class="space-y-2 text-slate-500 text-sm">
                        <li><a href="#" class="hover:text-orange-500 transition-colors">Fitur Kesiswaan</a></li>
                        <li><a href="#" class="hover:text-orange-500 transition-colors">Manajemen Keuangan</a></li>
                        <li><a href="#" class="hover:text-orange-500 transition-colors">Portal Orang Tua</a></li>
                    </ul>
                </div>

                <div>
                    <h4 class="text-white font-bold mb-4">Dukungan</h4>
                    <ul class="space-y-2 text-slate-500 text-sm">
                        <li><a href="#" class="hover:text-orange-500 transition-colors">Pusat Bantuan</a></li>
                        <li><a href="#" class="hover:text-orange-500 transition-colors">Dokumentasi API</a></li>
                        <li><a href="#" class="hover:text-orange-500 transition-colors">Status Server</a></li>
                    </ul>
                </div>

                <div>
                    <h4 class="text-white font-bold mb-4">Legal</h4>
                    <ul class="space-y-2 text-slate-500 text-sm">
                        <li><a href="#" class="hover:text-orange-500 transition-colors">Kebijakan Privasi</a></li>
                        <li><a href="#" class="hover:text-orange-500 transition-colors">Syarat & Ketentuan</a></li>
                    </ul>
                </div>
            </div>
            <div class="border-t border-slate-800/50 pt-8 flex flex-col md:flex-row justify-between items-center gap-4 text-slate-600 text-sm">
                <p>© {{ new Date().getFullYear() }} FLOZ LMS. All rights reserved.</p>
                <div class="flex gap-4">
                    <a href="#" class="hover:text-white transition-colors">Twitter</a>
                    <a href="#" class="hover:text-white transition-colors">LinkedIn</a>
                    <a href="#" class="hover:text-white transition-colors">Instagram</a>
                </div>
            </div>
        </div>
    </footer>
</template>
