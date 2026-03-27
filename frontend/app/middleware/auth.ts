export default defineNuxtRouteMiddleware((to) => {
    if (import.meta.server) return

    const accessToken = localStorage.getItem('accessToken')
    const role = localStorage.getItem('role')

    // 需要登录的页面
    const needLogin =
        to.path.startsWith('/my-posts') ||
        to.path.startsWith('/create-post') ||
        to.path.startsWith('/edit-post')

    // 管理员后台页面
    const needAdmin =
        to.path === '/dashboard' ||
        to.path.startsWith('/dashboard/')

    if (!accessToken && (needLogin || needAdmin)) {
        return navigateTo(`/login?redirect=${encodeURIComponent(to.fullPath)}`, {
            replace: true
        })
    }

    if (needAdmin && role !== 'admin') {
        return navigateTo('/', { replace: true })
    }
})
