#!/bin/sh

# 获取第一个参数，作为循环次数
count="$1"

# 如果未传参数，默认执行 5 次
if [ -z "$count" ]; then
  count=20
fi

echo "--- 脚本将执行 $count 轮数据下载 ---"

# 用空格分隔的 URL 字符串
URLS="\
https://p16-oec-ttp.tiktokcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg \
https://p19-oec-ttp.tiktokcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg \
https://p16-oec-ttp-useast5.ttcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg \
https://p19-oec-ttp-useast5.ttcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg"

i=1
while [ "$i" -le "$count" ]; do
  echo "============= 第 $i 轮下载 ============="

  for url in $URLS; do
    echo "下载中: $url"

    curl -m 30 -s -o ./tmp_output -D ./tmp_header -L "$url" \
      -w "平均速度: %{speed_download} bytes/s\n下载时间: %{time_total} 秒\n" > ./curl_output.log

    code=$?

    echo "URL: $url"

    if [ "$code" = "0" ]; then
      status=$(grep -i "^HTTP/" ./tmp_header | tail -1 | awk '{print $2}')
      echo "状态码: $status"
      cat ./curl_output.log

      st=$(grep -i "server-timing:" ./tmp_header)
      if [ -n "$st" ]; then
        echo "Server-Timing: $st"
      else
        echo "Server-Timing: (无)"
      fi
    else
      if [ "$code" = "28" ]; then
        echo "❌ 下载失败：超时"
      else
        echo "❌ 下载失败，curl 返回码: $code"
      fi
    fi

    echo "----------------------------------------"
  done

  i=$((i + 1))
done
