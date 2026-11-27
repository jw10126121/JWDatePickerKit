在项目根目录执行以下命令，将当前 Podspec 版本发布到 JWPublicSpecs。

```sh
bundle exec fastlane ios release_private_pod
```

发布前需更新 `JWDatePickerKit.podspec` 的版本号，并提交、推送源码改动。默认 Specs 仓库路径为项目同级目录 `../JWPublicSpecs`，也可通过 `JW_PUBLIC_SPECS_PATH` 指定其他 checkout 路径。
