# 3D Pixel Art

基于 **Unity 6 / URP** 的 3D 像素风场景与风格化 Shader 实验工程。通过卡通分层光照、描边、动态植被、水面与云影，构建像素画观感的遗迹庭院。

![遗迹庭院](image/1.png)
![云影效果](image/2.png)

## 视频展示

点击链接查看或下载原始 MP4：

- [演示 1](image/Movie_002.mp4)
- [演示 2](image/Movie_003.mp4)
- [演示 3](image/Movie_004.mp4)
- [演示 4](image/Movie_005.mp4)

## 工程内容

- `Cartoon.shadergraph`：卡通分层光照、描边与云影相关参数。
- `Grass.shadergraph`、`Leaf.shadergraph`：草与树叶材质，配合风场子图。
- `Water.shadergraph`：水面扰动、泡沫与反射子图。
- 手写 Shader：能量球、符文图集、云影 Cookie。
- `SampleScene.unity`：包含地形、植被、石柱、水池及特效的展示场景。
- 辅助脚本：相机环绕、树叶生成与云影控制。

## 环境与启动

工程版本为 **Unity 6000.3.11f1**，渲染管线为 **URP 17.3.0**。其他 Unity 版本尚未验证。包依赖由 `Packages/manifest.json` 和 `packages-lock.json` 记录，包括 Input System、Cinemachine 等。

主场景约 144 MB，场景与视频使用 **Git LFS** 存储。请先安装 [Git LFS](https://git-lfs.com/)，再克隆工程：

```bash
git lfs install
git clone https://github.com/nintreesssss/3D-Pixel-Art.git
cd 3D-Pixel-Art
git lfs pull
```

1. 在 Unity Hub 中使用 **Add project from disk** 添加仓库根目录。
2. 使用 Unity **6000.3.11f1** 打开，等待包安装与资源导入。
3. 打开 `Assets/Scenes/SampleScene.unity`，进入 Play 模式。
4. 使用 **A / D** 键让 `CinemaControl` 相机绕目标旋转。

首次导入较大的场景需要等待。建议通过 Git 克隆；ZIP 下载可能未包含完整 LFS 资源。若场景内容以 `version https://git-lfs.github.com/spec/v1` 开头，请运行 `git lfs pull`。

## 目录结构

| 路径 | 内容 |
| --- | --- |
| `Assets/Shader/` | Shader Graph、手写 Shader、共享子图 |
| `Assets/Scripts/` | C# 与 HLSL 辅助代码 |
| `Assets/Materials/` | 场景材质 |
| `Assets/Model/` | 模型与 Mesh |
| `Assets/Profabs/` | 植被预制体，沿用原目录名 |
| `Assets/Texture/` | 植被、噪声、符文等纹理 |
| `Assets/Scenes/` | 主场景与烘焙 Mesh |
| `Assets/Settings/` | URP、Renderer 和 Volume 配置 |
| `Packages/` | 包依赖和版本锁定 |
| `ProjectSettings/` | Unity 工程配置 |
| `image/` | 两张截图和四段演示视频 |

资源路径与 `.meta` 配对保留，避免破坏 Unity GUID 引用。缓存、日志和 IDE 生成文件不纳入版本控制。

## 第三方内容与许可

- 包含 [Cyanilux / URP Shader Graph Custom Lighting](https://github.com/Cyanilux/URP_ShaderGraphCustomLighting)，MIT 许可证保留于 [`Assets/URP_ShaderGraphCustomLighting-6000.1/LICENSE`](Assets/URP_ShaderGraphCustomLighting-6000.1/LICENSE)。相关 HLSL 副本也遵循该许可。
- 本地 `Assets/nTools/PrefabPainter` 是 Asset Store 编辑器工具，不随仓库分发。主场景中对应的隐藏编辑器设置对象已清理，已摆放的场景物体保留。
- 其余代码和美术资源尚未授予统一开源许可证；第三方内容遵循各自许可。

截图与视频为效果参考。实际表现与分辨率、相机和质量设置有关。主场景包含 Pixel Perfect Camera，参考分辨率为 320 × 180；像素风效果结合了相机设置与风格化材质。仓库整理阶段尚未执行 Unity 编辑器运行验证。
