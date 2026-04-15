<template>
  <svg viewBox="0 0 350 100" fill="none" xmlns="http://www.w3.org/2000/svg" :class="className">
    <defs>
      <linearGradient id="paint0_linear" x1="0" y1="0" x2="350" y2="100" gradientUnits="userSpaceOnUse">
        <stop offset="0%" stop-color="#FFFFFF"/>
        <stop offset="100%" stop-color="#EA580C"/>
      </linearGradient>
      
      <!-- Gradient for O -->
      <linearGradient id="grad_o" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="30%" :stop-color="color"/>
        <stop offset="100%" stop-color="#EA580C"/>
      </linearGradient>

       <!-- Gradient for Z Bottom -->
      <linearGradient id="grad_z" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#EA580C"/>
        <stop offset="100%" stop-color="#F97316"/>
      </linearGradient>
      
       <!-- Gradient for F Triangle -->
      <linearGradient id="grad_f" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#FFFFFF"/>
        <stop offset="100%" stop-color="#EA580C"/>
      </linearGradient>
    </defs>

    <!-- F -->
    <!-- Vertical Stem with Orange Triangle Accent -->
    <path d="M20 10 H50 V90 H20 V10 Z" :fill="color"/>
    <!-- Top Bar -->
    <path d="M50 10 H90 V30 H50 V10 Z" :fill="color"/>
    <!-- Middle Bar -->
    <path d="M50 50 H80 V70 H50 V50 Z" :fill="color"/>
    <!-- Orange Accent Triangle on F (Top Left corner style) -->
    <path d="M20 10 L50 10 L20 40 Z" fill="#EA580C"/>

    <!-- L -->
    <path d="M110 10 H140 V70 H170 V90 H110 V10 Z" :fill="color"/>

    <!-- O -->
    <!-- Outer Circle: r=30 + stroke=20/2*2? No stroke is centered. 
         Desired outer radius 40 (diameter 80). 10 to 90.
         Inner radius 20.
         Stroke width 20. Path radius = 30.
         30-10=20(inner), 30+10=40(outer). Correct. 
         Center X = 170(L end) + 20(gap) + 40(radius) = 230.
    -->
    <circle cx="230" cy="50" r="30" stroke="url(#grad_o)" stroke-width="20" fill="none"/>
    
    <!-- Z -->
    <!-- Starts at 230+40(radius)=270 + 20(gap) = 290. -->
    <!-- Top part (Dark) -->
    <path d="M290 10 H350 L320 50 H290 L290 10 Z" :fill="color"/>
    <!-- Bottom part (Orange) -->
    <path d="M320 50 L350 50 L350 90 H290 L320 50 Z" fill="url(#grad_z)"/>
    
  </svg>
</template>

<script setup>
defineProps({
  className: {
    type: String,
    default: 'w-full h-full'
  },
  color: {
    type: String,
    default: '#0F172A' // Slate-900
  }
})
</script>
