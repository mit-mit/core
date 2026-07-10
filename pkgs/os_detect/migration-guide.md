# Migration guide

This migration guide details how to migrate to `package:platform` version 3.2 or
later, from the Dart platform APIs located in `package:os_detect`.

## Overview

Package `os_detect` exposes platform APIs, such as `isMacOS`, as top-level
members. In package `platform` similar members exist, but they are placed inside
a `Platform` class. An instance of this class can be access using the `.current`
getter, as illustrated in the sample code below. 

## Automated migration

Run the `dart fix` command inside the project that needs to be migrated.

## Sample migration

Migrate from:
```dart
import 'package:os_detect/os_detect.dart' as Platform;

bool onAndroid = Platform.isAndroid;
```

To:
```dart
import 'package:platform/platform.dart';     // version 3.2.0 or later.

bool onAndroid = Platform.current.isAndroid;
```

