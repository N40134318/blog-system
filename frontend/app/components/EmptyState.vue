<script setup lang="ts">
defineProps<{
  title: string
  description?: string
  actionText?: string
  actionTo?: string
}>()
</script>

<template>
  <div class="rounded-2xl border border-gray-200 bg-white p-8 md:p-10 text-center shadow-sm">
    <div class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-100 text-2xl">
      📭
    </div>

    <h3 class="text-xl font-semibold text-gray-900">
      {{ title }}
    </h3>

    <p v-if="description" class="mt-3 text-gray-600 leading-7">
      {{ description }}
    </p>

    <div v-if="actionText && actionTo" class="mt-6">
      <NuxtLink
        :to="actionTo"
        class="inline-flex rounded-xl bg-gray-900 px-5 py-3 text-white hover:bg-gray-800 transition"
      >
        {{ actionText }}
      </NuxtLink>
    </div>
  </div>
</template>