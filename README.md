# ROXCARD

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue.svg" alt="версия">
  <img src="https://img.shields.io/badge/Flutter-3.10%2B-blue.svg" alt="Flutter версия">
  <img src="https://img.shields.io/badge/Dart-3.0%2B-blue.svg" alt="Dart версия">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="лицензия">
</p>

![ROXCARD баннер](https://via.placeholder.com/800x200?text=ROXCARD+-+%D0%AD%D0%BC%D1%83%D0%BB%D1%8F%D1%82%D0%BE%D1%80+%D0%B1%D0%B0%D0%BD%D0%BA%D0%BE%D0%B2%D1%81%D0%BA%D0%B8%D1%85+%D0%BA%D0%B0%D1%80%D1%82)

## Описание

ROXCARD - это мобильное приложение на Flutter для эмуляции банковских карт через NFC. Приложение использует технологию Host Card Emulation (HCE) на устройствах Android для эмуляции банковских карт, позволяя пользователям хранить и использовать свои карты на мобильном устройстве.

## Основные функции

- 💳 Добавление и хранение банковских карт разных типов (Visa, MasterCard, AmEx и др.)
- 📱 Эмуляция карт через NFC
- 🔒 Шифрование и безопасное хранение данных карт
- ⭐ Возможность отмечать карты как избранные
- 🖌️ Кастомизация внешнего вида карт
- 📊 Отслеживание использования карт

## Скриншоты

<div align="center">
    <img src="https://via.placeholder.com/270x500?text=Домашний+экран" alt="Домашний экран" width="270">
    <img src="https://via.placeholder.com/270x500?text=Добавление+карты" alt="Добавление карты" width="270">
    <img src="https://via.placeholder.com/270x500?text=NFC+эмуляция" alt="NFC эмуляция" width="270">
</div>

## Установка

### Системные требования

- Flutter 3.10.0 или выше
- Dart 3.0.0 или выше
- Android 7.0 (API уровень 24) или выше с поддержкой NFC и HCE
- iOS 14.0 или выше (с ограниченной функциональностью)

### Запуск

Клонируйте репозиторий и запустите приложение:

```bash
git clone https://github.com/username/roxcard.git
cd roxcard
flutter pub get
flutter run
```

### Сборка APK

```bash
flutter build apk --release
```

APK файл будет доступен по пути: `build/app/outputs/flutter-apk/app-release.apk`

## Получение APK через GitHub Actions

Проект настроен с использованием GitHub Actions для автоматической сборки APK при каждом коммите в ветку `main` или создании тега версии.

### Как получить собранный APK:

1. Перейдите на вкладку "Actions" в репозитории GitHub
2. Выберите последний успешный запуск workflow (обозначен зеленой галочкой)
3. Прокрутите страницу вниз до раздела "Artifacts"
4. Скачайте артефакт "app-release" для финальной версии или "app-debug" для отладочной версии

### Создание релиза с APK:

1. Создайте новый тег версии:
   ```bash
   git tag -a v1.0.1 -m "Версия 1.0.1"
   git push origin v1.0.1
   ```

2. GitHub Actions автоматически запустит workflow "Release to Google Play"
3. После завершения сборки, на вкладке "Releases" появится новый релиз с прикрепленным APK-файлом
4. APK также будет отправлен в Google Play Console (если настроены соответствующие секреты)

## Архитектура

Приложение построено с использованием архитектуры Provider для управления состоянием и следует принципам чистой архитектуры.

- `lib/models/` - Модели данных
- `lib/screens/` - Экраны приложения
- `lib/widgets/` - Пользовательские виджеты
- `lib/services/` - Сервисы (NFC, шифрование и т.д.)

## Ограничения

- Эмуляция банковских карт ограничена возможностями API Android и наличием соответствующих разрешений
- Приложение не поддерживает эмуляцию защищенных платежных систем без дополнительных сертификатов и разрешений
- На iOS функциональность чтения, но не эмуляции карт

## Лицензия

Этот проект лицензирован под MIT License - см. файл [LICENSE](LICENSE) для деталей

## Разработка

### CI/CD

Проект настроен для автоматической сборки с использованием GitHub Actions. При каждом пуше в ветку `main` будет происходить сборка APK файла, который можно скачать в артефактах.

### Вклад в проект

1. Сделайте форк репозитория
2. Создайте ветку для вашей функции (`git checkout -b feature/amazing-feature`)
3. Зафиксируйте ваши изменения (`git commit -m 'Add amazing feature'`)
4. Отправьте изменения в вашу ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request 