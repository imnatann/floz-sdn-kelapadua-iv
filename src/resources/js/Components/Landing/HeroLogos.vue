<script setup>
// HeroLogos.vue
// Refined for strict radial distribution around the center text
</script>

<template>
    <div class="hero-logos-container pointer-events-none select-none">
        <!-- Outer Ring (Slower, Clockwise) -->
        <div class="ring-wrapper ring-outer">
            <div class="logo-item" style="--angle: 0deg">
                <img src="https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93ed96e30b5810b3a288_justworks.svg" alt="Justworks" loading="lazy" width="64" height="64">
            </div>
            <div class="logo-item" style="--angle: 45deg">
                <img src="https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93ed890ce4399c491d85_namely.svg" alt="Namely" loading="lazy" width="64" height="64">
            </div>
            <div class="logo-item" style="--angle: 90deg">
                <img src="https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93f0d7505dff5e981869_onpay.svg" alt="Onpay" loading="lazy" width="64" height="64">
            </div>
            <div class="logo-item" style="--angle: 135deg">
                <img src="https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93ed2cf6e7e6e692e7de_paychex.svg" alt="Paychex" loading="lazy" width="64" height="64">
            </div>
            <div class="logo-item" style="--angle: 180deg">
                <img src="https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93ee8d3dc30bbea1ce6b_paycor.svg" alt="Paycor" loading="lazy" width="64" height="64">
            </div>
            <div class="logo-item" style="--angle: 225deg">
                <img src="https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93ed0f1fff92b2616dad_patriot.svg" alt="Patriot" loading="lazy" width="64" height="64">
            </div>
            <div class="logo-item" style="--angle: 270deg">
                <img src="https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93eeca170614ecf86df8_personio.svg" alt="Personio" loading="lazy" width="64" height="64">
            </div>
            <div class="logo-item" style="--angle: 315deg">
                <img src="https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93eefac8a5d0d4ca67ea_prismhr.svg" alt="Prism HR" loading="lazy" width="64" height="64">
            </div>
        </div>
        
        <!-- Inner Ring (Faster, Counter-Clockwise) -->
        <div class="ring-wrapper ring-inner">
            <div class="logo-item" style="--angle: 0deg">
                <img src="https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93efbd77caac7452fa04_wave.svg" alt="Wave" loading="lazy" width="64" height="64">
            </div>
            <div class="logo-item" style="--angle: 60deg">
                <img src="https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93efd76daf77e359a1f8_workday.svg" alt="Workday" loading="lazy" width="64" height="64">
            </div>
            <div class="logo-item" style="--angle: 120deg">
                <img src="https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93ed60c27b531d929adb_alphastaff.svg" alt="Alphastaff" loading="lazy" width="64" height="64">
            </div>
            <div class="logo-item" style="--angle: 180deg">
                <img src="https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93eded9819f49766664c_oysterhr%201.svg" alt="Oyster HR" loading="lazy" width="64" height="64">
            </div>
            <div class="logo-item" style="--angle: 240deg">
                <img src="https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93ee608a73339de88c5d_sapling.svg" alt="Sapling" loading="lazy" width="64" height="64">
            </div>
            <div class="logo-item" style="--angle: 300deg">
                <img src="https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93eee1f5d8137f24c958_sequoia%20one.svg" alt="Sequoia" loading="lazy" width="64" height="64">
            </div>
        </div>
    </div>
</template>

<style scoped>
.hero-logos-container {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 100%;
    height: 100%;
    overflow: hidden; /* Ensure no scrollbars */
}

.ring-wrapper {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    border-radius: 50%;
    width: 0;
    height: 0;
}

/* 
    Configuration 
    --radius: Distance from center
    --size: Logo size
    --duration: Seconds per rotation
*/

.ring-outer {
    --radius: 28rem; /* Desktop default */
    --size: 4.5rem;
    --duration: 80s;
    animation: spin var(--duration) linear infinite;
}

.ring-inner {
    --radius: 18rem; /* Desktop default */
    --size: 3.5rem;
    --duration: 60s;
    animation: spin-reverse var(--duration) linear infinite;
}

/* Mobile Adjustments (Responsive Radius) */
@media (max-width: 768px) {
    .ring-outer {
        --radius: 14rem; 
        --size: 3rem;
    }
    .ring-inner {
        --radius: 9rem;
        --size: 2.5rem;
    }
}

.logo-item {
    position: absolute;
    top: 0;
    left: 0;
    width: var(--size);
    height: var(--size);
    margin-left: calc(var(--size) / -2);
    margin-top: calc(var(--size) / -2);
    
    /* 
       Transform Logic:
       1. rotate(angle): Point to the correct direction on the clock
       2. translate(radius): Move out to the edge
       3. rotate(-angle): Counter-rotate so the box itself is upright relative to the center? 
          No, we want the logo to stay upright relative to the SCREEN.
    */
    transform: rotate(var(--angle)) translate(var(--radius));
    will-change: transform; /* Performance Optimization: Hint browser to promote to composior layer */
}

.logo-item img {
    width: 100%;
    height: 100%;
    object-fit: contain;
    background: rgba(255, 255, 255, 0.9);
    backdrop-filter: blur(4px);
    border-radius: 12px;
    padding: 10px;
    box-shadow: 0 8px 16px rgba(0,0,0,0.2);
    
    /* 
       Counter-Rotation Logic:
       The parent .ring-wrapper spins.
       This IMG needs to spin in reverse to stay upright.
    */
    animation: keep-upright var(--duration) linear infinite;
    will-change: transform; /* Performance Optimization */
}

/* If the wrapper spins clockwise (spin), img must spin counter-clockwise (keep-upright = spin-reverse) */
.ring-outer .logo-item img {
    animation-name: spin-reverse;
}

/* If the wrapper spins counter-clockwise (spin-reverse), img must spin clockwise (keep-upright = spin) */
.ring-inner .logo-item img {
    animation-name: spin;
}

@keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
}

@keyframes spin-reverse {
    from { transform: rotate(360deg); }
    to { transform: rotate(0deg); }
}
</style>
