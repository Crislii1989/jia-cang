# 手机端使用指引（PWA）

> 面向「家藏」自用场景：不买开发者账号、不上架应用商店，用一条网址把 App 装到手机上。
> **主用地址（推荐，国内直连秒开）：https://jia-cang.app.workbuddy.host/**
> 备用地址（GitHub Pages，国内直连常被限速，需代理）：https://crislii1989.github.io/jia-cang/
> 更新记录：
> - 2026-09-17 首次打通 GitHub Pages（commit23 工作流 + commit24 加固，run 35219250161 success）
> - 2026-09-17 新增 WorkBuddy 托管线路（国内直连实测：首页 0.68s、主包 4.57MB / 0.98s）；
>   同时修掉一个白屏真凶——静态托管拦截 `assets/.env`（403）导致启动中断，见第五节

---

## 一、这是什么

Web 版就是完整 App：同一套 Dart 代码编译成 Web 产物，功能与手机原生版一致。
数据存在**手机本地**（浏览器数据库 IndexedDB/OPFS），不经任何服务器——
和原生版一样是「本地优先」，隐私不外泄。

首次打开需要联网（约 4.6MB，加载一次）；之后 Service Worker 会把资源缓存到本地，
**断网也能打开**。

⚠️ 两个托管地址是**不同的域名**，各自有独立的本地数据库与 Service Worker，
同一台设备上混用会出现「数据对不上」的错觉。**选定一个长期用**（推荐 WorkBuddy 那条）。

---

## 二、装到手机上

### iPhone / iPad
1. 用 **Safari** 打开 https://jia-cang.app.workbuddy.host/
   （必须是 Safari；微信内置浏览器、Chrome iOS、Edge iOS 都不能「添加到主屏幕」成独立 App）
2. 等页面出现首页（首次约 10~25 秒）
3. 底部**分享**按钮 → 向下滑 → **添加到主屏幕** → 起名「家藏」→ 添加
4. 桌面出现图标，点开是**全屏无浏览器边框**，和原生 App 观感一致

### Android
1. 用 **Chrome** 或 **Edge** 打开同一地址（安卓两个都支持装 PWA）
2. 右上角 **⋮** → **安装应用 / 添加到主屏幕**（部分机型地址栏会直接弹出「安装」）
3. 确认后在桌面/应用列表出现「家藏」图标

### 电脑上也能用
Chrome / Edge 打开同一地址即可，或地址栏右侧「安装」图标装成桌面应用。

---

## 三、⚠️ 数据安全（最重要的一节）

| 事项 | 说明 |
| --- | --- |
| 数据在哪 | 只在这台设备的浏览器里。**换手机、清浏览器数据、卸载 PWA 都会丢** |
| iPhone 特别提醒 | Safari 对「长期不访问」的站点存储有清理策略，**不要几个月不打开** |
| 强制建议 | 在「我的 → 数据备份」里配置 WebDAV（如坚果云），**每周做一次备份** |
| 多设备 | 各设备数据独立；用 WebDAV 备份 + 恢复来同步或迁移 |
| WebDAV 目录 | `/jiacang_backups` |

> 不要依赖「浏览器同步」——浏览器不会同步站点数据。

---

## 四、怎么更新线上版本

两条线路的更新方式**不一样**：

| 线路 | 更新方式 |
| --- | --- |
| GitHub Pages（备用） | `git push origin main` 后**自动**重新构建部署（约 3~5 分钟），见 `.github/workflows/deploy-web.yml` |
| WorkBuddy 托管（主用） | **不会自动更新**：改动后需要用本地产物重新发布一次（重新构建 → 发布 → 覆盖同一链接） |

```bash
git push origin main      # 只触发 GitHub Pages 那条
```

Pages 进度查看：https://github.com/Crislii1989/jia-cang/actions

手机上更新：**彻底关掉再重开** PWA 即可（Service Worker 会自动拉新版本）；
若界面没变，把网址在浏览器里打开并刷新一次再回主屏打开。

> 回滚：`git revert` 或 `git reset` 后再 push，会重新部署上一版本（Pages 线路）。

---

## 五、验证与排障

| 现象 | 处理 |
| --- | --- |
| 白色空白页（GitHub Pages） | 国内直连 `github.io` 常被限速：实测直连 25 秒只下到 1.65MB / 共 4.57MB（卡死超时），走代理 0.84 秒下完。**换主用地址**或给设备挂代理 |
| 白色空白页（其它托管） | 先按 F12 → 网络，看 `main.dart.js` 是否加载失败；再看控制台有没有未捕获异常 |
| 装完图标是旧 logo | 删除主屏图标重新添加（图标被缓存） |
| 数据不见了 | 检查是否换了浏览器/清了数据；用 WebDAV 备份恢复 |
| 部署失败 | 去 Actions 页面看红叉任务的日志，多数是构建依赖问题 |

踩过的坑（均已修）：
- **静态托管拦截点号开头的文件 → 白屏**：WorkBuddy 托管对 `assets/.env` 返回 403，
  而 Flutter 引擎资源加载失败会抛未捕获异常、`dotenv.env` 在加载失败后再读还会抛
  `NotInitializedError`，任一处都会中断 `main()` 使 `runApp()` 不执行 → 纯白屏。
  已在 `lib/main.dart` 改为 **Web 端整体跳过 .env**（Bugsnag 本就不支持 Web），
  本地已复现并验证修复。换托管平台若又白屏，先查这一条。
- Pages 站点必须存在，`actions/configure-pages` 才能过。工作流里虽开了
  `enablement: true`，但 GITHUB_TOKEN **无权创建** Pages 站点（实测报
  `Resource not accessible by integration`）——所以站点已由本人手动创建，
  若哪天被删掉，需在仓库 Settings → Pages → Source 选 GitHub Actions 重建。
- 工作流里 `cp .env.example .env` 依赖 `.env.example` 已入库，别把它删了。
- 两条线路的产物 `base-href` 不同：Pages 是 `/jia-cang/`，WorkBuddy 托管是 `/`，
  发布前要按目标路径重新构建，别直接复用另一条线路的产物。

---

## 六、附：想要真正的原生安装包

### Android APK（无需 Mac，GitHub 免费构建）
仓库已带 `.github/workflows/flutter_build_apk.yml`，推送 `v*` 标签即自动出 APK：

```bash
git tag v1.2.0 && git push origin v1.2.0
```

产物在 Releases 里。⚠️ 需先在仓库 Secrets 配置：
`BUGSNAG_API_KEY`、`KEYSTORE_BASE64`、`KEYSTORE_PASSWORD`、`KEY_ALIAS`、`KEY_PASSWORD`
（未配置时该工作流会直接报错退出）。

### iOS
必须 Mac + Xcode 编译（Windows 无法产出 iOS 包）。
- 自用：免费 Apple ID 自签，**7 天有效需重新签**
- 长期：付费开发者账号 ¥688/年，走 Ad Hoc / TestFlight（**不必上架 App Store**）

结论：**想上手机直接用，PWA 这条路的成本最低**；要长期免维护的原生体验，再考虑 Android APK / iOS 自签。
