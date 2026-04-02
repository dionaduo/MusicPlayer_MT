/**
 * @file tools.ets
 * @description 工具函数集合
 * @module utils
 * @author CodeArts
 * @date 2026-04-02
 *
 * 功能特性:
 * - 时间格式转换
 * - 音乐下载功能
 * - 文件保存到公共目录
 * - Toast提示
 * - 自动清理临时文件
 */

import { common } from '@kit.AbilityKit';
import { request } from '@kit.BasicServicesKit';
import { fileIo as fs, picker } from '@kit.CoreFileKit';
import { promptAction } from '@kit.ArkUI';

/**
 * ConvertTime 时间转换函数
 * 将毫秒数转换为 MM:SS 格式
 * @param num 毫秒数
 * @returns 格式化后的时间字符串 MM:SS
 * @example
 * ConvertTime(65000) // 返回 "01:05"
 * ConvertTime(0) // 返回 "00:00"
 */
export const ConvertTime = (num: number | null | undefined): string => {
  if (!num || num <= 0) return '00:00';
  const mm = Math.floor(num / 60000).toString().padStart(2, '0');
  const ss = Math.floor((num / 1000) % 60).toString().padStart(2, '0');
  return `${mm}:${ss}`;
};

/**
 * showToast 显示Toast提示
 * @param message 提示消息
 */
async function showToast(message: string): Promise<void> {
  try {
    await promptAction.showToast({ message, duration: 3000, bottom: '10%' });
  } catch (error) {
    console.error('Toast提示失败:', error);
  }
}

/**
 * saveToPublicDir 保存文件到公共目录
 * 先下载到沙箱目录,然后通过文件选择器保存到用户选择的公共目录
 * @param context 上下文
 * @param sandboxPath 沙箱文件路径
 * @param fileName 文件名
 * @returns 是否保存成功
 */
async function saveToPublicDir(context: common.UIAbilityContext, sandboxPath: string, fileName: string): Promise<boolean> {
  try {
    // 创建文件选择器
    const docPicker = new picker.DocumentViewPicker(context);
    const options = new picker.DocumentSaveOptions();
    options.newFileNames = [fileName];

    // 打开文件保存对话框
    const uris = await docPicker.save(options);
    if (!uris || uris.length === 0) {
      console.error('用户取消了文件保存');
      return false;
    }

    // 打开源文件(只读)
    const sourceFile = await fs.open(sandboxPath, fs.OpenMode.READ_ONLY);
    // 打开目标文件(写入|创建)
    const destFile = await fs.open(uris[0], fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);

    // 读取源文件内容
    const sourceStat = await fs.stat(sourceFile.fd);
    const buffer = new ArrayBuffer(sourceStat.size);
    await fs.read(sourceFile.fd, buffer);

    // 写入目标文件
    await fs.write(destFile.fd, buffer);

    // 关闭文件
    await fs.close(sourceFile.fd);
    await fs.close(destFile.fd);

    console.info('文件已保存到公共目录');
    return true;
  } catch (err) {
    console.error('保存到公共目录失败:', JSON.stringify(err));
    return false;
  }
}

/**
 * downMusic 下载音乐并保存到公共目录
 * 先下载到沙箱缓存目录,然后通过文件选择器保存到用户选择的公共目录
 * @param url 音乐URL
 * @param fileName 文件名
 * @param context 上下文
 * @returns 下载是否成功
 * @example
 * const success = await downMusic('https://example.com/music.mp3', 'song.mp3', context);
 * if (success) {
 *   console.log('下载成功');
 * }
 */
export const downMusic = async (url: string, fileName: string, context: common.UIAbilityContext): Promise<boolean> => {
  let sandboxPath = '';

  try {
    // 1. 下载到沙箱缓存目录
    sandboxPath = `${context.cacheDir}/${fileName}`;
    const downloadTask = await request.downloadFile(context, { url, filePath: sandboxPath });
    console.log('下载任务创建成功, taskId:', JSON.stringify(downloadTask));
    await showToast('正在下载中,请稍后.....')

    // 等待下载完成
    await new Promise<void>((resolve, reject) => {
      downloadTask.on('complete', () => {
        console.log('下载完成');
        resolve();
      });
      downloadTask.on('fail', (err) => {
        console.error('下载失败:', JSON.stringify(err));
        reject(new Error(`下载失败: ${JSON.stringify(err)}`));
      });
    });

    // 检查下载的文件
    const stat = await fs.stat(sandboxPath);
    if (stat.size === 0) {
      await showToast('下载失败: 文件大小为0');
      return false;
    }

    // 2. 保存到公共目录
    const saveSuccess = await saveToPublicDir(context, sandboxPath, fileName);
    if (saveSuccess) {
      await showToast(`下载成功: ${fileName}`);

      // 清理沙箱临时文件
      try {
        await fs.unlink(sandboxPath);
      } catch (err) {
        console.warn('删除临时文件失败:', err);
      }

      return true;
    } else {
      console.error('保存到公共目录失败');
      await showToast('保存失败,请重试');
      return false;
    }
  } catch (error) {
    console.error('下载过程出错:', JSON.stringify(error));
    await showToast('下载失败,请重试');

    // 清理可能存在的临时文件
    if (sandboxPath) {
      try {
        await fs.unlink(sandboxPath);
        console.log('清理临时文件');
      } catch (err) {
        console.warn('清理临时文件失败:', err);
      }
    }

    return false;
  }
};
