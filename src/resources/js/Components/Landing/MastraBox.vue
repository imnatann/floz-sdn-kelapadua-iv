<script setup>
import { computed } from 'vue';

const props = defineProps({
    // Corner curves (inverse radius)
    curveTopLeft: Boolean,
    curveTopRight: Boolean,
    curveBottomLeft: Boolean,
    curveBottomRight: Boolean,
    
    // Connectors (lines bridging the gap)
    connectTop: Boolean,
    connectBottom: Boolean,
    connectLeft: Boolean, // Usually handling by border, but if we need a filler
    
    // Standard Border Radius (if NOT curved)
    roundedTop: { type: Boolean, default: true },
    roundedBottom: { type: Boolean, default: true },
    
    className: { type: String, default: '' }
});

const containerClasses = computed(() => {
    return [
        'box',
        props.roundedTop ? 'rounded-t-[24px]' : '', // Standard radius where no curve
        props.roundedBottom ? 'rounded-b-[24px]' : '',
        props.className
    ];
});
</script>

<template>
    <div :class="containerClasses">
        <div class="pointer-events-none">
            <!-- Top Left Curve -->
            <div v-if="curveTopLeft" class="absolute anti-grid-curve anti-grid-curve-top-left">
                <div class="anti-grid-square"></div>
                <div class="anti-grid-circle [clip-path:inset(0_51%_51%_0)]"></div>
            </div>

            <!-- Top Right Curve -->
            <div v-if="curveTopRight" class="absolute anti-grid-curve anti-grid-curve-top-right">
                <div class="anti-grid-square"></div>
                <div class="anti-grid-circle [clip-path:inset(0_0_51%_51%)]"></div>
            </div>

            <!-- Bottom Right Curve -->
            <div v-if="curveBottomRight" class="absolute anti-grid-curve anti-grid-curve-bottom-right">
                <div class="anti-grid-square"></div>
                <div class="anti-grid-circle [clip-path:inset(51%_0_0_51%)]"></div>
            </div>

            <!-- Bottom Left Curve -->
            <div v-if="curveBottomLeft" class="absolute anti-grid-curve anti-grid-curve-bottom-left">
                <div class="anti-grid-square"></div>
                <div class="anti-grid-circle [clip-path:inset(51%_51%_0_0)]"></div>
            </div>

            <!-- Connectors (Briding the gap) -->
            <!-- Vertical Top Connector (fills gap above) -->
            <div v-if="connectTop" class="connector-v-top border-l-2 border-r-2"></div>
        </div>

        <div class="box--content">
            <slot />
        </div>
    </div>
</template>
