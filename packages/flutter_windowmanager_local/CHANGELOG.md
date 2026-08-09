## 0.2.0

* Finish flutter embedding v2 migration. #17

## 0.1.0

* null-safety migration (@ValeteTech, PR#16)
* Switch to version 2 of flutter embedding.
* Add documentation

## 0.0.2

* Update pubspec.yaml format for newer versions of Flutter, require 1.10.

## 0.0.1+1

* Suppress deprecation warnings in build, all uses are safe.

## 0.0.1

* Initial release.

## Local Qmatch patch

- Added Android `namespace 'io.adaptant.labs.flutter_windowmanager'` for AGP compatibility.
- Removed obsolete Flutter v1 embedding `PluginRegistry.Registrar` registration (API removed
  from current Flutter embedding). FlutterPlugin / ActivityAware (v2) path unchanged.
- Dart API and FLAG_SECURE method-channel behavior unchanged.
- Source: flutter_windowmanager 0.2.0 from pub.dev.
