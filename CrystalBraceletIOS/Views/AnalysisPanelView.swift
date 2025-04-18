import SwiftUI
import MarkdownUI

struct AnalysisPanelView: View {
    @EnvironmentObject var analysisVM: AnalysisViewModel
    var text: String
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("分析报告").font(.headline)
                Spacer()
                Button(action: { analysisVM.copyReport() }) { Image(systemName: "doc.on.doc") }
            }
            ScrollView {
                Markdown(text)
                    .markdownTheme(.gitHub)          // replaces deprecated .markdownStyle
                    .font(.system(size: 14))
            }
            .frame(maxHeight: expanded ? .infinity : 180)
            .mask {
                LinearGradient(stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: expanded ? 1 : 0.85),
                    .init(color: .clear, location: expanded ? 1 : 1)
                ], startPoint: .top, endPoint: .bottom)
            }
            Button(expanded ? "收起" : "展开全文") { withAnimation { expanded.toggle() } }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }
}
