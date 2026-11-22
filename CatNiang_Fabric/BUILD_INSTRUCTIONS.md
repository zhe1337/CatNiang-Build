# CatNiang 1.5.1 - Fabric Mod Build Instructions

## 项目结构
```
CatNiang_Fabric/
├── build.gradle          # Gradle 构建脚本 (Fabric Loom)
├── gradle.properties     # 版本配置
├── settings.gradle       # Gradle 设置
└── src/
    ├── main/
    │   ├── java/
    │   │   └── dev/BULLWW/...  # 完整源码 (包含新增的 PistonCrystalPlus)
    │   └── resources/
    │       ├── fabric.mod.json      # 模组元数据
    │       ├── bullww.accesswidener # Access Widener
    │       ├── bullww.mixins.json   # Mixin 配置
    │       ├── kimi-title.mixins.json
    │       └── assets/              # 资源文件
```

## 编译步骤 (在电脑上运行)

### 1. 环境要求
- JDK 17+
- Git (可选)

### 2. 克隆/解压项目
```bash
# 如果是从压缩包解压
tar -xzf CatNiang_Fabric.tar.gz
cd CatNiang_Fabric
```

### 3. 添加模块注册 (重要!)
在 `src/main/java/dev/BULLWW/Bullww.java` 的 `register()` 方法中添加新模块：

```java
// 在 register() 方法中，找到战斗模块注册区域，添加:
MODULE.addModule(new PistonCrystalPlus());
```

或者在 ModuleManager 的 init() 反射列表中添加：
```java
"dev.BULLWW.mod.modules.impl.combat.PistonCrystalPlus"
```

### 4. 编译
```bash
# Linux/macOS
./gradlew build

# Windows
gradlew.bat build
```

### 5. 输出文件
编译成功后，生成的 JAR 文件在：
```
build/libs/CatNiang-1.5.1.jar
```

## 新增模块: PistonCrystalPlus
- **位置**: 战斗类别
- **功能**: 活塞+红石块+水晶推送攻击
- **设置**:
  - Fire (是否点火) - 默认开启
  - Range (攻击范围) - 1-6 格，默认 5
  - Delay (延迟) - 0-500ms，默认 50ms
- **中文名**: 活塞水晶+

## 依赖说明
build.gradle 中已配置：
- Fabric Loader 0.15.11
- Minecraft 1.21.1 (Intermediary mappings)
- Fabric API 0.95.0+1.21.1

原版 JAR 中的嵌套 JAR (IAS, Satin, Skija 等) 已作为依赖配置，无需手动处理。

## 注意事项
1. 确保在 Bullww.java 的 register() 中注册了 PistonCrystalPlus
2. 如果编译报错，检查 1.21.1 intermediary mappings 中的字段名：
   - 活塞物品: `class_1792.field_10743` (需验证)
   - 打火石: `class_1792.field_11678` (需验证)
3. 如有映射字段错误，请根据 1.21.1 mappings 调整 PistonCrystalPlus.java 中的字段名

## 快速测试
```bash
./gradlew runClient
```
