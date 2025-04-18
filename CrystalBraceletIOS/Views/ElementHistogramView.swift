import SwiftUI
import Charts

struct ElementHistogramView: View {
    var current: ElementRatio
    var goal: ElementRatio
    var colors: AnalysisResponse.ElementColors

    struct Bar: Identifiable { let id = UUID(); var element: String; var type: String; var value: Double; var hex: String }

    var dataset: [Bar] {
        [
            ("金", current.metal,  goal.metal,  colors.metal),
            ("木", current.wood,   goal.wood,   colors.wood),
            ("水", current.water,  goal.water,  colors.water),
            ("火", current.fire,   goal.fire,   colors.fire),
            ("土", current.earth,  goal.earth,  colors.earth)
        ].flatMap { name, curr, tar, hex in
            [Bar(element: name, type: "当前", value: curr, hex: hex),
             Bar(element: name, type: "目标", value: tar, hex: hex)]
        }
    }

    var body: some View {
        Chart(dataset) { bar in
            BarMark(
                x: .value("百分比", bar.value),
                y: .value("五行", bar.element)
            )
            .opacity(bar.type == "当前" ? 0.4 : 1.0)
            .annotation(position: .overlay, alignment: .trailing) {
                Text("\(Int(bar.value))%")
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .offset(x: 4)
            }
            .foregroundStyle(Color(hex: bar.hex))
        }
        .frame(height: 220)
        .chartXAxis(.hidden)
        .chartYAxis { AxisMarks(position: .leading) }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
