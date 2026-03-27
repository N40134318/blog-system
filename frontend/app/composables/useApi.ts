import type { ApiResponse } from '~/types/api'

let isRefreshing = false
let refreshPromise: Promise<void> | null = null

export const useApi = () => {
    const auth = useAuth()
    const config = useRuntimeConfig()
    const apiBase = config.public.apiBase

    const requestRefresh = async () => {
        if (!import.meta.client) {
            throw new Error('当前环境无法刷新登录状态')
        }

        auth.loadTokens()
        const currentRefreshToken = auth.refreshToken.value

        if (!currentRefreshToken) {
            auth.clearTokens()
            throw new Error('登录已过期，请重新登录')
        }

        if (isRefreshing && refreshPromise) {
            return refreshPromise
        }

        isRefreshing = true

        refreshPromise = (async () => {
            try {
                const res = await $fetch<ApiResponse<{ accessToken: string; refreshToken: string; role: string }>>(
                    `${apiBase}/api/refresh`,
                    {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: {
                            refreshToken: currentRefreshToken
                        }
                    }
                )

                if (
                    res.code !== 200 ||
                    !res.data?.accessToken ||
                    !res.data?.refreshToken ||
                    !res.data?.role
                ) {
                    throw new Error(res.message || '刷新登录状态失败')
                }

                auth.setTokens(
                    res.data.accessToken,
                    res.data.refreshToken,
                    res.data.role
                )
            } catch (error) {
                auth.clearTokens()
                throw error
            } finally {
                isRefreshing = false
                refreshPromise = null
            }
        })()

        return refreshPromise
    }

    return async <T>(url: string, options: any = {}) => {
        if (import.meta.client) {
            auth.loadTokens()
        }

        const doRequest = async () => {
            const headers: Record<string, string> = {
                ...(options.headers || {})
            }

            if (!(options.body instanceof FormData)) {
                headers['Content-Type'] = 'application/json'
            }

            if (auth.accessToken.value) {
                headers['Authorization'] = `Bearer ${auth.accessToken.value}`
            }

            return await $fetch<ApiResponse<T>>(`${apiBase}${url}`, {
                ...options,
                headers
            })
        }

        try {
            const res = await doRequest()

            if (res.code !== 200) {
                throw new Error(res.message || '请求失败')
            }

            return res.data
        } catch (error: any) {
            const message = error?.data?.message || error?.message || ''

            const shouldRefresh =
                import.meta.client &&
                auth.refreshToken.value &&
                typeof message === 'string' &&
                (
                    message.includes('token无效') ||
                    message.includes('token已过期') ||
                    message.includes('token无效或已过期')
                )

            if (!shouldRefresh) {
                throw new Error(message || '请求失败')
            }

            try {
                await requestRefresh()

                const retryRes = await doRequest()
                if (retryRes.code !== 200) {
                    throw new Error(retryRes.message || '请求失败')
                }

                return retryRes.data
            } catch (refreshError: any) {
                auth.clearTokens()

                if (import.meta.client) {
                    const currentPath = window.location.pathname + window.location.search
                    window.location.href = `/login?redirect=${encodeURIComponent(currentPath)}`
                }

                throw new Error(
                    refreshError?.data?.message ||
                    refreshError?.message ||
                    '登录已过期，请重新登录'
                )
            }
        }
    }
}
