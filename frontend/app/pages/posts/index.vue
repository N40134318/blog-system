<script setup lang="ts">
const api = useApi()

type PostItem = {
  id: number
  title: string
  summary: string
  author: string | null
  category: string | null
  tags: string | null
  coverImage: string | null
  status?: string | null
  createdAt?: number | null
  updatedAt?: number | null
  viewCount?: number | null
}

type PageResponse = {
  content: PostItem[]
  page: number
  totalPages: number
  totalElements: number
  size: number
}

const posts = ref<PostItem[]>([])
const loading = ref(true)
const errorMessage = ref('')
const keyword = ref('')
const sort = ref<'latest' | 'hot'>('latest')
const page = ref(0)
const size = ref(6)
const totalPages = ref(0)
const totalElements = ref(0)

const splitTags = (raw: string | null | undefined) => {
  return (raw || '')
    .split(/[,，、。;；|｜]/)
    .map(tag => tag.trim())
    .filter(Boolean)
}

const formatTime = (timestamp: number | null | undefined) => {
  if (!timestamp) return '暂无时间'
  return new Date(timestamp).toLocaleDateString()
}

const loadPosts = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const query = new URLSearchParams({
      page: String(page.value),
      size: String(size.value),
      keyword: keyword.value,
      sort: sort.value
    })

    const data = await api<PageResponse>(`/api/posts?${query.toString()}`)

    posts.value = data.content || []
    totalPages.value = data.totalPages || 0
    totalElements.value = data.totalElements || 0
  } catch (error: any) {
    posts.value = []
    totalPages.value = 0
    totalElements.value = 0
    errorMessage.value = error?.message || '加载文章失败'
  } finally {
    loading.value = false
  }
}

const search = async () => {
  page.value = 0
  await loadPosts()
}

const setSort = async (value: 'latest' | 'hot') => {
  if (sort.value === value) return
  sort.value = value
  page.value = 0
  await loadPosts()
}

const resetSearch = async () => {
  keyword.value = ''
  page.value = 0
  await loadPosts()
}

const prevPage = async () => {
  if (page.value <= 0) return
  page.value--
  await loadPosts()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const nextPage = async () => {
  if (page.value >= totalPages.value - 1) return
  page.value++
  await loadPosts()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

onMounted(loadPosts)
</script>

<template>
  <div class="min-h-screen bg-gray-100">
    <div class="max-w-6xl mx-auto px-4 py-8">
      <!-- 顶部标题 -->
      <section class="mb-8">
        <div class="rounded-3xl border border-gray-200 bg-white p-6 md:p-8 shadow-sm">
          <div class="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <div class="inline-flex rounded-full bg-blue-50 px-4 py-1 text-sm text-blue-700">
                Articles
              </div>

              <h1 class="mt-4 text-3xl md:text-4xl font-bold text-gray-900">
                全部文章
              </h1>

              <p class="mt-3 max-w-2xl text-gray-600 leading-7">
                浏览当前已发布的文章内容，支持关键词搜索、最新 / 最热排序、分页查看与分类标签跳转。
              </p>
            </div>

            <div class="grid grid-cols-2 gap-3 sm:grid-cols-3">
              <div class="rounded-2xl bg-gray-50 px-4 py-4">
                <div class="text-xs text-gray-500">总文章数</div>
                <div class="mt-2 text-xl font-semibold text-gray-900">
                  {{ totalElements }}
                </div>
              </div>

              <div class="rounded-2xl bg-gray-50 px-4 py-4">
                <div class="text-xs text-gray-500">当前页</div>
                <div class="mt-2 text-xl font-semibold text-gray-900">
                  {{ page + 1 }}
                </div>
              </div>

              <div class="rounded-2xl bg-gray-50 px-4 py-4 col-span-2 sm:col-span-1">
                <div class="text-xs text-gray-500">总页数</div>
                <div class="mt-2 text-xl font-semibold text-gray-900">
                  {{ totalPages }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

    <!-- 搜索栏 -->
        <section class="mb-8">
            <div class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm space-y-4">
            <div class="flex flex-col gap-3 md:flex-row">
                <input
                v-model="keyword"
                @keyup.enter="search"
                placeholder="搜索标题或内容关键词"
                class="flex-1 rounded-xl border border-gray-300 px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500"
                />

                <div class="flex gap-3">
                <button
                    @click="search"
                    class="rounded-xl bg-gray-900 px-5 py-3 text-sm text-white hover:bg-gray-800 transition"
                >
                    搜索
                </button>

                <button
                    @click="resetSearch"
                    class="rounded-xl border border-gray-300 bg-white px-5 py-3 text-sm text-gray-700 hover:bg-gray-50 transition"
                >
                    重置
                </button>
                </div>
            </div>

            <div class="flex flex-wrap gap-3">
                <button
                @click="setSort('latest')"
                :class="[
                    'rounded-full px-4 py-2 text-sm transition',
                    sort === 'latest'
                    ? 'bg-gray-900 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                ]"
                >
                最新发布
                </button>

                <button
                @click="setSort('hot')"
                :class="[
                    'rounded-full px-4 py-2 text-sm transition',
                    sort === 'hot'
                    ? 'bg-orange-500 text-white'
                    : 'bg-orange-50 text-orange-700 hover:bg-orange-100'
                ]"
                >
                最热阅读
                </button>
            </div>
            </div>
        </section>

      <!-- 错误 -->
      <div
        v-if="errorMessage"
        class="mb-6 rounded-2xl border border-red-200 bg-red-50 p-4 text-red-600"
      >
        {{ errorMessage }}
      </div>

      <!-- 加载态 -->
      <div v-if="loading" class="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
        <div
          v-for="item in 6"
          :key="item"
          class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm"
        >
          <div class="h-52 animate-pulse bg-gray-200"></div>
          <div class="p-5">
            <div class="h-6 w-3/4 animate-pulse rounded bg-gray-200"></div>
            <div class="mt-4 h-4 w-full animate-pulse rounded bg-gray-100"></div>
            <div class="mt-2 h-4 w-5/6 animate-pulse rounded bg-gray-100"></div>
            <div class="mt-2 h-4 w-2/3 animate-pulse rounded bg-gray-100"></div>

            <div class="mt-5 flex gap-2">
              <div class="h-7 w-16 animate-pulse rounded-full bg-gray-100"></div>
              <div class="h-7 w-20 animate-pulse rounded-full bg-gray-100"></div>
              <div class="h-7 w-14 animate-pulse rounded-full bg-gray-100"></div>
            </div>

            <div class="mt-6 h-9 w-24 animate-pulse rounded-lg bg-gray-100"></div>
          </div>
        </div>
      </div>

      <!-- 空状态 -->
      <EmptyState
        v-else-if="posts.length === 0"
        title="没有找到文章"
        :description="keyword ? '试试换一个关键词，或者清空搜索条件。' : '当前还没有已发布文章。'"
        action-text="去首页看看"
        action-to="/"
      />

      <!-- 文章列表 -->
      <div v-else class="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
        <article
          v-for="post in posts"
          :key="post.id"
          class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
        >
          <div v-if="post.coverImage" class="bg-gray-100">
            <img
              :src="post.coverImage"
              alt="封面图"
              class="h-52 w-full object-cover"
            />
          </div>

          <div v-else class="flex h-52 items-center justify-center bg-gray-100 text-sm text-gray-400">
            暂无封面
          </div>

          <div class="p-5">
            <div class="flex flex-wrap items-center gap-2 text-xs">
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">
                {{ post.author || '未知作者' }}
              </span>

              <NuxtLink
                :to="`/categories/${encodeURIComponent(post.category || '未分类')}`"
                class="rounded-full bg-blue-50 px-3 py-1 text-blue-700 hover:bg-blue-100 transition"
              >
                {{ post.category || '未分类' }}
              </NuxtLink>
            </div>

            <NuxtLink :to="`/posts/${post.id}`" class="mt-4 block">
              <h2 class="text-xl font-semibold text-gray-900 transition hover:text-blue-600 line-clamp-2 min-h-[3.5rem]">
                {{ post.title }}
              </h2>
            </NuxtLink>

            <p class="mt-3 text-sm leading-6 text-gray-600 line-clamp-3 min-h-[4.5rem]">
              {{ post.summary }}
            </p>

            <div class="mt-4 flex flex-wrap gap-2 text-xs">
              <template v-for="tag in splitTags(post.tags).slice(0, 3)" :key="tag">
                <NuxtLink
                  :to="`/tags/${encodeURIComponent(tag)}`"
                  class="rounded-full bg-green-50 px-3 py-1 text-green-700 hover:bg-green-100 transition"
                >
                  # {{ tag }}
                </NuxtLink>
              </template>

              <span
                v-if="splitTags(post.tags).length === 0"
                class="rounded-full bg-gray-100 px-3 py-1 text-gray-500"
              >
                无标签
              </span>
            </div>

            <div class="mt-5 flex items-center justify-between gap-3 border-t border-gray-100 pt-4">
              <div class="text-xs text-gray-500">
                <div>发布：{{ formatTime(post.createdAt) }}</div>
                <div class="mt-1">更新：{{ formatTime(post.updatedAt || post.createdAt) }}</div>
                <div class="mt-1">阅读：{{ post.viewCount ?? 0 }}</div>
              </div>

              <NuxtLink
                :to="`/posts/${post.id}`"
                class="inline-flex items-center rounded-lg border border-gray-300 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition"
              >
                阅读全文
              </NuxtLink>
            </div>
          </div>
        </article>
      </div>

      <!-- 分页 -->
      <div
        v-if="!loading && totalPages > 0"
        class="mt-10 flex flex-col items-center justify-center gap-4"
      >
        <div class="text-sm text-gray-600">
          第 {{ page + 1 }} 页 / 共 {{ totalPages }} 页 · 共 {{ totalElements }} 篇文章
        </div>

        <div class="flex items-center gap-3">
          <button
            @click="prevPage"
            :disabled="page === 0"
            class="rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            上一页
          </button>

          <button
            @click="nextPage"
            :disabled="page >= totalPages - 1"
            class="rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            下一页
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
