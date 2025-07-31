@echo off
echo ========================================
echo    RENTILAX MARKER - Lancement
echo ========================================
echo.
echo Verification des dependances...
flutter pub get
echo.
echo Lancement sur Chrome (recommande)...
echo L'application va s'ouvrir dans votre navigateur.
echo.
flutter run -d chrome
echo.
echo Application fermee.
pause