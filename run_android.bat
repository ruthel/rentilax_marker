@echo off
echo ========================================
echo    RENTILAX MARKER - Android
echo ========================================
echo.
echo Configuration de Gradle...
set PATH=%PATH%;C:\Users\baloc\AndroidStudioProjects\Marker\gradle-8.12\gradle-8.12\bin

echo.
echo Verification des appareils Android...
flutter devices

echo.
echo Lancement sur Android...
echo L'application va s'installer et se lancer sur votre appareil.
echo.

flutter run -d R58X60DZY5W

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Erreur detectee. Tentative de construction APK...
    flutter build apk --debug
    echo.
    echo APK cree dans: build\app\outputs\flutter-apk\app-debug.apk
    echo Vous pouvez l'installer manuellement sur votre appareil.
)

pause