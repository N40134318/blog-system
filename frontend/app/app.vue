<script setup lang="ts">
const auth = useAuth()

onMounted(() => {
  auth.loadTokens()
})
</script>

<template>
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
</template>
