/**
 * @file request.ets
 * @description 网络请求封装
 * @module utils
 * @author CodeArts
 * @date 2026-04-02
 *
 * 功能特性:
 * - 基于axios的网络请求封装
 * - 请求/响应拦截器
 * - 统一的错误处理
 * - 自动日志记录
 */

import axios, { AxiosError, AxiosInstance, AxiosResponse, InternalAxiosRequestConfig } from '@ohos/axios'

/**
 * 创建axios实例
 * 配置基础URL、超时时间和请求头
 */
const axiosInstance: AxiosInstance = axios.create({
  baseURL: 'https://api.qqmp3.vip/api/',
  timeout: 60000,
  headers: {
    'Content-Type': 'application/json'
  }
})

/**
 * 请求拦截器
 * 在请求发送前执行,可用于添加token、修改配置等
 */
axiosInstance.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    console.log('请求发送:', JSON.stringify(config))
    return config
  },
  (error: AxiosError) => {
    console.error('请求错误:', error)
    return Promise.reject(error)
  }
)

/**
 * 响应拦截器
 * 在响应返回后执行,可用于统一处理响应数据、错误等
 */
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

// 导出axios实例和axios对象
export { axiosInstance as request }
export { axios }
