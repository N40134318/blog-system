<script setup lang="ts">
const api = useApi()
const auth = useAuth()

type PostItem = {
  id: number
  title: string
  summary: string
  author: string | null
  category: string | null
  tags: string | null
  coverImage: string | null
  createdAt?: number | null
  updatedAt?: number | null
  viewCount?: number | null
  weight?: number | null
}

type PostListResponse = {
  content: PostItem[]
  page: number
  totalPages: number
  totalElements: number
  size: number
}

const latestPosts = ref<PostItem[]>([])
const hotPosts = ref<PostItem[]>([])
const loading = ref(true)
const totalPosts = ref(0)

onMounted(async () => {
  auth.loadTokens()
  await Promise.all([loadLatestPosts(), loadHotPosts()])
})

const isLoggedIn = computed(() => !!auth.accessToken.value)
const isAdmin = computed(() => auth.role.value === 'admin')

const splitTags = (raw: string | null | undefined) => {
  return (raw || '')
    .split(/[,，、。;；|｜]/)
    .map(tag => tag.trim())
    .filter(Boolean)
}

const formatTime = (timestamp: number | null | undefined) => {
  if (!timestamp) return '最近更新'
  return new Date(timestamp).toLocaleDateString()
}

const loadLatestPosts = async () => {
  try {
    const data = await api<PostListResponse>('/api/posts?page=0&size=6&keyword=&sort=latest')
    latestPosts.value = data.content || []
    totalPosts.value = data.totalElements || 0
  } catch (error) {
    latestPosts.value = []
    totalPosts.value = 0
  }
}

const loadHotPosts = async () => {
  try {
    const data = await api<PostListResponse>('/api/posts/hot?size=6')
    hotPosts.value = data.content || []
  } catch (error) {
    hotPosts.value = []
  } finally {
    loading.value = false
  }
}

const categoryList = computed(() => {
  const map = new Map<string, number>()

  for (const post of latestPosts.value) {
    const key = (post.category || '未分类').trim() || '未分类'
    map.set(key, (map.get(key) || 0) + 1)
  }

  return Array.from(map.entries())
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 6)
})

const tagList = computed(() => {
  const map = new Map<string, number>()

  for (const post of latestPosts.value) {
    for (const tag of splitTags(post.tags)) {
      map.set(tag, (map.get(tag) || 0) + 1)
    }
  }

  return Array.from(map.entries())
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 10)
})

const latestUpdatedText = computed(() => {
  const timestamps = latestPosts.value
    .map(post => post.updatedAt || post.createdAt || 0)
    .filter(Boolean)

  if (timestamps.length === 0) return '暂无更新记录'

  const latest = Math.max(...timestamps)
  return formatTime(latest)
})

const secondaryCta = computed(() => {
  if (isAdmin.value) {
    return {
      to: '/dashboard',
      text: '进入后台'
    }
  }

  if (isLoggedIn.value) {
    return {
      to: '/my-posts',
      text: '我的文章'
    }
  }

  return {
    to: '/posts',
    text: '浏览文章'
  }
})
</script>

<template>
  <div class="min-h-screen bg-gray-100">
    <!-- Hero -->
    <section class="border-b border-gray-200 bg-white">
      <div class="max-w-6xl mx-auto px-4 py-14 md:py-20">
        <div class="grid gap-10 lg:grid-cols-[minmax(0,1fr)_340px] items-start">
          <div>
            <div class="inline-flex rounded-full bg-blue-50 px-4 py-1 text-sm text-blue-700">
              Rainstorm Blog / Engineering Content System
            </div>

            <h1 class="mt-6 text-4xl md:text-6xl font-bold tracking-tight text-gray-900 leading-tight">
              一个持续迭代中的
              <span class="text-blue-600">工程化个人博客系统</span>
            </h1>

            <p class="mt-6 max-w-3xl text-lg leading-8 text-gray-600">
              这是一个以内容发布为核心、以工程化演进为主线的博客项目。
              当前已经完成 JWT 登录鉴权、refresh 自动续期、admin / user 权限分级、
              后台全站文章管理、评论审核、Flyway 数据迁移规范化、
              Redis 缓存阅读统计、文章权重排序、Markdown 阅读增强、
              分类标签与分页搜索等核心能力。
            </p>

            <div class="mt-8 flex flex-wrap gap-4">
              <NuxtLink
                to="/create-post"
                class="rounded-xl bg-gray-900 px-6 py-3 text-white hover:bg-gray-800 transition"
              >
                开始写作
              </NuxtLink>

              <NuxtLink
                :to="secondaryCta.to"
                class="rounded-xl border border-gray-300 bg-white px-6 py-3 text-gray-700 hover:bg-gray-50 transition"
              >
                {{ secondaryCta.text }}
              </NuxtLink>
            </div>

            <div class="mt-10 flex flex-wrap gap-3 text-sm">
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">JWT 鉴权</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">Refresh 续期</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">Admin / User</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">全站文章管理</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">评论审核</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">Flyway 迁移</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">Redis 缓存</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">阅读量统计</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">阅读去重</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">定时回写</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">文章权重</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">热门排序</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">置顶 / 沉底</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">Markdown 渲染</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">目录 TOC</span>
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">代码高亮复制</span>
            </div>
          </div>

          <div class="grid gap-4">
            <div class="rounded-2xl border border-gray-200 bg-gray-900 p-6 text-white shadow-sm">
              <div class="text-sm text-gray-300">公开内容概览</div>
              <div class="mt-4 text-3xl font-bold">{{ totalPosts }}</div>
              <div class="mt-2 text-sm text-gray-400">当前已公开文章总数</div>
            </div>

            <div class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
              <div class="text-sm text-gray-500">最近更新</div>
              <div class="mt-3 text-xl font-semibold text-gray-900">
                {{ latestUpdatedText }}
              </div>
              <div class="mt-2 text-sm text-gray-600">
                首页数据由公开文章自动汇总生成
              </div>
            </div>

            <div class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
              <div class="text-sm text-gray-500">当前阶段设计</div>
              <ul class="mt-4 space-y-2 text-sm text-gray-700">
                <li>• 前后端分离，接口职责清晰</li>
                <li>• 已形成后台、权限、审核与排序体系</li>
                <li>• 支持通过权重对测试文章沉底或置顶</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- 最新文章 -->
    <section class="max-w-6xl mx-auto px-4 py-14">
      <div class="mb-8 flex items-end justify-between gap-4">
        <div>
          <h2 class="text-2xl md:text-3xl font-bold text-gray-900">最新文章</h2>
          <p class="mt-2 text-gray-600">按发布时间与权重综合排序的公开内容</p>
        </div>

        <NuxtLink
          to="/posts"
          class="text-sm font-medium text-blue-600 hover:text-blue-700"
        >
          查看全部 →
        </NuxtLink>
      </div>

      <div v-if="loading" class="text-gray-500">
        加载中...
      </div>

      <EmptyState
        v-else-if="latestPosts.length === 0"
        title="还没有文章"
        description="当前还没有最新文章内容，去发布第一篇文章吧。"
        action-text="去发布文章"
        action-to="/create-post"
      />

      <div v-else class="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
        <article
          v-for="post in latestPosts"
          :key="post.id"
          class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
        >
          <div class="h-52 bg-gray-100 flex items-center justify-center overflow-hidden">
            <img
              v-if="post.coverImage"
              :src="post.coverImage"
              alt="封面图"
              class="h-full w-full object-cover"
            />
            <div
              v-else
              class="flex h-full w-full items-center justify-center text-sm text-gray-400"
            >
              暂无封面
            </div>
          </div>

          <div class="p-5">
            <div class="mb-3 flex flex-wrap items-center gap-2 text-xs">
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">
                {{ post.author || '未知作者' }}
              </span>

              <span class="rounded-full bg-blue-50 px-3 py-1 text-blue-700">
                {{ post.category || '未分类' }}
              </span>
            </div>

            <NuxtLink :to="`/posts/${post.id}`" class="block">
              <h3 class="text-xl font-semibold text-gray-900 hover:text-blue-600 transition line-clamp-2 min-h-[3.5rem]">
                {{ post.title }}
              </h3>
            </NuxtLink>

            <p class="mt-3 text-sm leading-6 text-gray-600 line-clamp-3 min-h-[4.5rem]">
              {{ post.summary }}
            </p>

            <div class="mt-4 flex min-h-[2rem] flex-wrap gap-2 text-xs">
              <template v-for="tag in splitTags(post.tags).slice(0, 3)" :key="tag">
                <NuxtLink
                  :to="`/tags/${encodeURIComponent(tag)}`"
                  class="rounded-full bg-green-50 px-3 py-1 text-green-700 hover:bg-green-100 transition"
                >
                  # {{ tag }}
                </NuxtLink>
              </template>
            </div>

            <div class="mt-5 flex items-center justify-between gap-3">
              <div class="text-xs text-gray-500">
                <div>更新：{{ formatTime(post.updatedAt || post.createdAt) }}</div>
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
    </section>

    <!-- 热门文章 -->
    <section class="max-w-6xl mx-auto px-4 pb-14">
      <div class="mb-8 flex items-end justify-between gap-4">
        <div>
          <h2 class="text-2xl md:text-3xl font-bold text-gray-900">热门文章</h2>
          <p class="mt-2 text-gray-600">按权重与阅读量综合排序的公开内容</p>
        </div>

        <NuxtLink
          to="/posts"
          class="text-sm font-medium text-blue-600 hover:text-blue-700"
        >
          查看全部 →
        </NuxtLink>
      </div>

      <div v-if="!loading && hotPosts.length === 0" class="text-gray-500">
        暂无热门文章
      </div>

      <div v-else class="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
        <article
          v-for="post in hotPosts"
          :key="`hot-${post.id}`"
          class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
        >
          <div class="h-52 bg-gray-100 flex items-center justify-center overflow-hidden">
            <img
              v-if="post.coverImage"
              :src="post.coverImage"
              alt="封面图"
              class="h-full w-full object-cover"
            />
            <div
              v-else
              class="flex h-full w-full items-center justify-center text-sm text-gray-400"
            >
              暂无封面
            </div>
          </div>

          <div class="p-5">
            <div class="mb-3 flex flex-wrap items-center gap-2 text-xs">
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">
                {{ post.author || '未知作者' }}
              </span>

              <span class="rounded-full bg-orange-50 px-3 py-1 text-orange-700">
                热门
              </span>

              <span class="rounded-full bg-blue-50 px-3 py-1 text-blue-700">
                {{ post.category || '未分类' }}
              </span>
            </div>

            <NuxtLink :to="`/posts/${post.id}`" class="block">
              <h3 class="text-xl font-semibold text-gray-900 hover:text-blue-600 transition line-clamp-2 min-h-[3.5rem]">
                {{ post.title }}
              </h3>
            </NuxtLink>

            <p class="mt-3 text-sm leading-6 text-gray-600 line-clamp-3 min-h-[4.5rem]">
              {{ post.summary }}
            </p>

            <div class="mt-4 flex min-h-[2rem] flex-wrap gap-2 text-xs">
              <template v-for="tag in splitTags(post.tags).slice(0, 3)" :key="tag">
                <NuxtLink
                  :to="`/tags/${encodeURIComponent(tag)}`"
                  class="rounded-full bg-green-50 px-3 py-1 text-green-700 hover:bg-green-100 transition"
                >
                  # {{ tag }}
                </NuxtLink>
              </template>
            </div>

            <div class="mt-5 flex items-center justify-between gap-3">
              <div class="text-xs text-gray-500">
                <div>更新：{{ formatTime(post.updatedAt || post.createdAt) }}</div>
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
    </section>

    <!-- 分类 / 标签 -->
    <section class="bg-white border-y border-gray-200">
      <div class="max-w-6xl mx-auto px-4 py-14">
        <div class="grid gap-8 lg:grid-cols-2">
          <div>
            <div class="mb-6">
              <h2 class="text-2xl md:text-3xl font-bold text-gray-900">分类速览</h2>
              <p class="mt-2 text-gray-600">从最新公开内容中提取的分类分布</p>
            </div>

            <div class="grid gap-4 sm:grid-cols-2">
              <NuxtLink
                v-for="category in categoryList"
                :key="category.name"
                :to="`/categories/${encodeURIComponent(category.name)}`"
                class="rounded-2xl border border-gray-200 bg-gray-50 p-5 hover:bg-gray-100 transition"
              >
                <div class="text-lg font-semibold text-gray-900">{{ category.name }}</div>
                <div class="mt-2 text-sm text-gray-500">
                  最近文章中出现 {{ category.count }} 次
                </div>
              </NuxtLink>

              <div
                v-if="categoryList.length === 0"
                class="rounded-2xl border border-dashed border-gray-200 p-5 text-sm text-gray-500"
              >
                暂无分类数据
              </div>
            </div>
          </div>

          <div>
            <div class="mb-6">
              <h2 class="text-2xl md:text-3xl font-bold text-gray-900">标签速览</h2>
              <p class="mt-2 text-gray-600">快速进入你关心的内容主题</p>
            </div>

            <div class="rounded-2xl border border-gray-200 bg-gray-50 p-5">
              <div class="flex flex-wrap gap-3">
                <NuxtLink
                  v-for="tag in tagList"
                  :key="tag.name"
                  :to="`/tags/${encodeURIComponent(tag.name)}`"
                  class="rounded-full bg-white px-4 py-2 text-sm text-gray-700 border border-gray-200 hover:border-green-200 hover:bg-green-50 hover:text-green-700 transition"
                >
                  # {{ tag.name }}（{{ tag.count }}）
                </NuxtLink>

                <span
                  v-if="tagList.length === 0"
                  class="text-sm text-gray-500"
                >
                  暂无标签数据
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- 当前系统能力 -->
    <section class="max-w-6xl mx-auto px-4 py-14">
      <div class="mb-8">
        <h2 class="text-2xl md:text-3xl font-bold text-gray-900">当前系统能力</h2>
        <p class="mt-2 text-gray-600">项目现阶段已经完成的核心设计与能力模块</p>
      </div>

      <div class="grid gap-6 md:grid-cols-2 xl:grid-cols-4">
        <div class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
          <h3 class="text-lg font-semibold text-gray-900">认证体系</h3>
          <p class="mt-3 text-sm leading-6 text-gray-600">
            已完成注册、登录、JWT accessToken、refreshToken 自动续期，以及 logout 失效控制。
          </p>
        </div>

        <div class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
          <h3 class="text-lg font-semibold text-gray-900">权限分级</h3>
          <p class="mt-3 text-sm leading-6 text-gray-600">
            已完成 admin / user 角色分级，支持前端菜单、页面中间件与后端接口三级权限控制。
          </p>
        </div>

        <div class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
          <h3 class="text-lg font-semibold text-gray-900">后台管理</h3>
          <p class="mt-3 text-sm leading-6 text-gray-600">
            管理员已可查看全站文章、评论审核、状态切换、删除内容，并支持文章权重管理与排序控制。
          </p>
        </div>

        <div class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
          <h3 class="text-lg font-semibold text-gray-900">阅读与排序</h3>
          <p class="mt-3 text-sm leading-6 text-gray-600">
            已具备 Redis 阅读量统计、阅读去重、热门文章排序、文章权重置顶沉底，以及 Markdown 阅读增强能力。
          </p>
        </div>
      </div>
    </section>

    <!-- 系统架构 / 演进路线 -->
    <section class="bg-white border-y border-gray-200">
      <div class="max-w-6xl mx-auto px-4 py-14">
        <div class="mb-8">
          <h2 class="text-2xl md:text-3xl font-bold text-gray-900">系统架构 / 演进路线</h2>
          <p class="mt-2 text-gray-600">从博客页面到工程化内容系统的当前结构与下一步方向</p>
        </div>

        <div class="grid gap-6 md:grid-cols-2 xl:grid-cols-4">
          <div class="rounded-2xl border border-gray-200 bg-gray-50 p-6">
            <div class="text-lg font-semibold text-gray-900">认证层</div>
            <p class="mt-3 text-sm leading-6 text-gray-600">
              采用 JWT accessToken + refreshToken 方案，前端自动续期，后端通过 tokenVersion 控制失效。
            </p>
          </div>

          <div class="rounded-2xl border border-gray-200 bg-gray-50 p-6">
            <div class="text-lg font-semibold text-gray-900">内容层</div>
            <p class="mt-3 text-sm leading-6 text-gray-600">
              已完成文章发布、编辑、删除、分类、标签、搜索、分页、草稿 / 发布管理，并支持文章权重字段。
            </p>
          </div>

          <div class="rounded-2xl border border-gray-200 bg-gray-50 p-6">
            <div class="text-lg font-semibold text-gray-900">管理层</div>
            <p class="mt-3 text-sm leading-6 text-gray-600">
              admin 已具备全站文章管理、评论隐藏恢复删除、全站统计、后台导航骨架，以及权重调度能力。
            </p>
          </div>

          <div class="rounded-2xl border border-gray-200 bg-gray-50 p-6">
            <div class="text-lg font-semibold text-gray-900">数据层</div>
            <p class="mt-3 text-sm leading-6 text-gray-600">
              已接入 Flyway 数据迁移，完成 role、comment.status、view_count、weight 等字段演进，后续升级更可控。
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA -->
    <section class="max-w-6xl mx-auto px-4 pb-14 pt-14">
      <div class="rounded-3xl bg-gray-900 px-8 py-12 text-center text-white">
        <h2 class="text-2xl md:text-3xl font-bold">准备继续扩展这个博客系统了吗？</h2>
        <p class="mt-3 text-gray-300">
          现在它已经不仅能发文章，也具备了认证、权限、后台管理、评论审核、阅读统计、权重排序与数据迁移规范化的系统基础。
        </p>

        <div class="mt-8 flex flex-wrap justify-center gap-4">
          <NuxtLink
            to="/create-post"
            class="rounded-xl bg-white px-6 py-3 text-gray-900 hover:bg-gray-100 transition"
          >
            去发布文章
          </NuxtLink>

          <NuxtLink
            :to="secondaryCta.to"
            class="rounded-xl border border-gray-600 px-6 py-3 text-white hover:bg-gray-800 transition"
          >
            {{ secondaryCta.text }}
          </NuxtLink>
        </div>
      </div>
    </section>
  </div>
</template>
