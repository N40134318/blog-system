<script setup lang="ts">
const auth = useAuth()

const logout = async () => {
  await auth.logout()
}
</script>

<template>
  <div class="h-screen bg-gray-100 text-gray-900 overflow-hidden">
    <div class="flex h-full">
      <aside class="flex w-64 shrink-0 flex-col border-r border-gray-200 bg-white sticky top-0 h-screen">
        <div class="border-b border-gray-200 px-6 py-5">
          <NuxtLink to="/" class="text-xl font-bold text-gray-900 hover:text-blue-600 transition">
            Rainstorm Admin
          </NuxtLink>
          <p class="mt-2 text-sm text-gray-500">
            内容管理后台
          </p>
        </div>

        <nav class="flex-1 px-4 py-4 space-y-2 overflow-y-auto">
          <NuxtLink
            to="/dashboard"
            class="block rounded-xl px-4 py-3 text-sm text-gray-700 hover:bg-gray-100 transition"
            active-class="bg-gray-900 text-white hover:bg-gray-900"
          >
            总览
          </NuxtLink>

          <NuxtLink
            to="/dashboard/posts"
            class="block rounded-xl px-4 py-3 text-sm text-gray-700 hover:bg-gray-100 transition"
            active-class="bg-gray-900 text-white hover:bg-gray-900"
          >
            文章管理
          </NuxtLink>

          <NuxtLink
            to="/dashboard/comments"
            class="block rounded-xl px-4 py-3 text-sm text-gray-700 hover:bg-gray-100 transition"
            active-class="bg-gray-900 text-white hover:bg-gray-900"
          >
            评论管理
          </NuxtLink>

          <NuxtLink
            to="/create-post"
            class="block rounded-xl px-4 py-3 text-sm text-gray-700 hover:bg-gray-100 transition"
          >
            写新文章
          </NuxtLink>

          <NuxtLink
            to="/my-posts"
            class="block rounded-xl px-4 py-3 text-sm text-gray-700 hover:bg-gray-100 transition"
          >
            我的文章
          </NuxtLink>

          <NuxtLink
            to="/posts"
            class="block rounded-xl px-4 py-3 text-sm text-gray-700 hover:bg-gray-100 transition"
          >
            查看前台
          </NuxtLink>
        </nav>

        <div class="border-t border-gray-200 p-4">
          <button
            @click="logout"
            class="w-full rounded-xl bg-gray-900 px-4 py-3 text-sm text-white hover:bg-gray-800 transition"
          >
            退出登录
          </button>
        </div>
      </aside>

      <div class="min-w-0 flex-1 h-screen overflow-y-auto">
        <header class="sticky top-0 z-40 border-b border-gray-200 bg-white/90 backdrop-blur">
          <div class="mx-auto flex max-w-7xl items-center justify-between px-4 py-4">
            <div>
              <h1 class="text-lg font-semibold text-gray-900">
                {{
                  $route.path.startsWith('/dashboard/comments')
                    ? '评论管理'
                    : $route.path.startsWith('/dashboard/posts')
                      ? '文章管理'
                      : '总览'
                }}
              </h1>
              <p class="text-sm text-gray-500">
                {{
                  $route.path.startsWith('/dashboard/comments')
                    ? '查看和清理全站评论内容'
                    : $route.path.startsWith('/dashboard/posts')
                      ? '管理草稿与已发布文章'
                      : '查看你的内容数据与统计'
                }}
              </p>
            </div>

            <div class="flex items-center gap-3">
              <NuxtLink
                to="/"
                class="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition"
              >
                返回前台
              </NuxtLink>
            </div>
          </div>
        </header>

        <main class="mx-auto max-w-7xl px-4 py-6">
          <slot />
        </main>
      </div>
    </div>
  </div>
</template>
