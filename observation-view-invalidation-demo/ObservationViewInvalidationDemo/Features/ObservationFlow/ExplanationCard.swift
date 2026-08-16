import SwiftUI

struct ExplanationCard: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label("如何观察", systemImage: "terminal")
        .font(.headline)

      Text("在 Xcode Console 搜索 OBS-DEMO。建议先点击一次完成预热，再清空日志并点击目标属性。两组实验共享同一个 @Observable model。")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Text("INIT 表示重新构造 View 值；BODY 表示重新计算该 View 的描述。两者都不等于 UIKit 底层视图一定被重建。")
        .font(.caption)
        .foregroundStyle(.secondary)

      Text("首次布局、懒加载等因素可能产生额外 BODY；重复实验的稳定结果更适合判断依赖边界。")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(.blue.opacity(0.1), in: .rect(cornerRadius: 16))
  }
}
