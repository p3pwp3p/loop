#!/usr/bin/env bash
# LOOP 웹 배포 스크립트
#
# Vercel은 이 repo에 커밋된 build/web 정적 산출물을 그대로 서빙한다
# (vercel.json 참고). Flutter를 Vercel에서 직접 빌드하는 방식은 root/SDK
# 환경 문제로 실패해서, "로컬에서 빌드 → build/web 커밋 → push" 방식으로 배포한다.
#
# 사용법 (프로젝트 루트에서):  bash deploy.sh  ["커밋 메시지"]
set -e

MSG="${1:-deploy: rebuild web $(date +%Y-%m-%d_%H:%M)}"

echo "▶ Flutter 웹 릴리즈 빌드..."
flutter build web --release

echo "▶ build/web 스테이징 (gitignore 무시)..."
git add -f build/web
git add -A

if git diff --cached --quiet; then
  echo "변경 사항 없음. 종료."
  exit 0
fi

echo "▶ 커밋 & 푸시..."
git commit -m "$MSG"
git push origin main

echo "✅ 푸시 완료. Vercel이 자동으로 재배포합니다 (정적 서빙, 수 초 내 Ready)."
