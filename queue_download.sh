#!/bin/sh

# 用空格分隔的 URL 字符串
URLS="\
https://p16-oec-ttp.tiktokcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg \
https://p19-oec-ttp.tiktokcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg \
https://p16-oec-ttp-useast5.ttcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg \
https://p19-oec-ttp-useast5.ttcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg"

# 兼容 dash 的循环方式
i=1
while [ "$i" -le 20 ]; do
  echo "============= 第 $i 轮下载 ============="
  
  for url in $URLS; do
    echo "下载中: $url"

    # 下载文件，设置 30 秒超时，保存 header
    curl -m 30 -s -o /tmp/tmp_output -D /tmp/tmp_header -L "$url" \
      -w "平均速度: %{speed_download} bytes/s\n下载时间: %{time_total} 秒\n" > /tmp/curl_output.log

    code=$?

    echo "URL: $url"

    if [ "$code" = "0" ]; then
      # 提取状态码
      status=$(grep -i "^HTTP/" /tmp/tmp_header | tail -1 | cut -d' ' -f2)
      echo "状态码: $status"
      cat /tmp/curl_output.log

      st=$(grep -i "server-timing:" /tmp/tmp_header)
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

  i=$((i + 1))  # dash 支持这种形式的算术运算
done
