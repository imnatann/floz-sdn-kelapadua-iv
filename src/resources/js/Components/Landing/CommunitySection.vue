<script setup>
import { Link } from '@inertiajs/vue3';
</script>

<template>
    <section class="py-24 bg-[#09090b] text-white relative">
        <div class="container mx-auto px-4 max-w-6xl">
            
            <!-- Section Header -->
            <div class="text-center mb-16">
                <span class="text-purple-500 font-mono text-sm tracking-wider uppercase mb-2 block">Community First</span>
                <h2 class="text-3xl md:text-5xl font-bold mb-4">
                    Bergabung dengan <span class="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-600">Revolusi.</span>
                </h2>
                <p class="text-slate-400 max-w-2xl mx-auto">
                    FLOZ dibangun oleh komunitas, untuk komunitas. Berkontribusi, berdiskusi, dan bangun masa depan pendidikan bersama.
                </p>
            </div>

            <!-- Bento Grid -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-6 auto-rows-[minmax(180px, auto)]">
                
                <!-- Card 1: GitHub (Variable Width) -->
                <a href="https://github.com/imnatann/floz-lms" target="_blank" class="md:col-span-2 row-span-2 group relative overflow-hidden rounded-3xl border border-slate-800 bg-[#0c0c0e] hover:border-slate-600 transition-all duration-300">
                    <div class="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
                    
                    <div class="p-8 h-full flex flex-col justify-between relative z-10">
                        <div class="flex justify-between items-start">
                            <div class="w-12 h-12 rounded-full bg-white text-black flex items-center justify-center text-2xl">
                                <svg class="w-7 h-7" fill="currentColor" viewBox="0 0 24 24"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
                            </div>
                            <span class="px-3 py-1 rounded-full bg-slate-800 border border-slate-700 text-xs text-slate-300 flex items-center gap-1">
                                <span class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span> Public
                            </span>
                        </div>
                        
                        <div class="mt-8">
                            <h3 class="text-3xl font-bold mb-2 group-hover:text-white transition-colors">GitHub Repository</h3>
                            <p class="text-slate-400 text-sm mb-6">Explore the source code, report issues, and star the project to support us.</p>
                            
                            <div class="inline-flex items-center gap-2 text-white font-medium group-hover:translate-x-2 transition-transform">
                                Star us now <span class="text-xl">→</span>
                            </div>
                        </div>
                    </div>
                    <!-- Decorative BG Pattern -->
                    <div class="absolute -right-10 -bottom-10 w-64 h-64 bg-slate-800/20 rounded-full blur-3xl group-hover:bg-slate-700/30 transition-colors"></div>
                </a>

                <!-- Card 2: Discord (Tall) -->
                <a href="#" class="md:col-span-1 md:row-span-2 group relative overflow-hidden rounded-3xl border border-slate-800 bg-[#5865F2] hover:bg-[#4752c4] transition-all duration-300">
                    <div class="absolute inset-0 bg-[url('https://assets-global.website-files.com/6257adef93867e56f84d3092/636e0a6ac3c481f273141736_icon_clyde_white_RGB.png')] bg-center bg-no-repeat bg-contain opacity-10"></div>
                    
                    <div class="p-6 h-full flex flex-col items-center justify-center text-center relative z-10">
                        <div class="w-16 h-16 mb-6 rounded-2xl bg-white/20 backdrop-blur-sm flex items-center justify-center">
                             <svg class="w-8 h-8 text-white" viewBox="0 0 127.14 96.36" fill="currentColor">
                                <path d="M107.7,8.07A105.15,105.15,0,0,0,81.47,0a72.06,72.06,0,0,0-3.36,6.83A97.68,97.68,0,0,0,49,6.83,72.37,72.37,0,0,0,45.64,0,105.89,105.89,0,0,0,19.39,8.09C2.79,32.65-1.71,56.6.54,80.21h0A105.73,105.73,0,0,0,32.71,96.36,77.11,77.11,0,0,0,39.6,85.25a68.42,68.42,0,0,1-10.85-5.18c.91-.66,1.8-1.34,2.66-2a75.57,75.57,0,0,0,64.32,0c.87.71,1.76,1.39,2.66,2a68.68,68.68,0,0,1-10.87,5.19,77,77,0,0,0,6.89,11.1A105.25,105.25,0,0,0,126.6,80.22c2.36-24.44-2.54-46.74-18.9-72.15ZM42.45,65.69C36.18,65.69,31,60,31,53s5-12.74,11.43-12.74S54,46,53.89,53,48.84,65.69,42.45,65.69Zm42.24,0C78.41,65.69,73.25,60,73.25,53s5-12.74,11.44-12.74S96.23,46,96.12,53,91.08,65.69,84.69,65.69Z"/>
                            </svg>
                        </div>
                        <h3 class="text-xl font-bold text-white mb-2">Join Discord</h3>
                        <p class="text-white/80 text-sm mb-6">Chat with dev, share ideas, get help.</p>
                        <span class="inline-block px-4 py-2 bg-white text-[#5865F2] rounded-full text-sm font-bold shadow-lg group-hover:scale-105 transition-transform">
                            Connect
                        </span>
                    </div>
                </a>

                <!-- Card 3: Contributing (Standard) -->
                <div class="md:col-span-1 md:row-span-1 rounded-3xl border border-slate-800 bg-[#0c0c0e] p-6 flex flex-col justify-between hover:border-purple-500/50 transition-colors group">
                    <div class="w-10 h-10 rounded-full bg-purple-500/10 flex items-center justify-center text-purple-500 mb-4">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path></svg>
                    </div>
                    <div>
                        <h4 class="font-bold text-lg mb-1 group-hover:text-purple-400 transition-colors">Documentation</h4>
                        <p class="text-xs text-slate-500">Read setup guide.</p>
                    </div>
                </div>

                <!-- Card 4: Roadmap / Issues (Standard) -->
                <div class="md:col-span-1 md:row-span-1 rounded-3xl border border-slate-800 bg-[#0c0c0e] p-6 flex flex-col justify-between hover:border-orange-500/50 transition-colors group">
                    <div class="w-10 h-10 rounded-full bg-orange-500/10 flex items-center justify-center text-orange-500 mb-4">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                    </div>
                    <div>
                        <h4 class="font-bold text-lg mb-1 group-hover:text-orange-400 transition-colors">Contribute</h4>
                        <p class="text-xs text-slate-500">Fix bugs, add features.</p>
                    </div>
                </div>

            </div>

        </div>
    </section>
</template>
