#!/bin/sh

# 获取第一个参数，作为循环次数
PARAMS="$1"
count="$2"

if [ -z "$PARAMS" ]; then
  echo "缺少需要执行的参数"
  EXIT
fi

# 如果未传参数，默认执行 5 次
if [ -z "$count" ]; then
  count=20
fi

echo "--- 脚本将执行 $count 轮数据下载 ---"


i=1
while [ "$i" -le "$count" ]; do
  echo "============= 第 $i 轮下载 ============="

  # for url in $PARAMS; do
    # echo "下载中: $PARAMS"

    eval "$PARAMS"

  echo "----------------------------------------"
  # done

  i=$((i + 1))
done
