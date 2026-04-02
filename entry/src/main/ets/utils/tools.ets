export const ConvertTime = (num: number | null | undefined) => {
  if (!num || num <= 0) {
    return '00:00'
  }
  let mm = Math.floor(num / 60000).toString().padStart(2, '0');
  let ss = Math.floor((num / 1000) % 60).toString().padStart(2, '0');
  let result = `${mm}:${ss}`
  return result
}