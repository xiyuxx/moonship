# AI 素材提示词包

## 视觉基准

参考图所传达的方向是：**第一人称可探索的卡通 3D 邮局空间**。

- 圆润、略低多边形的几何体，边缘有明显倒角；
- 厚木梁、木地板、金属支架、模块化货架；
- 物品丰富但工作动线清楚，空间有“正在营业”的生活感；
- 海上傍晚的冷蓝环境光，与暖黄吊灯、窗光形成对比；
- 手绘感主要来自材质色块、轻微磨损和柔和的色彩，不要做写实 PBR；
- 猫咪世界中的拟人动物是居民，空间尺度与人类一致。

## 使用方式

1. 每次提示词先保留“统一风格前缀”。
2. 环境概念图使用 16:9；单个道具使用方形 1:1；角色用角色设定图/三视图。
3. AI 图像最适合用于概念、美术参考、2D UI 与背景。需要在 Godot 中使用的 3D 道具，建议先用生成图定稿，再手工搭建低模或购买/改造可商用模型。
4. 不要要求模型在图中生成可读文字、地址、商标或 UI 文案；这些应在 Godot 内以文字和贴图实现。

## 统一风格前缀

将这一段放在所有环境和 3D 道具提示词开头：

```text
cozy stylized 3D game art for a first-person exploration game, rounded low-poly forms with beveled edges, hand-painted color-block materials, practical modular wooden construction, slightly imperfect handcrafted details, rich but readable prop density, cool twilight blue ambient light contrasted with warm amber lanterns, soft global illumination, whimsical maritime atmosphere, game-ready proportions, no text, no logos, no watermark
```

通用负面提示词：

```text
photorealistic, realistic human, horror, grimy decay, cyberpunk, hard sci-fi, flat vector art, tiny unreadable labels, readable text, logo, watermark, clutter blocking every path, fisheye distortion
```

## 1. 船上邮局：整体风格基准图

```text
[统一风格前缀]
Interior of a compact sea-going postal ship run by anthropomorphic cats.
Eye-level first-person game view, wide 16:9 composition. A wooden postal cabin with sturdy beams,
parcel shelves, a receiving counter, a packing table, a label-printing station, a special-handling desk,
a small insulated cold-storage cabinet, and a tiny glass greenhouse cabinet.
Many parcels, envelopes, twine, stamp pads, route maps and brass lanterns, but a clear walkable central aisle.
Portholes reveal a calm dark teal sea at dusk. Warm lamps make the cabin safe and inviting.
No characters, no text, no logos, no watermark.
```

## 2. 船外观概念图

```text
[统一风格前缀]
A small magical postal boat travelling between islands at twilight, designed for a world of anthropomorphic cats.
Chunky wooden hull, cream painted cabin, coral-red postal pennant, round portholes, warm windows,
a small crane for parcels, rooftop lanterns, cargo nets, lifebuoy, and a compact greenhouse window.
Three-quarter view from slightly above, calm teal ocean, distant lighthouse silhouette, readable game silhouette.
No characters, no text, no logos, no watermark.
```

## 3. 邮务设备：单个道具概念图

每次只改 `[设备名称]` 与功能细节，保持其它部分不变。

```text
[统一风格前缀]
Single game prop concept: [设备名称] for a maritime cat postal ship.
Three-quarter orthographic-like view, centered on a neutral warm gray background.
Functional, tactile, compact, made from painted wood, brass, canvas and enamel metal.
Include clear interaction surfaces and a believable scale for an anthropomorphic cat worker.
Show only one prop, no character, no text, no logo, no watermark.
```

建议优先生成的设备名称：

- receiving counter with parcel scale and bell（接件柜台与称重台）
- wooden packing table with paper roll, twine, tape dispenser and cardboard boxes（打包台）
- compact label printer with blank paper labels（标签打印机）
- special handling stamp desk with colored stamp pads and seals（特殊标识台）
- modular open parcel shelf with small parcel cubbies（常温货架）
- nautical insulated cold-storage cabinet with frosted glass door（冷冻室）
- compact glass plant cabinet for living parcels and seedlings（温室）
- wall-mounted route board with blank map cards and colored pins（航线看板）

## 4. 包裹与小道具图集

```text
[统一风格前缀]
Game prop sheet of maritime postal parcels for a cozy cat world, arranged in a clean 4 by 3 grid.
Include a sealed cardboard parcel, wooden crate, insulated delivery box, envelope bundle,
potted seedling container, fragile lamp crate, fish cooler, travel trunk, spool of twine,
blank postage stamp sheet, blank address tag, colored special-handling stickers.
Simple isolated props, consistent scale, transparent-background-friendly clean silhouette,
no readable text, no logos, no watermark.
```

## 5. 拟人猫角色：角色设定图

角色设定图先用于统一比例、服装和表情，不直接当游戏模型。

```text
Stylized 3D character concept sheet for a cozy maritime postal game.
An anthropomorphic cat [角色描述] in a practical sea-town outfit.
Rounded low-poly game character proportions, hand-painted materials, expressive ears and tail,
warm approachable personality, full body front view, side view, back view, and four small facial expressions.
Clean neutral background, clear silhouette, no text, no logo, no watermark.
```

可替换的角色描述：

- elderly lighthouse keeper, weathered cardigan, oilskin cape, brass lantern, calm and lonely
- cheerful beach kiosk owner, striped scarf, shell charm, busy and sociable
- young forest expedition leader, canvas backpack, compass, patched explorer jacket, energetic
- town postmaster, neat vest, stamp pouch, gentle and organized

## 6. 四类岛屿：横版背景概念图

### 北礁灯塔

```text
[统一风格前缀]
Side-scrolling 2D game background concept for a wind-swept lighthouse island in a world of anthropomorphic cats.
Rocky shoreline, tall cream lighthouse with a warm glowing window, small keeper's cottage,
rope fences, seabirds, lantern posts, dramatic blue dusk sky and safe warm light near the home.
Clear walkable foreground path, layered parallax background, no characters, no text.
```

### 热闹沙滩景点

```text
[统一风格前缀]
Side-scrolling 2D game background concept for a lively cat beach resort.
Colorful wooden kiosks, striped umbrellas, boardwalk, shell decorations, little ferry dock,
warm sunset, playful but organized tourist activity, clear walkable foreground path,
layered parallax background, no characters, no text.
```

### 森林探险队驻地

```text
[统一风格前缀]
Side-scrolling 2D game background concept for a forest expedition camp run by adventurous cats.
Tall soft-shaped trees, canvas tents, rope bridge, field maps, supply crates, lanterns,
misty green-blue forest light with warm campfire glow, clear walkable foreground path,
layered parallax background, no characters, no text.
```

### 猫咪城镇

```text
[统一风格前缀]
Side-scrolling 2D game background concept for a cozy coastal cat town.
Narrow stone street, warm shop windows, mailboxes, flower balconies, small plaza,
laundry lines, distant sea glimpsed between buildings, early evening light,
clear walkable foreground path, layered parallax background, no characters, no text.
```

## 生成顺序

先生成并确认这六项，再开始批量生产：

1. 船上邮局整体基准图；
2. 船外观；
3. 主角 + 灯塔老人两张角色设定图；
4. 接件柜台、打包台、常温货架三件设备；
5. 北礁灯塔岛背景；
6. 包裹与标签图集。
