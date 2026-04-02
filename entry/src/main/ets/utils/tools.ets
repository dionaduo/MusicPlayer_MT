import { common } from '@kit.AbilityKit';
import { request } from '@kit.BasicServicesKit';
import { fileIo as fs, picker } from '@kit.CoreFileKit';
import { promptAction } from '@kit.ArkUI';

export const ConvertTime = (num: number | null | undefined): string => {
  if (!num || num <= 0) return '00:00';
  const mm = Math.floor(num / 60000).toString().padStart(2, '0');
  const ss = Math.floor((num / 1000) % 60).toString().padStart(2, '0');
  return `${mm}:${ss}`;
};

async function showToast(message: string): Promise<void> {
  try {
    await promptAction.showToast({ message, duration: 3000, bottom: '10%' });
  } catch (error) {
    console.error('Toast提示失败:', error);
  }
}

async function saveToPublicDir(context: common.UIAbilityContext, sandboxPath: string, fileName: string): Promise<boolean> {
  try {
    const docPicker = new picker.DocumentViewPicker(context);
    const options = new picker.DocumentSaveOptions();
    options.newFileNames = [fileName];

    const uris = await docPicker.save(options);
    if (!uris || uris.length === 0) {
      console.error('用户取消了文件保存');
      return false;
    }

    const sourceFile = await fs.open(sandboxPath, fs.OpenMode.READ_ONLY);
    const destFile = await fs.open(uris[0], fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);

    const sourceStat = await fs.stat(sourceFile.fd);
    const buffer = new ArrayBuffer(sourceStat.size);
    await fs.read(sourceFile.fd, buffer);
    await fs.write(destFile.fd, buffer);

    await fs.close(sourceFile.fd);
    await fs.close(destFile.fd);

    console.info('文件已保存到公共目录');
    return true;
  } catch (err) {
    console.error('保存到公共目录失败:', JSON.stringify(err));
    return false;
  }
}

export const downMusic = async (url: string, fileName: string, context: common.UIAbilityContext): Promise<boolean> => {
  let sandboxPath = '';

  try {
    sandboxPath = `${context.cacheDir}/${fileName}`;
    const downloadTask = await request.downloadFile(context, { url, filePath: sandboxPath });
    console.log('下载任务创建成功, taskId:', JSON.stringify(downloadTask));
    await showToast('正在下载中,请稍后.....')

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
    const stat = await fs.stat(sandboxPath);
    if (stat.size === 0) {
      await showToast('下载失败: 文件大小为0');
      return false;
    }
    const saveSuccess = await saveToPublicDir(context, sandboxPath, fileName);
    if (saveSuccess) {
      await showToast(`下载成功: ${fileName}`);
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
