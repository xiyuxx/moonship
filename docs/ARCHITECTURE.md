# 代码与场景架构

## 运行调用链

```text
project.godot
  -> Main.tscn
	-> main.gd（场景协调器）
	   -> scripts/world/ship_builder.gd（构建 3D 船舱与格位）
	   -> scripts/ui/game_hud.gd（创建 HUD 与岛屿覆盖层）
	   -> scripts/data/order_data.gd（提供每日订单）
	   -> scripts/views/island_view.gd（绘制并驱动横版岛屿）
```

## 模块职责

| 文件 | 职责 | 调用方 |
|---|---|---|
| `main.gd` | 输入分发、昼夜/订单/仓储/背包流程、模块编排 | `Main.tscn` |
| `scripts/world/ship_builder.gd` | 船舱灯光、墙体、工作台、仓储格位、玩家和相机 | `main.gd::_build_ship` |
| `scripts/ui/game_hud.gd` | 顶部 HUD、提示、岛屿 CanvasLayer 的节点创建 | `main.gd::_build_hud`、`_build_island` |
| `scripts/views/package_view.gd` | 包裹的生成、封箱、面单与持取/放置 | `main.gd` 的包裹流程 |
| `scripts/data/order_data.gd` | 订单样例与后续订单池 | `main.gd::_ready`、新一天流程 |
| `scripts/views/island_view.gd` | 岛屿的绘制、快递员移动和区域判断 | `GameHud.build_island`，再由 `main.gd` 驱动 |

## 边界约定

- `main.gd` 不再创建 3D 静态物体、HUD 控件或包裹外观；新增船舱设施放进 `ShipBuilder`，新增 HUD 元素放进 `GameHud`，包裹外观放进 `PackageView`。
- `IslandView` 不处理订单、金币或背包，只提供位置和区域判断。
- `OrderData` 只保存数据；不要让它引用场景节点。
- `storage_slots` 由 `ShipBuilder` 注册，`slot_orders` 与 `slot_visuals` 仍由主流程维护，保证数据与对应包裹视觉同步。

根目录中的 `main_refactored.gd` 与 `main_storage.gd` 是未接入启动场景的实验版本，当前入口始终为 `Main.tscn -> main.gd`；在确认不再需要其历史参考后可另行清理。
