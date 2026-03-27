<script setup lang="ts">
definePageMeta({
  middleware: 'auth',
  layout: 'admin'
})

const api = useApi()

type PostItem = {
  id: number
  title: string
  summary: string
  author: string | null
  category: string | null
  tags: string | null
  coverImage: string | null
  status: string | null
  createdAt: number | null
  updatedAt: number | null
  viewCount?: number | null
}

type PageResponse = {
  list: PostItem[]
  page: number
  totalPages: number
  totalElements: number
  size: number
}

type DashboardResponse = {
  totalPosts: number
  draftCount: number
  publishedCount: number
  recentPosts: PostItem[]
}

const loading = ref(true)
const errorMessage = ref('')
const currentUsername = ref('')
const recentPosts = ref<PostItem[]>([])
const totalPosts = ref(0)
const draftCount = ref(0)
const publishedCount = ref(0)

const formatTime = (timestamp: number | null | undefined) => {
  if (!timestamp) return '暂无时间'
  return new Date(timestamp).toLocaleString()
}

const loadDashboard = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const me = await api<{ username: string; role?: string }>('/api/auth/me')
    currentUsername.value = me.username

    const data = await api<DashboardResponse>('/api/admin/dashboard')

    recentPosts.value = data.recentPosts || []
    totalPosts.value = data.totalPosts || 0
    draftCount.value = data.draftCount || 0
    publishedCount.value = data.publishedCount || 0
  } catch (error: any) {
    const message = error?.message || '加载后台数据失败'
    errorMessage.value = message

    if (
      message.includes('未登录') ||
      message.includes('401') ||
      message.includes('403') ||
      message.includes('token')
    ) {
      await navigateTo('/login')
      return
    }
  } finally {
    loading.value = false
  }
}

onMounted(loadDashboard)
</script>

<template>
  <div class="min-h-screen bg-gray-100">
    <div class="max-w-6xl mx-auto px-4 py-8">
      <div v-if="loading" class="text-gray-500 py-10">
        加载中...
      </div>

      <div
        v-else-if="errorMessage"
        class="rounded-2xl border border-red-200 bg-red-50 p-4 text-red-600"
      >
        {{ errorMessage }}
      </div>

      <div v-else class="space-y-8">
        <!-- 顶部欢迎区 -->
        <section class="rounded-3xl border border-gray-200 bg-white p-6 md:p-8 shadow-sm">
          <div class="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <div class="inline-flex rounded-full bg-blue-50 px-4 py-1 text-sm text-blue-700">
                Dashboard
              </div>

              <h1 class="mt-4 text-3xl md:text-4xl font-bold text-gray-900">
                欢迎回来，{{ currentUsername || '用户' }}
              </h1>

              <p class="mt-3 max-w-2xl text-gray-600 leading-7">
                这里是你的内容管理首页，可以快速查看文章状态、进入写作、管理草稿和已发布内容。
              </p>
            </div>

            <div class="flex flex-wrap gap-3">
              <NuxtLink
                to="/create-post"
                class="rounded-xl bg-gray-900 px-5 py-3 text-sm text-white hover:bg-gray-800 transition"
              >
                写新文章
              </NuxtLink>

              <NuxtLink
                to="/dashboard/posts"
                class="rounded-xl border border-gray-300 bg-white px-5 py-3 text-sm text-gray-700 hover:bg-gray-50 transition"
              >
                文章管理
              </NuxtLink>
            </div>
          </div>
        </section>

        <!-- 统计卡片 -->
        <section class="grid gap-6 sm:grid-cols-2 xl:grid-cols-4">
          <div class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
            <div class="text-sm text-gray-500">全站文章总数</div>
            <div class="mt-3 text-3xl font-bold text-gray-900">
              {{ totalPosts }}
            </div>
            <div class="mt-2 text-sm text-gray-500">
              当前站点下可管理的全部文章
            </div>
          </div>

          <div class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
            <div class="text-sm text-gray-500">全站草稿数</div>
            <div class="mt-3 text-3xl font-bold text-yellow-600">
              {{ draftCount }}
            </div>
            <div class="mt-2 text-sm text-gray-500">
              最近文章中仍未发布的内容
            </div>
          </div>

          <div class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
            <div class="text-sm text-gray-500">全站已发布数</div>
            <div class="mt-3 text-3xl font-bold text-green-600">
              {{ publishedCount }}
            </div>
            <div class="mt-2 text-sm text-gray-500">
              最近文章中已公开展示的内容
            </div>
          </div>

          <div class="rounded-2xl border border-gray-200 bg-gray-900 p-6 text-white shadow-sm">
            <div class="text-sm text-gray-300">下一步建议</div>
            <div class="mt-3 text-xl font-semibold">
              继续完善后台管理
            </div>
            <div class="mt-2 text-sm text-gray-400">
              下一步可以做文章状态切换、评论管理、统计页
            </div>
          </div>
        </section>

        <!-- 快捷入口 -->
        <section class="grid gap-6 lg:grid-cols-3">
          <NuxtLink
            to="/create-post"
            class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
          >
            <div class="text-lg font-semibold text-gray-900">创建文章</div>
            <p class="mt-3 text-sm leading-6 text-gray-600">
              进入 Markdown 编辑与预览页面，支持封面上传、草稿保存与正式发布。
            </p>
          </NuxtLink>

          <NuxtLink
            to="/dashboard/posts"
            class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
          >
            <div class="text-lg font-semibold text-gray-900">管理全站文章</div>
            <p class="mt-3 text-sm leading-6 text-gray-600">
                查看全站文章列表，区分草稿与已发布内容，并进入编辑页继续修改。
            </p>
          </NuxtLink>

          <NuxtLink
            to="/posts"
            class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
          >
            <div class="text-lg font-semibold text-gray-900">查看前台</div>
            <p class="mt-3 text-sm leading-6 text-gray-600">
              从读者视角查看文章列表与详情页面，检查展示效果、目录、代码块与评论体验。
            </p>
          </NuxtLink>
        </section>

        <!-- 最近文章 -->
        <section class="rounded-3xl border border-gray-200 bg-white p-6 md:p-8 shadow-sm">
          <div class="mb-6 flex items-end justify-between gap-4">
            <div>
              <h2 class="text-2xl font-bold text-gray-900">最近文章</h2>
              <p class="mt-2 text-gray-600">快速查看最近创建或修改的内容</p>
            </div>

            <NuxtLink
              to="/dashboard/posts"
              class="text-sm font-medium text-blue-600 hover:text-blue-700"
            >
              查看全部 →
            </NuxtLink>
          </div>

          <div v-if="recentPosts.length === 0">
            <EmptyState
              title="你还没有文章"
              description="先写一篇文章，后台首页就会开始展示你的最近内容。"
              action-text="去写文章"
              action-to="/create-post"
            />
          </div>

          <div v-else class="grid gap-4">
            <article
              v-for="post in recentPosts"
              :key="post.id"
              class="rounded-2xl border border-gray-200 bg-gray-50 p-5"
            >
              <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                <div class="min-w-0">
                  <div class="flex flex-wrap items-center gap-2">
                    <NuxtLink
                      :to="`/posts/${post.id}`"
                      class="text-lg font-semibold text-gray-900 hover:text-blue-600 transition"
                    >
                      {{ post.title }}
                    </NuxtLink>

                    <span
                      v-if="post.status === 'draft'"
                      class="inline-flex rounded-full bg-yellow-50 px-3 py-1 text-xs text-yellow-700"
                    >
                      草稿
                    </span>

                    <span
                      v-else-if="post.status === 'published'"
                      class="inline-flex rounded-full bg-green-50 px-3 py-1 text-xs text-green-700"
                    >
                      已发布
                    </span>
                  </div>

                  <p class="mt-3 line-clamp-2 text-sm leading-6 text-gray-600">
                    {{ post.summary }}
                  </p>

                  <div class="mt-3 flex flex-wrap gap-2 text-xs">
                    <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">
                      {{ post.category || '未分类' }}
                    </span>
                    <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">
                      创建：{{ formatTime(post.createdAt) }}
                    </span>
                    <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">
                      更新：{{ formatTime(post.updatedAt) }}
                    </span>
                    <span class="rounded-full bg-blue-50 px-3 py-1 text-blue-700">
                      阅读：{{ post.viewCount ?? 0 }}
                    </span>
                  </div>
                </div>

                <div class="flex shrink-0 gap-3">
                  <NuxtLink
                    :to="`/edit-post/${post.id}`"
                    class="rounded-lg bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-800 transition"
                  >
                    编辑
                  </NuxtLink>

                  <NuxtLink
                    :to="`/posts/${post.id}`"
                    class="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition"
                  >
                    查看
                  </NuxtLink>
                </div>
              </div>
            </article>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>
