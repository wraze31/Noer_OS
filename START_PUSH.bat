@echo off
echo ===================================================
echo Обновление кода Noer OS на GitHub...
echo ===================================================
cd /d "C:\Users\lubys\OneDrive\Desktop\Custom_Live_OS"
git add .
git commit -m "Update OS name to Noer OS"
git push -u origin main
echo.
echo Изменения отправлены! Возвращайся на сайт GitHub!
pause
