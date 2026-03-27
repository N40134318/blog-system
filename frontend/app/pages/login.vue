<script setup lang="ts">
import type { ApiResponse } from '~/types/api'

const auth = useAuth()
const config = useRuntimeConfig()
const apiBase = config.public.apiBase

const username = ref('')
const password = ref('')
const loading = ref(false)
const errorMessage = ref('')

const submit = async () => {
  if (!username.value.trim()) {
    errorMessage.value = '用户名不能为空'
    return
  }

  if (!password.value.trim()) {
    errorMessage.value = '密码不能为空'
    return
  }

  try {
    loading.value = true
    errorMessage.value = ''

    const res = await $fetch<ApiResponse<{ accessToken: string; refreshToken: string; role: string }>>(
      `${apiBase}/api/login`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: {
          username: username.value,
          password: password.value
        }
      }
    )

    if (
      res.code !== 200 ||
      !res.data?.accessToken ||
      !res.data?.refreshToken ||
      !res.data?.role
    ) {
      throw new Error(res.message || '登录失败')
    }

    auth.setTokens(
      res.data.accessToken,
      res.data.refreshToken,
      res.data.role
    )

    window.location.href = '/?login=success'
  } catch (error: any) {
    errorMessage.value =
      error?.data?.message ||
      error?.message ||
      '登录失败'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-100 flex items-center justify-center px-4 py-10">
    <div class="w-full max-w-md rounded-2xl border border-gray-200 bg-white p-8 shadow-sm">
      <div class="mb-8 text-center">
        <h1 class="text-3xl font-bold text-gray-900">登录</h1>
        <p class="mt-2 text-sm text-gray-600">登录后可发布、编辑文章和参与评论</p>
      </div>

      <div class="space-y-5">
        <div>
          <label class="mb-2 block text-sm font-medium text-gray-700">用户名</label>
          <input
            v-model="username"
            type="text"
            placeholder="请输入用户名"
            class="w-full rounded-xl border border-gray-300 px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div>
          <label class="mb-2 block text-sm font-medium text-gray-700">密码</label>
          <input
            v-model="password"
            type="password"
            placeholder="请输入密码"
            class="w-full rounded-xl border border-gray-300 px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500"
            @keyup.enter="submit"
          />
        </div>

        <button
          @click="submit"
          :disabled="loading"
          class="w-full rounded-xl bg-gray-900 px-4 py-3 text-white transition hover:bg-gray-800 disabled:opacity-50"
        >
          {{ loading ? '登录中...' : '立即登录' }}
        </button>

        <p v-if="errorMessage" class="text-sm text-red-600">
          {{ errorMessage }}
        </p>
      </div>

      <div class="mt-8 border-t border-gray-200 pt-6 text-center text-sm text-gray-600">
        还没有账号？
        <NuxtLink to="/register" class="font-medium text-blue-600 hover:text-blue-700">
          去注册
        </NuxtLink>
      </div>
    </div>
  </div>
</template>
