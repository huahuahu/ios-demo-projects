enum SampleCatalog {
  static let sections: [AppCatalogSection] = [
    makeSection(
      id: "featured",
      title: "本周精选",
      subtitle: "值得立刻体验的新鲜内容",
      makeContent: CatalogSectionContent.featured,
      items: featuredItems,
      pageSize: 1
    ),
    makeSection(
      id: "recommended",
      title: "你可能会喜欢",
      subtitle: nil,
      makeContent: CatalogSectionContent.appList,
      items: recommendedItems,
      pageSize: 3
    ),
    AppCatalogSection(
      id: "categories",
      title: "浏览类别",
      subtitle: nil,
      content: .categories(
        CategoryGroupingStrategy.columns(
          sectionID: "categories",
          categories: categoryItems
        )
      )
    ),
    makeSection(
      id: "stories",
      title: "探索新体验",
      subtitle: "编辑团队为你挑选",
      makeContent: CatalogSectionContent.editorial,
      items: storyItems,
      pageSize: 1
    ),
    makeSection(
      id: "popular",
      title: "热门 App",
      subtitle: "大家最近都在下载",
      makeContent: CatalogSectionContent.appList,
      items: popularItems,
      pageSize: 3
    ),
    makeSection(
      id: "essential",
      title: "效率必备",
      subtitle: nil,
      makeContent: CatalogSectionContent.appList,
      items: essentialItems,
      pageSize: 3
    ),
  ]

  private static let featuredItems = [
    item(
      "stargazer", "星图日记", "记录每天仰望的天空", "本周主打", "把夜空装进口袋", "sparkles", "moon.stars.fill", .indigo),
    item(
      "slow-island", "慢岛", "留一点时间给自己", "编辑精选", "在一座小岛上放慢呼吸", "leaf.fill", "sun.horizon.fill", .coral
    ),
    item(
      "sound-map", "城市声景", "收集旅途中的声音", "新鲜 App", "听见城市不为人知的一面", "waveform",
      "building.2.crop.circle.fill", .aqua),
  ]

  private static let recommendedItems = [
    item("paper-plane", "纸飞机", "轻盈的旅行计划", "旅行", "下一站，随心出发", "paperplane.fill", "map.fill", .aqua),
    item("focus-tide", "潮汐专注", "白噪音与番茄钟", "效率", "给专注一个自然节拍", "timer", "water.waves", .indigo),
    item("plant-note", "植遇", "照顾你的植物朋友", "生活", "每一片新叶都值得记录", "leaf.fill", "camera.macro", .mint),
    item(
      "palette", "拾色", "随手保存灵感配色", "设计", "从真实世界采集颜色", "paintpalette.fill", "swatchpalette.fill",
      .pink),
    item("recipe", "一餐", "今天吃什么", "美食", "用手边食材做好一餐", "fork.knife", "carrot.fill", .orange),
    item(
      "habit", "微小习惯", "每天进步一点点", "健康", "让改变轻松发生", "checkmark.circle.fill",
      "chart.line.uptrend.xyaxis", .violet),
    item(
      "read", "页间", "安静的阅读清单", "图书", "把想读的书放在一起", "books.vertical.fill", "text.book.closed.fill",
      .coral),
  ]

  private static let categoryItems = [
    category("lifestyle", "生活", "chair.lounge.fill", .coral),
    category("utilities", "工具", "calculator.fill", .orange),
    category("entertainment", "娱乐", "popcorn.fill", .coral),
    category("social", "社交", "bubble.left.and.bubble.right.fill", .violet),
    category("travel", "旅游", "airplane", .mint),
    category("photo", "摄影", "camera.fill", .aqua),
    category("health", "健康健美", "heart.fill", .pink),
    category("education", "教育", "graduationcap.fill", .indigo),
    category("shopping", "购物", "cart.fill", .orange),
    category("music", "音乐", "music.note", .aqua),
  ]

  private static let storyItems = [
    item(
      "museum", "掌上博物馆", "在细节中发现艺术", "精彩专题", "一件藏品，一段穿越时间的故事", "building.columns.fill",
      "photo.artframe", .orange),
    item(
      "trail", "旷野路线", "寻找城市附近的自然", "周末灵感", "这个周末去哪里走走？", "figure.hiking", "mountain.2.fill", .mint),
    item(
      "music-room", "小小音乐室", "随时记录一段旋律", "创作工具", "从第一个音符开始创作", "music.note", "pianokeys", .violet),
  ]

  private static let popularItems = [
    item(
      "translate", "轻译", "自然好用的随身翻译", "工具", "跨过语言边界", "character.book.closed.fill",
      "globe.asia.australia.fill", .aqua),
    item(
      "weather", "云知道", "清晰的逐小时天气", "天气", "出门前看懂天空", "cloud.sun.fill", "cloud.rainbow.half", .indigo
    ),
    item(
      "budget", "小账本", "简单记录每日开销", "财务", "让每一笔都心中有数", "yensign.circle.fill", "chart.pie.fill",
      .orange),
    item(
      "scan", "一拍即扫", "把纸张变成清晰文档", "商务", "随身携带的扫描仪", "doc.viewfinder.fill", "doc.text.viewfinder",
      .coral),
    item(
      "podcast", "耳边", "发现值得听的节目", "娱乐", "让声音陪你走一段路", "headphones", "waveform.circle.fill", .pink),
    item(
      "calendar", "日程方格", "一眼看清一周安排", "效率", "把时间放进合适的位置", "calendar", "rectangle.grid.2x2.fill",
      .violet),
    item(
      "fitness", "动一动", "轻量居家训练", "健康", "从今天的一小步开始", "figure.run",
      "figure.strengthtraining.traditional", .mint),
    item("photo", "光影修图", "自然细腻的照片滤镜", "摄影", "找回照片里的光", "camera.filters", "camera.aperture", .aqua),
  ]

  private static let essentialItems = [
    item("files", "收纳夹", "整理散落的文件", "效率", "给数字生活留出秩序", "folder.fill", "tray.full.fill", .indigo),
    item(
      "clipboard", "摘抄", "收藏重要文字片段", "工具", "不再错过一句好文字", "doc.on.clipboard.fill",
      "quote.bubble.fill", .coral),
    item(
      "mail", "清简邮箱", "专注重要来信", "商务", "让收件箱轻一点", "envelope.fill", "paperplane.circle.fill", .aqua),
    item("password", "密钥盒", "安全保管账号信息", "工具", "重要信息妥善保存", "key.fill", "lock.shield.fill", .violet),
    item("notes", "灵感便笺", "快速捕捉想法", "效率", "念头出现时马上记下", "note.text", "lightbulb.max.fill", .orange),
    item(
      "timer", "时光刻度", "多个计时器井然有序", "工具", "让等待也清清楚楚", "stopwatch.fill", "clock.badge.fill", .mint),
  ]

  private static func makeSection(
    id: String,
    title: String,
    subtitle: String?,
    makeContent: ([AppGroupPage]) -> CatalogSectionContent,
    items: [StoreAppItem],
    pageSize: Int
  ) -> AppCatalogSection {
    AppCatalogSection(
      id: id,
      title: title,
      subtitle: subtitle,
      content: makeContent(
        GroupingStrategy.pages(sectionID: id, items: items, pageSize: pageSize)
      )
    )
  }

  private static func category(
    _ id: String,
    _ title: String,
    _ symbol: String,
    _ palette: AppPalette
  ) -> StoreCategory {
    StoreCategory(id: id, title: title, symbol: symbol, palette: palette)
  }

  private static func item(
    _ id: String,
    _ name: String,
    _ subtitle: String,
    _ eyebrow: String,
    _ featureTitle: String,
    _ iconSymbol: String,
    _ heroSymbol: String,
    _ palette: AppPalette
  ) -> StoreAppItem {
    StoreAppItem(
      id: id,
      name: name,
      subtitle: subtitle,
      eyebrow: eyebrow,
      featureTitle: featureTitle,
      iconSymbol: iconSymbol,
      heroSymbol: heroSymbol,
      palette: palette
    )
  }
}
