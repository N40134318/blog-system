<script setup lang="ts">
const highlights = [
  {
    title: '面向写作',
    description: '围绕文章发布、编辑、阅读、分类和标签组织内容，让个人博客保持清晰可维护。'
  },
  {
    title: '前后端分离',
    description: 'Nuxt 前端负责交互体验，Spring Boot 后端提供 API，MySQL 和 Redis 承载数据与缓存。'
  },
  {
    title: '本地可部署',
    description: '当前迁移到 Ubuntu VM，通过 Docker Compose 管理服务，便于在本机网络内验证和迭代。'
  }
]

const stack = [
  'Nuxt 3',
  'Vue 3',
  'Tailwind CSS',
  'Spring Boot',
  'MySQL',
  'Redis',
  'Docker Compose'
]

const roadmap = [
  '完善文章管理和发布流程',
  '沉淀 VM 部署、回滚和排障文档',
  '补齐数据备份、恢复与上传目录迁移流程',
  '持续整理 README，让新环境可以按步骤复现'
]
</script>

<template>
  <div class="min-h-screen bg-gray-100">
    <div class="mx-auto max-w-6xl px-4 py-8">
      <section class="mb-8">
        <div class="rounded-3xl border border-gray-200 bg-white p-6 shadow-sm md:p-8">
          <div class="flex flex-col gap-8 lg:flex-row lg:items-end lg:justify-between">
            <div class="max-w-3xl">
              <div class="inline-flex rounded-full bg-blue-50 px-4 py-1 text-sm text-blue-700">
                About
              </div>

              <h1 class="mt-4 text-3xl font-bold text-gray-900 md:text-4xl">
                关于 Rainstorm Blog
              </h1>

              <p class="mt-4 text-base leading-8 text-gray-600 md:text-lg">
                Rainstorm Blog 是一个用于记录文章、分类知识和管理内容的个人博客系统。
                现在它已经迁移到本地 Ubuntu VM，适合继续做功能开发、部署实验和运维流程沉淀。
              </p>
            </div>

            <div class="flex flex-wrap gap-3">
              <NuxtLink
                to="/posts"
                class="rounded-xl bg-gray-900 px-5 py-3 text-sm text-white transition hover:bg-gray-800"
              >
                浏览文章
              </NuxtLink>

              <NuxtLink
                to="/categories"
                class="rounded-xl border border-gray-300 bg-white px-5 py-3 text-sm text-gray-700 transition hover:bg-gray-50"
              >
                查看分类
              </NuxtLink>
            </div>
          </div>
        </div>
      </section>

      <section class="mb-8 grid gap-4 md:grid-cols-3">
        <article
          v-for="item in highlights"
          :key="item.title"
          class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm"
        >
          <h2 class="text-lg font-semibold text-gray-900">
            {{ item.title }}
          </h2>

          <p class="mt-3 leading-7 text-gray-600">
            {{ item.description }}
          </p>
        </article>
      </section>

      <section class="mb-8 grid gap-8 lg:grid-cols-[1.2fr_0.8fr]">
        <div class="rounded-3xl border border-gray-200 bg-white p-6 shadow-sm md:p-8">
          <div class="inline-flex rounded-full bg-emerald-50 px-4 py-1 text-sm text-emerald-700">
            Migration
          </div>

          <h2 class="mt-4 text-2xl font-bold text-gray-900">
            本地 VM 迁移实验
          </h2>

          <p class="mt-4 leading-8 text-gray-600">
            本次迁移的目标是把 GitHub 上的博客系统接入本地虚拟机环境：
            代码从 GitHub 拉取，服务在 VM 内构建和运行，前端通过局域网访问后端 API。
            迁移过程中的环境变量、Docker Compose 配置、CORS 调整、GitHub SSH 连接和排障记录都会持续写入文档。
          </p>

          <div class="mt-6 grid gap-3 sm:grid-cols-2">
            <div class="rounded-2xl bg-gray-50 p-4">
              <div class="text-sm text-gray-500">运行位置</div>
              <div class="mt-2 font-semibold text-gray-900">Ubuntu VM</div>
            </div>

            <div class="rounded-2xl bg-gray-50 p-4">
              <div class="text-sm text-gray-500">代码来源</div>
              <div class="mt-2 font-semibold text-gray-900">GitHub main</div>
            </div>

            <div class="rounded-2xl bg-gray-50 p-4">
              <div class="text-sm text-gray-500">前端端口</div>
              <div class="mt-2 font-semibold text-gray-900">3001</div>
            </div>

            <div class="rounded-2xl bg-gray-50 p-4">
              <div class="text-sm text-gray-500">后端端口</div>
              <div class="mt-2 font-semibold text-gray-900">8081</div>
            </div>
          </div>
        </div>

        <aside class="rounded-3xl border border-gray-200 bg-white p-6 shadow-sm md:p-8">
          <div class="inline-flex rounded-full bg-amber-50 px-4 py-1 text-sm text-amber-700">
            Stack
          </div>

          <h2 class="mt-4 text-2xl font-bold text-gray-900">
            技术栈
          </h2>

          <div class="mt-5 flex flex-wrap gap-2">
            <span
              v-for="item in stack"
              :key="item"
              class="rounded-full bg-gray-100 px-3 py-2 text-sm text-gray-700"
            >
              {{ item }}
            </span>
          </div>
        </aside>
      </section>

      <section class="rounded-3xl border border-gray-200 bg-white p-6 shadow-sm md:p-8">
        <div class="flex flex-col gap-6 lg:flex-row lg:items-start lg:justify-between">
          <div class="max-w-2xl">
            <div class="inline-flex rounded-full bg-slate-100 px-4 py-1 text-sm text-slate-700">
              Next
            </div>

            <h2 class="mt-4 text-2xl font-bold text-gray-900">
              接下来会继续完善
            </h2>

            <p class="mt-4 leading-8 text-gray-600">
              这个页面会随着系统迁移和功能迭代继续更新，作为对外介绍和内部维护说明之间的连接页。
            </p>
          </div>

          <ul class="grid gap-3 text-sm text-gray-700 sm:grid-cols-2 lg:max-w-xl">
            <li
              v-for="item in roadmap"
              :key="item"
              class="rounded-2xl bg-gray-50 px-4 py-3"
            >
              {{ item }}
            </li>
          </ul>
        </div>
      </section>
    </div>
  </div>
</template>
