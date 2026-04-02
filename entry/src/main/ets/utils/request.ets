import axios, { AxiosError, AxiosInstance, AxiosResponse, InternalAxiosRequestConfig } from '@ohos/axios'

// 创建 axios 实例
const axiosInstance: AxiosInstance = axios.create({
  baseURL: 'https://api.qqmp3.vip/api/',
  timeout: 60000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器
axiosInstance.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    console.log('请求发送:')
    return config
  },
  (error: AxiosError) => {
    console.error('请求错误:', error)
    return Promise.reject(error)
  }
)

// 响应拦截器
axiosInstance.interceptors.response.use(
  (response: AxiosResponse) => {
    console.log('响应接收:', response.status, JSON.stringify(response.data))
    return response.data
  },
  (error: AxiosError) => {
    console.error('响应错误:', error)
    return Promise.reject(error)
  }
)

// 导出 axios 实例
export { axiosInstance as request }

// 也可以导出默认的 axios
export { axios }
