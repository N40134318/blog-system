<script setup lang="ts">
const auth = useAuth()

const isLoggedIn = computed(() => !!auth.accessToken.value)
const isAdmin = computed(() => auth.role.value === 'admin')

const logout = async () => {
  await auth.logout()
}
</script>

<template>
  <div class="min-h-screen bg-gray-100 text-gray-900">
    <header class="sticky top-0 z-50 border-b border-gray-200 bg-white/95 backdrop-blur">
      <div class="mx-auto flex max-w-6xl items-center justify-between px-4 py-3">
        <div class="flex items-center gap-6">
          <NuxtLink to="/" class="text-lg font-bold text-gray-900 hover:text-blue-600">
            Rainstorm Blog
          </NuxtLink>

          <nav class="hidden md:flex items-center gap-4 text-sm text-gray-600">
            <NuxtLink to="/" class="hover:text-blue-600 transition">首页</NuxtLink>
            <NuxtLink to="/about" class="hover:text-blue-600 transition">关于</NuxtLink>
            <NuxtLink to="/posts" class="hover:text-blue-600 transition">文章</NuxtLink>
            <NuxtLink to="/categories" class="hover:text-blue-600 transition">分类</NuxtLink>
            <NuxtLink to="/tags" class="hover:text-blue-600 transition">标签</NuxtLink>

            <template v-if="isLoggedIn">
              <NuxtLink to="/my-posts" class="hover:text-blue-600 transition">我的文章</NuxtLink>
              <NuxtLink to="/create-post" class="hover:text-blue-600 transition">发布</NuxtLink>

              <NuxtLink
                v-if="isAdmin"
                to="/dashboard"
                class="hover:text-blue-600 transition"
              >
                后台
              </NuxtLink>
            </template>
          </nav>
        </div>

        <div class="flex items-center gap-2">
          <template v-if="isLoggedIn">
            <button
              @click="logout"
              class="rounded-lg bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-800"
            >
              退出登录
            </button>
          </template>

          <template v-else>
            <NuxtLink
              to="/login"
              class="rounded-lg px-3 py-2 text-sm text-gray-700 hover:bg-gray-100"
            >
              登录
            </NuxtLink>

            <NuxtLink
              to="/register"
              class="rounded-lg bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-800"
            >
              注册
            </NuxtLink>
          </template>
        </div>
      </div>
    </header>

    <main>
      <slot />
    </main>
  </div>
</template>
