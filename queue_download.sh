#!/bin/bash

# 下载 URL 队列
urls=(
  "https://p16-oec-ttp.tiktokcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg"
  "https://p19-oec-ttp.tiktokcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg"
  "https://p16-oec-ttp-useast5.ttcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg"
  "https://p19-oec-ttp-useast5.ttcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg"
)

# 临时文件
tmp_output="tmp_output"
tmp_header="tmp_header"

# 执行 20 次循环
for round in $(seq 1 20); do
  echo "============= 第 $round 轮下载 ============="

  for url in "${urls[@]}"; do
    echo "下载中: $url"

    # 执行 curl 下载，输出 header 到 tmp_header，数据输出到 tmp_output，最多耗时 30 秒
    curl -m 30 -o "$tmp_output" -s -D "$tmp_header" -L "$url" -w "\n平均速度: %{speed_download} bytes/s\n下载时间: %{time_total} 秒\n" > /tmp/curl_output.log
    curl_status=$?

    # 打印 URL
    echo "URL: $url"

    if [ $curl_status -eq 0 ]; then
      # 获取状态码
      status_code=$(grep -i "^HTTP/" "$tmp_header" | tail -1 | awk '{print $2}')
      echo "状态码: $status_code"

      # 打印 curl 输出的速度和时间
      cat /tmp/curl_output.log

      # 提取 Server-Timing
      server_timing=$(grep -i "server-timing:" "$tmp_header" | sed 's/\r//g')
      if [[ -n "$server_timing" ]]; then
        echo "Server-Timing: $server_timing"
      else
        echo "Server-Timing: (无)"
      fi
    else
      if [ $curl_status -eq 28 ]; then
        echo "❌ 下载失败：超时（curl 返回码 28）"
      else
        echo "❌ 下载失败，curl 返回码: $curl_status"
      fi
    fi

    echo "----------------------------------------"
  done
done

# 清理临时文件
rm -f "$tmp_output" "$tmp_header" /tmp/curl_output.log
