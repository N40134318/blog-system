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
}

const loading = ref(true)
const errorMessage = ref('')
const categories = ref<{ name: string; count: number }[]>([])

const goToCategory = async (name: string) => {
  await navigateTo(`/categories/${encodeURIComponent(name)}`)
}

const loadCategories = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const data = await api<{
      content: PostItem[]
      page: number
      totalPages: number
      totalElements: number
      size: number
    }>('/api/posts?page=0&size=100&keyword=')

    const map = new Map<string, number>()

    for (const post of data.content || []) {
      const name = (post.category || '未分类').trim() || '未分类'
      map.set(name, (map.get(name) || 0) + 1)
    }

    categories.value = Array.from(map.entries())
      .map(([name, count]) => ({ name, count }))
      .sort((a, b) => b.count - a.count)
  } catch (error: any) {
    errorMessage.value = error?.message || '加载分类失败'
  } finally {
    loading.value = false
  }
}

onMounted(loadCategories)
</script>

<template>
  <div class="min-h-screen bg-gray-100">
    <div class="max-w-6xl mx-auto px-4 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">分类</h1>
        <p class="mt-2 text-gray-600">按文章分类浏览内容</p>
      </div>

      <div v-if="loading" class="text-gray-500">
        加载中...
      </div>

      <div
        v-else-if="errorMessage"
        class="rounded-xl border border-red-200 bg-red-50 p-4 text-red-600"
      >
        {{ errorMessage }}
      </div>

      <EmptyState
        v-else-if="categories.length === 0"
        title="暂无分类数据"
        description="当前文章还没有形成可展示的分类。"
        action-text="浏览文章"
        action-to="/posts"
      />

      <div v-else class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <div
          v-for="item in categories"
          :key="item.name"
          class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
        >
          <div class="flex items-center justify-between gap-4">
            <div>
              <div class="text-lg font-semibold text-gray-900">
                {{ item.name }}
              </div>
              <div class="mt-2 text-sm text-gray-500">
                共 {{ item.count }} 篇文章
              </div>
            </div>

            <button
              class="rounded-full bg-blue-50 px-3 py-1 text-sm text-blue-700 hover:bg-blue-100"
              @click="goToCategory(item.name)"
            >
              查看
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
